#!/usr/bin/env bash
set -euo pipefail

# ai-lab backup script
# Backs up PostgreSQL, Docker volumes, and config files
# Encrypts with age, uploads to Backblaze B2

# ============ CONFIGURATION ============
PROJECT_DIR="/home/bruno/ai-lab"
BACKUP_DIR="/home/bruno/ai-lab/backups"
TIMESTAMP=$(date +"%Y%m%d-%H%M%S")
RETENTION_DAYS=30

# Age encryption (public key for encryption)
AGE_PUBLIC_KEY="age10fvp8smrv8lzugxkm0na39kn9q3gcrahmtmml26pqrfganu6mf8s2f87ne"

# Infisical machine identity
INFISICAL_TOKEN="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpZGVudGl0eUlkIjoiYzIzZDMyNTUtYzBmMC00NDE1LWI5OTQtMjRjYzAyNDc1NDE2IiwiaWRlbnRpdHlOYW1lIjoibWFjLWNsaSIsImF1dGhNZXRob2QiOiJ1bml2ZXJzYWwtYXV0aCIsIm9yZ0lkIjoiYTRlZDBmMjYtMjAwMS00ZmNlLTk5NGEtODMxNmViMWZlYzYxIiwicm9vdE9yZ0lkIjoiYTRlZDBmMjYtMjAwMS00ZmNlLTk5NGEtODMxNmViMWZlYzYxIiwicGFyZW50T3JnSWQiOiJhNGVkMGYyNi0yMDAxLTRmY2UtOTk0YS04MzE2ZWIxZmVjNjEiLCJjbGllbnRTZWNyZXRJZCI6IjFiMjRkNmU2LWRkYzQtNGUwMS1iMmQ5LTFmM2UyMjZlNWE5MSIsImlkZW50aXR5QWNjZXNzVG9rZW5JZCI6IjlkOGU2YTdmLWUxM2ItNGYwNy05NjA0LTllOTRlNTViOGUyMSIsImlwUmVzdHJpY3Rpb25FbmFibGVkIjp0cnVlLCJhY2Nlc3NUb2tlblRUTCI6MjU5MjAwMCwiYWNjZXNzVG9rZW5NYXhUVEwiOjI1OTIwMDAsImFjY2Vzc1Rva2VuUGVyaW9kIjowLCJjcmVhdGlvbkVwb2NoIjoxNzg3MTk0MzE5LCJhdXRoVG9rZW5UeXBlIjoiaWRlbnRpdHlBY2Nlc3NUb2tlbiIsImlkZW50aXR5QXV0aCI6e30sImlhdCI6MTc4NzE5NDMxOSwiZXhwIjoxNzg5Nzg2MzE5LCJqdGkiOiI5ZDhlNmE3Zi1lMTNiLTRmMDctOTYwNC05ZTk0ZTU1YjhlMjEifQ.U-kUSP5e91q1shCaeIYfyEeqN0L9BBtdMxyjqTAjKDY"
INFISICAL_PROJECT_ID="7ea02e25-4a83-47a1-a90e-985ef82f3eb6"
INFISICAL_ENV="prod"

# rclone
RCLONE_B2_BUCKET="ai-lab-backups"

# ============ FUNCTIONS ============
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"
}

# ============ MAIN ============
log "Starting backup: $TIMESTAMP"
mkdir -p "$BACKUP_DIR"

