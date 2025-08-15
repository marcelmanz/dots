#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 2 ]]; then
    echo "Usage: grsl <file> <start_line> [end_line]"
    echo ""
    echo "Restore specific lines from git diff for a file"
    echo ""
    echo "Arguments:"
    echo "  file       - Path to the file to restore"
    echo "  start_line - Starting line number to restore"
    echo "  end_line   - Ending line number to restore (optional, defaults to start_line)"
    echo ""
    echo "Examples:"
    echo "  grsl src/main.rs 15      # Restore line 15"
    echo "  grsl src/main.rs 10 20   # Restore lines 10-20"
    exit 1
fi

file=$1
start_line=$2
end_line=${3:-$2}

patch=$(git diff --no-ext-diff --color=never -U0 -- "$file" |
	awk -v s="$start_line" -v e="$end_line" '
	    BEGIN{keep=0}
	    /^diff --git/{
		hdr=$0
		getline; hdr=hdr RS $0
		getline; hdr=hdr RS $0
		getline; hdr=hdr RS $0
		keep=0
		next
	    }
	    /^@@ /{
		split($2,a,","); old_start=substr(a[1],2); old_len=(a[2]?a[2]:1)
		split($3,b,","); new_start=substr(b[1],2); new_len=(b[2]?b[2]:1)
		old_end=old_start+old_len-1
		new_end=new_start+new_len-1
		keep=(old_start<=e && old_end>=s) || (new_start<=e && new_end>=s)
		if(keep){print hdr; hdr=""; print}
		next
	    }
	    keep
	')

if [[ -z $patch ]]; then
	echo "nothing to restore"
	exit 0
fi

printf '%s\n' "$patch" | git apply -R --unidiff-zero
echo "Lines $start_line..$end_line restored from $file"
