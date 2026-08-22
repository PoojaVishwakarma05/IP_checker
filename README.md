ACCIO – Concurrent IP Checker
ACCIO is a Bash script that checks if a list of IP addresses or hostnames are reachable. It was built as a practice project to learn about Linux process management, background execution, PID handling, and concurrency control.

Features:
-------------------------------------------------------------------------------------------------------------------------------------------------------------
Read IPs/hosts from an input file

Check availability using ICMP ping

Run multiple checks at the same time (concurrency)

Control concurrency with -c option

Track background processes with PIDs

Wait for jobs to finish using wait

Show results: “is alive” or “is not alive”

Save results to an output file

Simple command‑line interface with -h/--help

-----------------------------------------------------------------------------------------------------------------------------------------------------------------
Requirements:
-----------------------------------------------------------------------------------------------------------------------------------------------------------------
Linux or WSL or vm with ubuntu guest os

Bash

ping (from iputils)

Optional: figlet and lolcat for a colorful banner

-----------------------------------------------------------------------------------------------------------------------------------------------------------------
Install dependencies (Ubuntu/WSL)

sudo apt update
sudo apt install -y iputils-ping figlet lolcat

Usage
./accio.sh -i ips.txt -o results.txt -c 10
here,
-i FILE → input file with IPs/hosts

-o FILE → output file for results

-c NUMBER → number of concurrent checks (default: 10)

-h or --help → show usage

------------------------------------------------------------------------------------------------------------------------------------------------------------------
Example of input file:
ips.txt --->>
8.8.8.8
1.1.1.1  # cloudflare
example.com

To execute the script:--->
./accio.sh -i ips.txt -o results.txt -c 5

Exppected Output:
8.8.8.8 is alive
1.1.1.1 is not alive
example.com is alive  
