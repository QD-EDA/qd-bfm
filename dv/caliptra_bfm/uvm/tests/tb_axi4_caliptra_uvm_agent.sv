// SPDX-License-Identifier: Apache-2.0
`timescale 1ns/1ps
`include "uvm_macros.svh"

module tb_axi4_caliptra_uvm_agent #(parameter integer USE_DMA_TARGET = 0);
  import uvm_pkg::*;
  import axi4_caliptra_uvm_pkg::*;
`ifndef CALIPTRA_BFM_EXTERNAL_AVERY
  import aaxi_uvm_pkg::*;
`endif

  reg ACLK = 0;
  reg ARESETn = 0;
  wire [7:0] AWID, ARID, BID, RID;
  wire [47:0] AWADDR, ARADDR;
  wire [7:0] AWLEN, ARLEN;
  wire [2:0] AWSIZE, ARSIZE;
  wire [1:0] AWBURST, ARBURST, BRESP, RRESP;
  wire AWLOCK, AWVALID, AWREADY, WLAST, WVALID, WREADY, BVALID, BREADY;
  wire ARLOCK, ARVALID, ARREADY, RLAST, RVALID, RREADY;
  wire [31:0] AWUSER, WDATA, WUSER, BUSER, ARUSER, RDATA, RUSER;
  wire [3:0] WSTRB;
  wire stall_aw = 0;
  wire stall_w = 0;
  logic stall_b = 0;
  wire stall_ar = 0;
  logic stall_r = 0;
  wire inject_error;

  axi4_caliptra_master_cmd_if cmd_if(ACLK);
  axi4_caliptra_record_if record_if(ACLK);
  assign cmd_if.ARESETn = ARESETn;
  assign inject_error = cmd_if.inject_target_error;
  assign record_if.ARESETn = ARESETn;
  always #5 ACLK = ~ACLK;

  wire aw_fire, w_fire, b_fire, ar_fire, r_fire;
  wire [101:0] aw_record, ar_record;
  wire [68:0] w_record;
  wire [41:0] b_record;
  wire [74:0] r_record;
  wire [63:0] cycle_count;
  wire [31:0] aw_count, w_count, b_count, ar_count, r_count;
  wire [31:0] aw_stall_cycles, w_stall_cycles, b_stall_cycles;
  wire [31:0] ar_stall_cycles, r_stall_cycles;
  axi4_caliptra_monitor #(
    .ADDR_WIDTH(48), .DATA_WIDTH(32), .ID_WIDTH(8), .USER_WIDTH(32)
  ) channel_monitor (
    .*,
    .aw_valid_cycles(record_if.aw_valid_cycles),
    .w_valid_cycles(record_if.w_valid_cycles),
    .b_valid_cycles(record_if.b_valid_cycles),
    .ar_valid_cycles(record_if.ar_valid_cycles),
    .r_valid_cycles(record_if.r_valid_cycles),
    .aw_burst_fixed_count(record_if.aw_burst_fixed_count),
    .aw_burst_incr_count(record_if.aw_burst_incr_count),
    .aw_burst_wrap_count(record_if.aw_burst_wrap_count),
    .aw_burst_reserved_count(record_if.aw_burst_reserved_count),
    .aw_burst_unknown_count(record_if.aw_burst_unknown_count),
    .aw_lock_clear_count(record_if.aw_lock_clear_count),
    .aw_lock_set_count(record_if.aw_lock_set_count),
    .aw_lock_unknown_count(record_if.aw_lock_unknown_count),
    .ar_burst_fixed_count(record_if.ar_burst_fixed_count),
    .ar_burst_incr_count(record_if.ar_burst_incr_count),
    .ar_burst_wrap_count(record_if.ar_burst_wrap_count),
    .ar_burst_reserved_count(record_if.ar_burst_reserved_count),
    .ar_burst_unknown_count(record_if.ar_burst_unknown_count),
    .ar_lock_clear_count(record_if.ar_lock_clear_count),
    .ar_lock_set_count(record_if.ar_lock_set_count),
    .ar_lock_unknown_count(record_if.ar_lock_unknown_count),
    .b_resp_okay_count(record_if.b_resp_okay_count),
    .b_resp_exokay_count(record_if.b_resp_exokay_count),
    .b_resp_slverr_count(record_if.b_resp_slverr_count),
    .b_resp_decerr_count(record_if.b_resp_decerr_count),
    .b_resp_unknown_count(record_if.b_resp_unknown_count),
    .r_resp_okay_count(record_if.r_resp_okay_count),
    .r_resp_exokay_count(record_if.r_resp_exokay_count),
    .r_resp_slverr_count(record_if.r_resp_slverr_count),
    .r_resp_decerr_count(record_if.r_resp_decerr_count),
    .r_resp_unknown_count(record_if.r_resp_unknown_count),
    .w_strb_full_count(record_if.w_strb_full_count),
    .w_strb_partial_count(record_if.w_strb_partial_count),
    .w_strb_zero_count(record_if.w_strb_zero_count),
    .w_strb_unknown_count(record_if.w_strb_unknown_count),
    .w_last_count(record_if.w_last_count), .r_last_count(record_if.r_last_count)
  );
  assign record_if.aw_fire = aw_fire;
  assign record_if.aw_record = aw_record;
  assign record_if.w_fire = w_fire;
  assign record_if.w_record = w_record;
  assign record_if.b_fire = b_fire;
  assign record_if.b_record = b_record;
  assign record_if.ar_fire = ar_fire;
  assign record_if.ar_record = ar_record;
  assign record_if.r_fire = r_fire;
  assign record_if.r_record = r_record;
  assign record_if.channel_cycle = cycle_count;
  assign record_if.aw_count = aw_count;
  assign record_if.w_count = w_count;
  assign record_if.b_count = b_count;
  assign record_if.ar_count = ar_count;
  assign record_if.r_count = r_count;
  assign record_if.aw_stall_cycles = aw_stall_cycles;
  assign record_if.w_stall_cycles = w_stall_cycles;
  assign record_if.b_stall_cycles = b_stall_cycles;
  assign record_if.ar_stall_cycles = ar_stall_cycles;
  assign record_if.r_stall_cycles = r_stall_cycles;

  axi4_caliptra_uvm_master_proxy proxy (
    .cmd_if(cmd_if), .ACLK(ACLK), .ARESETn(ARESETn),
    .AWID(AWID), .AWADDR(AWADDR), .AWLEN(AWLEN), .AWSIZE(AWSIZE),
    .AWBURST(AWBURST), .AWLOCK(AWLOCK), .AWUSER(AWUSER),
    .AWVALID(AWVALID), .AWREADY(AWREADY), .WDATA(WDATA), .WSTRB(WSTRB),
    .WUSER(WUSER), .WLAST(WLAST), .WVALID(WVALID), .WREADY(WREADY),
    .BID(BID), .BRESP(BRESP), .BUSER(BUSER), .BVALID(BVALID), .BREADY(BREADY),
    .ARID(ARID), .ARADDR(ARADDR), .ARLEN(ARLEN), .ARSIZE(ARSIZE),
    .ARBURST(ARBURST), .ARLOCK(ARLOCK), .ARUSER(ARUSER),
    .ARVALID(ARVALID), .ARREADY(ARREADY), .RID(RID), .RDATA(RDATA),
    .RRESP(RRESP), .RUSER(RUSER), .RLAST(RLAST), .RVALID(RVALID),
    .RREADY(RREADY)
  );

  generate
    if (USE_DMA_TARGET != 0) begin : gen_dma_target
      axi4_caliptra_dma_subordinate #(.RECOVERY_MODE(2)) dma_target (
        .ACLK(ACLK), .ARESETn(ARESETn), .fifo_clear(1'b0),
        .auto_fifo_push(1'b0), .auto_fifo_pop(1'b0),
        .use_dma_gen_sequence(1'b0), .dma_gen_done(1'b0),
        .dma_gen_block_size_bytes(1200'b0), .en_recovery_emulation(1'b0),
        .recovery_threshold_words(32'd2), .recovery_block_words(32'd8),
        .inject_error(inject_error),
        .stall_sram_aw(stall_aw), .stall_sram_w(stall_w), .stall_sram_b(stall_b),
        .stall_sram_ar(stall_ar), .stall_sram_r(stall_r),
        .stall_fifo_aw(stall_aw), .stall_fifo_w(stall_w), .stall_fifo_b(stall_b),
        .stall_fifo_ar(stall_ar), .stall_fifo_r(stall_r),
        .fifo_level(), .fifo_push_event(), .fifo_pop_event(),
        .recovery_data_avail(),
        .AWID(AWID), .AWADDR(AWADDR), .AWLEN(AWLEN), .AWSIZE(AWSIZE),
        .AWBURST(AWBURST), .AWLOCK(AWLOCK), .AWUSER(AWUSER),
        .AWVALID(AWVALID), .AWREADY(AWREADY), .WDATA(WDATA), .WSTRB(WSTRB),
        .WUSER(WUSER), .WLAST(WLAST), .WVALID(WVALID), .WREADY(WREADY),
        .BID(BID), .BRESP(BRESP), .BUSER(BUSER), .BVALID(BVALID), .BREADY(BREADY),
        .ARID(ARID), .ARADDR(ARADDR), .ARLEN(ARLEN), .ARSIZE(ARSIZE),
        .ARBURST(ARBURST), .ARLOCK(ARLOCK), .ARUSER(ARUSER),
        .ARVALID(ARVALID), .ARREADY(ARREADY), .RID(RID), .RDATA(RDATA),
        .RRESP(RRESP), .RUSER(RUSER), .RLAST(RLAST), .RVALID(RVALID),
        .RREADY(RREADY)
      );
    end else begin : gen_memory_target
      axi4_caliptra_memory_subordinate #(
        .ADDR_WIDTH(48), .BASE_ADDR(CALIPTRA_DMA_SRAM_BASE), .MEM_BYTES(256)
      ) memory (
        .ACLK(ACLK), .ARESETn(ARESETn),
        .stall_aw(stall_aw), .stall_w(stall_w), .stall_b(stall_b),
        .stall_ar(stall_ar), .stall_r(stall_r), .inject_error(inject_error),
        .AWID(AWID), .AWADDR(AWADDR), .AWLEN(AWLEN), .AWSIZE(AWSIZE),
        .AWBURST(AWBURST), .AWLOCK(AWLOCK), .AWUSER(AWUSER),
        .AWVALID(AWVALID), .AWREADY(AWREADY), .WDATA(WDATA), .WSTRB(WSTRB),
        .WUSER(WUSER), .WLAST(WLAST), .WVALID(WVALID), .WREADY(WREADY),
        .BID(BID), .BRESP(BRESP), .BUSER(BUSER), .BVALID(BVALID), .BREADY(BREADY),
        .ARID(ARID), .ARADDR(ARADDR), .ARLEN(ARLEN), .ARSIZE(ARSIZE),
        .ARBURST(ARBURST), .ARLOCK(ARLOCK), .ARUSER(ARUSER),
        .ARVALID(ARVALID), .ARREADY(ARREADY), .RID(RID), .RDATA(RDATA),
        .RRESP(RRESP), .RUSER(RUSER), .RLAST(RLAST), .RVALID(RVALID),
        .RREADY(RREADY)
      );
    end
  endgenerate

  axi4_caliptra_transaction_monitor transaction_monitor (
    .ACLK(ACLK), .ARESETn(ARESETn),
    .AWID(AWID), .AWADDR(AWADDR), .AWLEN(AWLEN), .AWSIZE(AWSIZE),
    .AWBURST(AWBURST), .AWLOCK(AWLOCK), .AWUSER(AWUSER),
    .AWVALID(AWVALID), .AWREADY(AWREADY), .WDATA(WDATA), .WSTRB(WSTRB),
    .WUSER(WUSER), .WLAST(WLAST), .WVALID(WVALID), .WREADY(WREADY),
    .BID(BID), .BRESP(BRESP), .BUSER(BUSER), .BVALID(BVALID), .BREADY(BREADY),
    .ARID(ARID), .ARADDR(ARADDR), .ARLEN(ARLEN), .ARSIZE(ARSIZE),
    .ARBURST(ARBURST), .ARLOCK(ARLOCK), .ARUSER(ARUSER),
    .ARVALID(ARVALID), .ARREADY(ARREADY), .RID(RID), .RDATA(RDATA),
    .RRESP(RRESP), .RUSER(RUSER), .RLAST(RLAST), .RVALID(RVALID),
    .RREADY(RREADY),
    .write_complete(record_if.write_complete),
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
    .write_status(record_if.write_status), .write_id(record_if.write_id),
    .write_addr(record_if.write_addr), .write_len(record_if.write_len),
    .write_size(record_if.write_size), .write_burst(record_if.write_burst),
    .write_lock(record_if.write_lock), .write_awuser(record_if.write_awuser),
    .write_beat_count(record_if.write_beat_count), .write_data(record_if.write_data),
    .write_strb(record_if.write_strb), .write_wuser(record_if.write_wuser),
    .write_last_mask(record_if.write_last_mask),
    .write_response_id(record_if.write_response_id),
    .write_response(record_if.write_response), .write_buser(record_if.write_buser),
    .read_complete(record_if.read_complete), .read_error(record_if.read_error),
    .read_error_code(record_if.read_error_code),
    .read_status(record_if.read_status), .read_id(record_if.read_id),
    .read_addr(record_if.read_addr), .read_len(record_if.read_len),
    .read_size(record_if.read_size), .read_burst(record_if.read_burst),
    .read_lock(record_if.read_lock), .read_aruser(record_if.read_aruser),
    .read_beat_count(record_if.read_beat_count), .read_data(record_if.read_data),
    .read_resp(record_if.read_resp), .read_ruser(record_if.read_ruser),
    .read_last_mask(record_if.read_last_mask)
  );

  class axi4_caliptra_uvm_subscriber extends uvm_subscriber #(axi4_caliptra_transaction);
    int write_count;
    int read_count;
    int error_read_count;
    int fifo_write_count;
    int fifo_read_count;
    int full_range_write_count;
    int full_range_read_count;
    int ral_write_count;
    int ral_read_count;
    int ral_error_read_count;
    int exclusive_read_count;
    int exclusive_write_count;
    int exclusive_readback_count;
    int invalidated_exclusive_read_count;
    int reservation_invalidating_write_count;
    int failed_exclusive_write_count;
    int invalidated_exclusive_readback_count;
    event received;

    `uvm_component_utils(axi4_caliptra_uvm_subscriber)

    function new(string name, uvm_component parent);
      super.new(name, parent);
    endfunction

    function void write(axi4_caliptra_transaction item);
      if (item.addr == CALIPTRA_DMA_SRAM_BASE + 48'h1000) begin
        if (item.is_write()) begin
          if (item.id != 8'h60 || item.lock || item.awuser != 32'hcafe_0001 ||
              item.buser != 32'hcafe_0001 || item.len != 8'hff ||
              item.beatQ.size() != 256 || item.strbQ.size() != 256 ||
              item.beat_userQ.size() != 256 || item.lastQ.size() != 256 ||
              item.resp != 2'b00 || item.protocol_error)
            `uvm_fatal("AXI_FULL_WRITE_MON", "Malformed 256-beat write analysis record")
          for (int beat = 0; beat < 256; beat++) begin
            if (item.beatQ[beat] != (32'hd00d_0000 ^ beat) ||
                item.strbQ[beat] != 4'hf ||
                item.beat_userQ[beat] != (32'hb055_0000 | beat) ||
                item.lastQ[beat] != (beat == 255))
              `uvm_fatal("AXI_FULL_WRITE_MON", $sformatf("Bad write record at beat %0d", beat))
          end
          full_range_write_count++;
        end else if (item.is_read()) begin
          if (item.id != 8'h61 || item.lock || item.aruser != 32'hcaf0_0002 ||
              item.len != 8'hff || item.beatQ.size() != 256 ||
              item.respQ.size() != 256 || item.beat_userQ.size() != 256 ||
              item.lastQ.size() != 256 || item.protocol_error)
            `uvm_fatal("AXI_FULL_READ_MON", "Malformed 256-beat read analysis record")
          for (int beat = 0; beat < 256; beat++) begin
            if (item.beatQ[beat] != (32'hd00d_0000 ^ beat) ||
                item.beat_userQ[beat] != 32'hcaf0_0002 ||
                item.respQ[beat] != 2'b00 || item.lastQ[beat] != (beat == 255))
              `uvm_fatal("AXI_FULL_READ_MON", $sformatf("Bad read record at beat %0d", beat))
          end
          full_range_read_count++;
        end
        -> received;
        return;
      end

      if (item.addr == CALIPTRA_DMA_FIFO_BASE) begin
        if (item.is_write()) begin
          fifo_write_count++;
          if (item.id != 8'h51 || item.lock || item.awuser != 32'h5a5a_0001 ||
              item.buser != 32'h5a5a_0001 || item.len != 1 ||
              item.burst != 2'b00 || item.beatQ.size() != 2 ||
              item.beatQ[0] != 32'hc001_0001 || item.beatQ[1] != 32'hc001_0002 ||
              item.strbQ[0] != 4'hf || item.strbQ[1] != 4'hf ||
              item.beat_userQ[0] != 32'h5a5a_1001 ||
              item.beat_userQ[1] != 32'h5a5a_1002 ||
              item.lastQ[0] != 0 || item.lastQ[1] != 1 ||
              item.resp != 2'b00 || item.protocol_error)
            `uvm_fatal("AXI_FIFO_WRITE_MON", $sformatf("Bad FIFO write record: %s", item.convert2string()))
        end else if (item.is_read()) begin
          fifo_read_count++;
          if (item.id != 8'h52 || item.lock || item.aruser != 32'ha5a5_0002 ||
              item.len != 1 || item.burst != 2'b00 || item.beatQ.size() != 2 ||
              item.beatQ[0] != 32'hc001_0001 || item.beatQ[1] != 32'hc001_0002 ||
              item.beat_userQ[0] != 32'ha5a5_0002 ||
              item.beat_userQ[1] != 32'ha5a5_0002 ||
              item.respQ[0] != 2'b00 || item.respQ[1] != 2'b00 ||
              item.lastQ[0] != 0 || item.lastQ[1] != 1 || item.protocol_error)
            `uvm_fatal("AXI_FIFO_READ_MON", $sformatf("Bad FIFO read record: %s", item.convert2string()))
        end else begin
          `uvm_fatal("AXI_FIFO_KIND", "Unknown FIFO transaction kind")
        end
        -> received;
        return;
      end

      if (item.addr == CALIPTRA_DMA_SRAM_BASE + 48'h40) begin
        if (item.is_write()) begin
          if (item.id != 0 || item.lock || item.awuser != 32'hcafe_0123 ||
              item.buser != 32'hcafe_0123 || item.len != 0 || item.beatQ.size() != 1 ||
              item.beatQ[0] != 32'h7654_3210 || item.strbQ[0] != 4'hf ||
              item.beat_userQ[0] != 0 || item.lastQ[0] != 1 ||
              item.resp != 2'b00 || item.protocol_error)
            `uvm_fatal("AXI_RAL_WRITE_MON", "Malformed RAL frontdoor write record")
          ral_write_count++;
        end else if (item.is_read()) begin
          if (item.id != 0 || item.lock || item.aruser != 32'hcafe_0123 ||
              item.response_id != 0 ||
              item.len != 0 || item.beatQ.size() != 1 || item.respQ.size() != 1 ||
              item.protocol_error)
            `uvm_fatal("AXI_RAL_READ_MON", "Malformed RAL frontdoor read record")
          ral_read_count++;
          if (item.respQ[0] == 2'b10) begin
            if (item.resp != 2'b10)
              `uvm_fatal("AXI_RAL_READ_MON", "SLVERR was not preserved in the RAL read record")
            ral_error_read_count++;
          end else if (item.respQ[0] != 2'b00 || item.beatQ[0] != 32'h7654_3210 ||
                       item.beat_userQ[0] != 32'hcafe_0123 || item.lastQ[0] != 1) begin
            `uvm_fatal("AXI_RAL_READ_MON", "Unexpected successful RAL read data or response")
          end
        end else begin
          `uvm_fatal("AXI_RAL_KIND_MON", "Unknown RAL AXI transaction kind")
        end
        -> received;
        return;
      end

      if (item.addr == CALIPTRA_DMA_SRAM_BASE + 48'h60) begin
        if (item.is_write()) begin
          if (item.id == 8'h71) begin
            if (!item.lock || item.awuser != 32'h71a0_0001 || item.buser != 32'h71a0_0001 ||
                item.len != 0 || item.beatQ.size() != 1 || item.beatQ[0] != 32'hc0de_6001 ||
                item.strbQ[0] != 4'hf || item.beat_userQ[0] != 0 || item.lastQ[0] != 1 ||
                item.resp != 2'b01 || item.protocol_error)
              `uvm_fatal("AXI_EXCL_WRITE", "Malformed successful exclusive write record")
            exclusive_write_count++;
          end else if (item.id == 8'h74) begin
            if (item.lock || item.awuser != 32'h74a0_0004 || item.buser != 32'h74a0_0004 ||
                item.len != 0 || item.beatQ.size() != 1 || item.beatQ[0] != 32'hc0de_6002 ||
                item.strbQ[0] != 4'hf || item.beat_userQ[0] != 0 || item.lastQ[0] != 1 ||
                item.resp != 2'b00 || item.protocol_error)
              `uvm_fatal("AXI_EXCL_INVALIDATE_WRITE", "Malformed reservation-invalidating write")
            reservation_invalidating_write_count++;
          end else if (item.id == 8'h73) begin
            if (!item.lock || item.awuser != 32'h73a0_0003 || item.buser != 32'h73a0_0003 ||
                item.len != 0 || item.beatQ.size() != 1 || item.beatQ[0] != 32'hc0de_6003 ||
                item.strbQ[0] != 4'hf || item.beat_userQ[0] != 0 || item.lastQ[0] != 1 ||
                item.resp != 2'b00 || item.protocol_error)
              `uvm_fatal("AXI_EXCL_FAILED_WRITE", "Invalidated exclusive write did not return OKAY")
            failed_exclusive_write_count++;
          end else begin
            `uvm_fatal("AXI_EXCL_WRITE_ID", "Unexpected write ID at exclusive test address")
          end
        end else if (item.is_read()) begin
          if (item.id == 8'h71) begin
            if (!item.lock || item.aruser != 32'h71a0_0001 || item.len != 0 ||
                item.beatQ.size() != 1 || item.respQ.size() != 1 ||
                item.beatQ[0] != 0 || item.respQ[0] != 2'b01 ||
                item.beat_userQ[0] != 32'h71a0_0001 || item.lastQ[0] != 1 ||
                item.protocol_error)
              `uvm_fatal("AXI_EXCL_READ", "Malformed exclusive read record")
            exclusive_read_count++;
          end else if (item.id == 8'h72) begin
            if (item.lock || item.aruser != 32'h72a0_0002 || item.len != 0 ||
                item.beatQ.size() != 1 || item.respQ.size() != 1 ||
                item.beatQ[0] != 32'hc0de_6001 || item.respQ[0] != 2'b00 ||
                item.beat_userQ[0] != 32'h72a0_0002 || item.lastQ[0] != 1 ||
                item.protocol_error)
              `uvm_fatal("AXI_EXCL_READBACK", "Exclusive write data did not read back")
            exclusive_readback_count++;
          end else if (item.id == 8'h73) begin
            if (!item.lock || item.aruser != 32'h73a0_0003 || item.len != 0 ||
                item.beatQ.size() != 1 || item.respQ.size() != 1 ||
                item.beatQ[0] != 32'hc0de_6001 || item.respQ[0] != 2'b01 ||
                item.beat_userQ[0] != 32'h73a0_0003 || item.lastQ[0] != 1 ||
                item.protocol_error)
              `uvm_fatal("AXI_EXCL_INVALIDATE_READ", "Malformed second exclusive read record")
            invalidated_exclusive_read_count++;
          end else if (item.id == 8'h75) begin
            if (item.lock || item.aruser != 32'h75a0_0005 || item.len != 0 ||
                item.beatQ.size() != 1 || item.respQ.size() != 1 ||
                item.beatQ[0] != 32'hc0de_6002 || item.respQ[0] != 2'b00 ||
                item.beat_userQ[0] != 32'h75a0_0005 || item.lastQ[0] != 1 ||
                item.protocol_error)
              `uvm_fatal("AXI_EXCL_FAILED_READBACK", "Failed exclusive write changed memory")
            invalidated_exclusive_readback_count++;
          end else begin
            `uvm_fatal("AXI_EXCL_ID", "Unexpected read ID at exclusive test address")
          end
        end else begin
          `uvm_fatal("AXI_EXCL_KIND", "Unknown transaction kind at exclusive test address")
        end
        -> received;
        return;
      end

      if (item.is_write()) begin
        write_count++;
        if (item.addr != CALIPTRA_DMA_SRAM_BASE + 48'h20 || item.id != 8'h31 || item.lock ||
            item.awuser != 32'h1122_3344 || item.buser != 32'h1122_3344 ||
            item.len != 1 || item.beatQ.size() != 2 ||
            item.beatQ[0] != 32'ha5a5_5a5a || item.beatQ[1] != 32'h1357_9bdf ||
            item.strbQ[0] != 4'hf || item.strbQ[1] != 4'hf ||
            item.beat_userQ[0] != 32'h5566_7788 ||
            item.beat_userQ[1] != 32'h1020_3040 ||
            item.lastQ[0] != 0 || item.lastQ[1] != 1 ||
            item.resp != 2'b00 || item.protocol_error)
          `uvm_fatal("AXI_WRITE_MON", $sformatf("Bad write record: %s", item.convert2string()))
      end else if (item.is_read()) begin
        if (item.id == 8'h43) begin
          error_read_count++;
          if (item.addr != CALIPTRA_DMA_SRAM_BASE + 48'h20 || item.lock || item.aruser != 32'hface_cafe ||
              item.len != 0 || item.beatQ.size() != 1 ||
              item.respQ[0] != 2'b10 || item.protocol_error)
            `uvm_fatal("AXI_READ_ERR_MON", $sformatf("Bad SLVERR read record: %s", item.convert2string()))
        end else begin
          read_count++;
          if (item.addr != CALIPTRA_DMA_SRAM_BASE + 48'h20 || item.id != 8'h42 || item.lock ||
              item.aruser != 32'h89ab_cdef || item.len != 1 || item.beatQ.size() != 2 ||
              item.beatQ[0] != 32'ha5a5_5a5a ||
              item.beatQ[1] != 32'h1357_9bdf ||
              item.beat_userQ[0] != 32'h89ab_cdef ||
              item.beat_userQ[1] != 32'h89ab_cdef ||
              item.lastQ[0] != 0 || item.lastQ[1] != 1 ||
              item.respQ[0] != 2'b00 || item.respQ[1] != 2'b00 ||
              item.protocol_error)
            `uvm_fatal("AXI_READ_MON", $sformatf("Bad read record: %s", item.convert2string()))
        end
      end else begin
        `uvm_fatal("AXI_KIND", "Unknown transaction kind")
      end
      -> received;
    endfunction
  endclass

  class axi4_caliptra_channel_subscriber extends uvm_subscriber #(axi4_caliptra_channel_transaction);
    int channel_count[0:4];

    `uvm_component_utils(axi4_caliptra_channel_subscriber)

    function new(string name, uvm_component parent);
      super.new(name, parent);
      foreach (channel_count[i]) channel_count[i] = 0;
    endfunction

    function void write(axi4_caliptra_channel_transaction item);
      if (item.channel inside {AXI4_CHANNEL_AW, AXI4_CHANNEL_W, AXI4_CHANNEL_B,
                               AXI4_CHANNEL_AR, AXI4_CHANNEL_R})
        channel_count[item.channel]++;
      else
        `uvm_fatal("AXI_CHANNEL_KIND", "Unknown AXI channel item")
    endfunction
  endclass

`ifndef CALIPTRA_BFM_EXTERNAL_AVERY
  class axi4_caliptra_aaxi_subscriber extends uvm_subscriber #(aaxi_master_tr);
    int write_count;
    int read_count;
    int error_read_count;
    int fifo_write_count;
    int fifo_read_count;
    int full_range_write_count;
    int full_range_read_count;
    int ral_write_count;
    int ral_read_count;
    int ral_error_read_count;
    aaxi_master_tr previous_item;
    event received;

    `uvm_component_utils(axi4_caliptra_aaxi_subscriber)

    function new(string name, uvm_component parent);
      super.new(name, parent);
    endfunction

    function void write(aaxi_master_tr item);
      aaxi_master_tr copy_item;
      string diff;
      string trace;

      if (previous_item == item)
        `uvm_fatal("AAXI_ALIAS", "Projected AXI stream reused the previous transaction handle")
      copy_item = item.copy();
      if (copy_item == null)
        `uvm_fatal("AAXI_COPY", "Projected transaction copy returned null")
      if (copy_item == item)
        `uvm_fatal("AAXI_COPY", "Projected transaction copy reused the source handle")
      if (!item.compare(copy_item, diff, item.kind))
        `uvm_fatal("AAXI_COPY", $sformatf("Projected transaction copy/compare failed: %s source_kind=%0d copy_kind=%0d requested_kind=%0d",
                                           diff, item.kind, copy_item.kind, item.kind))
      copy_item.kind = (item.kind == AAXI_WRITE) ? AAXI_READ : AAXI_WRITE;
      diff = "";
      if (item.compare(copy_item, diff, item.kind) || diff != "kind")
        `uvm_fatal("AAXI_COMPARE", "Projected transaction compare missed a kind mismatch or modified the source")
      trace = item.sprint(UVM_LOW, "aaxi");
      if (trace == "")
        `uvm_fatal("AAXI_SPRINT", "Projected transaction sprint returned an empty string")
      previous_item = item;

      if (item.is_write()) begin
        if (item.addr == CALIPTRA_DMA_FIFO_BASE) begin
          if (item.id != 8'h51 || item.lock || item.awuser != 32'h5a5a_0001 ||
              item.buser != 32'h5a5a_0001 || item.len != 1 || item.burst != 2'b00 ||
              item.beatQ.size() != 2 || item.strbQ.size() != 2 ||
              item.beat_userQ.size() != 2 || item.lastQ.size() != 2 ||
              item.beatQ[0] != 32'hc001_0001 || item.beatQ[1] != 32'hc001_0002 ||
              item.strbQ[0] != 4'hf || item.strbQ[1] != 4'hf ||
              item.beat_userQ[0] != 32'h5a5a_1001 || item.beat_userQ[1] != 32'h5a5a_1002 ||
              item.lastQ[0] != 0 || item.lastQ[1] != 1 || item.resp != 2'b00 ||
              item.protocol_error)
            `uvm_fatal("AAXI_FIFO_WRITE", $sformatf("Bad projected FIFO write: %s", item.convert2string()))
          fifo_write_count++;
        end else if (item.addr == CALIPTRA_DMA_SRAM_BASE + 48'h40) begin
          if (item.id != 0 || item.lock || item.awuser != 32'hcafe_0123 ||
              item.buser != 32'hcafe_0123 || item.len != 0 || item.beatQ.size() != 1 ||
              item.beatQ[0] != 32'h7654_3210 || item.strbQ[0] != 4'hf ||
              item.beat_userQ[0] != 0 || item.lastQ[0] != 1 ||
              item.resp != 2'b00 || item.protocol_error)
            `uvm_fatal("AAXI_RAL_WRITE", "Malformed projected RAL write")
          ral_write_count++;
        end else if (item.addr == CALIPTRA_DMA_SRAM_BASE + 48'h1000) begin
          if (item.id != 8'h60 || item.lock || item.awuser != 32'hcafe_0001 ||
              item.buser != 32'hcafe_0001 || item.len != 8'hff ||
              item.beatQ.size() != 256 || item.strbQ.size() != 256 ||
              item.beat_userQ.size() != 256 || item.lastQ.size() != 256 ||
              item.resp != 2'b00 || item.protocol_error)
            `uvm_fatal("AAXI_FULL_WRITE", "Malformed projected 256-beat write")
          for (int beat = 0; beat < 256; beat++) begin
            if (item.beatQ[beat] != (32'hd00d_0000 ^ beat) || item.strbQ[beat] != 4'hf ||
                item.beat_userQ[beat] != (32'hb055_0000 | beat) ||
                item.lastQ[beat] != (beat == 255))
              `uvm_fatal("AAXI_FULL_WRITE", $sformatf("Bad projected write beat %0d", beat))
          end
          full_range_write_count++;
        end else if (item.addr == CALIPTRA_DMA_SRAM_BASE + 48'h60) begin
          if (item.len != 0 || item.beatQ.size() != 1 || item.strbQ.size() != 1 ||
              item.beat_userQ.size() != 1 || item.lastQ.size() != 1 || item.protocol_error)
            `uvm_fatal("AAXI_EXCL_WRITE", "Malformed projected exclusive test write")
          if (item.id == 8'h71) begin
            if (!item.lock || item.awuser != 32'h71a0_0001 || item.buser != 32'h71a0_0001 ||
                item.beatQ[0] != 32'hc0de_6001 || item.strbQ[0] != 4'hf ||
                item.beat_userQ[0] != 0 || item.lastQ[0] != 1 || item.resp != 2'b01)
              `uvm_fatal("AAXI_EXCL_WRITE", "Malformed projected successful exclusive write")
          end else if (item.id == 8'h74) begin
            if (item.lock || item.awuser != 32'h74a0_0004 || item.buser != 32'h74a0_0004 ||
                item.beatQ[0] != 32'hc0de_6002 || item.strbQ[0] != 4'hf ||
                item.beat_userQ[0] != 0 || item.lastQ[0] != 1 || item.resp != 2'b00)
              `uvm_fatal("AAXI_EXCL_INVALIDATE_WRITE", "Malformed reservation-invalidating write")
          end else if (item.id == 8'h73) begin
            if (!item.lock || item.awuser != 32'h73a0_0003 || item.buser != 32'h73a0_0003 ||
                item.beatQ[0] != 32'hc0de_6003 || item.strbQ[0] != 4'hf ||
                item.beat_userQ[0] != 0 || item.lastQ[0] != 1 || item.resp != 2'b00)
              `uvm_fatal("AAXI_EXCL_FAILED_WRITE", "Invalidated projected exclusive write did not return OKAY")
          end else begin
            `uvm_fatal("AAXI_EXCL_WRITE_ID", "Unexpected projected write ID at exclusive test address")
          end
        end else begin
          if (item.addr != CALIPTRA_DMA_SRAM_BASE + 48'h20 || item.id != 8'h31 || item.lock ||
              item.awuser != 32'h1122_3344 || item.buser != 32'h1122_3344 ||
              item.len != 1 || item.beatQ.size() != 2 || item.strbQ.size() != 2 ||
              item.beat_userQ.size() != 2 || item.lastQ.size() != 2 ||
              item.beatQ[0] != 32'ha5a5_5a5a || item.beatQ[1] != 32'h1357_9bdf ||
              item.strbQ[0] != 4'hf || item.strbQ[1] != 4'hf ||
              item.beat_userQ[0] != 32'h5566_7788 || item.beat_userQ[1] != 32'h1020_3040 ||
              item.lastQ[0] != 0 || item.lastQ[1] != 1 || item.resp != 2'b00 ||
              item.protocol_error)
            `uvm_fatal("AAXI_WRITE", $sformatf("Bad projected write: %s", item.convert2string()))
          write_count++;
        end
      end else if (item.is_read()) begin
        if (item.addr == CALIPTRA_DMA_FIFO_BASE) begin
          if (item.id != 8'h52 || item.lock || item.aruser != 32'ha5a5_0002 || item.len != 1 ||
              item.burst != 2'b00 || item.beatQ.size() != 2 || item.respQ.size() != 2 ||
              item.beat_userQ.size() != 2 || item.lastQ.size() != 2 ||
              item.beatQ[0] != 32'hc001_0001 || item.beatQ[1] != 32'hc001_0002 ||
              item.beat_userQ[0] != 32'ha5a5_0002 || item.beat_userQ[1] != 32'ha5a5_0002 ||
              item.respQ[0] != 2'b00 || item.respQ[1] != 2'b00 ||
              item.lastQ[0] != 0 || item.lastQ[1] != 1 || item.protocol_error)
            `uvm_fatal("AAXI_FIFO_READ", $sformatf("Bad projected FIFO read: %s", item.convert2string()))
          fifo_read_count++;
        end else if (item.addr == CALIPTRA_DMA_SRAM_BASE + 48'h1000) begin
          if (item.id != 8'h61 || item.lock || item.aruser != 32'hcaf0_0002 || item.len != 8'hff ||
              item.beatQ.size() != 256 || item.respQ.size() != 256 ||
              item.beat_userQ.size() != 256 || item.lastQ.size() != 256 || item.protocol_error)
            `uvm_fatal("AAXI_FULL_READ", "Malformed projected 256-beat read")
          for (int beat = 0; beat < 256; beat++) begin
            if (item.beatQ[beat] != (32'hd00d_0000 ^ beat) ||
                item.beat_userQ[beat] != 32'hcaf0_0002 || item.respQ[beat] != 2'b00 ||
                item.lastQ[beat] != (beat == 255))
              `uvm_fatal("AAXI_FULL_READ", $sformatf("Bad projected read beat %0d", beat))
          end
          full_range_read_count++;
        end else if (item.addr == CALIPTRA_DMA_SRAM_BASE + 48'h40) begin
          if (item.id != 0 || item.lock || item.aruser != 32'hcafe_0123 ||
              item.response_id != 0 || item.len != 0 ||
              item.beatQ.size() != 1 || item.respQ.size() != 1 || item.protocol_error)
            `uvm_fatal("AAXI_RAL_READ", "Malformed projected RAL read")
          ral_read_count++;
          if (item.respQ[0] == 2'b10) begin
            if (item.resp != 2'b10)
              `uvm_fatal("AAXI_RAL_READ", "Projected RAL SLVERR response was not preserved")
            ral_error_read_count++;
          end else if (item.respQ[0] != 2'b00 || item.beatQ[0] != 32'h7654_3210 ||
                       item.beat_userQ[0] != 32'hcafe_0123 || item.lastQ[0] != 1) begin
            `uvm_fatal("AAXI_RAL_READ", "Projected RAL read data or response mismatch")
          end
        end else if (item.addr == CALIPTRA_DMA_SRAM_BASE + 48'h60) begin
          if (item.len != 0 || item.beatQ.size() != 1 || item.respQ.size() != 1 ||
              item.beat_userQ.size() != 1 || item.lastQ.size() != 1 || item.protocol_error)
            `uvm_fatal("AAXI_EXCL_READ", "Malformed projected exclusive access record")
          if (item.id == 8'h71) begin
            if (!item.lock || item.aruser != 32'h71a0_0001 || item.beatQ[0] != 0 ||
                item.respQ[0] != 2'b01 || item.resp != 2'b01 ||
                item.beat_userQ[0] != 32'h71a0_0001 || item.lastQ[0] != 1)
              `uvm_fatal("AAXI_EXCL_READ", "Malformed projected exclusive read")
          end else if (item.id == 8'h72) begin
            if (item.lock || item.aruser != 32'h72a0_0002 ||
                item.beatQ[0] != 32'hc0de_6001 || item.respQ[0] != 2'b00 ||
                item.beat_userQ[0] != 32'h72a0_0002 || item.lastQ[0] != 1)
              `uvm_fatal("AAXI_EXCL_READBACK", "Projected exclusive write data did not read back")
          end else if (item.id == 8'h73) begin
            if (!item.lock || item.aruser != 32'h73a0_0003 ||
                item.beatQ[0] != 32'hc0de_6001 || item.respQ[0] != 2'b01 ||
                item.resp != 2'b01 || item.beat_userQ[0] != 32'h73a0_0003 ||
                item.lastQ[0] != 1)
              `uvm_fatal("AAXI_EXCL_INVALIDATE_READ", "Malformed second projected exclusive read")
          end else if (item.id == 8'h75) begin
            if (item.lock || item.aruser != 32'h75a0_0005 ||
                item.beatQ[0] != 32'hc0de_6002 || item.respQ[0] != 2'b00 ||
                item.beat_userQ[0] != 32'h75a0_0005 || item.lastQ[0] != 1)
              `uvm_fatal("AAXI_EXCL_FAILED_READBACK", "Failed projected exclusive write changed memory")
          end else begin
            `uvm_fatal("AAXI_EXCL_ID", "Unexpected projected read ID at exclusive test address")
          end
        end else if (item.id == 8'h43) begin
          if (item.addr != CALIPTRA_DMA_SRAM_BASE + 48'h20 || item.lock || item.aruser != 32'hface_cafe ||
              item.len != 0 || item.beatQ.size() != 1 || item.respQ.size() != 1 ||
              item.respQ[0] != 2'b10 || item.resp != 2'b10 || item.protocol_error)
            `uvm_fatal("AAXI_READ_ERR", $sformatf("Bad projected SLVERR read: %s", item.convert2string()))
          error_read_count++;
        end else begin
          if (item.addr != CALIPTRA_DMA_SRAM_BASE + 48'h20 || item.id != 8'h42 || item.lock ||
              item.aruser != 32'h89ab_cdef || item.len != 1 || item.beatQ.size() != 2 ||
              item.respQ.size() != 2 || item.beat_userQ.size() != 2 || item.lastQ.size() != 2 ||
              item.beatQ[0] != 32'ha5a5_5a5a || item.beatQ[1] != 32'h1357_9bdf ||
              item.beat_userQ[0] != 32'h89ab_cdef || item.beat_userQ[1] != 32'h89ab_cdef ||
              item.respQ[0] != 2'b00 || item.respQ[1] != 2'b00 ||
              item.lastQ[0] != 0 || item.lastQ[1] != 1 || item.protocol_error)
            `uvm_fatal("AAXI_READ", $sformatf("Bad projected read: %s", item.convert2string()))
          read_count++;
        end
      end else begin
        `uvm_fatal("AAXI_KIND", "Unknown projected AXI transaction kind")
      end
      -> received;
    endfunction
  endclass
`endif

  class axi4_caliptra_uvm_env extends uvm_env;
    axi4_caliptra_uvm_agent agent;
    axi4_caliptra_uvm_subscriber sub;
    axi4_caliptra_channel_subscriber channel_sub;
`ifndef CALIPTRA_BFM_EXTERNAL_AVERY
    axi4_caliptra_aaxi_uvm_agent aaxi_agent;
    axi4_caliptra_aaxi_subscriber aaxi_sub;
    axi4_caliptra_channel_subscriber aaxi_channel_sub;
`endif

    `uvm_component_utils(axi4_caliptra_uvm_env)

    function new(string name, uvm_component parent);
      super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      agent = axi4_caliptra_uvm_agent::type_id::create("agent", this);
      sub = axi4_caliptra_uvm_subscriber::type_id::create("sub", this);
      channel_sub = axi4_caliptra_channel_subscriber::type_id::create("channel_sub", this);
`ifndef CALIPTRA_BFM_EXTERNAL_AVERY
      aaxi_agent = axi4_caliptra_aaxi_uvm_agent::type_id::create("aaxi_agent", this);
      aaxi_sub = axi4_caliptra_aaxi_subscriber::type_id::create("aaxi_sub", this);
      aaxi_channel_sub = axi4_caliptra_channel_subscriber::type_id::create("aaxi_channel_sub", this);
`endif
    endfunction

    function void connect_phase(uvm_phase phase);
      super.connect_phase(phase);
      agent.ap.connect(sub.analysis_export);
      agent.channel_ap.connect(channel_sub.analysis_export);
`ifndef CALIPTRA_BFM_EXTERNAL_AVERY
      agent.aaxi_ap.connect(aaxi_sub.analysis_export);
      aaxi_agent.channel_ap.connect(aaxi_channel_sub.analysis_export);
`endif
    endfunction
  endclass

  class axi4_caliptra_uvm_error_sequence extends uvm_sequence #(axi4_caliptra_uvm_transfer);
    `uvm_object_utils(axi4_caliptra_uvm_error_sequence)

    function new(string name = "axi4_caliptra_uvm_error_sequence");
      super.new(name);
    endfunction

    task body();
      axi4_caliptra_uvm_transfer req;
      req = axi4_caliptra_uvm_transfer::type_id::create("slverr_read_req");
      start_item(req);
      req.write = 0;
      req.addr = CALIPTRA_DMA_SRAM_BASE + 48'h20;
      req.len = 0;
      req.size = 2;
      req.burst = 2'b01;
      req.id = 8'h43;
      req.user = 32'hface_cafe;
      finish_item(req);
      if (req.success || req.read_response[0 +: 2] != 2'b10)
        `uvm_fatal("AXI_READ_ERR", "UVM driver did not preserve injected SLVERR status")
    endtask
  endclass

  class axi4_caliptra_ral_smoke_reg extends uvm_reg;
    uvm_reg_field value;

    `uvm_object_utils(axi4_caliptra_ral_smoke_reg)

    function new(string name = "axi4_caliptra_ral_smoke_reg");
      super.new(name, 32, UVM_NO_COVERAGE);
    endfunction

    function void build();
      value = uvm_reg_field::type_id::create("value");
      value.configure(this, 32, 0, "RW", 0, 0, 1, 0, 0);
    endfunction
  endclass

  class axi4_caliptra_ral_smoke_block extends uvm_reg_block;
    axi4_caliptra_ral_smoke_reg csr;
    uvm_reg_map aaxi_map;

    `uvm_object_utils(axi4_caliptra_ral_smoke_block)

    function new(string name = "axi4_caliptra_ral_smoke_block");
      super.new(name, UVM_NO_COVERAGE);
    endfunction

    virtual function void build();
      default_map = create_map("default_map", CALIPTRA_DMA_SRAM_BASE, 4,
                               UVM_LITTLE_ENDIAN, 1);
      aaxi_map = create_map("aaxi_map", CALIPTRA_DMA_SRAM_BASE, 4,
                            UVM_LITTLE_ENDIAN, 1);
      csr = axi4_caliptra_ral_smoke_reg::type_id::create("csr");
      csr.configure(this);
      csr.build();
      default_map.add_reg(csr, 48'h40, "RW");
      aaxi_map.add_reg(csr, 48'h40, "RW");
      lock_model();
    endfunction
  endclass

  class axi4_caliptra_reg_predict_subscriber extends uvm_subscriber #(uvm_reg_item);
    int unsigned observed_count;
    `uvm_component_utils(axi4_caliptra_reg_predict_subscriber)

    function new(string name, uvm_component parent);
      super.new(name, parent);
    endfunction

    function void write(uvm_reg_item item);
      observed_count++;
    endfunction
  endclass

  class axi4_caliptra_uvm_reset_abort_sequence extends uvm_sequence #(axi4_caliptra_uvm_transfer);
    `uvm_object_utils(axi4_caliptra_uvm_reset_abort_sequence)

    function new(string name = "axi4_caliptra_uvm_reset_abort_sequence");
      super.new(name);
    endfunction

    task body();
      axi4_caliptra_uvm_transfer req;
      bit completed;

      req = axi4_caliptra_uvm_transfer::type_id::create("reset_abort_read");
      start_item(req);
      req.write = 0;
      req.addr = CALIPTRA_DMA_SRAM_BASE + 48'h80;
      req.len = 0;
      req.size = 2;
      req.burst = 2'b01;
      req.id = 8'h7e;
      completed = 0;
      fork
        begin
          finish_item(req);
          completed = 1;
        end
        begin
          #2000;
          if (!completed)
            `uvm_fatal("AXI_RESET_ABORT_TIMEOUT", "Reset-aborted item did not complete within 200 cycles")
        end
      join_any
      disable fork;
      if (req.success)
        `uvm_fatal("AXI_RESET_ABORT", "Read unexpectedly succeeded across reset")
    endtask
  endclass

  class axi4_caliptra_uvm_reset_abort_write_sequence extends uvm_sequence #(axi4_caliptra_uvm_transfer);
    `uvm_object_utils(axi4_caliptra_uvm_reset_abort_write_sequence)

    function new(string name = "axi4_caliptra_uvm_reset_abort_write_sequence");
      super.new(name);
    endfunction

    task body();
      axi4_caliptra_uvm_transfer req;
      bit completed;

      req = axi4_caliptra_uvm_transfer::type_id::create("reset_abort_write");
      start_item(req);
      req.write = 1;
      req.addr = CALIPTRA_DMA_SRAM_BASE + 48'h90;
      req.len = 0;
      req.size = 2;
      req.burst = 2'b01;
      req.id = 8'h7d;
      req.write_data[0 +: 32] = 32'hbad0_0001;
      req.write_strb[0 +: 4] = 4'hf;
      completed = 0;
      fork
        begin
          finish_item(req);
          completed = 1;
        end
        begin
          #2000;
          if (!completed)
            `uvm_fatal("AXI_RESET_ABORT_WRITE_TIMEOUT", "Reset-aborted write did not complete within 200 cycles")
        end
      join_any
      disable fork;
      if (req.success)
        `uvm_fatal("AXI_RESET_ABORT_WRITE", "Write unexpectedly succeeded across reset")
    endtask
  endclass

  class axi4_caliptra_uvm_agent_test extends uvm_test;
    axi4_caliptra_uvm_env env;
    bit use_dma_target;
    axi4_caliptra_ral_smoke_block ral_model;
    axi4_caliptra_uvm_reg_adapter ral_adapter;
`ifndef CALIPTRA_BFM_EXTERNAL_AVERY
    aaxi_uvm_reg_predictor #(aaxi_master_tr) aaxi_predictor;
    axi4_caliptra_aaxi_reg_adapter aaxi_reg_adapter;
    axi4_caliptra_reg_predict_subscriber reg_predict_subscriber;
`endif
    `uvm_component_utils(axi4_caliptra_uvm_agent_test)

    function new(string name, uvm_component parent);
      super.new(name, parent);
    endfunction

    function void check_register_adapter();
      axi4_caliptra_uvm_reg_adapter adapter;
      axi4_caliptra_uvm_user_extension user_extension;
      axi4_caliptra_uvm_transfer transfer;
      uvm_reg_item reg_item;
      uvm_reg_bus_op rw;
      uvm_sequence_item bus_item;
`ifndef CALIPTRA_BFM_EXTERNAL_AVERY
      aaxi_uvm_mem_adapter aaxi_adapter;
      aaxi_master_tr aaxi_transfer;
`endif

      adapter = axi4_caliptra_uvm_reg_adapter::type_id::create("ral_adapter");
      user_extension = axi4_caliptra_uvm_user_extension::type_id::create("ral_user");
      user_extension.set_addr_user(32'hcafe_0123);
      reg_item = uvm_reg_item::type_id::create("ral_item");
      reg_item.set_extension(user_extension);
      adapter.m_set_item(reg_item);

      rw.kind = UVM_WRITE;
      rw.addr = CALIPTRA_DMA_SRAM_BASE + 48'h40;
      rw.data = 32'h7654_3210;
      rw.n_bits = 32;
      rw.byte_en = '1;
      rw.status = UVM_IS_OK;
      bus_item = adapter.reg2bus(rw);
      if (!$cast(transfer, bus_item) || !transfer.write ||
          transfer.addr != rw.addr || transfer.len != 0 || transfer.size != 2 ||
          transfer.burst != 2'b01 || transfer.user != 32'hcafe_0123 ||
          transfer.write_data[0 +: 32] != 32'h7654_3210 ||
          transfer.write_strb[0 +: 4] != 4'hf)
        `uvm_fatal("AXI_RAL_WRITE", "Register write did not map to a 32-bit AXI request with USER and byte enables")

      transfer.success = 1;
      transfer.response = 2'b00;
      adapter.bus2reg(transfer, rw);
      if (rw.kind != UVM_WRITE || rw.addr != CALIPTRA_DMA_SRAM_BASE + 48'h40 ||
          rw.data != 32'h7654_3210 || rw.byte_en[3:0] != 4'hf ||
          rw.status != UVM_IS_OK || adapter.get_last_addr_user() != 32'hcafe_0123 ||
          adapter.bus2reg_user_obj.get_addr_user() != 32'hcafe_0123)
        `uvm_fatal("AXI_RAL_WRITE", "AXI write response did not map back to the register operation")
      transfer.response = 2'b01;
      adapter.bus2reg(transfer, rw);
      if (rw.status != UVM_IS_OK)
        `uvm_fatal("AXI_RAL_EXOKAY", "Successful exclusive write response mapped to UVM_NOT_OK")

      rw.kind = UVM_READ;
      rw.addr = CALIPTRA_DMA_SRAM_BASE + 48'h44;
      rw.data = '0;
      rw.n_bits = 32;
      rw.byte_en = '1;
      bus_item = adapter.reg2bus(rw);
      if (!$cast(transfer, bus_item) || transfer.write ||
          transfer.addr != rw.addr || transfer.user != 32'hcafe_0123)
        `uvm_fatal("AXI_RAL_READ", "Register read did not map to an AXI request with USER")
      transfer.success = 1;
      transfer.read_data[0 +: 32] = 32'h89ab_cdef;
      transfer.read_response[0 +: 2] = 2'b00;
      adapter.bus2reg(transfer, rw);
      if (rw.kind != UVM_READ || rw.addr != CALIPTRA_DMA_SRAM_BASE + 48'h44 ||
          rw.data != 32'h89ab_cdef || rw.status != UVM_IS_OK ||
          adapter.get_last_addr_user() != 32'hcafe_0123 ||
          adapter.bus2reg_user_obj.get_addr_user() != 32'hcafe_0123)
        `uvm_fatal("AXI_RAL_READ", "AXI read response or ARUSER did not map back to the register operation")
      transfer.read_response[0 +: 2] = 2'b01;
      adapter.bus2reg(transfer, rw);
      if (rw.status != UVM_IS_OK)
        `uvm_fatal("AXI_RAL_EXOKAY", "Successful exclusive read response mapped to UVM_NOT_OK")

      transfer.success = 0;
      transfer.read_response[0 +: 2] = 2'b10;
      adapter.bus2reg(transfer, rw);
      if (rw.status != UVM_NOT_OK)
        `uvm_fatal("AXI_RAL_ERROR", "SLVERR did not map to UVM_NOT_OK")

`ifndef CALIPTRA_BFM_EXTERNAL_AVERY
      aaxi_adapter = new("aaxi_ral_adapter");
      rw.kind = UVM_WRITE;
      rw.addr = CALIPTRA_DMA_SRAM_BASE + 48'h48;
      rw.data = 32'hcafe_f00d;
      rw.n_bits = 32;
      rw.byte_en = '1;
      bus_item = aaxi_adapter.reg2bus(rw);
      if (!$cast(aaxi_transfer, bus_item) || aaxi_transfer.kind != AAXI_WRITE ||
          aaxi_transfer.addr != rw.addr || aaxi_transfer.len != 0 ||
          aaxi_transfer.size != 2 || aaxi_transfer.burst != 2'b01 ||
          aaxi_transfer.beatQ.size() != 1 ||
          aaxi_transfer.beatQ[0] != 32'hcafe_f00d ||
          aaxi_transfer.strbQ[0] != 4'hf)
        `uvm_fatal("AAXI_RAL_WRITE", "AAXI compatibility adapter produced a malformed scalar register write")
      aaxi_transfer.resp = 2'b00;
      aaxi_adapter.bus2reg(aaxi_transfer, rw);
      if (rw.kind != UVM_WRITE || rw.addr != CALIPTRA_DMA_SRAM_BASE + 48'h48 ||
          rw.data != 32'hcafe_f00d || rw.byte_en[3:0] != 4'hf ||
          rw.status != UVM_IS_OK)
        `uvm_fatal("AAXI_RAL_WRITE", "AAXI response did not map back to the register operation")
      aaxi_transfer.resp = 2'b01;
      aaxi_adapter.bus2reg(aaxi_transfer, rw);
      if (rw.status != UVM_IS_OK)
        `uvm_fatal("AAXI_RAL_EXOKAY", "Successful exclusive write response mapped to UVM_NOT_OK")

      rw.kind = UVM_READ;
      rw.addr = CALIPTRA_DMA_SRAM_BASE + 48'h4c;
      rw.n_bits = 32;
      bus_item = aaxi_adapter.reg2bus(rw);
      if (!$cast(aaxi_transfer, bus_item) || aaxi_transfer.kind != AAXI_READ ||
          aaxi_transfer.addr != rw.addr || aaxi_transfer.len != 0 ||
          aaxi_transfer.beatQ.size() != 0)
        `uvm_fatal("AAXI_RAL_READ", "AAXI compatibility adapter produced a malformed scalar register read")
      aaxi_transfer.beatQ.push_back(32'h89ab_cdef);
      aaxi_transfer.respQ.push_back(2'b00);
      aaxi_adapter.bus2reg(aaxi_transfer, rw);
      if (rw.kind != UVM_READ || rw.addr != CALIPTRA_DMA_SRAM_BASE + 48'h4c ||
          rw.data != 32'h89ab_cdef || rw.status != UVM_IS_OK)
        `uvm_fatal("AAXI_RAL_READ", "AAXI read response did not map back to the register operation")
      aaxi_transfer.respQ[0] = 2'b01;
      aaxi_adapter.bus2reg(aaxi_transfer, rw);
      if (rw.status != UVM_IS_OK)
        `uvm_fatal("AAXI_RAL_EXOKAY", "Successful exclusive read response mapped to UVM_NOT_OK")
`endif
    endfunction

    function void build_phase(uvm_phase phase);
      axi4_caliptra_uvm_transfer transfer_probe;
      axi4_caliptra_uvm_transfer transfer_clone;
      uvm_object transfer_clone_object;
`ifndef CALIPTRA_BFM_EXTERNAL_AVERY
      aaxi_master_tr factory_probe;
      aaxi_master_tr clone_probe;
      uvm_object clone_object;
`endif
      super.build_phase(phase);
      if (!uvm_config_db#(bit)::get(this, "", "use_dma_target", use_dma_target))
        `uvm_fatal("AXI_TARGET_CFG", "Missing AXI UVM target selection")
      check_register_adapter();
      transfer_probe = axi4_caliptra_uvm_transfer::type_id::create("transfer_probe");
      transfer_probe.write = 1;
      transfer_probe.addr = 48'h1234_5678_9abc;
      transfer_probe.len = 8'hff;
      transfer_probe.size = 2;
      transfer_probe.burst = 2'b01;
      transfer_probe.id = 8'ha5;
      transfer_probe.user = 32'h7654_3210;
      transfer_probe.lock = 1;
      transfer_probe.write_data[8191 -: 32] = 32'hcafe_babe;
      transfer_probe.write_strb[1023 -: 4] = 4'h5;
      transfer_probe.write_user[8191 -: 32] = 32'h89ab_cdef;
      transfer_probe.success = 1;
      transfer_probe.response = 2'b00;
      transfer_probe.response_user = 32'h1122_3344;
      transfer_probe.read_data[8191 -: 32] = 32'hdead_beef;
      transfer_probe.read_user[8191 -: 32] = 32'h5566_7788;
      transfer_probe.read_response[511 -: 2] = 2'b10;
      transfer_clone_object = transfer_probe.clone();
      if (!$cast(transfer_clone, transfer_clone_object))
        `uvm_fatal("AXI_TRANSFER_CLONE", "AXI transfer clone returned the wrong type")
      if (transfer_clone == transfer_probe || !transfer_probe.compare(transfer_clone) ||
          transfer_clone.write !== transfer_probe.write ||
          transfer_clone.addr !== transfer_probe.addr || transfer_clone.len !== transfer_probe.len ||
          transfer_clone.size !== transfer_probe.size || transfer_clone.burst !== transfer_probe.burst ||
          transfer_clone.id !== transfer_probe.id || transfer_clone.user !== transfer_probe.user ||
          transfer_clone.lock !== transfer_probe.lock ||
          transfer_clone.write_data !== transfer_probe.write_data ||
          transfer_clone.write_strb !== transfer_probe.write_strb ||
          transfer_clone.write_user !== transfer_probe.write_user ||
          transfer_clone.success !== transfer_probe.success ||
          transfer_clone.response !== transfer_probe.response ||
          transfer_clone.response_user !== transfer_probe.response_user ||
          transfer_clone.read_data !== transfer_probe.read_data ||
          transfer_clone.read_user !== transfer_probe.read_user ||
          transfer_clone.read_response !== transfer_probe.read_response)
        `uvm_fatal("AXI_TRANSFER_CLONE", "AXI transfer clone did not preserve every request/response field")
      transfer_clone.write_data[8191] = ~transfer_probe.write_data[8191];
      if (transfer_probe.compare(transfer_clone))
        `uvm_fatal("AXI_TRANSFER_COMPARE", "AXI transfer comparison ignored payload changes")
      ral_model = axi4_caliptra_ral_smoke_block::type_id::create("ral_model");
      ral_model.build();
      ral_adapter = axi4_caliptra_uvm_reg_adapter::type_id::create("ral_adapter");
`ifndef CALIPTRA_BFM_EXTERNAL_AVERY
      aaxi_predictor = aaxi_uvm_reg_predictor #(aaxi_master_tr)::type_id::create("aaxi_predictor", this);
      aaxi_reg_adapter = axi4_caliptra_aaxi_reg_adapter::type_id::create("aaxi_reg_adapter");
      reg_predict_subscriber = axi4_caliptra_reg_predict_subscriber::type_id::create("reg_predict_subscriber", this);
      aaxi_predictor.map = ral_model.aaxi_map;
      aaxi_predictor.adapter = aaxi_reg_adapter;
      factory_probe = aaxi_master_tr::type_id::create("factory_probe");
      if (factory_probe == null)
        `uvm_fatal("AAXI_FACTORY", "aaxi_master_tr factory creation failed")
      factory_probe.kind = AAXI_WRITE;
      factory_probe.addr = CALIPTRA_DMA_SRAM_BASE + 48'h20;
      factory_probe.beatQ.push_back(32'h1234_5678);
      clone_object = factory_probe.clone();
      if (!$cast(clone_probe, clone_object))
        `uvm_fatal("AAXI_CLONE", "aaxi_master_tr clone returned the wrong object type")
      if (clone_probe == factory_probe || !factory_probe.do_compare(clone_probe, null) ||
          clone_probe.kind != AAXI_WRITE || clone_probe.addr != factory_probe.addr ||
          clone_probe.beatQ.size() != 1 || clone_probe.beatQ[0] != 32'h1234_5678)
        `uvm_fatal("AAXI_CLONE", "aaxi_master_tr clone did not preserve its observed fields")
`endif
      env = axi4_caliptra_uvm_env::type_id::create("env", this);
    endfunction

    function void connect_phase(uvm_phase phase);
      super.connect_phase(phase);
      ral_model.default_map.set_sequencer(env.agent.sequencer, ral_adapter);
`ifndef CALIPTRA_BFM_EXTERNAL_AVERY
      ral_model.aaxi_map.set_sequencer(env.aaxi_agent.sequencer, aaxi_reg_adapter);
      env.aaxi_agent.ms_tx_AW_W_export.connect(aaxi_predictor.bus_item_write_export);
      env.aaxi_agent.ms_rx_rvalid_export.connect(aaxi_predictor.bus_item_read_export);
      aaxi_predictor.reg_ap.connect(reg_predict_subscriber.analysis_export);
`endif
    endfunction

    task run_phase(uvm_phase phase);
      axi4_caliptra_uvm_smoke_sequence smoke_seq;
      axi4_caliptra_uvm_reset_abort_sequence reset_abort_seq;
      axi4_caliptra_uvm_reset_abort_write_sequence reset_abort_write_seq;
      axi4_caliptra_uvm_exclusive_sequence exclusive_seq;
      axi4_caliptra_uvm_error_sequence error_seq;
      axi4_caliptra_fifo_uvm_sequence fifo_seq;
      axi4_caliptra_full_range_uvm_sequence full_range_seq;
      axi4_caliptra_uvm_user_extension ral_user;
`ifndef CALIPTRA_BFM_EXTERNAL_AVERY
      axi4_caliptra_uvm_user_extension aaxi_user;
`endif
      uvm_status_e ral_status;
      uvm_reg_data_t ral_read_value;
      phase.raise_objection(this);
      if ($test$plusargs("RESET_ABORT_WRITE")) begin
        reset_abort_write_seq = axi4_caliptra_uvm_reset_abort_write_sequence::type_id::create("reset_abort_write_seq");
        reset_abort_write_seq.start(env.agent.sequencer);
        if (env.sub.write_count != 0)
          `uvm_fatal("AXI_RESET_ABORT_WRITE_MON", "Aborted write was published as a completed transaction")
        smoke_seq = axi4_caliptra_uvm_smoke_sequence::type_id::create("post_reset_smoke_seq");
        smoke_seq.start(env.agent.sequencer);
        $display("PASS: native UVM AXI agent aborts an accepted write before B and recovers for a burst");
        phase.drop_objection(this);
        return;
      end
      if ($test$plusargs("RESET_ABORT")) begin
        reset_abort_seq = axi4_caliptra_uvm_reset_abort_sequence::type_id::create("reset_abort_seq");
        reset_abort_seq.start(env.agent.sequencer);
        if (env.sub.read_count != 0)
          `uvm_fatal("AXI_RESET_ABORT_MON", "Aborted read was published as a completed transaction")
        smoke_seq = axi4_caliptra_uvm_smoke_sequence::type_id::create("post_reset_smoke_seq");
        smoke_seq.start(env.agent.sequencer);
        $display("PASS: native UVM AXI agent aborts an accepted read on reset and recovers for a burst");
        phase.drop_objection(this);
        return;
      end
      ral_user = axi4_caliptra_uvm_user_extension::type_id::create("ral_user");
      ral_user.set_addr_user(32'hcafe_0123);
      ral_model.csr.write(ral_status, 32'h7654_3210, UVM_FRONTDOOR,
                          ral_model.default_map, null, -1, ral_user);
      if (ral_status != UVM_IS_OK)
        `uvm_fatal("AXI_RAL_WRITE", "RAL frontdoor write failed")
      ral_model.csr.read(ral_status, ral_read_value, UVM_FRONTDOOR,
                         ral_model.default_map, null, -1, ral_user);
      if (ral_status != UVM_IS_OK || ral_read_value != 32'h7654_3210)
        `uvm_fatal("AXI_RAL_READ", $sformatf("RAL frontdoor read failed status=%s value=%08h",
                                             ral_status.name(), ral_read_value))
      env.agent.driver.cmd_vif.inject_target_error = 1'b1;
      ral_model.csr.read(ral_status, ral_read_value, UVM_FRONTDOOR,
                         ral_model.default_map, null, -1, ral_user);
      env.agent.driver.cmd_vif.inject_target_error = 1'b0;
      if (ral_status != UVM_NOT_OK)
        `uvm_fatal("AXI_RAL_ERROR", "RAL frontdoor did not report the injected SLVERR")
`ifndef CALIPTRA_BFM_EXTERNAL_AVERY
      aaxi_user = axi4_caliptra_uvm_user_extension::type_id::create("aaxi_user");
      aaxi_user.set_addr_user(32'hcafe_0123);
      ral_model.csr.write(ral_status, 32'h7654_3210, UVM_FRONTDOOR,
                          ral_model.aaxi_map, null, -1, aaxi_user);
      if (ral_status != UVM_IS_OK)
        `uvm_fatal("AAXI_RAL_WRITE", "AAXI-compatible RAL frontdoor write failed")
      ral_model.csr.read(ral_status, ral_read_value, UVM_FRONTDOOR,
                         ral_model.aaxi_map, null, -1, aaxi_user);
      if (ral_status != UVM_IS_OK || ral_read_value != 32'h7654_3210)
        `uvm_fatal("AAXI_RAL_READ", "AAXI-compatible RAL frontdoor read failed")
      env.agent.driver.cmd_vif.inject_target_error = 1'b1;
      ral_model.csr.read(ral_status, ral_read_value, UVM_FRONTDOOR,
                         ral_model.aaxi_map, null, -1, aaxi_user);
      env.agent.driver.cmd_vif.inject_target_error = 1'b0;
      if (ral_status != UVM_NOT_OK ||
          aaxi_reg_adapter.bus2reg_user_obj.get_addr_user() != 32'hcafe_0123 ||
          reg_predict_subscriber.observed_count < 6)
        `uvm_fatal("AAXI_RAL_ERROR", "AAXI adapter, callback USER, or live analysis predictor path failed")
`endif
      smoke_seq = axi4_caliptra_uvm_smoke_sequence::type_id::create("smoke_seq");
      smoke_seq.start(env.agent.sequencer);
      exclusive_seq = axi4_caliptra_uvm_exclusive_sequence::type_id::create("exclusive_seq");
      exclusive_seq.start(env.agent.sequencer);
      env.agent.driver.cmd_vif.inject_target_error = 1'b1;
      error_seq = axi4_caliptra_uvm_error_sequence::type_id::create("error_seq");
      error_seq.start(env.agent.sequencer);
      env.agent.driver.cmd_vif.inject_target_error = 1'b0;
      if (use_dma_target) begin
        fifo_seq = axi4_caliptra_fifo_uvm_sequence::type_id::create("fifo_seq");
        fifo_seq.start(env.agent.sequencer);
        full_range_seq = axi4_caliptra_full_range_uvm_sequence::type_id::create("full_range_seq");
        full_range_seq.start(env.agent.sequencer);
      end
      fork
        begin
          while (env.sub.write_count == 0 || env.sub.read_count == 0 ||
                 env.sub.error_read_count == 0 ||
                 env.sub.exclusive_read_count == 0 || env.sub.exclusive_write_count == 0 ||
                 env.sub.exclusive_readback_count == 0 ||
                 env.sub.invalidated_exclusive_read_count == 0 ||
                 env.sub.reservation_invalidating_write_count == 0 ||
                 env.sub.failed_exclusive_write_count == 0 ||
                 env.sub.invalidated_exclusive_readback_count == 0 ||
                 env.sub.ral_write_count == 0 || env.sub.ral_read_count < 2 ||
                 env.sub.ral_error_read_count == 0 ||
                 env.channel_sub.channel_count[AXI4_CHANNEL_AW] == 0 ||
                 env.channel_sub.channel_count[AXI4_CHANNEL_W] == 0 ||
                 env.channel_sub.channel_count[AXI4_CHANNEL_B] == 0 ||
                 env.channel_sub.channel_count[AXI4_CHANNEL_AR] == 0 ||
                 env.channel_sub.channel_count[AXI4_CHANNEL_R] == 0 ||
                 (use_dma_target &&
                  (env.sub.fifo_write_count == 0 || env.sub.fifo_read_count == 0 ||
                   env.sub.full_range_write_count == 0 || env.sub.full_range_read_count == 0)))
            @env.sub.received;
        end
`ifndef CALIPTRA_BFM_EXTERNAL_AVERY
        begin
          while (env.aaxi_sub.write_count == 0 || env.aaxi_sub.read_count == 0 ||
                 env.aaxi_sub.error_read_count == 0 ||
                 env.aaxi_sub.ral_write_count == 0 || env.aaxi_sub.ral_read_count < 2 ||
                 env.aaxi_sub.ral_error_read_count == 0 ||
                 env.aaxi_channel_sub.channel_count[AXI4_CHANNEL_AW] == 0 ||
                 env.aaxi_channel_sub.channel_count[AXI4_CHANNEL_W] == 0 ||
                 env.aaxi_channel_sub.channel_count[AXI4_CHANNEL_B] == 0 ||
                 env.aaxi_channel_sub.channel_count[AXI4_CHANNEL_AR] == 0 ||
                 env.aaxi_channel_sub.channel_count[AXI4_CHANNEL_R] == 0 ||
                 (use_dma_target &&
                  (env.aaxi_sub.fifo_write_count == 0 || env.aaxi_sub.fifo_read_count == 0 ||
                   env.aaxi_sub.full_range_write_count == 0 || env.aaxi_sub.full_range_read_count == 0)))
            @env.aaxi_sub.received;
        end
`endif
        begin
          #10000;
          `uvm_fatal("AXI_TIMEOUT", "Timed out waiting for monitored read/write transactions")
        end
      join_any
      disable fork;
      if (use_dma_target)
`ifndef CALIPTRA_BFM_EXTERNAL_AVERY
        $display("PASS: UVM AXI agent and AAXI compatibility stream exercised Caliptra DMA SRAM/FIFO map and propagated SLVERR");
`else
        $display("PASS: UVM AXI agent exercised Caliptra DMA SRAM/FIFO map and propagated SLVERR");
`endif
      else
`ifndef CALIPTRA_BFM_EXTERNAL_AVERY
        $display("PASS: UVM AXI agent and AAXI compatibility stream completed burst read/write and propagated SLVERR");
`else
        $display("PASS: UVM AXI agent completed burst read/write and propagated SLVERR");
`endif
      phase.drop_objection(this);
    endtask

    function void report_phase(uvm_phase phase);
      super.report_phase(phase);
      for (int channel = 0; channel < 5; channel++) begin
        if (env.channel_sub.channel_count[channel] == 0)
          `uvm_error("AXI_CHANNEL", $sformatf("Native agent missed channel %0d", channel))
`ifndef CALIPTRA_BFM_EXTERNAL_AVERY
        if (env.aaxi_channel_sub.channel_count[channel] == 0)
          `uvm_error("AAXI_CHANNEL", $sformatf("AAXI agent missed channel %0d", channel))
`endif
      end
    endfunction
  endclass

  initial begin
    uvm_config_db#(bit)::set(
      null, "uvm_test_top", "use_dma_target", (USE_DMA_TARGET != 0));
    uvm_config_db#(virtual axi4_caliptra_master_cmd_if)::set(
      null, "uvm_test_top.env.agent.driver", "cmd_vif", cmd_if);
    uvm_config_db#(virtual axi4_caliptra_record_if)::set(
      null, "uvm_test_top.env.agent.monitor", "vif", record_if);
`ifndef CALIPTRA_BFM_EXTERNAL_AVERY
    uvm_config_db#(virtual axi4_caliptra_master_cmd_if)::set(
      null, "uvm_test_top.env.aaxi_agent.driver", "cmd_vif", cmd_if);
    uvm_config_db#(virtual axi4_caliptra_record_if)::set(
      null, "uvm_test_top.env.aaxi_agent.monitor", "vif", record_if);
`endif
    run_test("axi4_caliptra_uvm_agent_test");
  end

  initial begin
    if ($test$plusargs("RESET_ABORT_WRITE")) begin
      integer cycles;
      reg aw_accepted;
      reg w_accepted;
      stall_b = 1;
      repeat (2) @(posedge ACLK);
      @(negedge ACLK);
      ARESETn = 1;
      aw_accepted = 0;
      w_accepted = 0;
      for (cycles = 0; cycles < 128 && (!aw_accepted || !w_accepted); cycles = cycles + 1) begin
        @(posedge ACLK);
        if (AWVALID && AWREADY) aw_accepted = 1;
        if (WVALID && WREADY && WLAST) w_accepted = 1;
      end
      if (!aw_accepted || !w_accepted)
        $fatal(1, "Timed out waiting for reset-abort write address/data handshakes");
      @(negedge ACLK);
      if (BVALID) $fatal(1, "B response became valid while reset-abort write was stalled");
      ARESETn = 0;
      repeat (2) @(posedge ACLK);
      @(negedge ACLK);
      ARESETn = 1;
      stall_b = 0;
    end else if ($test$plusargs("RESET_ABORT")) begin
      integer cycles;
      reg ar_accepted;
      stall_r = 1;
      repeat (2) @(posedge ACLK);
      @(negedge ACLK);
      ARESETn = 1;
      ar_accepted = 0;
      for (cycles = 0; cycles < 128 && !ar_accepted; cycles = cycles + 1) begin
        @(posedge ACLK);
        if (ARVALID && ARREADY) ar_accepted = 1;
      end
      if (!ar_accepted) $fatal(1, "Timed out waiting for reset-abort read address handshake");
      @(negedge ACLK);
      ARESETn = 0;
      repeat (2) @(posedge ACLK);
      @(negedge ACLK);
      ARESETn = 1;
      stall_r = 0;
    end else begin
      repeat (2) @(posedge ACLK);
      @(negedge ACLK);
      ARESETn = 1;
    end
  end
endmodule
