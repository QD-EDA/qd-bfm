// SPDX-License-Identifier: Apache-2.0
// AHB-Lite completed transfer records consumed by the UVM monitor adapter.
interface ahb_lite_caliptra_record_if(input wire HCLK);
  wire HRESETn;
  wire address_phase_fire;
  wire address_phase_selected;
  wire [1:0] address_phase_trans;
  wire address_fire;
  wire transfer_fire;
  wire transfer_protocol_error;
  wire [31:0] transfer_addr;
  wire transfer_write;
  wire [1:0] transfer_trans;
  wire [2:0] transfer_size;
  wire [63:0] transfer_data;
  wire transfer_error;
  wire [63:0] cycle_count;
  wire [31:0] wait_cycle_count;
  wire [31:0] address_count;
  wire [31:0] transfer_count;
  wire [31:0] read_address_count;
  wire [31:0] write_address_count;
  wire [31:0] size_1byte_count;
  wire [31:0] size_2byte_count;
  wire [31:0] size_4byte_count;
  wire [31:0] size_8byte_count;
  wire [31:0] pending_wait_cycle_count;
  wire [31:0] error_transfer_count;
  wire protocol_error;
  wire [31:0] protocol_error_count;
  wire checker_error;
  wire [3:0] checker_error_code;
  wire [31:0] checker_error_count;
endinterface
