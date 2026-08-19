# ACCIO - Concurrent IP Checker

ACCIO is a Bash-based concurrent IP availability checker designed to practice and demonstrate Linux process management, Bash scripting, background execution, PID handling, and concurrency control.

## Features

- Read IP addresses from an input file
- Check IP availability using ICMP `ping`
- Run multiple ping operations concurrently
- Configurable concurrency using `-c`
- Track background processes using PIDs
- Wait for background processes using `wait`
- Display whether each IP is alive or not alive
- Save scan results to an output file
- Simple command-line interface
- Help/usage option

## Requirements

- Linux / WSL
- Bash
- `ping`
- `figlet`
- `lolcat`

On Ubuntu/WSL, install the required packages with:

```bash
sudo apt update
sudo apt install iputils-ping figlet lolcat -y

