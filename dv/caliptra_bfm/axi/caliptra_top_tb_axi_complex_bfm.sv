// SPDX-License-Identifier: Apache-2.0
// Drop-in replacement for Caliptra's testbench AXI complex. Compile this file
// in place of caliptra_top_tb_axi_complex.sv when attaching the open BFM.
`include "config_defines.svh"
`default_nettype none

module caliptra_top_tb_axi_complex import caliptra_top_tb_pkg::*; (
  input logic core_clk,
  input logic cptra_rst_b,
  axi_if m_axi_if,
  output logic recovery_data_avail,
  input var axi_complex_ctrl_t ctrl,
  input logic axi_error_inj_en
);
  import axi_pkg::*;
  import soc_ifc_pkg::*;

  localparam integer ADDR_WIDTH = `CALIPTRA_AXI_DMA_ADDR_WIDTH;
  localparam integer DATA_WIDTH = CPTRA_AXI_DMA_DATA_WIDTH;
  localparam integer ID_WIDTH = CPTRA_AXI_DMA_ID_WIDTH;
  localparam integer USER_WIDTH = CPTRA_AXI_DMA_USER_WIDTH;
  localparam integer LOW_DECODE_BITS = 18;
  localparam [ADDR_WIDTH-1:0] SRAM_BASE_ADDR = ADDR_WIDTH'(48'h0001_2344_0000);
  localparam [ADDR_WIDTH-1:0] FIFO_BASE_ADDR = ADDR_WIDTH'(48'h0000_fa57_0000);

  logic [ADDR_WIDTH-1:0] err_resp_start_addr = '0;
  logic [ADDR_WIDTH-1:0] err_resp_end_addr = '0;
  logic cmdline_err_resp_enable = 1'b0;
  logic use_dma_gen_sequence;
  reg err_resp_consumed;

  wire error_armed = cmdline_err_resp_enable &&
                     (axi_error_inj_en === 1'b1) && !err_resp_consumed;
  wire read_error_candidate = error_armed && m_axi_if.arvalid &&
      (m_axi_if.araddr >= err_resp_start_addr) &&
      (m_axi_if.araddr <= err_resp_end_addr);
  wire write_error_candidate = error_armed && m_axi_if.awvalid &&
      (m_axi_if.awaddr >= err_resp_start_addr) &&
      (m_axi_if.awaddr <= err_resp_end_addr);

  wire [9:0] channel_stall;
  axi4_caliptra_random_stalls #(.CHANNELS(10)) i_random_stalls (
    .ACLK(core_clk), .ARESETn(cptra_rst_b),
    .enable(ctrl.rand_delays), .stall(channel_stall)
  );

  wire target_awready, target_wready, target_bvalid, target_arready;
  wire target_rvalid, target_rlast;
  wire [ID_WIDTH-1:0] target_bid, target_rid;
  wire [1:0] target_bresp, target_rresp;
  wire [USER_WIDTH-1:0] target_buser, target_ruser;
  wire [DATA_WIDTH-1:0] target_rdata;

  reg err_write_active, err_write_fifo;
  reg err_b_pending, err_b_valid;
  reg [ID_WIDTH-1:0] err_bid;
  reg [USER_WIDTH-1:0] err_buser;
  reg [7:0] err_write_len, err_write_beat;
  reg err_read_active;
  wire read_error_accept = read_error_candidate && target_arready;
  wire write_error_accept = write_error_candidate && target_awready &&
                            !read_error_accept;
  wire err_b_stall_bit = err_write_fifo ? channel_stall[7] : channel_stall[2];
  wire err_w_fifo_selected = write_error_accept ?
      (m_axi_if.awaddr[ADDR_WIDTH-1:LOW_DECODE_BITS] ==
       FIFO_BASE_ADDR[ADDR_WIDTH-1:LOW_DECODE_BITS]) : err_write_fifo;
  wire err_w_stall_bit = err_w_fifo_selected ? channel_stall[6] : channel_stall[1];

  initial begin
    use_dma_gen_sequence = $test$plusargs("CPTRA_RAND_TEST_DMA");
    if ($value$plusargs("ERR_RESP_START_ADDR=%x", err_resp_start_addr)) begin
      if ($value$plusargs("ERR_RESP_END_ADDR=%x", err_resp_end_addr)) begin
        cmdline_err_resp_enable = 1'b1;
        if (err_resp_start_addr > err_resp_end_addr) begin
          cmdline_err_resp_enable = 1'b0;
          $error("TB: ERR_RESP_START_ADDR exceeds ERR_RESP_END_ADDR; injection disabled");
        end else begin
          $display("[%0t] TB: one-shot AXI SLVERR range 0x%0h to 0x%0h",
                   $time, err_resp_start_addr, err_resp_end_addr);
        end
      end else begin
        $error("TB: ERR_RESP_START_ADDR specified without ERR_RESP_END_ADDR; injection disabled");
      end
    end
  end

  // Route normal traffic into the open target. A selected error request is
  // accepted when the target's corresponding address channel is available,
  // then handled locally without causing target-side memory/FIFO side effects.
  assign m_axi_if.awready = !err_write_active && target_awready;
  assign m_axi_if.wready = (err_write_active || write_error_accept) ?
                           !err_w_stall_bit : target_wready;
  assign m_axi_if.bid = err_b_valid ? err_bid : target_bid;
  assign m_axi_if.bresp = err_b_valid ? AXI_RESP_SLVERR : target_bresp;
  assign m_axi_if.buser = err_b_valid ? err_buser : target_buser;
  assign m_axi_if.bvalid = err_b_valid ? 1'b1 : target_bvalid;

  assign m_axi_if.arready = !err_read_active && target_arready;
  assign m_axi_if.rid = target_rid;
  assign m_axi_if.rdata = target_rdata;
  assign m_axi_if.rresp = err_read_active ? AXI_RESP_SLVERR : target_rresp;
  assign m_axi_if.ruser = target_ruser;
  assign m_axi_if.rlast = target_rlast;
  assign m_axi_if.rvalid = target_rvalid;

  // Keep these instance names: Caliptra firmware seeds i_sram.ram by hierarchy.
  axi4_caliptra_dma_subordinate #(
    .ADDR_WIDTH(ADDR_WIDTH), .DATA_WIDTH(DATA_WIDTH),
    .ID_WIDTH(ID_WIDTH), .USER_WIDTH(USER_WIDTH),
    .SRAM_BASE_ADDR(SRAM_BASE_ADDR), .SRAM_BYTES(262144),
    .FIFO_BASE_ADDR(FIFO_BASE_ADDR), .FIFO_CAPACITY_BYTES(65536),
    .DECODE_LOW_BITS(LOW_DECODE_BITS)
  ) i_axi_sram (
    .ACLK(core_clk), .ARESETn(cptra_rst_b),
    .fifo_clear(ctrl.fifo_clear),
    .auto_fifo_push(ctrl.fifo_auto_push), .auto_fifo_pop(ctrl.fifo_auto_pop),
    .use_dma_gen_sequence(use_dma_gen_sequence), .dma_gen_done(ctrl.dma_gen_done),
    .dma_gen_block_size_bytes(ctrl.dma_gen_block_size),
    .en_recovery_emulation(ctrl.en_recovery_emulation),
    .recovery_threshold_words(32'd1), .recovery_block_words(32'd1),
    .inject_error(1'b0),
    .stall_sram_aw(channel_stall[0]), .stall_sram_w(channel_stall[1]),
    .stall_sram_b(channel_stall[2]), .stall_sram_ar(channel_stall[3]),
    .stall_sram_r(channel_stall[4]), .stall_fifo_aw(channel_stall[5]),
    .stall_fifo_w(channel_stall[6]), .stall_fifo_b(channel_stall[7]),
    .stall_fifo_ar(channel_stall[8]), .stall_fifo_r(channel_stall[9]),
    .fifo_level(), .fifo_push_event(), .fifo_pop_event(),
    .recovery_data_avail(recovery_data_avail),
    .AWID(m_axi_if.awid), .AWADDR(m_axi_if.awaddr), .AWLEN(m_axi_if.awlen),
    .AWSIZE(m_axi_if.awsize), .AWBURST(m_axi_if.awburst), .AWLOCK(m_axi_if.awlock),
    .AWUSER(m_axi_if.awuser),
    .AWVALID(m_axi_if.awvalid && !write_error_accept && !err_write_active),
    .AWREADY(target_awready),
    .WDATA(m_axi_if.wdata), .WSTRB(m_axi_if.wstrb), .WUSER(m_axi_if.wuser),
    .WLAST(m_axi_if.wlast),
    .WVALID(m_axi_if.wvalid && !err_write_active && !write_error_accept),
    .WREADY(target_wready),
    .BID(target_bid), .BRESP(target_bresp), .BUSER(target_buser),
    .BVALID(target_bvalid), .BREADY(m_axi_if.bready && !err_write_active),
    .ARID(m_axi_if.arid), .ARADDR(m_axi_if.araddr), .ARLEN(m_axi_if.arlen),
    .ARSIZE(m_axi_if.arsize), .ARBURST(m_axi_if.arburst), .ARLOCK(m_axi_if.arlock),
    .ARUSER(m_axi_if.aruser),
    .ARVALID(m_axi_if.arvalid && !err_read_active), .ARREADY(target_arready),
    .RID(target_rid), .RDATA(target_rdata), .RRESP(target_rresp),
    .RUSER(target_ruser), .RLAST(target_rlast), .RVALID(target_rvalid),
    .RREADY(m_axi_if.rready)
  );

`ifdef CALIPTRA_BFM_CHECKER
  axi4_caliptra_checker #(
    .ADDR_WIDTH(ADDR_WIDTH), .DATA_WIDTH(DATA_WIDTH),
    .ID_WIDTH(ID_WIDTH), .USER_WIDTH(USER_WIDTH)
  ) i_profile_checker (
    .ACLK(core_clk), .ARESETn(cptra_rst_b),
    .AWID(m_axi_if.awid), .AWADDR(m_axi_if.awaddr),
    .AWLEN(m_axi_if.awlen), .AWSIZE(m_axi_if.awsize),
    .AWBURST(m_axi_if.awburst), .AWLOCK(m_axi_if.awlock),
    .AWUSER(m_axi_if.awuser), .AWVALID(m_axi_if.awvalid),
    .AWREADY(m_axi_if.awready),
    .WDATA(m_axi_if.wdata), .WSTRB(m_axi_if.wstrb),
    .WUSER(m_axi_if.wuser), .WLAST(m_axi_if.wlast),
    .WVALID(m_axi_if.wvalid), .WREADY(m_axi_if.wready),
    .BID(m_axi_if.bid), .BRESP(m_axi_if.bresp), .BUSER(m_axi_if.buser),
    .BVALID(m_axi_if.bvalid), .BREADY(m_axi_if.bready),
    .ARID(m_axi_if.arid), .ARADDR(m_axi_if.araddr),
    .ARLEN(m_axi_if.arlen), .ARSIZE(m_axi_if.arsize),
    .ARBURST(m_axi_if.arburst), .ARLOCK(m_axi_if.arlock),
    .ARUSER(m_axi_if.aruser), .ARVALID(m_axi_if.arvalid),
    .ARREADY(m_axi_if.arready),
    .RID(m_axi_if.rid), .RDATA(m_axi_if.rdata), .RRESP(m_axi_if.rresp),
    .RUSER(m_axi_if.ruser), .RLAST(m_axi_if.rlast),
    .RVALID(m_axi_if.rvalid), .RREADY(m_axi_if.rready)
  );
