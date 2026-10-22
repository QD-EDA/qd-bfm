#!/bin/bash
set -euo pipefail

root=$(cd "$(dirname "$0")" && pwd)
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
cd "$work"

cc "$root/read_command.c" -o read_command
printf 'Icarus: '
iverilog -V 2>/dev/null | head -n 1
iverilog -g2012 -s command_width -o command_width.vvp "$root/command_width.sv"
vvp command_width.vvp
cat commands.hex
./read_command commands.hex 0000120012

rm commands.hex
printf 'Verilator: '
verilator --version
verilator --binary --timing -Wno-fatal --top-module command_width "$root/command_width.sv"
./obj_dir/Vcommand_width
cat commands.hex
./read_command commands.hex 0120121212
