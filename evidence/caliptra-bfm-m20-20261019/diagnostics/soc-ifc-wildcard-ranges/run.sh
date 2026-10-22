#!/bin/bash
set -euo pipefail

root=$(cd "$(dirname "$0")" && pwd)
iverilog_bin=${IVERILOG_BIN:-iverilog}
"$iverilog_bin" -g2017 -s soc_ifc_wildcard_ranges_tb -o /dev/null "$root/compatibility.sv"
