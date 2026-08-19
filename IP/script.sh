#!/bin/bash

red='\033[0;31m'
green='\033[0;32m'
end='\033[0m'

function help(){
    figlet "A C C I O" | lolcat

    echo "+------------------------------------------+"
    echo "| -h/--help : help or usage                |"
    echo "| -i FILENAME : Provide IPs file           |"
    echo "| -o FILENAME : Output file                |"
    echo "| -c NUMBER : Concurrent tasks             |"
    echo "+------------------------------------------+"
}

function code(){

    mapfile -t ips < "${i_file}"

    PIDS=()
    JOBS=${c_tasks}

    for i in "${!ips[@]}"; do

        (
            if ping -c 1 "${ips[$i]}" &> /dev/null; then
                echo "${ips[$i]} is alive"
            else
                echo "${ips[$i]} is not alive"
            fi
        ) &

        PIDS+=("$!")

        if [[ ${#PIDS[@]} -ge ${JOBS} ]]; then
            wait "${PIDS[@]}"
            PIDS=()
        fi

    done

    wait "${PIDS[@]}"
}

while [[ $# -gt 0 ]]; do

    case "$1" in

        "-h"|"--help")
            help
            exit 0
            ;;

        "-i")
            i_file="$2"
            ;;

        "-o")
            o_file="$2"
            ;;

        "-c")
            c_tasks="$2"
            ;;

        *)
            echo "Error: Invalid argument, check help"
            help
            exit 128
            ;;

    esac

    shift 2

done

if [[ -z "${i_file}" ]] || [[ -z "${o_file}" ]] || [[ -z "${c_tasks}" ]]; then
    echo "Error: arguments are required, check -h/--help."
    exit 200
fi

code | tee "${o_file}"