`endif

  always @(posedge core_clk or negedge cptra_rst_b) begin
    if (!cptra_rst_b) begin
      err_resp_consumed <= 1'b0;
      err_write_active <= 1'b0;
      err_write_fifo <= 1'b0;
      err_b_pending <= 1'b0;
      err_b_valid <= 1'b0;
      err_bid <= '0;
      err_buser <= '0;
      err_write_len <= '0;
      err_write_beat <= '0;
      err_read_active <= 1'b0;
    end else begin
      if (read_error_accept || write_error_accept)
        err_resp_consumed <= 1'b1;

      if (write_error_accept) begin
        err_write_active <= 1'b1;
        err_write_fifo <= m_axi_if.awaddr[ADDR_WIDTH-1:LOW_DECODE_BITS] ==
                          FIFO_BASE_ADDR[ADDR_WIDTH-1:LOW_DECODE_BITS];
        err_bid <= m_axi_if.awid;
        err_buser <= m_axi_if.awuser;
        err_write_len <= m_axi_if.awlen;
        err_write_beat <= 0;
      end
      if ((err_write_active || write_error_accept) &&
          m_axi_if.wvalid && m_axi_if.wready) begin
        if (m_axi_if.wlast !==
            ((err_write_active ? err_write_beat : 0) ==
             (err_write_active ? err_write_len : m_axi_if.awlen)))
          $fatal(1, "Caliptra AXI BFM error sink received WLAST inconsistent with AWLEN");
        if (m_axi_if.wlast) begin
          err_b_pending <= 1'b1;
        end else begin
          err_write_beat <= (err_write_active ? err_write_beat : 0) + 1'b1;
        end
      end
      if (err_b_pending && !err_b_valid && !err_b_stall_bit) begin
        err_b_pending <= 1'b0;
        err_b_valid <= 1'b1;
      end
      if (err_b_valid && m_axi_if.bready) begin
        err_b_valid <= 1'b0;
        err_write_active <= 1'b0;
      end

      if (read_error_accept)
        err_read_active <= 1'b1;
      if (err_read_active && m_axi_if.rvalid && m_axi_if.rready && m_axi_if.rlast)
        err_read_active <= 1'b0;
    end
  end
endmodule

`default_nettype wire
