#!/usr/bin/env bash
# Trello Personal Kanban sync for the AI Lab project.
#
# Reads credentials from TRELLO_API_KEY and TRELLO_TOKEN env vars, or from
# ~/.config/ai-lab/trello.conf.
#
# Commands:
#   sync  ensure the board, lists and labels, then seed task cards
#   init  ensure the board, lists and labels only
#   seed  push new task cards to the project list, the board must exist
#
# Idempotent, safe to rerun. Trello limits each key to 300 requests per 10s,
# a 429 response is retried with backoff.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
CONF_FILE="${TRELLO_CONF:-$HOME/.config/ai-lab/trello.conf}"

BOARD_NAME="Personal Kanban"
LIST_NAMES=("[ai-lab]")
LABEL_PROJECTS=(ai-lab expandir opensearch)
LABEL_COLORS=(blue green orange)
CARD_PREFIX="ai-lab"

log() { printf '[trello-kanban] %s\n' "$*" >&2; }

load_credentials() {
  if [[ -n "${TRELLO_API_KEY:-}" && -n "${TRELLO_TOKEN:-}" ]]; then
    return
  fi
  if [[ ! -f "$CONF_FILE" ]]; then
    echo "No Trello credentials found." >&2
    echo "Set TRELLO_API_KEY and TRELLO_TOKEN, or create $CONF_FILE." >&2
    exit 1
  fi
  # shellcheck disable=SC1090
  source "$CONF_FILE"
  if [[ -z "${TRELLO_API_KEY:-}" || -z "${TRELLO_TOKEN:-}" ]]; then
    echo "trello.conf must define TRELLO_API_KEY and TRELLO_TOKEN." >&2
    exit 1
  fi
}

api_request() {
  local method="$1" endpoint="$2" data="${3:-}"
  local url="https://api.trello.com/1${endpoint}"
  local sep="?"
  [[ "$url" == *\?* ]] && sep="&"
  local tries=0 code tmp part args
  while true; do
    tmp="$(mktemp -t trello.XXXXXX)"
    if [[ "$method" == "GET" ]]; then
      code="$(curl -sS -o "$tmp" -w '%{http_code}' "$url${sep}key=$TRELLO_API_KEY&token=$TRELLO_TOKEN")"
    else
      args=()
      IFS='&' read -ra parts <<<"$data"
      for part in "${parts[@]}"; do
        args+=(--data-urlencode "$part")
      done
      code="$(curl -sS -o "$tmp" -w '%{http_code}' -X "$method" "${args[@]}" "$url${sep}key=$TRELLO_API_KEY&token=$TRELLO_TOKEN")"
    fi
    if [[ "$code" == "429" ]]; then
      rm -f "$tmp"
      tries=$((tries + 1))
      if (( tries >= 5 )); then
        echo "Trello rate limited five times in a row, giving up." >&2
        exit 1
      fi
      log "rate limited (429), retrying in $((tries * 2))s"
      sleep "$((tries * 2))"
      continue
    fi
    if [[ "$code" != 2* ]]; then
      echo "Trello API error $code for $method $endpoint" >&2
      cat "$tmp" >&2
      echo >&2
      rm -f "$tmp"
      exit 1
    fi
    cat "$tmp"
    rm -f "$tmp"
    return 0
  done
}

jfind_id_by_name() {
  # stdin: JSON array of {name,id} objects, args: needle, prints the id
  python3 -c '
import json, sys
needle = sys.argv[1]
for item in json.load(sys.stdin):
    if item.get("name") == needle:
        print(item["id"])
        break
' "$1"
}

jhas_name() {
  # stdin: JSON array of {name} objects, args: needle, prints yes or no
  python3 -c '
import json, sys
needle = sys.argv[1]
print("yes" if any(i.get("name") == needle for i in json.load(sys.stdin)) else "no")
' "$1"
}

jget_id() {
  # stdin: JSON object, prints the id field
  python3 -c 'import json, sys; print(json.load(sys.stdin)["id"])'
}

find_board() {
  local boards
  boards="$(api_request GET "/members/me/boards?fields=name,id")"
  BOARD_ID="$(printf '%s' "$boards" | jfind_id_by_name "$BOARD_NAME")"
  [[ -n "$BOARD_ID" ]]
}

ensure_board() {
  local json
  if find_board; then
    log "using existing board $BOARD_NAME"
    return
  fi
  json="$(api_request POST "/boards" "name=$BOARD_NAME&defaultLists=false")"
  BOARD_ID="$(printf '%s' "$json" | jget_id)"
  log "created board $BOARD_NAME"
}

ensure_lists() {
  local lists name
  lists="$(api_request GET "/boards/$BOARD_ID/lists?fields=name,id")"
  for name in "${LIST_NAMES[@]}"; do
    [[ "$(printf '%s' "$lists" | jhas_name "$name")" == "yes" ]] && continue
    api_request POST "/lists" "name=$name&idBoard=$BOARD_ID" >/dev/null
    log "created list $name"
  done
}

ensure_labels() {
  local labels name i
  labels="$(api_request GET "/boards/$BOARD_ID/labels?fields=name,id")"
  for i in "${!LABEL_PROJECTS[@]}"; do
    name="${LABEL_PROJECTS[$i]}"
    [[ "$(printf '%s' "$labels" | jhas_name "$name")" == "yes" ]] && continue
    api_request POST "/boards/$BOARD_ID/labels" "name=$name&color=${LABEL_COLORS[$i]}" >/dev/null
    log "created label $name"
  done
}

seed_ai_lab() {
  local doc="$REPO_ROOT/ai-lab-summary.md"
  local lists labels cards list_id ai_label card task line
  lists="$(api_request GET "/boards/$BOARD_ID/lists?fields=name,id")"
  labels="$(api_request GET "/boards/$BOARD_ID/labels?fields=name,id")"
  cards="$(api_request GET "/boards/$BOARD_ID/cards?fields=name")"
  list_id="$(printf '%s' "$lists" | jfind_id_by_name "[ai-lab]")"
  ai_label="$(printf '%s' "$labels" | jfind_id_by_name "ai-lab")"
  if [[ -z "$list_id" || -z "$ai_label" ]]; then
    echo "ai-lab list or label missing. Run init first." >&2
    exit 1
  fi
  while IFS= read -r line; do
    task="$(printf '%s' "$line" | sed -E 's/^\s*- \[ \] //')"
    [[ -z "$task" ]] && continue
    card="[$CARD_PREFIX] $task"
    [[ "$(printf '%s' "$cards" | jhas_name "$card")" == "yes" ]] && continue
    api_request POST "/cards" "idList=$list_id&name=$card&idLabels=$ai_label" >/dev/null
    log "seeded $card"
  done < <(grep -E '^\s*- \[ \] ' "$doc" || true)
}

cmd_init() {
  load_credentials
  ensure_board
  ensure_lists
  ensure_labels
  log "init complete"
}

cmd_seed() {
  load_credentials
  if ! find_board; then
    echo "Board $BOARD_NAME not found. Run init first." >&2
    exit 1
  fi
  seed_ai_lab
  log "seed complete"
}

main() {
  local cmd="${1:-}"
  case "$cmd" in
    sync) cmd_init && cmd_seed ;;
    init) cmd_init ;;
    seed) cmd_seed ;;
    *)
      echo "Usage: $0 sync|init|seed" >&2
      exit 1
      ;;
  esac
}

main "$@"
