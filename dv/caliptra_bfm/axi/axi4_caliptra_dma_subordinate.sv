// SPDX-License-Identifier: Apache-2.0
// Caliptra DMA SRAM/FIFO map composed from the bounded endpoint models.
module axi4_caliptra_dma_subordinate #(
  parameter integer ADDR_WIDTH = 48,
  parameter integer DATA_WIDTH = 32,
  parameter integer ID_WIDTH = 8,
  parameter integer USER_WIDTH = 32,
  parameter [ADDR_WIDTH-1:0] SRAM_BASE_ADDR = 48'h0001_2344_0000,
  parameter integer SRAM_BYTES = 262144,
  parameter [ADDR_WIDTH-1:0] FIFO_BASE_ADDR = 48'h0000_fa57_0000,
  parameter integer FIFO_CAPACITY_BYTES = 65536,
  parameter integer DECODE_LOW_BITS = $clog2(SRAM_BYTES),
  parameter integer RECOVERY_MODE = 0,
  parameter integer DMA_BLOCK_COUNT = 100,
  parameter integer MAX_OUTSTANDING = 4
) (
  input wire ACLK,
  input wire ARESETn,
  input wire fifo_clear,
  input wire auto_fifo_push,
  input wire auto_fifo_pop,
  input wire use_dma_gen_sequence,
  input wire dma_gen_done,
  input wire [DMA_BLOCK_COUNT*12-1:0] dma_gen_block_size_bytes,
  input wire en_recovery_emulation,
  input wire [31:0] recovery_threshold_words,
  input wire [31:0] recovery_block_words,
  input wire inject_error,
  input wire stall_sram_aw,
  input wire stall_sram_w,
  input wire stall_sram_b,
  input wire stall_sram_ar,
  input wire stall_sram_r,
  input wire stall_fifo_aw,
  input wire stall_fifo_w,
  input wire stall_fifo_b,
  input wire stall_fifo_ar,
  input wire stall_fifo_r,
  output wire [31:0] fifo_level,
  output wire fifo_push_event,
  output wire fifo_pop_event,
  output wire recovery_data_avail,
  input wire [ID_WIDTH-1:0] AWID,
  input wire [ADDR_WIDTH-1:0] AWADDR,
  input wire [7:0] AWLEN,
  input wire [2:0] AWSIZE,
  input wire [1:0] AWBURST,
  input wire AWLOCK,
  input wire [USER_WIDTH-1:0] AWUSER,
  input wire AWVALID,
  output wire AWREADY,
  input wire [DATA_WIDTH-1:0] WDATA,
  input wire [DATA_WIDTH/8-1:0] WSTRB,
  input wire [USER_WIDTH-1:0] WUSER,
  input wire WLAST,
  input wire WVALID,
  output wire WREADY,
  output wire [ID_WIDTH-1:0] BID,
  output wire [1:0] BRESP,
  output wire [USER_WIDTH-1:0] BUSER,
  output wire BVALID,
  input wire BREADY,
  input wire [ID_WIDTH-1:0] ARID,
  input wire [ADDR_WIDTH-1:0] ARADDR,
  input wire [7:0] ARLEN,
  input wire [2:0] ARSIZE,
  input wire [1:0] ARBURST,
  input wire ARLOCK,
  input wire [USER_WIDTH-1:0] ARUSER,
  input wire ARVALID,
  output wire ARREADY,
  output wire [ID_WIDTH-1:0] RID,
  output wire [DATA_WIDTH-1:0] RDATA,
  output wire [1:0] RRESP,
  output wire [USER_WIDTH-1:0] RUSER,
  output wire RLAST,
  output wire RVALID,
  input wire RREADY
);
  localparam [63:0] SRAM_BASE_64 = SRAM_BASE_ADDR;
  localparam [63:0] FIFO_BASE_64 = FIFO_BASE_ADDR;
  wire ar_to_fifo, aw_to_fifo;
  wire sram_awready, sram_wready, sram_bvalid;
  wire [ID_WIDTH-1:0] sram_bid;
  wire [1:0] sram_bresp;
  wire [USER_WIDTH-1:0] sram_buser;
  wire sram_arready, sram_rvalid, sram_rlast;
  wire [ID_WIDTH-1:0] sram_rid;
  wire [DATA_WIDTH-1:0] sram_rdata;
  wire [1:0] sram_rresp;
  wire [USER_WIDTH-1:0] sram_ruser;

  wire fifo_awready, fifo_wready, fifo_bvalid;
  wire [ID_WIDTH-1:0] fifo_bid;
  wire [1:0] fifo_bresp;
  wire [USER_WIDTH-1:0] fifo_buser;
  wire fifo_arready, fifo_rvalid, fifo_rlast;
  wire fifo_push_event_internal, fifo_pop_event_internal;
  wire [31:0] sequenced_block_index;
  wire [31:0] sequenced_block_words, sequenced_threshold_words;
  wire recovery_sequence_ready, recovery_sequence_done;
  wire [31:0] effective_block_words, effective_threshold_words;
  wire use_generated_sequence = (use_dma_gen_sequence === 1'b1);
  wire [ID_WIDTH-1:0] fifo_rid;
  wire [DATA_WIDTH-1:0] fifo_rdata;
  wire [1:0] fifo_rresp;
  wire [USER_WIDTH-1:0] fifo_ruser;

  reg wr_route_fifo_q [0:MAX_OUTSTANDING-1];
  integer wr_route_head, wr_route_tail, wr_route_count;
  reg b_active, b_route_fifo, b_prefer_fifo;
  reg r_active, r_route_fifo, r_prefer_fifo;
  wire b_choose_fifo = b_active ? b_route_fifo :
                       (fifo_bvalid && (b_prefer_fifo || !sram_bvalid));
  wire b_any_valid = sram_bvalid || fifo_bvalid;
  wire b_selected_valid = b_choose_fifo ? fifo_bvalid : sram_bvalid;
  wire b_fire = b_selected_valid && BREADY;
  wire r_choose_fifo = r_active ? r_route_fifo :
                       (fifo_rvalid && (r_prefer_fifo || !sram_rvalid));
  wire r_any_valid = sram_rvalid || fifo_rvalid;
  wire r_selected_valid = r_choose_fifo ? fifo_rvalid : sram_rvalid;
  wire r_fire = r_selected_valid && RREADY;
  wire aw_fire = AWVALID && AWREADY;
  wire w_last_fire = WVALID && WREADY && WLAST;

  function automatic is_fifo_address(input [ADDR_WIDTH-1:0] addr);
    reg [63:0] addr64;
    begin
      if ((^addr) === 1'bx) is_fifo_address = 1'b0;
      else begin
        addr64 = addr;
        is_fifo_address = (addr64 >> DECODE_LOW_BITS) ==
                          (FIFO_BASE_64 >> DECODE_LOW_BITS);
      end
    end
  endfunction

  assign aw_to_fifo = is_fifo_address(AWADDR);
  assign ar_to_fifo = is_fifo_address(ARADDR);

  assign AWREADY = ARESETn && (wr_route_count < MAX_OUTSTANDING) &&
                   (aw_to_fifo ? fifo_awready : sram_awready);
  assign WREADY = (wr_route_count != 0) ?
                  (wr_route_fifo_q[wr_route_head] ? fifo_wready : sram_wready) : 1'b0;
  assign BID = b_choose_fifo ? fifo_bid : sram_bid;
  assign BRESP = b_choose_fifo ? fifo_bresp : sram_bresp;
  assign BUSER = b_choose_fifo ? fifo_buser : sram_buser;
  assign BVALID = b_selected_valid;

  assign ARREADY = ARESETn &&
                   (ar_to_fifo ? fifo_arready : sram_arready);
  assign RID = r_choose_fifo ? fifo_rid : sram_rid;
  assign RDATA = r_choose_fifo ? fifo_rdata : sram_rdata;
  assign RRESP = r_choose_fifo ? fifo_rresp : sram_rresp;
  assign RUSER = r_choose_fifo ? fifo_ruser : sram_ruser;
  assign RLAST = r_choose_fifo ? fifo_rlast : sram_rlast;
  assign RVALID = r_selected_valid;
  assign fifo_push_event = fifo_push_event_internal;
  assign fifo_pop_event = fifo_pop_event_internal;
  assign effective_block_words = use_generated_sequence ?
                                 (recovery_sequence_ready ? sequenced_block_words : 32'd1) :
                                 recovery_block_words;
  assign effective_threshold_words = use_generated_sequence ?
                                     (recovery_sequence_ready ? sequenced_threshold_words : 32'd1) :
                                     recovery_threshold_words;

  always @(posedge ACLK) begin
    if (!ARESETn) begin
      wr_route_head <= 0;
      wr_route_tail <= 0;
      wr_route_count <= 0;
      b_active <= 0;
      b_route_fifo <= 0;
      b_prefer_fifo <= 0;
      r_active <= 0;
      r_route_fifo <= 0;
      r_prefer_fifo <= 0;
    end else begin
      if (aw_fire) begin
        wr_route_fifo_q[wr_route_tail] <= aw_to_fifo;
        wr_route_tail <= (wr_route_tail == MAX_OUTSTANDING - 1) ?
                         0 : wr_route_tail + 1;
      end
      if (w_last_fire)
        wr_route_head <= (wr_route_head == MAX_OUTSTANDING - 1) ?
                         0 : wr_route_head + 1;
      if (aw_fire && !w_last_fire) wr_route_count <= wr_route_count + 1;
      else if (!aw_fire && w_last_fire) wr_route_count <= wr_route_count - 1;

      if (b_active) begin
        if (b_fire) begin
          b_active <= 0;
          b_prefer_fifo <= !b_route_fifo;
        end
      end else if (b_any_valid) begin
        if (b_fire) b_prefer_fifo <= !b_choose_fifo;
        else begin
          b_active <= 1;
          b_route_fifo <= b_choose_fifo;
        end
      end

      if (r_active) begin
        if (r_fire && RLAST) begin
          r_active <= 0;
          r_prefer_fifo <= !r_route_fifo;
        end
      end else if (r_any_valid) begin
        if (r_fire && RLAST) r_prefer_fifo <= !r_choose_fifo;
        else begin
          r_active <= 1;
          r_route_fifo <= r_choose_fifo;
        end
      end
    end
  end

  axi4_caliptra_memory_subordinate #(
    .ADDR_WIDTH(ADDR_WIDTH),
    .DATA_WIDTH(DATA_WIDTH),
    .ID_WIDTH(ID_WIDTH),
    .USER_WIDTH(USER_WIDTH),
    .BASE_ADDR(SRAM_BASE_ADDR),
    .MEM_BYTES(SRAM_BYTES),
    .MAX_OUTSTANDING(MAX_OUTSTANDING)
  ) i_sram (
    .ACLK(ACLK), .ARESETn(ARESETn),
    .stall_aw(stall_sram_aw), .stall_w(stall_sram_w), .stall_b(stall_sram_b),
    .stall_ar(stall_sram_ar), .stall_r(stall_sram_r), .inject_error(inject_error),
    .AWID(AWID), .AWADDR(AWADDR), .AWLEN(AWLEN), .AWSIZE(AWSIZE),
    .AWBURST(AWBURST), .AWLOCK(AWLOCK), .AWUSER(AWUSER),
    .AWVALID(AWVALID && (wr_route_count < MAX_OUTSTANDING) && !aw_to_fifo),
    .AWREADY(sram_awready),
    .WDATA(WDATA), .WSTRB(WSTRB), .WUSER(WUSER), .WLAST(WLAST),
    .WVALID(WVALID && (wr_route_count != 0) &&
            !wr_route_fifo_q[wr_route_head]), .WREADY(sram_wready),
    .BID(sram_bid), .BRESP(sram_bresp), .BUSER(sram_buser), .BVALID(sram_bvalid),
    .BREADY(BREADY && b_selected_valid && !b_choose_fifo),
    .ARID(ARID), .ARADDR(ARADDR), .ARLEN(ARLEN), .ARSIZE(ARSIZE),
    .ARBURST(ARBURST), .ARLOCK(ARLOCK), .ARUSER(ARUSER),
    .ARVALID(ARVALID && !ar_to_fifo), .ARREADY(sram_arready),
    .RID(sram_rid), .RDATA(sram_rdata), .RRESP(sram_rresp), .RUSER(sram_ruser),
    .RLAST(sram_rlast), .RVALID(sram_rvalid),
    .RREADY(RREADY && r_selected_valid && !r_choose_fifo)
  );

  axi4_caliptra_fifo_subordinate #(
    .ADDR_WIDTH(ADDR_WIDTH),
    .DATA_WIDTH(DATA_WIDTH),
    .ID_WIDTH(ID_WIDTH),
    .USER_WIDTH(USER_WIDTH),
    .BASE_ADDR(FIFO_BASE_ADDR),
    .FIFO_CAPACITY_BYTES(FIFO_CAPACITY_BYTES),
    .DECODE_LOW_BITS(DECODE_LOW_BITS)
  ) i_fifo (
    .ACLK(ACLK), .ARESETn(ARESETn), .fifo_clear(fifo_clear),
    .auto_push(auto_fifo_push), .auto_pop(auto_fifo_pop),
    .stall_aw(stall_fifo_aw), .stall_w(stall_fifo_w), .stall_b(stall_fifo_b),
    .stall_ar(stall_fifo_ar), .stall_r(stall_fifo_r), .inject_error(inject_error),
    .fifo_level(fifo_level), .fifo_push_event(fifo_push_event_internal),
    .fifo_pop_event(fifo_pop_event_internal),
    .AWID(AWID), .AWADDR(AWADDR), .AWLEN(AWLEN), .AWSIZE(AWSIZE),
    .AWBURST(AWBURST), .AWLOCK(AWLOCK), .AWUSER(AWUSER),
    .AWVALID(AWVALID && (wr_route_count < MAX_OUTSTANDING) && aw_to_fifo),
    .AWREADY(fifo_awready),
    .WDATA(WDATA), .WSTRB(WSTRB), .WUSER(WUSER), .WLAST(WLAST),
    .WVALID(WVALID && (wr_route_count != 0) &&
            wr_route_fifo_q[wr_route_head]), .WREADY(fifo_wready),
    .BID(fifo_bid), .BRESP(fifo_bresp), .BUSER(fifo_buser), .BVALID(fifo_bvalid),
    .BREADY(BREADY && b_selected_valid && b_choose_fifo),
    .ARID(ARID), .ARADDR(ARADDR), .ARLEN(ARLEN), .ARSIZE(ARSIZE),
    .ARBURST(ARBURST), .ARLOCK(ARLOCK), .ARUSER(ARUSER),
    .ARVALID(ARVALID && ar_to_fifo), .ARREADY(fifo_arready),
    .RID(fifo_rid), .RDATA(fifo_rdata), .RRESP(fifo_rresp), .RUSER(fifo_ruser),
    .RLAST(fifo_rlast), .RVALID(fifo_rvalid),
    .RREADY(RREADY && r_selected_valid && r_choose_fifo)
  );

  axi4_caliptra_recovery_sequence #(
    .DATA_WIDTH(DATA_WIDTH),
    .BLOCK_COUNT(DMA_BLOCK_COUNT)
  ) i_recovery_sequence (
    .ACLK(ACLK), .ARESETn(ARESETn),
    .sequence_enable(use_generated_sequence),
    .dma_gen_done(dma_gen_done),
    .en_recovery_emulation(en_recovery_emulation),
    .dma_gen_block_size_bytes(dma_gen_block_size_bytes),
    .block_index(sequenced_block_index),
    .block_words(sequenced_block_words),
    .threshold_words(sequenced_threshold_words),
    .sequence_ready(recovery_sequence_ready),
    .sequence_done(recovery_sequence_done)
  );

  axi4_caliptra_recovery_avail #(
    .MODE(RECOVERY_MODE)
  ) i_recovery_avail (
    .ACLK(ACLK), .ARESETn(ARESETn),
    .en_recovery_emulation(en_recovery_emulation),
    .fifo_level(fifo_level),
    .fifo_push_event(fifo_push_event_internal),
    .fifo_pop_event(fifo_pop_event_internal),
    .threshold_words(effective_threshold_words),
    .block_words(effective_block_words),
    .recovery_data_avail(recovery_data_avail),
    .selected_mode(), .recovery_data_avail_pulse(),
    .writes_since_enable(), .reads_since_enable(), .writes_since_avail(),
    .deassert_at_read_count()
  );

  initial begin
    if (ADDR_WIDTH < 32 || ADDR_WIDTH > 64 || SRAM_BYTES < 1 ||
        MAX_OUTSTANDING < 1 ||
        DECODE_LOW_BITS < 0 || DECODE_LOW_BITS >= ADDR_WIDTH ||
        DECODE_LOW_BITS != $clog2(SRAM_BYTES) ||
        (SRAM_BYTES & (SRAM_BYTES - 1)) != 0 || FIFO_CAPACITY_BYTES < 1 ||
        SRAM_BASE_64 > (64'hffff_ffff_ffff_ffff - SRAM_BYTES) ||
        (SRAM_BASE_64 % SRAM_BYTES) != 0 ||
        ((SRAM_BASE_64 >> DECODE_LOW_BITS) == (FIFO_BASE_64 >> DECODE_LOW_BITS)))
      $fatal(1, "Invalid or overlapping Caliptra DMA subordinate regions");
  end
endmodule
