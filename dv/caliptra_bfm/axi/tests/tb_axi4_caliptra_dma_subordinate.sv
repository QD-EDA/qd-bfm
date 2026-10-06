// SPDX-License-Identifier: Apache-2.0
`timescale 1ns/1ps

module tb_axi4_caliptra_dma_subordinate;
  localparam [47:0] SRAM_BASE = 48'h0001_2344_0000;
  localparam [47:0] FIFO_BASE = 48'h0000_fa57_0000;

  reg ACLK = 0;
  reg ARESETn = 0;
  reg [7:0] AWID = 0;
  reg [47:0] AWADDR = 0;
  reg [7:0] AWLEN = 0;
  reg [2:0] AWSIZE = 2;
  reg [1:0] AWBURST = 1;
  reg AWLOCK = 0;
  reg [31:0] AWUSER = 0;
  reg AWVALID = 0;
  wire AWREADY;
  reg [31:0] WDATA = 0;
  reg [3:0] WSTRB = 4'hf;
  reg [31:0] WUSER = 0;
  reg WLAST = 1;
  reg WVALID = 0;
  wire WREADY;
  wire [7:0] BID;
  wire [1:0] BRESP;
  wire [31:0] BUSER;
  wire BVALID;
  reg BREADY = 1;
  reg [7:0] ARID = 0;
  reg [47:0] ARADDR = 0;
  reg [7:0] ARLEN = 0;
  reg [2:0] ARSIZE = 2;
  reg [1:0] ARBURST = 1;
  reg ARLOCK = 0;
  reg [31:0] ARUSER = 0;
  reg ARVALID = 0;
  wire ARREADY;
  wire [7:0] RID;
  wire [31:0] RDATA;
  wire [1:0] RRESP;
  wire [31:0] RUSER;
  wire RLAST;
  wire RVALID;
  reg RREADY = 1;
  reg auto_fifo_push = 0;
  reg auto_fifo_pop = 0;
  reg stall_sram_b = 0;
  reg stall_sram_r = 0;
  reg use_dma_gen_sequence = 0;
  reg dma_gen_done = 0;
  reg [99:0][11:0] dma_gen_block_size = '0;
  reg en_recovery_emulation = 0;
  wire [31:0] fifo_level;
  wire fifo_push_event;
  wire fifo_pop_event;
  wire recovery_data_avail;
  wire z_control = 1'bz;

  integer timeout;
  integer pop_event_count = 0;
  integer pop_count_before_read;
  integer b_seen_mask;
  integer r_seen_mask;
  integer sram_read_beats;
  integer response_count;
  reg [7:0] held_rid;
  reg [31:0] held_rdata;
  reg [31:0] read_data;
  reg [1:0] response;

  always #5 ACLK = ~ACLK;
  always @(posedge ACLK) begin
    if (fifo_pop_event)
      pop_event_count = pop_event_count + 1;
  end

  axi4_caliptra_dma_subordinate #(
    .RECOVERY_MODE(2)
  ) dut (
    .ACLK(ACLK), .ARESETn(ARESETn),
    .fifo_clear(z_control),
    .auto_fifo_push(auto_fifo_push), .auto_fifo_pop(auto_fifo_pop),
    .use_dma_gen_sequence(use_dma_gen_sequence), .dma_gen_done(dma_gen_done),
    .dma_gen_block_size_bytes(dma_gen_block_size),
    .en_recovery_emulation(en_recovery_emulation),
    .recovery_threshold_words(32'd4), .recovery_block_words(32'd99),
    .inject_error(z_control),
    .stall_sram_aw(z_control), .stall_sram_w(z_control),
    .stall_sram_b(stall_sram_b), .stall_sram_ar(z_control), .stall_sram_r(stall_sram_r),
    .stall_fifo_aw(z_control), .stall_fifo_w(z_control),
    .stall_fifo_b(z_control), .stall_fifo_ar(z_control), .stall_fifo_r(z_control),
    .fifo_level(fifo_level), .fifo_push_event(fifo_push_event),
    .fifo_pop_event(fifo_pop_event), .recovery_data_avail(recovery_data_avail),
    .AWID(AWID), .AWADDR(AWADDR), .AWLEN(AWLEN), .AWSIZE(AWSIZE),
    .AWBURST(AWBURST), .AWLOCK(AWLOCK), .AWUSER(AWUSER),
    .AWVALID(AWVALID), .AWREADY(AWREADY), .WDATA(WDATA), .WSTRB(WSTRB),
    .WUSER(WUSER), .WLAST(WLAST), .WVALID(WVALID), .WREADY(WREADY),
    .BID(BID), .BRESP(BRESP), .BUSER(BUSER), .BVALID(BVALID), .BREADY(BREADY),
    .ARID(ARID), .ARADDR(ARADDR), .ARLEN(ARLEN), .ARSIZE(ARSIZE),
    .ARBURST(ARBURST), .ARLOCK(ARLOCK), .ARUSER(ARUSER),
    .ARVALID(ARVALID), .ARREADY(ARREADY), .RID(RID), .RDATA(RDATA),
    .RRESP(RRESP), .RUSER(RUSER), .RLAST(RLAST), .RVALID(RVALID), .RREADY(RREADY)
  );

  task automatic write_one(input [47:0] addr, input [31:0] data);
    begin
      @(negedge ACLK);
      AWADDR = addr;
      AWLEN = 0;
      AWBURST = addr == FIFO_BASE ? 2'b00 : 2'b01;
      AWID = 8'h2a;
      AWVALID = 1;
      while (!AWREADY) @(posedge ACLK);
      @(negedge ACLK);
      AWVALID = 0;
      WDATA = data;
      WLAST = 1;
      WVALID = 1;
      while (!WREADY) @(posedge ACLK);
      @(negedge ACLK);
      WVALID = 0;
      timeout = 0;
      while (!BVALID && timeout < 20) begin
        @(posedge ACLK);
        timeout = timeout + 1;
      end
      if (!BVALID || BRESP != 2'b00 || BID != 8'h2a)
        $fatal(1, "Write failed: addr=%h BVALID=%b BRESP=%b BID=%h",
               addr, BVALID, BRESP, BID);
      @(negedge ACLK);
    end
  endtask

  task automatic read_one(input [47:0] addr, output [31:0] data);
    begin
      @(negedge ACLK);
      ARADDR = addr;
      ARLEN = 0;
      ARBURST = addr == FIFO_BASE ? 2'b00 : 2'b01;
      ARID = 8'h35;
      ARVALID = 1;
      while (!ARREADY) @(posedge ACLK);
      @(negedge ACLK);
      ARVALID = 0;
      timeout = 0;
      while (!RVALID && timeout < 1000) begin
        @(posedge ACLK);
        timeout = timeout + 1;
      end
      if (!RVALID || !RLAST || RRESP != 2'b00 || RID != 8'h35)
        $fatal(1, "Read failed: addr=%h RVALID=%b RLAST=%b RRESP=%b RID=%h",
               addr, RVALID, RLAST, RRESP, RID);
      data = RDATA;
      @(negedge ACLK);
    end
  endtask

  task automatic send_aw(input [7:0] id, input [47:0] addr,
                         input [7:0] len, input [1:0] burst,
                         input [31:0] user_value);
    begin
      @(negedge ACLK);
      AWID = id;
      AWADDR = addr;
      AWLEN = len;
      AWBURST = burst;
      AWUSER = user_value;
      AWVALID = 1;
      do @(posedge ACLK); while (!(AWVALID && AWREADY));
      @(negedge ACLK);
      AWVALID = 0;
    end
  endtask

  task automatic send_w(input [31:0] data_value, input last_value);
    begin
      @(negedge ACLK);
      WDATA = data_value;
      WLAST = last_value;
      WVALID = 1;
      do @(posedge ACLK); while (!(WVALID && WREADY));
      @(negedge ACLK);
      WVALID = 0;
    end
  endtask

  task automatic send_ar(input [7:0] id, input [47:0] addr,
                         input [7:0] len, input [1:0] burst,
                         input [31:0] user_value);
    begin
      @(negedge ACLK);
      ARID = id;
      ARADDR = addr;
      ARLEN = len;
      ARBURST = burst;
      ARUSER = user_value;
      ARVALID = 1;
      do @(posedge ACLK); while (!(ARVALID && ARREADY));
      @(negedge ACLK);
      ARVALID = 0;
    end
  endtask

  initial begin
    repeat (2) @(posedge ACLK);
    @(negedge ACLK);
    ARESETn = 1;

    write_one(FIFO_BASE, 32'h1234_5678);
    read_one(FIFO_BASE, read_data);
    if (read_data != 32'h1234_5678 || fifo_level != 0)
      $fatal(1, "FIFO AXI write/read mismatch data=%h level=%0d", read_data, fifo_level);

    write_one(SRAM_BASE, 32'hcafe_babe);
    read_one(SRAM_BASE, read_data);
    if (read_data != 32'hcafe_babe)
      $fatal(1, "DMA SRAM write/read mismatch data=%h", read_data);

    // A later FIFO response with the same ID must wait for an earlier SRAM B.
    stall_sram_b = 1;
    BREADY = 0;
    send_aw(8'h44, SRAM_BASE + 48'd16, 0, 2'b01, 32'h4400_0001);
    send_aw(8'h44, FIFO_BASE, 0, 2'b00, 32'h4400_0002);
    send_w(32'h4444_0001, 1);
    send_w(32'h4444_0002, 1);
    timeout = 0;
    while (!dut.i_fifo.BVALID && timeout < 100) begin
      @(posedge ACLK);
      timeout = timeout + 1;
    end
    #1;
    if (!dut.i_fifo.BVALID || BVALID)
      $fatal(1, "Same-ID FIFO B overtook the stalled earlier SRAM B");

    @(negedge ACLK); stall_sram_b = 0;
    timeout = 0;
    while (!BVALID && timeout < 100) begin
      @(posedge ACLK);
      timeout = timeout + 1;
    end
    #1;
    if (!BVALID || BID != 8'h44 || BRESP != 0 || BUSER != 32'h4400_0001)
      $fatal(1, "Same-ID SRAM B was not returned before FIFO B");
    @(negedge ACLK); BREADY = 1;
    @(posedge ACLK);
    if (!BVALID || BID != 8'h44 || BRESP != 0 || BUSER != 32'h4400_0001)
      $fatal(1, "Same-ID SRAM B handshake mismatch");
    @(negedge ACLK); BREADY = 0;
    #1;
    if (!BVALID || BID != 8'h44 || BRESP != 0 || BUSER != 32'h4400_0002)
      $fatal(1, "Same-ID FIFO B did not follow SRAM B");
    @(negedge ACLK); BREADY = 1;
    @(posedge ACLK);
    if (!BVALID || BID != 8'h44 || BRESP != 0 || BUSER != 32'h4400_0002)
      $fatal(1, "Same-ID FIFO B handshake mismatch");
    @(negedge ACLK); BREADY = 0;
    read_one(FIFO_BASE, read_data);
    if (read_data != 32'h4444_0002)
      $fatal(1, "Same-ID B-order setup FIFO data mismatch");

    // Interleave write destinations. W follows AW order; target responses may
    // become ready independently while AXI ID ordering remains intact.
    @(negedge ACLK);
    BREADY = 0;
    send_aw(8'h51, SRAM_BASE + 48'd4, 1, 2'b01, 32'h5100_0001);
    send_aw(8'h62, FIFO_BASE, 0, 2'b00, 32'h6200_0002);
    send_aw(8'h73, SRAM_BASE + 48'd12, 0, 2'b01, 32'h7300_0003);
    send_w(32'h1111_5151, 0);
    send_w(32'h2222_5151, 1);
    send_w(32'h3333_6262, 1);
    send_w(32'h4444_7373, 1);
    wait (dut.i_sram.BVALID && dut.i_fifo.BVALID);
    #1;
    if (!BVALID || (BID != 8'h51 && BID != 8'h62 && BID != 8'h73))
      $fatal(1, "DMA map did not select a valid mixed-target B response");
    held_rid = BID;
    repeat (2) begin
      @(posedge ACLK); #1;
      if (!BVALID || BID != held_rid)
        $fatal(1, "DMA map changed a stalled B response source or ID");
    end
    @(negedge ACLK); BREADY = 1;
    b_seen_mask = 0;
    timeout = 0;
    while (b_seen_mask != 7 && timeout < 100) begin
      @(posedge ACLK);
      if (BVALID && BREADY) begin
        case (BID)
          8'h51: begin
            if (BRESP != 0 || BUSER != 32'h5100_0001 || b_seen_mask[0])
              $fatal(1, "Bad/duplicate SRAM burst B response");
            b_seen_mask[0] = 1;
          end
          8'h62: begin
            if (BRESP != 0 || BUSER != 32'h6200_0002 || b_seen_mask[1])
              $fatal(1, "Bad/duplicate FIFO B response");
            b_seen_mask[1] = 1;
          end
          8'h73: begin
            if (BRESP != 0 || BUSER != 32'h7300_0003 || b_seen_mask[2])
              $fatal(1, "Bad/duplicate second SRAM B response");
            b_seen_mask[2] = 1;
          end
          default: $fatal(1, "Unexpected mixed-target B ID %02h", BID);
        endcase
      end
      timeout = timeout + 1;
    end
    if (b_seen_mask != 7 || dut.i_sram.word_at(1) != 32'h1111_5151 ||
        dut.i_sram.word_at(2) != 32'h2222_5151 ||
        dut.i_sram.word_at(3) != 32'h4444_7373 || fifo_level != 1)
      $fatal(1, "Mixed-target write queue lost data or B responses");

    // Hold one SRAM burst and a FIFO read together. The R arbiter must keep
    // the selected source through RLAST, then deliver both remaining IDs.
    @(negedge ACLK);
    RREADY = 0;
    send_ar(8'h81, SRAM_BASE + 48'd4, 1, 2'b01, 32'h8100_0001);
    send_ar(8'h92, FIFO_BASE, 0, 2'b00, 32'h9200_0002);
    send_ar(8'ha3, SRAM_BASE + 48'd12, 0, 2'b01, 32'ha300_0003);
    wait (dut.i_sram.RVALID && dut.i_fifo.RVALID);
    #1;
    if (!RVALID || (RID != 8'h81 && RID != 8'h92 && RID != 8'ha3))
      $fatal(1, "DMA map did not select a valid mixed-target R response");
    held_rid = RID;
    held_rdata = RDATA;
    repeat (2) begin
      @(posedge ACLK); #1;
      if (!RVALID || RID != held_rid || RDATA != held_rdata)
        $fatal(1, "DMA map changed a stalled R response source or payload");
    end
    @(negedge ACLK); RREADY = 1;
    r_seen_mask = 0;
    sram_read_beats = 0;
    response_count = 0;
    timeout = 0;
    while (r_seen_mask != 7 && timeout < 200) begin
      @(posedge ACLK);
      if (RVALID && RREADY) begin
        case (RID)
          8'h81: begin
            if (RRESP != 0 || RUSER != 32'h8100_0001 ||
                RDATA != (sram_read_beats == 0 ? 32'h1111_5151 : 32'h2222_5151) ||
                RLAST !== (sram_read_beats == 1))
              $fatal(1, "Bad SRAM multi-beat R response");
            sram_read_beats = sram_read_beats + 1;
            if (RLAST) r_seen_mask[0] = 1;
          end
          8'h92: begin
            if (RRESP != 0 || RUSER != 32'h9200_0002 ||
                RDATA != 32'h3333_6262 || !RLAST || r_seen_mask[1])
              $fatal(1, "Bad/duplicate FIFO R response");
            r_seen_mask[1] = 1;
          end
          8'ha3: begin
            if (RRESP != 0 || RUSER != 32'ha300_0003 ||
                RDATA != 32'h4444_7373 || !RLAST || r_seen_mask[2])
              $fatal(1, "Bad/duplicate second SRAM R response");
            r_seen_mask[2] = 1;
          end
          default: $fatal(1, "Unexpected mixed-target R ID %02h", RID);
        endcase
        response_count = response_count + 1;
      end
      timeout = timeout + 1;
    end
    if (r_seen_mask != 7 || sram_read_beats != 2 || response_count != 4 ||
        fifo_level != 0)
      $fatal(1, "Mixed-target read arbitration did not complete all beats");
    @(negedge ACLK); RREADY = 1;

    // A later FIFO read with the same ID must wait for the earlier SRAM RLAST.
    write_one(FIFO_BASE, 32'h4545_4545);
    stall_sram_r = 1;
    RREADY = 0;
    send_ar(8'h5a, SRAM_BASE + 48'd4, 0, 2'b01, 32'h5a00_0001);
    send_ar(8'h5a, FIFO_BASE, 0, 2'b00, 32'h5a00_0002);
    timeout = 0;
    while (!dut.i_fifo.RVALID && timeout < 100) begin
      @(posedge ACLK);
      timeout = timeout + 1;
    end
    #1;
    if (!dut.i_fifo.RVALID || RVALID)
      $fatal(1, "Same-ID FIFO R overtook the stalled earlier SRAM R");

    @(negedge ACLK); stall_sram_r = 0;
    timeout = 0;
    while (!RVALID && timeout < 100) begin
      @(posedge ACLK);
      timeout = timeout + 1;
    end
    #1;
    if (!RVALID || RID != 8'h5a || RDATA != 32'h1111_5151 || RRESP != 0 ||
        RUSER != 32'h5a00_0001 || !RLAST)
      $fatal(1, "Same-ID SRAM R was not returned before FIFO R");
    @(negedge ACLK); RREADY = 1;
    @(posedge ACLK);
    if (!RVALID || RID != 8'h5a || RDATA != 32'h1111_5151 || RRESP != 0 ||
        RUSER != 32'h5a00_0001 || !RLAST)
      $fatal(1, "Same-ID SRAM R handshake mismatch");
    @(negedge ACLK); RREADY = 0;
    #1;
    if (!RVALID || RID != 8'h5a || RDATA != 32'h4545_4545 || RRESP != 0 ||
        RUSER != 32'h5a00_0002 || !RLAST)
      $fatal(1, "Same-ID FIFO R did not follow SRAM R");
    @(negedge ACLK); RREADY = 1;
    @(posedge ACLK);
    if (!RVALID || RID != 8'h5a || RDATA != 32'h4545_4545 || RRESP != 0 ||
        RUSER != 32'h5a00_0002 || !RLAST)
      $fatal(1, "Same-ID FIFO R handshake mismatch");
    @(negedge ACLK); RREADY = 1;
    if (fifo_level != 0)
      $fatal(1, "Same-ID read-order test left FIFO data behind");

    @(negedge ACLK);
    auto_fifo_push = 1;
    timeout = 0;
    while (fifo_level == 0 && timeout < 3000) begin
      @(negedge ACLK);
      timeout = timeout + 1;
    end
    auto_fifo_push = 0;
    if (fifo_level != 1)
      $fatal(1, "Autonomous FIFO producer timed out, level=%0d", fifo_level);
    repeat (3) @(negedge ACLK);
    pop_count_before_read = pop_event_count;
    read_one(FIFO_BASE, read_data);
    if (pop_event_count != pop_count_before_read + 1)
      $fatal(1, "Autonomous FIFO word was not consumed");
    while (fifo_level != 0) begin
      pop_count_before_read = pop_event_count;
      read_one(FIFO_BASE, read_data);
      if (pop_event_count != pop_count_before_read + 1)
        $fatal(1, "Pending autonomous FIFO word was not consumed");
    end

    // Use one known word for the consumer check. The autonomous producer may
    // have a second accepted word pending when its enable is dropped.
    write_one(FIFO_BASE, 32'h7654_3210);
    if (fifo_level != 1)
      $fatal(1, "FIFO consumer setup expected one word, level=%0d", fifo_level);
    pop_count_before_read = pop_event_count;
    @(negedge ACLK);
    auto_fifo_pop = 1;
    timeout = 0;
    while (fifo_level != 0 && timeout < 3000) begin
      @(negedge ACLK);
      timeout = timeout + 1;
    end
    auto_fifo_pop = 0;
    if (fifo_level != 0 || pop_event_count != pop_count_before_read + 1)
      $fatal(1, "Autonomous FIFO consumer failed: level=%0d pops=%0d",
             fifo_level, pop_event_count - pop_count_before_read);

    @(negedge ACLK);
    dma_gen_block_size[0] = 12'd8;
    dma_gen_block_size[1] = 12'd0;
    dma_gen_block_size[2] = 12'd12;
    use_dma_gen_sequence = 1;
    dma_gen_done = 1;
    repeat (2) @(negedge ACLK);
    if (!dut.recovery_sequence_ready || dut.sequenced_block_words != 2 ||
        dut.sequenced_threshold_words < 1 || dut.sequenced_threshold_words > 2)
      $fatal(1, "DMA wrapper did not select the first generated recovery block");

    en_recovery_emulation = 1;
    write_one(FIFO_BASE, 32'h1111_0001);
    write_one(FIFO_BASE, 32'h1111_0002);
    if (!recovery_data_avail)
      $fatal(1, "Sequenced threshold did not assert recovery_data_avail");
    @(negedge ACLK);
    en_recovery_emulation = 0;
    repeat (2) @(negedge ACLK);
    if (dut.sequenced_block_index != 2 || dut.sequenced_block_words != 3 ||
        dut.sequenced_threshold_words < 1 || dut.sequenced_threshold_words > 3)
      $fatal(1, "DMA wrapper did not advance to the next recovery block");
    read_one(FIFO_BASE, read_data);
    read_one(FIFO_BASE, read_data);

    $display("PASS: DMA map, unknown optional controls, autonomous FIFO push/pop, and recovery sequence integration");
    $finish;
  end
endmodule
