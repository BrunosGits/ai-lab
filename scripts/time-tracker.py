#!/usr/bin/env python3
"""AI Lab project time tracker.

Usage:
  python3 time-tracker.py start    # mark the start timestamp
  python3 time-tracker.py close    # mark end, compute hours, append session
  python3 time-tracker.py status   # show open session / totals
  python3 time-tracker.py summary  # show totals

State is stored in time-tracker.json next to this script.
"""

import json
import sys
import os
from datetime import datetime, timedelta

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
TRACKER = os.path.join(SCRIPT_DIR, "..", "time-tracker.json")


def load():
    if not os.path.exists(TRACKER):
        return {"current_start": None, "sessions": [], "total_sessions": 0, "total_hours": 0.0}
    with open(TRACKER) as f:
        return json.load(f)


def save(data):
    with open(TRACKER, "w") as f:
        json.dump(data, f, indent=2, ensure_ascii=False)
        f.write("\n")


def now_iso():
    return datetime.now().astimezone().isoformat(timespec="seconds")


def hours_hm(hours):
    total_min = int(round(hours * 60))
    h, m = divmod(total_min, 60)
    return f"{h}h {m:02d}m"


def cmd_start(data):
    if data.get("current_start"):
        print(f"Tracker already open since {data['current_start']}")
        sys.exit(1)
    data["current_start"] = now_iso()
    save(data)
    print(f"Tracker started at {data['current_start']}")


def cmd_close(data):
    start = data.get("current_start")
    if not start:
        print("No open session. Run 'start' first.")
        sys.exit(1)
    start_dt = datetime.fromisoformat(start)
    end = now_iso()
    end_dt = datetime.fromisoformat(end)
    elapsed = (end_dt - start_dt).total_seconds() / 3600.0
    elapsed = round(elapsed, 4)
    if elapsed < 0:
        print("Negative elapsed time - clock went backwards? Aborting.")
        sys.exit(1)
    data["sessions"].append({"start": start, "end": end, "hours": elapsed})
    data["total_sessions"] = len(data["sessions"])
    data["total_hours"] = round(data["total_hours"] + elapsed, 4)
    data["current_start"] = None
    save(data)
    print(f"Session closed: {hours_hm(elapsed)} ({elapsed:.2f}h)")
    print(f"  started  {start}")
    print(f"  ended    {end}")
    print(f"  totals   {data['total_sessions']} sessions | {hours_hm(data['total_hours'])} | {data['total_hours']:.2f}h")


def cmd_status(data):
    if data.get("current_start"):
        start = datetime.fromisoformat(data["current_start"])
        running = max(datetime.now(start.tzinfo) - start, timedelta(0))
        print(f"Session open since {data['current_start']} (running {hours_hm(running.total_seconds() / 3600)})")
    else:
        print("No open session.")
    print(f"Totals: {data['total_sessions']} sessions | {hours_hm(data['total_hours'])} | {data['total_hours']:.2f}h")


def cmd_summary(data):
    print(f"Sessions: {data['total_sessions']}")
    print(f"Total:    {hours_hm(data['total_hours'])} ({data['total_hours']:.2f}h)")
    for i, s in enumerate(data["sessions"], 1):
        print(f"  {i:>2}. {s['start']} -> {s['end']}  ({hours_hm(s['hours'])})")


def main():
    if len(sys.argv) < 2:
        print(__doc__)
        sys.exit(1)
    cmd = sys.argv[1]
    data = load()
    if cmd == "start":
        cmd_start(data)
    elif cmd == "close":
        cmd_close(data)
    elif cmd == "status":
        cmd_status(data)
    elif cmd == "summary":
        cmd_summary(data)
    else:
        print(__doc__)
        sys.exit(1)


if __name__ == "__main__":
    main()
