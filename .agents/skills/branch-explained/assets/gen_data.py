#!/usr/bin/env python3
"""Dump a branch's commits, diffs and final-file blame into data.js for the explainer page.

usage: gen_data.py --repo PATH --base REV --head REV --out DIR/data.js FILE [FILE ...]
FILE paths are repo-relative and shown in the code explorer, in the given order.
"""
import argparse, json, pathlib, subprocess

parser = argparse.ArgumentParser()
parser.add_argument("--repo", required=True)
parser.add_argument("--base", required=True, help="last commit before the branch work, excluded")
parser.add_argument("--head", required=True, help="branch name or commit, included")
parser.add_argument("--out", required=True)
parser.add_argument("files", nargs="+")
args = parser.parse_args()


def git(*cmd):
    return subprocess.run(["git", "-C", args.repo, *cmd], capture_output=True, text=True, check=True).stdout


commits = []
log = git("log", "--reverse", "--no-merges", "--format=%H%x09%h%x09%ad%x09%an%x09%s", "--date=short", f"{args.base}..{args.head}")
for line in log.splitlines():
    full, short, date, author, subject = line.split("\t", 4)
    commits.append(dict(
        hash=short, full=full, date=date, author=author, subject=subject,
        diff=git("show", "--format=", "--no-color", full),
        stat=git("show", "--format=", "--stat=120", full).strip(),
    ))

short_len = len(commits[0]["hash"]) if commits else 7
files = {}
for path in args.files:
    lines = git("show", f"{args.head}:{path}").splitlines()
    blame = [l.split(" ", 1)[0].lstrip("^")[:short_len] for l in git("blame", "-s", "-l", args.head, "--", path).splitlines()]
    files[path] = dict(lines=lines, blame=blame)

out = pathlib.Path(args.out)
out.write_text("window.COMMITS = " + json.dumps(commits) + ";\nwindow.FILES = " + json.dumps(files) + ";\n")
print(f"wrote {out}: {len(commits)} commits, {len(files)} files")
