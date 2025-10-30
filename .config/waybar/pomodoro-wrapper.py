#!/usr/bin/env python3
import json
import os
import signal
import subprocess
import sys


def main() -> int:
    cmd = [os.path.expanduser("~/.cargo/bin/waybar-module-pomodoro")]
    proc = subprocess.Popen(
        cmd,
        stdout=subprocess.PIPE,
        stderr=sys.stderr,
        text=True,
        bufsize=1,
        universal_newlines=True,
    )

    def _terminate(signum, _frame):
        if proc.poll() is None:
            proc.terminate()

    for sig in (signal.SIGTERM, signal.SIGINT, signal.SIGHUP):
        signal.signal(sig, _terminate)

    assert proc.stdout is not None
    for raw_line in proc.stdout:
        line = raw_line.strip()
        if not line:
            continue
        try:
            payload = json.loads(line)
        except json.JSONDecodeError:
            print(raw_line, end="", flush=True)
            continue

        text = payload.get("text", "")
        if "▶" in text and "⏸" not in text:
            payload["text"] = ""
        print(json.dumps(payload), flush=True)

    return proc.wait()


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except KeyboardInterrupt:
        pass
