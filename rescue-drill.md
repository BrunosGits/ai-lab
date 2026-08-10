# Rescue Mode Drill — Runbook

**Goal:** prove we can reboot into OVH rescue mode, mount the data disk, verify access,
and get back to a normal boot before it's ever actually needed. **No data loss, no reinstall.**

- Server: `<vps-ip>` (OVH VPS-1 2027, Debian 13, local disk)
- When: once, before Phase 2 (Docker). Budget ~30 min.
- Risk: LOW (this is a safe reboot. Rescue leaves the disk untouched until you mount it read-only first)

---

## Step 0 — Before you start (on your computer)

Save the current state so we can compare after the drill:

```sh
ssh <user>@<vps-ip> 'echo "--- disk"; lsblk -o NAME,SIZE,FSTYPE,MOUNTPOINT; \
echo "--- fstab"; cat /etc/fstab; \
echo "--- services"; for s in ssh postgresql hello fail2ban; do printf "%s=%s\n" "$s" "$(systemctl is-active $s)"; done; \
echo "--- ufw-iptables"; sudo iptables -S INPUT | head; sudo iptables -L DOCKER-USER -n; \
echo "--- uptime"; uptime' > /tmp/pre-drill-state.txt
```

Save a marker file (so rescue has something unique to look for):

```sh
echo "rescue-drill-$(date -u +%F)" | ssh <user>@<vps-ip> 'cat > /home/<user>/drill-marker.txt; sudo sh -c "cat > /root/drill-marker.txt"'
```

Have credentials handy (both needed later):
- Rescue password → arrives **by email** from OVH when rescue is activated
- Debian password = `VPS_SECRET` in Infisical (fallback: `<user>` account)

---

## Step 1 — Boot into rescue mode (OVH dashboard)

1. OVH Control Panel → Bare Metal Cloud → your VPS → **Reboot** tab
2. **Boot mode** → `Rescue` → choose **rescue-customer** (Debian 12, cloud-init available)
3. Save, then **Restart**
4. Wait for status `DONE` (2–5 min). OVH emails you the **rescue IP + password**
5. Take note of the rescue IP (different from `<vps-ip>`!)

> The rescue environment runs in RAM. Your disk (`/dev/sda`) is *not* mounted yet.
> Nothing is modified until we mount it ourselves.

---

## Step 2 — Mount the disk read-only (verify data)

```sh
# from your computer, using the rescue IP from the email
ssh root@<RESCUE_IP>
# password from the email (the keyboard layout quirk: "$" etc. can differ — paste carefully)

lsblk                      # confirm /dev/sda with sda1 (ext4 root)
mount -o ro /dev/sda1 /mnt
grep -c rescue-drill /mnt/home/<user>/drill-marker.txt   # expect 1
cat /mnt/home/<user>/drill-marker.txt
umount /mnt

# extra check: confirm the data partition would mount rw if needed
e2fsck -n /dev/sda1        # read-only check, no writes
```

Expected result: marker file present → disk is intact and readable.

---

## Step 3 — Verify a credential recovery path (do this SECOND)

Recovery does not depend on the Linux password (we can chroot in rescue). Prove it:

```sh
mount -o rw /dev/sda1 /mnt
mount --bind /dev /mnt/dev
mount --bind /proc /mnt/proc
mount --bind /sys /mnt/sys
chroot /mnt /bin/bash
# inside chroot:
cat /etc/shadow | grep <user>     # hash present (no need to log in)
exit
# clean up
umount /mnt/dev /mnt/proc /mnt/sys
umount /mnt
```

This demonstrates: even with zero login access, we can enter the system from rescue.

---

## Step 4 — Reboot back to normal

1. OVH dashboard → VPS → **Reboot** tab → Boot mode: **Boot from disk**
2. Save, then **Restart**
3. Wait ~2 min, then:

```sh
ssh <user>@<vps-ip> 'uptime; lsblk; systemctl is-active ssh postgresql hello fail2ban docker'
sudo iptables -S INPUT   # should show 22/80/443 ACCEPT + DROP policy
```

Compare with `/tmp/pre-drill-state.txt` (disk, fstab, services must match).

---

## Step 5 — Close out

- [ ] Remove marker files: `rm /home/<user>/drill-marker.txt /root/drill-marker.txt`
- [ ] Record the drill in the private session log (local `session-log.md`, timing, what worked, what surprised)
- [ ] Check the printed plan blockquote note gets ticked / noted

---

## Notes & gotchas

- **Keyboard layout** in rescue: the on-screen/SSH console can map symbols oddly. Type passwords carefully.
- **Rescue password** arrives by email only. Check spam. One password per activation.
- **Do NOT reboot from the SSH shell.** Always use the OVH dashboard so we control the boot mode.
- The disk is **local SSD** (not LVM, no RAID) → `/dev/sda1` directly, no volume groups to activate.
- Firewall is pure iptables (ufw removed when netfilter-persistent was installed for the DOCKER-USER chain). Verify with `iptables -S INPUT` (DROP policy + 22/80/443 ACCEPT) and `iptables -L DOCKER-USER -n` (default-drop). Rules persist in `/etc/iptables/rules.v4` and `rules.v6` via `netfilter-persistent save`.
- If anything looks wrong after reboot: reselect **Boot from disk** and restart again. The rescue flag was still set.
