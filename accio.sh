
#!/usr/bin/env bash
# accio.sh - simple concurrent IP status checker

set -euo pipefail
IFS=$'\n\t'

# Colors

red='\033[0;31m'
green='\033[0;32m'
yellow='\033[0;33m'
blue='\033[0;34m'
end='\033[0m'

# Defaults

DEFAULT_CONCURRENCY=10
PING_COUNT=1
PING_TIMEOUT=2   # seconds per ping

# Dependency flags (set by check_deps)

HAVE_FIGLET=0
HAVE_LOLCAT=0

# Simple logging helpers 

log()  { printf '%s %b%s%b\n' "[$(date +'%Y-%m-%d %H:%M:%S')]" "$2" "$1" "$end" >&2; }
info() { log "$1" "$green"; }
warn() { log "$1" "$yellow"; }
err()  { log "$1" "$red"; }

# Check required dependencies

check_deps(){

    if ! command -v ping >/dev/null 2>&1; then
        err "ping not found. Install iputils or equivalent."
        exit 2
    fi

    if command -v figlet >/dev/null 2>&1; then
        HAVE_FIGLET=1
    fi
    if command -v lolcat >/dev/null 2>&1; then
        HAVE_LOLCAT=1
    fi
}

# Banner: use figlet|lolcat if available; otherwise print plain banner

banner(){

    if [[ ${HAVE_FIGLET} -eq 1 && ${HAVE_LOLCAT} -eq 1 ]]; then
        figlet "A C C I O" | lolcat
    elif [[ ${HAVE_FIGLET} -eq 1 && ${HAVE_LOLCAT} -eq 0 ]]; then
        figlet "A C C I O"
        warn "Note: 'lolcat' not found; banner printed without color."
    else
        # plain banner (keeps it simple and student-like)
        printf '%b\n' "${blue}A C C I O${end}"
        warn "Optional tools 'figlet' and/or 'lolcat' not found; banner printed plainly."

    fi

    echo -e "${blue}This script verifies whether IPs are alive${end}"

}

help(){

	echo -e "${blue}\
	+----------------------------------------------------------------+
	|      -h/--help : help or usage                                 |
	|   -i FILE   : input file                                       |	
	|   -o FILE   : output file                                      |
	| -c NUMBER : concurrent tasks (dehault: ${DEFAULT_CONCURRENCY}) |
	+----------------------------------------------------------------+${end}"

}

# for argument parsing

i_file=""
o_file=""
c_tasks=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        -h|--help)
            help
            exit 0
            ;;
        -i)
            if [[ -n "${2:-}" && "${2:0:1}" != "-" ]]; then
                i_file="$2"
                shift 2
                continue
            else
                err "Option -i requires a filename."
                help
                exit 128
            fi
            ;;
        -o)
            if [[ -n "${2:-}" && "${2:0:1}" != "-" ]]; then
                o_file="$2"
                shift 2
                continue
            else
                err "Option -o requires a filename."
                help
                exit 128
            fi
            ;;
        -c)
            if [[ -n "${2:-}" && "${2:0:1}" != "-" ]]; then
                c_tasks="$2"
                shift 2
                continue
            else
                err "Option -c requires a number."
                help
                exit 128
            fi
            ;;
        --) shift; break ;;
        *)
            err "Invalid argument: $1"
            help
            exit 128
            ;;
    esac
done

# Validate required args

if [[ -z "${i_file:-}" || -z "${o_file:-}" ]]; then

    err "Input and output files are required."
    help
    exit 200

fi

if [[ ! -f "${i_file}" || ! -r "${i_file}" ]]; then

    err "Input file '${i_file}' does not exist or is not readable."
    exit 3

fi

# Concurrency default and validation

if [[ -z "${c_tasks:-}" ]]; then

    c_tasks="${DEFAULT_CONCURRENCY}"
fi

if ! [[ "${c_tasks}" =~ ^[0-9]+$ ]] || (( c_tasks < 1 )); then
	
	err "Concurrency must be a positive integer."
   	exit 4
fi

# Prepare temp output

tmp_out="$(mktemp --tmpdir accio.out.XXXXXX)" || { err "Failed to create temp file."; exit 5; }
trap 'rm -f "${tmp_out}"; exit 130' INT TERM

check_deps

banner

# Read IPs, ignore blank lines and comments (#)

mapfile -t raw_ips < "${i_file}"
ips=()
for line in "${raw_ips[@]}"; do

    # strip comments and trim whitespace
    line="${line%%#*}"
    line="${line#"${line%%[![:space:]]*}"}"
    line="${line%"${line##*[![:space:]]}"}"
    [[ -z "$line" ]] && continue
    ips+=("$line")
done

if (( ${#ips[@]} == 0 )); then

    warn "No IPs found in ${i_file}."
    rm -f "${tmp_out}"
    exit 0
fi

# Concurrency control 
pids=()
enqueue_pid(){

    pids+=("$1")
    # if reached concurrency, wait for at least one to finish
    while (( ${#pids[@]} >= c_tasks )); do
        if wait -n 2>/dev/null; then
            # rebuild pids array keeping only running PIDs (best-effort)
            new=()
            for pid in "${pids[@]}"; do
                if kill -0 "$pid" 2>/dev/null; then
                    new+=("$pid")
                fi
            done
            pids=("${new[@]}")
        else
            # fallback: wait for all then clear
            wait "${pids[@]}" 2>/dev/null || true
            pids=()
        fi
    done
}

# Worker function (keeps output format same as original)
worker(){
    local ip="$1"
    if ping -c "${PING_COUNT}" -W "${PING_TIMEOUT}" "${ip}" &>/dev/null; then
        printf '%s is alive\n' "${ip}" >> "${tmp_out}"
    else
        printf '%s is not alive\n' "${ip}" >> "${tmp_out}"
    fi
}

# Launch workers 
for ip in "${ips[@]}"; do
    worker "${ip}" & pid=$!
    enqueue_pid "${pid}"
done

# Wait for remaining jobs
if (( ${#pids[@]} )); then
    wait "${pids[@]}" 2>/dev/null || true
fi

# Move temp file to final output and show results
mv "${tmp_out}" "${o_file}"
info "Results written to ${o_file}"
cat "${o_file}" | tee /dev/stderr >/dev/null

exit 0
