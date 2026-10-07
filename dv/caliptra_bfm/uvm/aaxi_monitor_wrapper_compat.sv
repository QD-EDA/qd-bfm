// SPDX-License-Identifier: Apache-2.0
// Clean-room generated-path wrapper: open manager, profile checker, and monitor.
`ifndef CALIPTRA_BFM_EXTERNAL_AVERY
module aaxi_monitor_wrapper #(
  parameter integer ID_WIDTH = aaxi_pkg::AAXI_ID_WIDTH,
  parameter integer BUS_DATA_WIDTH = aaxi_pkg::AAXI_DATA_WIDTH,
  parameter [4:0] USER_SUPPORT = 5'b11111,
  parameter VER = "AXI4",
  parameter bit INTERNAL_MASTER = 1'b1
) (aaxi_intf bus);
  import uvm_pkg::*;

  axi4_caliptra_record_if record_if(bus.ACLK);
  axi4_caliptra_master_cmd_if cmd_if(bus.ACLK);
  assign cmd_if.ARESETn = bus.ARESETn;

  axi4_caliptra_checker #(
    .ADDR_WIDTH(aaxi_pkg::AAXI_ADDR_WIDTH),
    .DATA_WIDTH(BUS_DATA_WIDTH),
    .ID_WIDTH(ID_WIDTH),
    .USER_WIDTH(aaxi_pkg::AAXI_AWUSER_WIDTH)
  ) profile_checker (
    .ACLK(bus.ACLK), .ARESETn(bus.ARESETn),
    .AWID(bus.AWID), .AWADDR(bus.AWADDR), .AWLEN(bus.AWLEN),
    .AWSIZE(bus.AWSIZE), .AWBURST(bus.AWBURST), .AWLOCK(bus.AWLOCK),
    .AWUSER(bus.AWUSER), .AWVALID(bus.AWVALID), .AWREADY(bus.AWREADY),
    .WDATA(bus.WDATA), .WSTRB(bus.WSTRB), .WUSER(bus.WUSER),
    .WLAST(bus.WLAST), .WVALID(bus.WVALID), .WREADY(bus.WREADY),
    .BID(bus.BID), .BRESP(bus.BRESP), .BUSER(bus.BUSER),
    .BVALID(bus.BVALID), .BREADY(bus.BREADY),
    .ARID(bus.ARID), .ARADDR(bus.ARADDR), .ARLEN(bus.ARLEN),
    .ARSIZE(bus.ARSIZE), .ARBURST(bus.ARBURST), .ARLOCK(bus.ARLOCK),
    .ARUSER(bus.ARUSER), .ARVALID(bus.ARVALID), .ARREADY(bus.ARREADY),
    .RID(bus.RID), .RDATA(bus.RDATA), .RRESP(bus.RRESP),
    .RUSER(bus.RUSER), .RLAST(bus.RLAST), .RVALID(bus.RVALID),
    .RREADY(bus.RREADY)
  );

  assign record_if.ARESETn = bus.ARESETn;
  axi4_caliptra_transaction_monitor #(
    .ADDR_WIDTH(48),
    .DATA_WIDTH(BUS_DATA_WIDTH),
    .ID_WIDTH(ID_WIDTH),
    .USER_WIDTH(aaxi_pkg::AAXI_AWUSER_WIDTH)
  ) transaction_monitor (
    .ACLK(bus.ACLK), .ARESETn(bus.ARESETn),
    .AWID(bus.AWID), .AWADDR(bus.AWADDR[47:0]), .AWLEN(bus.AWLEN),
    .AWSIZE(bus.AWSIZE), .AWBURST(bus.AWBURST), .AWLOCK(bus.AWLOCK),
    .AWUSER(bus.AWUSER), .AWVALID(bus.AWVALID), .AWREADY(bus.AWREADY),
    .WDATA(bus.WDATA), .WSTRB(bus.WSTRB), .WUSER(bus.WUSER),
    .WLAST(bus.WLAST), .WVALID(bus.WVALID), .WREADY(bus.WREADY),
    .BID(bus.BID), .BRESP(bus.BRESP), .BUSER(bus.BUSER),
    .BVALID(bus.BVALID), .BREADY(bus.BREADY),
    .ARID(bus.ARID), .ARADDR(bus.ARADDR[47:0]), .ARLEN(bus.ARLEN),
    .ARSIZE(bus.ARSIZE), .ARBURST(bus.ARBURST), .ARLOCK(bus.ARLOCK),
    .ARUSER(bus.ARUSER), .ARVALID(bus.ARVALID), .ARREADY(bus.ARREADY),
    .RID(bus.RID), .RDATA(bus.RDATA), .RRESP(bus.RRESP),
    .RUSER(bus.RUSER), .RLAST(bus.RLAST), .RVALID(bus.RVALID),
    .RREADY(bus.RREADY),
    .cycle_count(), .write_complete(record_if.write_complete),
    .write_request_complete(record_if.write_request_complete),
    .write_request_error(record_if.write_request_error),
    .write_request_status(record_if.write_request_status),
    .write_request_id(record_if.write_request_id),
    .write_request_addr(record_if.write_request_addr),
    .write_request_len(record_if.write_request_len),
    .write_request_size(record_if.write_request_size),
    .write_request_burst(record_if.write_request_burst),
    .write_request_lock(record_if.write_request_lock),
    .write_request_awuser(record_if.write_request_awuser),
    .write_request_beat_count(record_if.write_request_beat_count),
    .write_request_data(record_if.write_request_data),
    .write_request_strb(record_if.write_request_strb),
    .write_request_wuser(record_if.write_request_wuser),
    .write_request_last_mask(record_if.write_request_last_mask),
    .write_error(record_if.write_error),
    .write_error_code(record_if.write_error_code),
    .write_status(record_if.write_status), .write_cycle(),
    .write_id(record_if.write_id), .write_addr(record_if.write_addr),
    .write_len(record_if.write_len), .write_size(record_if.write_size),
    .write_burst(record_if.write_burst), .write_lock(record_if.write_lock),
    .write_awuser(record_if.write_awuser),
    .write_beat_count(record_if.write_beat_count),
    .write_data(record_if.write_data), .write_strb(record_if.write_strb),
    .write_wuser(record_if.write_wuser),
    .write_last_mask(record_if.write_last_mask),
    .write_response_id(record_if.write_response_id),
    .write_response(record_if.write_response),
    .write_buser(record_if.write_buser),
    .read_complete(record_if.read_complete), .read_error(record_if.read_error),
    .read_error_code(record_if.read_error_code),
    .read_status(record_if.read_status), .read_cycle(),
    .read_id(record_if.read_id), .read_addr(record_if.read_addr),
    .read_len(record_if.read_len), .read_size(record_if.read_size),
    .read_burst(record_if.read_burst), .read_lock(record_if.read_lock),
    .read_aruser(record_if.read_aruser),
    .read_beat_count(record_if.read_beat_count),
    .read_data(record_if.read_data), .read_resp(record_if.read_resp),
    .read_ruser(record_if.read_ruser),
    .read_last_mask(record_if.read_last_mask)
  );

  generate
    if (INTERNAL_MASTER) begin : open_master
      axi4_caliptra_uvm_master_proxy #(
        .ADDR_WIDTH(48),
        .DATA_WIDTH(BUS_DATA_WIDTH),
        .ID_WIDTH(ID_WIDTH),
        .USER_WIDTH(aaxi_pkg::AAXI_AWUSER_WIDTH)
      ) manager (
        .cmd_if(cmd_if), .ACLK(bus.ACLK), .ARESETn(bus.ARESETn),
        .AWID(bus.AWID), .AWADDR(bus.AWADDR[47:0]), .AWLEN(bus.AWLEN),
        .AWSIZE(bus.AWSIZE), .AWBURST(bus.AWBURST), .AWLOCK(bus.AWLOCK),
        .AWUSER(bus.AWUSER), .AWVALID(bus.AWVALID), .AWREADY(bus.AWREADY),
        .WDATA(bus.WDATA), .WSTRB(bus.WSTRB), .WUSER(bus.WUSER),
        .WLAST(bus.WLAST), .WVALID(bus.WVALID), .WREADY(bus.WREADY),
        .BID(bus.BID), .BRESP(bus.BRESP), .BUSER(bus.BUSER),
        .BVALID(bus.BVALID), .BREADY(bus.BREADY),
        .ARID(bus.ARID), .ARADDR(bus.ARADDR[47:0]), .ARLEN(bus.ARLEN),
        .ARSIZE(bus.ARSIZE), .ARBURST(bus.ARBURST), .ARLOCK(bus.ARLOCK),
        .ARUSER(bus.ARUSER), .ARVALID(bus.ARVALID), .ARREADY(bus.ARREADY),
        .RID(bus.RID), .RDATA(bus.RDATA), .RRESP(bus.RRESP),
        .RUSER(bus.RUSER), .RLAST(bus.RLAST), .RVALID(bus.RVALID),
        .RREADY(bus.RREADY)
      );

    end
  endgenerate

  initial begin
    uvm_config_db #(virtual aaxi_intf)::set(
      uvm_root::get(), "*", "ports", bus);
    uvm_config_db #(virtual axi4_caliptra_record_if)::set(
      uvm_root::get(), "*", "vif", record_if);
    if (INTERNAL_MASTER)
      uvm_config_db #(virtual axi4_caliptra_master_cmd_if)::set(
        uvm_root::get(), "*", "cmd_vif", cmd_if);
  end
endmodule
`endif
