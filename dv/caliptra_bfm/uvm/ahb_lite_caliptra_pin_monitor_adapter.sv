// SPDX-License-Identifier: Apache-2.0
// Connects Caliptra/QVIP-shaped AHB-Lite pins to the native UVM record interface.
module ahb_lite_caliptra_pin_monitor_adapter #(
  parameter integer ADDR_WIDTH = 32,
  parameter integer DATA_WIDTH = 64
) (
  input wire HCLK,
  input wire HRESETn,
  input wire [ADDR_WIDTH-1:0] HADDR,
  input wire [DATA_WIDTH-1:0] HWDATA,
  input wire HSEL,
  input wire HWRITE,
  input wire [1:0] HTRANS,
  input wire [2:0] HSIZE,
  input wire HREADY,
  input wire HRESP,
  input wire [DATA_WIDTH-1:0] HRDATA,
  ahb_lite_caliptra_record_if record_if
);
  reg [31:0] wait_cycle_count;
  wire address_phase_fire;
  wire address_phase_selected;
  wire [1:0] address_phase_trans;
  wire address_fire;
  wire transfer_fire;
  wire transfer_protocol_error;
  wire [ADDR_WIDTH-1:0] transfer_addr;
  wire transfer_write;
  wire [1:0] transfer_trans;
  wire [2:0] transfer_size;
  wire [DATA_WIDTH-1:0] transfer_data;
  wire transfer_error;
  wire [63:0] cycle_count;
  wire [31:0] address_count;
  wire [31:0] transfer_count;
  wire protocol_error;
  wire [31:0] protocol_error_count;

  assign record_if.HRESETn = HRESETn;
  assign record_if.address_phase_fire = address_phase_fire;
  assign record_if.address_phase_selected = address_phase_selected;
  assign record_if.address_phase_trans = address_phase_trans;
  assign record_if.wait_cycle_count = wait_cycle_count;
  assign record_if.address_fire = address_fire;
  assign record_if.transfer_fire = transfer_fire;
  assign record_if.transfer_protocol_error = transfer_protocol_error;
  assign record_if.transfer_addr = transfer_addr;
  assign record_if.transfer_write = transfer_write;
  assign record_if.transfer_trans = transfer_trans;
  assign record_if.transfer_size = transfer_size;
  assign record_if.transfer_data = transfer_data;
  assign record_if.transfer_error = transfer_error;
  assign record_if.cycle_count = cycle_count;
  assign record_if.address_count = address_count;
  assign record_if.transfer_count = transfer_count;
  assign record_if.protocol_error = protocol_error;
  assign record_if.protocol_error_count = protocol_error_count;

  always @(posedge HCLK or negedge HRESETn) begin
    if (!HRESETn)
      wait_cycle_count <= '0;
    else if (HREADY === 1'b0)
      wait_cycle_count <= wait_cycle_count + 1'b1;
  end

  ahb_lite_caliptra_monitor #(
    .ADDR_WIDTH(ADDR_WIDTH),
    .DATA_WIDTH(DATA_WIDTH)
  ) monitor (
    .HCLK(HCLK),
    .HRESETn(HRESETn),
    .HADDR(HADDR),
    .HWDATA(HWDATA),
    .HSEL(HSEL),
    .HWRITE(HWRITE),
    .HTRANS(HTRANS),
    .HSIZE(HSIZE),
    .HREADY(HREADY),
    .HRESP(HRESP),
    .HRDATA(HRDATA),
    .address_phase_fire(address_phase_fire),
    .address_phase_selected(address_phase_selected),
    .address_phase_trans(address_phase_trans),
    .address_fire(address_fire),
    .transfer_fire(transfer_fire),
    .transfer_protocol_error(transfer_protocol_error),
    .transfer_addr(transfer_addr),
    .transfer_write(transfer_write),
    .transfer_trans(transfer_trans),
    .transfer_size(transfer_size),
    .transfer_data(transfer_data),
    .transfer_error(transfer_error),
    .cycle_count(cycle_count),
    .address_count(address_count),
    .transfer_count(transfer_count),
    .protocol_error(protocol_error),
    .protocol_error_count(protocol_error_count)
  );
endmodule
