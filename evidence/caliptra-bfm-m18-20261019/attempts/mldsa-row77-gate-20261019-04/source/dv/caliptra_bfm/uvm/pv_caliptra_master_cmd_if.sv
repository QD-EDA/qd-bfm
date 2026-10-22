// SPDX-License-Identifier: Apache-2.0
// Request/response boundary between UVM sequences and the PCRVault task BFM.
interface pv_caliptra_master_cmd_if #(
  parameter integer ENTRY_WIDTH = 5,
  parameter integer OFFSET_WIDTH = 4,
  parameter integer DATA_WIDTH = 32
) (input wire clk);
  wire rst_n;

  logic request_valid = 0;
  logic request_write = 0;
  logic [ENTRY_WIDTH-1:0] request_entry = 0;
  logic [OFFSET_WIDTH-1:0] request_offset = 0;
  logic [DATA_WIDTH-1:0] request_data = 0;

  logic response_valid = 0;
  logic response_request_ok = 0;
  logic response_success = 0;
  logic response_error = 0;
  logic response_last = 0;
  logic [DATA_WIDTH-1:0] response_data = 0;
endinterface
