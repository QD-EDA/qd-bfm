// SPDX-License-Identifier: Apache-2.0
// Caliptra's AXI interface omits CACHE, PROT, QOS, and REGION. This profile
// assumes at most one outstanding transaction per ID (as in the inspected
// Avery manager configuration), not arbitrary same-ID AXI concurrency.
module axi4_caliptra_checker #(
  parameter integer ADDR_WIDTH = 19,
  parameter integer DATA_WIDTH = 32,
  parameter integer ID_WIDTH = 8,
  parameter integer USER_WIDTH = 32,
  parameter integer QUEUE_DEPTH = 16
) (
  input wire ACLK,
  input wire ARESETn,
  input wire [ID_WIDTH-1:0] AWID,
  input wire [ADDR_WIDTH-1:0] AWADDR,
  input wire [7:0] AWLEN,
  input wire [2:0] AWSIZE,
  input wire [1:0] AWBURST,
  input wire AWLOCK,
  input wire [USER_WIDTH-1:0] AWUSER,
  input wire AWVALID,
  input wire AWREADY,
  input wire [DATA_WIDTH-1:0] WDATA,
  input wire [DATA_WIDTH/8-1:0] WSTRB,
  input wire [USER_WIDTH-1:0] WUSER,
  input wire WLAST,
  input wire WVALID,
  input wire WREADY,
  input wire [ID_WIDTH-1:0] BID,
  input wire [1:0] BRESP,
  input wire [USER_WIDTH-1:0] BUSER,
  input wire BVALID,
  input wire BREADY,
  input wire [ID_WIDTH-1:0] ARID,
  input wire [ADDR_WIDTH-1:0] ARADDR,
  input wire [7:0] ARLEN,
  input wire [2:0] ARSIZE,
  input wire [1:0] ARBURST,
  input wire ARLOCK,
  input wire [USER_WIDTH-1:0] ARUSER,
  input wire ARVALID,
  input wire ARREADY,
  input wire [ID_WIDTH-1:0] RID,
  input wire [DATA_WIDTH-1:0] RDATA,
  input wire [1:0] RRESP,
  input wire [USER_WIDTH-1:0] RUSER,
  input wire RLAST,
  input wire RVALID,
  input wire RREADY
);
  localparam integer DATA_BYTES = DATA_WIDTH / 8;
  localparam integer ID_COUNT = 1 << ID_WIDTH;
  localparam [1:0] EXCL_NONE = 2'd0, EXCL_PENDING = 2'd1, EXCL_COMPLETE = 2'd2;

  reg aw_stalled, w_stalled, b_stalled, ar_stalled, r_stalled;
  reg [ID_WIDTH+ADDR_WIDTH+8+3+2+1+USER_WIDTH-1:0] aw_hold;
  reg [DATA_WIDTH+DATA_WIDTH/8+USER_WIDTH:0] w_hold;
  reg [ID_WIDTH+1+1+USER_WIDTH-1:0] b_hold;
  reg [ID_WIDTH+ADDR_WIDTH+8+3+2+1+USER_WIDTH-1:0] ar_hold;
  reg [ID_WIDTH+DATA_WIDTH+USER_WIDTH+2:0] r_hold;

  reg wr_active [0:ID_COUNT-1];
  reg wr_data_done [0:ID_COUNT-1];
  reg wr_exclusive [0:ID_COUNT-1];
  reg rd_active [0:ID_COUNT-1];
  reg [8:0] rd_beats_left [0:ID_COUNT-1];
  reg rd_exclusive [0:ID_COUNT-1];
  reg rd_response_seen [0:ID_COUNT-1];
  reg rd_response_exokay [0:ID_COUNT-1];
  // Arm IHI0022L A7.3: match the exposed ID/address/length/size/burst fields;
  // the pinned Caliptra interface omits AXI's CACHE, PROT, and REGION fields.
  reg [1:0] exclusive_read_state [0:ID_COUNT-1];
  reg [ADDR_WIDTH+8+3+2-1:0] exclusive_read_shape [0:ID_COUNT-1];

  reg [8:0] expected_beats [0:QUEUE_DEPTH-1];
  reg [ID_WIDTH-1:0] expected_id [0:QUEUE_DEPTH-1];
  reg [ADDR_WIDTH-1:0] expected_addr [0:QUEUE_DEPTH-1];
  reg [2:0] expected_size [0:QUEUE_DEPTH-1];
  reg [1:0] expected_burst [0:QUEUE_DEPTH-1];
  reg [8:0] observed_beats [0:QUEUE_DEPTH-1];
  reg [DATA_BYTES-1:0] observed_strobes [0:QUEUE_DEPTH-1][0:255];
  integer expected_read, expected_write, expected_count;
  integer observed_read, observed_write, observed_count;
  reg [8:0] write_beats_in_progress;

  integer i;

  task automatic check_burst(
    input [ADDR_WIDTH-1:0] addr,
    input [7:0] len,
    input [2:0] size,
    input [1:0] burst,
    input [8*2-1:0] channel
  );
    reg [63:0] bytes_per_beat;
    reg [63:0] beats;
    reg [63:0] span;
    reg [63:0] wrap_base;
    begin
      if (size > $clog2(DATA_BYTES))
        $fatal(1, "AXI %0s AxSIZE exceeds bus width", channel);
      bytes_per_beat = 64'd1 << size;
      beats = {56'd0, len} + 1;
      if ((addr % bytes_per_beat) != 0)
        $fatal(1, "AXI %0s unaligned transfer is outside the Caliptra profile", channel);
      case (burst)
        2'b00: begin
          if (beats > 16)
            $fatal(1, "AXI %0s FIXED burst exceeds 16 beats", channel);
        end
        2'b01: begin
          span = beats * bytes_per_beat;
          if ((addr[11:0] + span) > 4096)
            $fatal(1, "AXI %0s INCR burst crosses a 4KB boundary", channel);
        end
        2'b10: begin
          if (!(beats == 2 || beats == 4 || beats == 8 || beats == 16))
            $fatal(1, "AXI %0s WRAP burst length must be 2, 4, 8, or 16", channel);
          span = beats * bytes_per_beat;
          wrap_base = (addr / span) * span;
          if (((wrap_base % 4096) + span) > 4096)
            $fatal(1, "AXI %0s WRAP burst crosses a 4KB boundary", channel);
        end
        default: $fatal(1, "AXI %0s reserved burst encoding", channel);
      endcase
    end
  endtask

  // Arm IHI0022L A6.3.3: <=16 transfers, power-of-two <=128 bytes,
  // and address aligned to the complete transfer size.
  // Source: https://documentation-service.arm.com/static/68b03beb01ae952d9559f9eb
  task automatic check_exclusive_burst(
    input [ADDR_WIDTH-1:0] addr,
    input [7:0] len,
    input [2:0] size,
    input [8*2-1:0] channel
  );
    reg [63:0] bytes_per_beat;
    reg [63:0] beats;
    reg [63:0] transfer_bytes;
    begin
      bytes_per_beat = 64'd1 << size;
      beats = {56'd0, len} + 1;
      if (beats > 16)
        $fatal(1, "AXI %0s exclusive burst exceeds 16 transfers", channel);
      transfer_bytes = beats * bytes_per_beat;
      if (transfer_bytes > 128)
        $fatal(1, "AXI %0s exclusive burst exceeds 128 bytes", channel);
      if ((transfer_bytes & (transfer_bytes - 1)) != 0)
        $fatal(1, "AXI %0s exclusive byte count is not a power of 2", channel);
      if ((addr % transfer_bytes) != 0)
        $fatal(1, "AXI %0s exclusive AXI address is not aligned to its transaction size", channel);
    end
  endtask

  task automatic pair_write_data;
    reg [ID_WIDTH-1:0] id;
    reg [DATA_BYTES-1:0] allowed_strobe;
    reg [63:0] beat_address;
    reg [63:0] beat_bytes;
    reg [63:0] burst_span;
    reg [63:0] wrap_base;
    integer beat_index;
    integer byte_index;
    begin
      while ((expected_count > 0) && (observed_count > 0)) begin
        if (expected_beats[expected_read] != observed_beats[observed_read])
          $fatal(1, "AXI W burst has %0d beats; AWLEN requires %0d",
                 observed_beats[observed_read], expected_beats[expected_read]);
        id = expected_id[expected_read];
        if (!wr_active[id])
          $fatal(1, "AXI W burst has no active AW transaction");
        beat_address = expected_addr[expected_read];
        beat_bytes = 64'd1 << expected_size[expected_read];
        burst_span = expected_beats[expected_read] * beat_bytes;
        wrap_base = (beat_address / burst_span) * burst_span;
        for (beat_index = 0; beat_index < expected_beats[expected_read]; beat_index = beat_index + 1) begin
          allowed_strobe = '0;
          for (byte_index = 0; byte_index < DATA_BYTES; byte_index = byte_index + 1) begin
            if ((byte_index >= (beat_address % DATA_BYTES)) &&
                (byte_index < ((beat_address % DATA_BYTES) + beat_bytes)))
              allowed_strobe[byte_index] = 1'b1;
          end
          if ((observed_strobes[observed_read][beat_index] & ~allowed_strobe) !== {DATA_BYTES{1'b0}})
            $fatal(1, "AXI WSTRB enables bytes outside the AW address/AWSIZE lanes");
          case (expected_burst[expected_read])
            2'b01: beat_address = beat_address + beat_bytes;
            2'b10: begin
              if ((beat_address + beat_bytes) >= (wrap_base + burst_span))
                beat_address = wrap_base;
              else
                beat_address = beat_address + beat_bytes;
            end
            default: begin end
          endcase
        end
        wr_data_done[id] = 1'b1;
        expected_read = (expected_read + 1) % QUEUE_DEPTH;
        expected_count = expected_count - 1;
        observed_read = (observed_read + 1) % QUEUE_DEPTH;
        observed_count = observed_count - 1;
      end
    end
  endtask

  // Call from the testbench's end-of-test/drain check to reject unfinished
  // reads, writes, or early W data that never paired with an AW.
  task automatic check_idle;
    integer index;
    begin
      if (expected_count != 0 || observed_count != 0 || write_beats_in_progress != 0)
        $fatal(1, "AXI checker has incomplete write address/data traffic");
      for (index = 0; index < ID_COUNT; index = index + 1) begin
        if (wr_active[index]) $fatal(1, "AXI checker has an outstanding write response");
        if (rd_active[index]) $fatal(1, "AXI checker has an incomplete read response");
      end
    end
  endtask

  initial begin
    if (ADDR_WIDTH < 12 || DATA_WIDTH < 8 || (DATA_WIDTH % 8) != 0 ||
        (DATA_BYTES & (DATA_BYTES - 1)) != 0 || QUEUE_DEPTH < 1)
      $fatal(1, "Invalid Caliptra AXI checker parameters");
  end

  always @(posedge ACLK) begin
    if (!ARESETn) begin
      aw_stalled = 0;
      w_stalled = 0;
      b_stalled = 0;
      ar_stalled = 0;
      r_stalled = 0;
      expected_read = 0;
      expected_write = 0;
      expected_count = 0;
      observed_read = 0;
      observed_write = 0;
      observed_count = 0;
      write_beats_in_progress = 0;
      for (i = 0; i < ID_COUNT; i = i + 1) begin
        wr_active[i] = 0;
        wr_data_done[i] = 0;
        wr_exclusive[i] = 0;
        rd_active[i] = 0;
        rd_beats_left[i] = 0;
        rd_exclusive[i] = 0;
        rd_response_seen[i] = 0;
        rd_response_exokay[i] = 0;
        exclusive_read_state[i] = EXCL_NONE;
      end
    end else begin
      if (aw_stalled && (!AWVALID ||
          {AWID, AWADDR, AWLEN, AWSIZE, AWBURST, AWLOCK, AWUSER} !== aw_hold))
        $fatal(1, "AXI AW payload changed or VALID dropped while stalled");
      if (w_stalled && (!WVALID || {WDATA, WSTRB, WUSER, WLAST} !== w_hold))
        $fatal(1, "AXI W payload changed or VALID dropped while stalled");
      if (b_stalled && (!BVALID || {BID, BRESP, BUSER} !== b_hold))
        $fatal(1, "AXI B payload changed or VALID dropped while stalled");
      if (ar_stalled && (!ARVALID ||
          {ARID, ARADDR, ARLEN, ARSIZE, ARBURST, ARLOCK, ARUSER} !== ar_hold))
        $fatal(1, "AXI AR payload changed or VALID dropped while stalled");
      if (r_stalled && (!RVALID || {RID, RDATA, RRESP, RUSER, RLAST} !== r_hold))
        $fatal(1, "AXI R payload changed or VALID dropped while stalled");

      aw_stalled = AWVALID && !AWREADY;
      if (aw_stalled) aw_hold = {AWID, AWADDR, AWLEN, AWSIZE, AWBURST, AWLOCK, AWUSER};
      w_stalled = WVALID && !WREADY;
      if (w_stalled) w_hold = {WDATA, WSTRB, WUSER, WLAST};
      b_stalled = BVALID && !BREADY;
      if (b_stalled) b_hold = {BID, BRESP, BUSER};
      ar_stalled = ARVALID && !ARREADY;
      if (ar_stalled) ar_hold = {ARID, ARADDR, ARLEN, ARSIZE, ARBURST, ARLOCK, ARUSER};
      r_stalled = RVALID && !RREADY;
      if (r_stalled) r_hold = {RID, RDATA, RRESP, RUSER, RLAST};

      if (AWVALID && AWREADY) begin
        if (AWLOCK !== 1'b0 && AWLOCK !== 1'b1)
          $fatal(1, "AXI AWLOCK is unknown");
        check_burst(AWADDR, AWLEN, AWSIZE, AWBURST, "AW");
        if (AWLOCK) check_exclusive_burst(AWADDR, AWLEN, AWSIZE, "AW");
        if (AWLOCK) begin
          if (exclusive_read_state[AWID] == EXCL_NONE)
            $fatal(1, "AXI exclusive write has no completed exclusive read");
          if (exclusive_read_state[AWID] == EXCL_PENDING)
            $fatal(1, "AXI exclusive write issued before the read completes");
          if (exclusive_read_shape[AWID] !== {AWADDR, AWLEN, AWSIZE, AWBURST})
            $fatal(1, "AXI exclusive read/write request fields differ");
          exclusive_read_state[AWID] = EXCL_NONE;
        end
        if (wr_active[AWID]) $fatal(1, "AXI Caliptra profile allows one outstanding write per ID");
        if (expected_count == QUEUE_DEPTH) $fatal(1, "AXI checker AW queue overflow");
        wr_active[AWID] = 1;
        wr_data_done[AWID] = 0;
        wr_exclusive[AWID] = AWLOCK;
        expected_beats[expected_write] = {1'b0, AWLEN} + 1'b1;
        expected_id[expected_write] = AWID;
        expected_addr[expected_write] = AWADDR;
        expected_size[expected_write] = AWSIZE;
        expected_burst[expected_write] = AWBURST;
        expected_write = (expected_write + 1) % QUEUE_DEPTH;
        expected_count = expected_count + 1;
        if ((write_beats_in_progress >= expected_beats[expected_read]) &&
            (write_beats_in_progress != 0))
          $fatal(1, "AXI WLAST missing on final AWLEN beat");
        pair_write_data();
      end

      if (WVALID && WREADY) begin
        if (WLAST !== 1'b0 && WLAST !== 1'b1) $fatal(1, "AXI WLAST is unknown");
        if ((^WSTRB) === 1'bx) $fatal(1, "AXI WSTRB is unknown");
        if (write_beats_in_progress >= 256)
          $fatal(1, "AXI W burst exceeds 256 beats");
        if ((write_beats_in_progress == 0) && (observed_count == QUEUE_DEPTH))
          $fatal(1, "AXI checker W queue overflow");
        observed_strobes[observed_write][write_beats_in_progress] = WSTRB;
        write_beats_in_progress = write_beats_in_progress + 1'b1;
        if ((expected_count > 0) &&
            (write_beats_in_progress > expected_beats[expected_read]))
          $fatal(1, "AXI W burst exceeds AWLEN");
        if ((expected_count > 0) &&
            (write_beats_in_progress == expected_beats[expected_read]) && !WLAST)
          $fatal(1, "AXI WLAST missing on final AWLEN beat");
        if (WLAST) begin
          if (observed_count == QUEUE_DEPTH) $fatal(1, "AXI checker W queue overflow");
          observed_beats[observed_write] = write_beats_in_progress;
          observed_write = (observed_write + 1) % QUEUE_DEPTH;
          observed_count = observed_count + 1;
          write_beats_in_progress = 0;
          pair_write_data();
        end
      end

      if (BVALID && BREADY) begin
        if (!wr_active[BID] || !wr_data_done[BID])
          $fatal(1, "AXI B response ID has no completed write transaction");
        if ((^BRESP) === 1'bx) $fatal(1, "AXI BRESP is unknown");
        if ((BRESP == 2'b01) && !wr_exclusive[BID])
          $fatal(1, "AXI B response is EXOKAY for a non-exclusive write");
        wr_active[BID] = 0;
        wr_data_done[BID] = 0;
        wr_exclusive[BID] = 0;
      end

      if (ARVALID && ARREADY) begin
        if (ARLOCK !== 1'b0 && ARLOCK !== 1'b1)
          $fatal(1, "AXI ARLOCK is unknown");
        check_burst(ARADDR, ARLEN, ARSIZE, ARBURST, "AR");
        if (ARLOCK) check_exclusive_burst(ARADDR, ARLEN, ARSIZE, "AR");
        if (rd_active[ARID]) $fatal(1, "AXI Caliptra profile allows one outstanding read per ID");
        rd_active[ARID] = 1;
        rd_exclusive[ARID] = ARLOCK;
        rd_response_seen[ARID] = 0;
        if (ARLOCK) begin
          exclusive_read_state[ARID] = EXCL_PENDING;
          exclusive_read_shape[ARID] = {ARADDR, ARLEN, ARSIZE, ARBURST};
        end
        rd_beats_left[ARID] = {1'b0, ARLEN} + 1'b1;
      end

      if (RVALID && RREADY) begin
        if (!rd_active[RID]) $fatal(1, "AXI R response ID has no active read transaction");
        if ((^RRESP) === 1'bx) $fatal(1, "AXI RRESP is unknown");
        if (!rd_exclusive[RID] && (RRESP == 2'b01))
          $fatal(1, "AXI R response is EXOKAY for a non-exclusive read");
        // Arm IHI0022L A7.3.4 requires all beats of one exclusive read to
        // report EXOKAY, or all beats to report a non-EXOKAY response.
        if (rd_exclusive[RID]) begin
          if (!rd_response_seen[RID]) begin
            rd_response_seen[RID] = 1;
            rd_response_exokay[RID] = (RRESP == 2'b01);
          end else if (rd_response_exokay[RID] != (RRESP == 2'b01)) begin
            $fatal(1, "AXI exclusive read mixes EXOKAY and non-EXOKAY responses");
          end
        end
        if (RLAST !== (rd_beats_left[RID] == 1))
          $fatal(1, "AXI RLAST does not match ARLEN for RID %0h", RID);
        if (rd_beats_left[RID] == 1) begin
          rd_beats_left[RID] = 0;
          rd_active[RID] = 0;
          if (exclusive_read_state[RID] == EXCL_PENDING)
            exclusive_read_state[RID] = EXCL_COMPLETE;
        end else begin
          rd_beats_left[RID] = rd_beats_left[RID] - 1'b1;
        end
      end
    end
  end
endmodule