# ---- 1. Fetch secrets from Infisical ----
log "Fetching secrets from Infisical..."
POSTGRES_USER=$(infisical run --token="$INFISICAL_TOKEN" --domain=https://app.infisical.com/api --projectId="$INFISICAL_PROJECT_ID" --env="$INFISICAL_ENV" --path=/ --recursive -- printenv 2>/dev/null | grep '^POSTGRES_USER=' | cut -d= -f2-)
POSTGRES_DB=$(infisical run --token="$INFISICAL_TOKEN" --domain=https://app.infisical.com/api --projectId="$INFISICAL_PROJECT_ID" --env="$INFISICAL_ENV" --path=/ --recursive -- printenv 2>/dev/null | grep '^POSTGRES_DB=' | cut -d= -f2-)
POSTGRES_PASSWORD=$(infisical run --token="$INFISICAL_TOKEN" --domain=https://app.infisical.com/api --projectId="$INFISICAL_PROJECT_ID" --env="$INFISICAL_ENV" --path=/ --recursive -- printenv 2>/dev/null | grep '^POSTGRES_PASSWORD=' | cut -d= -f2-)

if [[ -z "$POSTGRES_USER" || -z "$POSTGRES_DB" || -z "$POSTGRES_PASSWORD" ]]; then
    log "ERROR: Could not fetch PostgreSQL credentials from Infisical"
    exit 1
fi
log "PostgreSQL credentials loaded"

# ---- 2. PostgreSQL dump ----
log "Dumping PostgreSQL..."
DB_DUMP="$BACKUP_DIR/ai-lab-db-$TIMESTAMP.dump"
docker exec -e PGPASSWORD="$POSTGRES_PASSWORD" \
    ai-lab-postgres pg_dump -Fc -U "$POSTGRES_USER" -d "$POSTGRES_DB" > "$DB_DUMP"
log "Database dump: $DB_DUMP ($(du -h "$DB_DUMP" | cut -f1))"

# ---- 3. Docker volumes (pgdata, caddy_data, caddy_config) ----
log "Archiving Docker volumes..."
VOLUMES_TAR="$BACKUP_DIR/ai-lab-volumes-$TIMESTAMP.tar.gz"
docker run --rm \
    -v ai-lab_pgdata:/data/pgdata:ro \
    -v ai-lab_caddy_data:/data/caddy_data:ro \
    -v ai-lab_caddy_config:/data/caddy_config:ro \
    -v "$BACKUP_DIR":/backup \
    alpine tar -czf "/backup/ai-lab-volumes-$TIMESTAMP.tar.gz" -C /data .
log "Volumes archive: $VOLUMES_TAR ($(du -h "$VOLUMES_TAR" | cut -f1))"

# ---- 4. Config files (compose.yaml, Caddyfile, scripts, etc.) ----
log "Archiving config files..."
CONFIG_TAR="$BACKUP_DIR/ai-lab-config-$TIMESTAMP.tar.gz"
tar -czf "$CONFIG_TAR" -C "$PROJECT_DIR" \
    compose.yaml \
    Caddyfile \
    scripts/ \
    .gitignore \
    README.md \
    rescue-drill.md \
    2>/dev/null || true
log "Config archive: $CONFIG_TAR ($(du -h "$CONFIG_TAR" | cut -f1))"

# ---- 5. Encrypt all archives with age ----
log "Encrypting archives..."
ENCRYPTED_FILES=()
for file in "$DB_DUMP" "$VOLUMES_TAR" "$CONFIG_TAR"; do
    if [[ -f "$file" ]]; then
        encrypted="${file}.age"
        age -r "$AGE_PUBLIC_KEY" -o "$encrypted" "$file"
        rm -f "$file"
        ENCRYPTED_FILES+=("$encrypted")
        log "Encrypted: $encrypted ($(du -h "$encrypted" | cut -f1))"
    fi
done

# ---- 6. Upload to B2 ----
log "Uploading to Backblaze B2..."
for file in "${ENCRYPTED_FILES[@]}"; do
    rclone copy "$file" "b2:$RCLONE_B2_BUCKET/" --progress
    log "Uploaded: $(basename "$file")"
done

# ---- 7. Cleanup old local backups ----
log "Cleaning up local backups older than $RETENTION_DAYS days..."
find "$BACKUP_DIR" -name "ai-lab-*.age" -mtime +$RETENTION_DAYS -delete
log "Local cleanup done"

# ---- 8. Create latest symlinks for easy restore ----
log "Creating latest symlinks..."
for file in "${ENCRYPTED_FILES[@]}"; do
    base=$(basename "$file" | sed 's/-[0-9]\{8\}-[0-9]\{6\}//')
    ln -sf "$(basename "$file")" "$BACKUP_DIR/$base"
done

log "Backup completed successfully: $TIMESTAMP"