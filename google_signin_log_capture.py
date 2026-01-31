import argparse
import datetime as _dt
import os
import subprocess
import sys


def main() -> int:
    parser = argparse.ArgumentParser(
        description=(
            "Run the Flutter Google Sign-In test target and capture console logs to a file.\n"
            "Usage example: python google_signin_log_capture.py --project ."
        )
    )
    parser.add_argument(
        "--project",
        default=".",
        help="Path to the Flutter project root (where pubspec.yaml is)",
    )
    parser.add_argument(
        "--device",
        default="",
        help="Optional flutter device id (from: flutter devices)",
    )
    parser.add_argument(
        "--target",
        default=os.path.join("lib", "google_sign_in_test_main.dart"),
        help="Flutter target file to run",
    )
    parser.add_argument(
        "--logdir",
        default="logs",
        help="Directory to write logs into",
    )
    args = parser.parse_args()

    project = os.path.abspath(args.project)
    logdir = os.path.join(project, args.logdir)
    os.makedirs(logdir, exist_ok=True)

    ts = _dt.datetime.now().strftime("%Y%m%d_%H%M%S")
    logfile = os.path.join(logdir, f"google_signin_{ts}.log")

    cmd = ["flutter", "run", "-t", args.target, "--verbose"]
    if args.device:
        cmd.extend(["-d", args.device])

    print("Running:", " ".join(cmd))
    print("Project:", project)
    print("Log file:", logfile)
    print("\nInstructions:")
    print("  1) Wait for app to open")
    print("  2) Tap 'Sign in with Google'")
    print("  3) When error happens, close app or press 'q' in flutter terminal")
    print("  4) Copy/paste the contents of the log file back into chat")
    print("\n---\n")

    with open(logfile, "w", encoding="utf-8", errors="replace") as f:
        f.write("CMD: " + " ".join(cmd) + "\n")
        f.write("PROJECT: " + project + "\n")
        f.write("\n")
        f.flush()

        # Note: We capture stdout/stderr and write to file continuously.
        proc = subprocess.Popen(
            cmd,
            cwd=project,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            text=True,
            bufsize=1,
        )

        assert proc.stdout is not None
        for line in proc.stdout:
            sys.stdout.write(line)
            f.write(line)

        return proc.wait()


if __name__ == "__main__":
    raise SystemExit(main())
