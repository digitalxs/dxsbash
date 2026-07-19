#!/bin/bash
#=================================================================
# DXSBash shell startup benchmark
# Repository: https://github.com/digitalxs/dxsbash
# Website: https://dxsbash.digitalxs.ca
# License: GPL-3.0
#
# Measures interactive-shell startup time for every installed shell
# (cold = first run, warm = average of the remaining runs) so prompt
# and rc-file regressions are caught before they annoy anyone.
#
# Usage:
#   dxsbash bench              benchmark all installed shells
#   dxsbash bench --runs 10    number of timed runs per shell (default 5)
#   dxsbash bench --profile    also show the 15 slowest lines of the
#                              bash startup (bash only, xtrace-based)
#=================================================================

set -euo pipefail

RC='\033[0m'
GREEN='\033[32m'
YELLOW='\033[33m'
CYAN='\033[36m'
WHITE='\033[37m'

RUNS=5
PROFILE=0
while [ $# -gt 0 ]; do
    case "$1" in
        --runs) RUNS="${2:-5}"; shift ;;
        --profile) PROFILE=1 ;;
        -h|--help) sed -n '/^# Usage:/,/^#===/p' "$0" | sed 's/^# \{0,1\}//;$d'; exit 0 ;;
    esac
    shift
done
case "$RUNS" in ''|*[!0-9]*) echo "Invalid --runs value" >&2; exit 2 ;; esac
[ "$RUNS" -lt 2 ] && RUNS=2

# Millisecond timestamps: EPOCHREALTIME needs bash >= 5
now_ms() {
    if [ -n "${EPOCHREALTIME:-}" ]; then
        local t="${EPOCHREALTIME/,/.}"   # some locales use a comma
        local s="${t%.*}" us="${t#*.}"
        echo $(( s * 1000 + 10#${us:0:3} ))
    else
        date +%s%3N
    fi
}

bench_shell() {
    local shell="$1" cold=0 total=0 t0 t1 dt i
    command -v "$shell" >/dev/null 2>&1 || return 0

    for (( i = 1; i <= RUNS; i++ )); do
        t0=$(now_ms)
        # A broken rc file may make the shell exit non-zero — still
        # report the timing rather than aborting the benchmark.
        "$shell" -i -c exit </dev/null >/dev/null 2>&1 || true
        t1=$(now_ms)
        dt=$(( t1 - t0 ))
        if [ "$i" -eq 1 ]; then
            cold=$dt
        else
            total=$(( total + dt ))
        fi
    done
    local warm=$(( total / (RUNS - 1) ))

    local verdict="${GREEN}fast${RC}"
    if [ "$warm" -ge 500 ]; then
        verdict="${YELLOW}slow — consider 'dxsbash bench --profile' and trimming plugins${RC}"
    elif [ "$warm" -ge 200 ]; then
        verdict="${YELLOW}acceptable${RC}"
    fi
    printf "  %-6s cold %5s ms   warm %5s ms   " "$shell" "$cold" "$warm"
    echo -e "$verdict"
}

echo -e "${CYAN}▶ DXSBash startup benchmark${RC} (${RUNS} runs per shell; warm = avg of runs 2..${RUNS})"
echo ""
for s in bash zsh fish; do
    bench_shell "$s"
done
echo ""

if [ "$PROFILE" -eq 1 ]; then
    echo -e "${CYAN}▶ Profiling bash startup (15 slowest sourced lines)...${RC}"
    TRACE=$(mktemp)
    # The trace contains a full xtrace of the user's rc files — don't
    # leave it behind on Ctrl-C or errors.
    trap 'rm -f "$TRACE"' EXIT INT TERM
    # Timestamp every traced command, then diff consecutive stamps.
    # This is coarse (line granularity, xtrace overhead inflates
    # everything) but reliably points at the expensive block.
    # '-i' (not '-li') so the profiled path matches the timed runs.
    PS4='+T:${EPOCHREALTIME-0}:${BASH_SOURCE-}:${LINENO-}: ' \
        bash -i -x -c exit </dev/null >/dev/null 2>"$TRACE" || true
    awk -F: '
        /^\++T:/ {
            gsub(/,/, ".", $2)
            t = $2 + 0
            if (prev_t > 0 && prev_line != "") {
                ms = (t - prev_t) * 1000
                if (ms > 0.5) printf "%8.1f ms  %s:%s\n", ms, prev_src, prev_line
            }
            prev_t = t; prev_src = $3; prev_line = $4
        }
    ' "$TRACE" | sort -rn | head -15 | sed 's/^/  /' || true
    rm -f "$TRACE"
    echo ""
    echo -e "  ${WHITE}Tip:${RC} times include xtrace overhead — compare lines relatively, not absolutely."
fi
