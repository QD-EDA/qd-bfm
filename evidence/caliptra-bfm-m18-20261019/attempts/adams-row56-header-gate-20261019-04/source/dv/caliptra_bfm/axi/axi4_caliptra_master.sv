// SPDX-License-Identifier: Apache-2.0
// A task-based AXI4 manager with bounded concurrent reads and writes.
module axi4_caliptra_master #(
  parameter integer ADDR_WIDTH = 19,
  parameter integer DATA_WIDTH = 32,
  parameter integer ID_WIDTH = 8,
  parameter integer USER_WIDTH = 32,
  parameter integer MAX_BEATS = 256,
  parameter integer MAX_OUTSTANDING = 4,
  parameter integer TIMEOUT_CYCLES = 1024
) (
  input wire ACLK,
  input wire ARESETn,
  output reg [ID_WIDTH-1:0] AWID,
  output reg [ADDR_WIDTH-1:0] AWADDR,
  output reg [7:0] AWLEN,
  output reg [2:0] AWSIZE,
  output reg [1:0] AWBURST,
  output reg AWLOCK,
  output reg [USER_WIDTH-1:0] AWUSER,
  output reg AWVALID,
  input wire AWREADY,
  output reg [DATA_WIDTH-1:0] WDATA,
  output reg [DATA_WIDTH/8-1:0] WSTRB,
  output reg [USER_WIDTH-1:0] WUSER,
  output reg WLAST,
  output reg WVALID,
  input wire WREADY,
  input wire [ID_WIDTH-1:0] BID,
  input wire [1:0] BRESP,
  input wire [USER_WIDTH-1:0] BUSER,
  input wire BVALID,
  output reg BREADY,
  output reg [ID_WIDTH-1:0] ARID,
  output reg [ADDR_WIDTH-1:0] ARADDR,
  output reg [7:0] ARLEN,
  output reg [2:0] ARSIZE,
  output reg [1:0] ARBURST,
  output reg ARLOCK,
  output reg [USER_WIDTH-1:0] ARUSER,
  output reg ARVALID,
  input wire ARREADY,
  input wire [ID_WIDTH-1:0] RID,
  input wire [DATA_WIDTH-1:0] RDATA,
  input wire [1:0] RRESP,
  input wire [USER_WIDTH-1:0] RUSER,
  input wire RLAST,
  input wire RVALID,
  output reg RREADY,
  output reg [ID_WIDTH-1:0] write_response_id,
  output reg [ID_WIDTH-1:0] read_response_id
);
  reg write_busy = 0;
  reg read_busy = 0;
  wire busy = write_busy || read_busy;
  reg poisoned = 0;
  reg [MAX_OUTSTANDING-1:0] wr_slot_valid = '0;
  reg [MAX_OUTSTANDING-1:0] wr_slot_aw_done = '0;
  reg [MAX_OUTSTANDING-1:0] wr_slot_w_done = '0;
  reg [MAX_OUTSTANDING-1:0] wr_slot_done = '0;
  reg [ID_WIDTH-1:0] wr_id_q [0:MAX_OUTSTANDING-1];
  reg [1:0] wr_response_q [0:MAX_OUTSTANDING-1];
  reg [USER_WIDTH-1:0] wr_user_q [0:MAX_OUTSTANDING-1];
  integer wr_order_q [0:MAX_OUTSTANDING-1];
  integer wr_alloc_ticket = 0;
  integer wr_reserve_ticket = 0;
  integer wr_issue_ticket = 0;
  integer wr_active_count = 0;
  integer wr_drive_slot = -1;
  reg [MAX_OUTSTANDING-1:0] rd_slot_valid = '0;
  reg [MAX_OUTSTANDING-1:0] rd_slot_issued = '0;
  reg [MAX_OUTSTANDING-1:0] rd_slot_done = '0;
  reg [MAX_OUTSTANDING-1:0] rd_slot_success = '0;
  reg [7:0] rd_len_q [0:MAX_OUTSTANDING-1];
  reg [ID_WIDTH-1:0] rd_id_q [0:MAX_OUTSTANDING-1];
  reg [DATA_WIDTH*MAX_BEATS-1:0] rd_data_q [0:MAX_OUTSTANDING-1];
  reg [USER_WIDTH*MAX_BEATS-1:0] rd_user_data_q [0:MAX_OUTSTANDING-1];
  reg [2*MAX_BEATS-1:0] rd_response_q [0:MAX_OUTSTANDING-1];
  integer rd_order_q [0:MAX_OUTSTANDING-1];
  integer rd_received_q [0:MAX_OUTSTANDING-1];
  integer rd_alloc_ticket = 0;
  integer rd_reserve_ticket = 0;
  integer rd_issue_ticket = 0;
  integer rd_active_count = 0;
  integer rready_index;
  integer rscan_index;
  integer rchosen_slot;
  integer rchosen_order;
  integer rbeat_index;
  integer bready_index;
  integer bscan_index;
  integer bchosen_slot;
  integer bchosen_order;

  // Tasks release completed slots on negedge; keep READY through the response handshake edge.
  always @* begin
    BREADY = 1'b0;
    if (ARESETn && !poisoned)
      for (bready_index = 0; bready_index < MAX_OUTSTANDING; bready_index = bready_index + 1)
        if (wr_slot_valid[bready_index] &&
            (wr_slot_aw_done[bready_index] ||
             ((wr_drive_slot == bready_index) && AWVALID && AWREADY)) &&
            (wr_slot_w_done[bready_index] ||
             ((wr_drive_slot == bready_index) && WVALID && WREADY && WLAST)))
          BREADY = 1'b1;
  end

  always @* begin
    RREADY = 1'b0;
    if (ARESETn && !poisoned)
      for (rready_index = 0; rready_index < MAX_OUTSTANDING; rready_index = rready_index + 1)
        if (rd_slot_valid[rready_index] && rd_slot_issued[rready_index])
          RREADY = 1'b1;
  end

  // ponytail: linear RID lookup is simple at bounded depth; index by ID if depth grows.
  always @(posedge ACLK) begin
    if (ARESETn && RREADY && (RVALID !== 1'b0) && (RVALID !== 1'b1)) begin
      poisoned = 1'b1;
      $display("AXI master read response has unknown RVALID");
    end else if (ARESETn && RVALID && RREADY) begin
      rchosen_slot = -1;
      rchosen_order = 32'h7fffffff;
      for (rscan_index = 0; rscan_index < MAX_OUTSTANDING; rscan_index = rscan_index + 1) begin
        if (rd_slot_valid[rscan_index] && rd_slot_issued[rscan_index] && !rd_slot_done[rscan_index] &&
            rd_id_q[rscan_index] == RID && rd_order_q[rscan_index] < rchosen_order) begin
          rchosen_slot = rscan_index;
          rchosen_order = rd_order_q[rscan_index];
        end
      end
      read_response_id = RID;
      if (rchosen_slot < 0) begin
        poisoned = 1'b1;
        $display("AXI master read response has no outstanding RID");
      end else begin
        rbeat_index = rd_received_q[rchosen_slot];
        if (rbeat_index > rd_len_q[rchosen_slot]) begin
          rd_slot_done[rchosen_slot] = 1'b1;
          rd_slot_success[rchosen_slot] = 1'b0;
          poisoned = 1'b1;
          $display("AXI master received too many read beats");
        end else begin
          rd_data_q[rchosen_slot][rbeat_index*DATA_WIDTH +: DATA_WIDTH] = RDATA;
          rd_user_data_q[rchosen_slot][rbeat_index*USER_WIDTH +: USER_WIDTH] = RUSER;
          rd_response_q[rchosen_slot][rbeat_index*2 +: 2] = RRESP;
          if ((^RRESP) === 1'bx) begin
            rd_slot_success[rchosen_slot] = 1'b0;
            poisoned = 1'b1;
            $display("AXI master read response has unknown RRESP");
          end else if (RRESP !== 2'b00 && RRESP !== 2'b01)
            rd_slot_success[rchosen_slot] = 1'b0;
          if (RLAST !== (rbeat_index == rd_len_q[rchosen_slot])) begin
            rd_slot_done[rchosen_slot] = 1'b1;
            rd_slot_success[rchosen_slot] = 1'b0;
            poisoned = 1'b1;
            $display("AXI master read response ID or RLAST mismatch");
          end else if (rbeat_index == rd_len_q[rchosen_slot]) begin
            rd_slot_done[rchosen_slot] = 1'b1;
          end else begin
            rd_received_q[rchosen_slot] = rbeat_index + 1;
          end
        end
      end
    end
  end

  // ponytail: linear BID lookup is simple at bounded depth; index by ID if depth grows.
  always @(posedge ACLK) begin
    if (ARESETn) begin
      if (BREADY && (BVALID !== 1'b0) && (BVALID !== 1'b1)) begin
        poisoned = 1'b1;
        $display("AXI master write response has unknown BVALID");
      end
      if (wr_drive_slot >= 0) begin
        if (wr_slot_valid[wr_drive_slot]) begin
          if (AWVALID && AWREADY) wr_slot_aw_done[wr_drive_slot] = 1'b1;
          if (WVALID && WREADY && WLAST) wr_slot_w_done[wr_drive_slot] = 1'b1;
        end
      end
      if (BVALID && BREADY) begin
        bchosen_slot = -1;
        bchosen_order = 32'h7fffffff;
        for (bscan_index = 0; bscan_index < MAX_OUTSTANDING; bscan_index = bscan_index + 1) begin
          if (wr_slot_valid[bscan_index] && !wr_slot_done[bscan_index] &&
              wr_slot_aw_done[bscan_index] && wr_slot_w_done[bscan_index] &&
              wr_id_q[bscan_index] == BID && wr_order_q[bscan_index] < bchosen_order) begin
            bchosen_slot = bscan_index;
            bchosen_order = wr_order_q[bscan_index];
          end
        end
        write_response_id = BID;
        if (bchosen_slot < 0) begin
          poisoned = 1'b1;
          $display("AXI master write response has no outstanding BID");
        end else begin
          wr_response_q[bchosen_slot] = BRESP;
          wr_user_q[bchosen_slot] = BUSER;
          wr_slot_done[bchosen_slot] = 1'b1;
          if ((^BRESP) === 1'bx) begin
            poisoned = 1'b1;
            $display("AXI master write response has unknown BRESP");
          end
        end
      end
    end
  end

  function automatic burst_is_valid(
    input [ADDR_WIDTH-1:0] addr,
    input [7:0] len,
    input [2:0] size,
    input [1:0] burst
  );
    reg [63:0] bytes_per_beat;
    reg [63:0] beats;
    reg [63:0] span;
    reg [63:0] wrap_base;
    reg [63:0] aligned_addr;
    begin
      burst_is_valid = 0;
      bytes_per_beat = 64'd1 << size;
      beats = {56'd0, len} + 1;
      if (size <= $clog2(DATA_WIDTH/8)) begin
        case (burst)
          2'b00: burst_is_valid = (beats <= 16);
          2'b01: begin
            span = beats * bytes_per_beat;
            aligned_addr = (addr / bytes_per_beat) * bytes_per_beat;
            burst_is_valid = (((aligned_addr % 4096) + span) <= 4096);
          end
          2'b10: begin
            if (((addr % bytes_per_beat) == 0) &&
                (beats == 2 || beats == 4 || beats == 8 || beats == 16)) begin
              span = beats * bytes_per_beat;
              wrap_base = (addr / span) * span;
              burst_is_valid = (((wrap_base % 4096) + span) <= 4096);
            end
          end
          default: burst_is_valid = 0;
        endcase
      end
    end
  endfunction

  initial begin
    AWID = 0; AWADDR = 0; AWLEN = 0; AWSIZE = 0; AWBURST = 0; AWLOCK = 0;
    AWUSER = 0; AWVALID = 0; WDATA = 0; WSTRB = 0; WUSER = 0; WLAST = 0;
    WVALID = 0; ARID = 0; ARADDR = 0; ARLEN = 0; ARSIZE = 0;
    ARBURST = 0; ARLOCK = 0; ARUSER = 0; ARVALID = 0;
    write_response_id = 0; read_response_id = 0;
    if (ADDR_WIDTH < 12 || MAX_BEATS < 1 || MAX_BEATS > 256 || MAX_OUTSTANDING < 1 || TIMEOUT_CYCLES < 1 ||
        DATA_WIDTH < 8 || (DATA_WIDTH % 8) != 0 ||
        (((DATA_WIDTH/8) & ((DATA_WIDTH/8)-1)) != 0))
      $fatal(1, "Invalid Caliptra AXI master parameters");
  end

  task automatic clear_write_outputs;
    begin
      AWVALID = 0;
      WVALID = 0;
      WLAST = 0;
    end
  endtask

  task automatic clear_read_outputs;
    begin
      ARVALID = 0;
    end
  endtask

  task automatic clear_outputs;
    begin
      clear_write_outputs();
      clear_read_outputs();
    end
  endtask

  // Call only while ARESETn is low. Reset is the only recovery from a timeout
  // or an unexpected response ID/last marker.
  task automatic reset_master;
    begin
      if (ARESETn) $fatal(1, "AXI master reset_master requires ARESETn low");
      if (busy) $fatal(1, "AXI master cannot be reset while a task is active");
      clear_outputs();
      poisoned = 0;
      wr_alloc_ticket = 0;
      wr_reserve_ticket = 0;
      wr_issue_ticket = 0;
      wr_active_count = 0;
      wr_drive_slot = -1;
      wr_slot_valid = '0;
      wr_slot_aw_done = '0;
      wr_slot_w_done = '0;
      wr_slot_done = '0;
      write_busy = 0;
      write_response_id = 0;
      rd_alloc_ticket = 0;
      rd_reserve_ticket = 0;
      rd_issue_ticket = 0;
      rd_active_count = 0;
      rd_slot_valid = '0;
      rd_slot_issued = '0;
      rd_slot_done = '0;
      rd_slot_success = '0;
      read_busy = 0;
    end
  endtask

  // Packed beat arrays use beat zero in the least-significant slice.
  task automatic write_burst(
    input [ADDR_WIDTH-1:0] addr,
    input [7:0] len,
    input [2:0] size,
    input [1:0] burst,
    input [ID_WIDTH-1:0] id,
    input [USER_WIDTH-1:0] addr_user,
    input lock,
    input [DATA_WIDTH*MAX_BEATS-1:0] write_data,
    input [(DATA_WIDTH/8)*MAX_BEATS-1:0] write_strb,
    input [USER_WIDTH*MAX_BEATS-1:0] write_user,
    output reg success,
    output reg [1:0] response,
    output reg [USER_WIDTH-1:0] response_user
  );
    integer beat;
    integer cycles;
    integer ticket;
    integer slot;
    reg aw_done, w_done, aw_taken, w_taken;
    reg aborted, timed_out, owns_channels, allocated;
    begin
      success = 0;
      response = 0;
      response_user = 0;
      aborted = 0;
      timed_out = 0;
      owns_channels = 0;
      allocated = 0;
      ticket = -1;
      slot = -1;
      if (poisoned || (({1'b0, len} + 1) > MAX_BEATS) ||
          !burst_is_valid(addr, len, size, burst) ||
          (lock && ((addr % (64'd1 << size)) != 0))) begin
        if (({1'b0, len} + 1) > MAX_BEATS)
          $display("AXI master burst length exceeds MAX_BEATS");
        else if (!burst_is_valid(addr, len, size, burst))
          $display("AXI master rejected burst outside the Caliptra profile");
      end else begin
        ticket = wr_alloc_ticket;
        wr_alloc_ticket = wr_alloc_ticket + 1;
        slot = ticket % MAX_OUTSTANDING;
        cycles = 0;
        while (((wr_reserve_ticket != ticket) || wr_slot_valid[slot]) &&
               !aborted && !timed_out && !poisoned) begin
          @(posedge ACLK);
          if (!ARESETn) aborted = 1;
          else if (poisoned) aborted = 1;
          cycles = cycles + 1;
          if (cycles >= TIMEOUT_CYCLES && !aborted && !poisoned) begin
            timed_out = 1;
            poisoned = 1;
            $display("AXI master write slot timeout; reset required before reuse");
          end
        end

        if (!aborted && !timed_out && !poisoned) begin
          allocated = 1;
          wr_slot_valid[slot] = 1;
          wr_slot_aw_done[slot] = 0;
          wr_slot_w_done[slot] = 0;
          wr_slot_done[slot] = 0;
          wr_id_q[slot] = id;
          wr_response_q[slot] = 0;
          wr_user_q[slot] = 0;
          wr_order_q[slot] = ticket;
          wr_reserve_ticket = wr_reserve_ticket + 1;
          wr_active_count = wr_active_count + 1;
          write_busy = 1;

          cycles = 0;
          while ((wr_issue_ticket != ticket) && !aborted && !timed_out && !poisoned) begin
            @(posedge ACLK);
            if (!ARESETn) aborted = 1;
            else if (poisoned) aborted = 1;
            cycles = cycles + 1;
            if (cycles >= TIMEOUT_CYCLES && !aborted && !poisoned) begin
              timed_out = 1;
              poisoned = 1;
              $display("AXI master write issue queue timeout; reset required before reuse");
            end
          end

          if (!aborted && !timed_out && !poisoned) begin
            @(negedge ACLK);
            if (!ARESETn) aborted = 1;
            else if (poisoned) aborted = 1;
            else begin
              wr_drive_slot = slot;
              AWID = id; AWADDR = addr; AWLEN = len; AWSIZE = size;
              AWBURST = burst; AWLOCK = lock; AWUSER = addr_user; AWVALID = 1;
              WDATA = write_data[0 +: DATA_WIDTH];
              WSTRB = write_strb[0 +: DATA_WIDTH/8];
              WUSER = write_user[0 +: USER_WIDTH];
              WLAST = (len == 0); WVALID = 1;
              owns_channels = 1;
            end
          end

          aw_done = 0;
          w_done = 0;
          beat = 0;
          cycles = 0;
          while ((!aw_done || !w_done) && owns_channels &&
                 !aborted && !timed_out && !poisoned) begin
            aw_taken = 0;
            w_taken = 0;
            @(posedge ACLK);
            if (!ARESETn) aborted = 1;
            else if (poisoned) aborted = 1;
            else if ((AWVALID && (AWREADY !== 1'b0) && (AWREADY !== 1'b1)) ||
                     (WVALID && (WREADY !== 1'b0) && (WREADY !== 1'b1))) begin
              poisoned = 1'b1;
              $display("AXI master write request has unknown AWREADY/WREADY");
            end
            else begin
              if (AWVALID && AWREADY) aw_taken = 1;
              if (WVALID && WREADY) w_taken = 1;
            end
            cycles = cycles + 1;
            @(negedge ACLK);
            if (aborted || !ARESETn || poisoned) begin
              clear_write_outputs();
              wr_drive_slot = -1;
              owns_channels = 0;
              if (!ARESETn) begin poisoned = 0; aborted = 1; end
              else aborted = 1;
            end else begin
              if (aw_taken) begin AWVALID = 0; aw_done = 1; end
              if (w_taken) begin
                if (beat == len) begin WVALID = 0; WLAST = 0; w_done = 1; end
                else begin
                  beat = beat + 1;
                  WDATA = write_data[beat*DATA_WIDTH +: DATA_WIDTH];
                  WSTRB = write_strb[beat*(DATA_WIDTH/8) +: DATA_WIDTH/8];
                  WUSER = write_user[beat*USER_WIDTH +: USER_WIDTH];
                  WLAST = (beat == len);
                end
              end
              if (aw_done && w_done) begin
                wr_issue_ticket = wr_issue_ticket + 1;
                wr_drive_slot = -1;
                owns_channels = 0;
              end else if (cycles >= TIMEOUT_CYCLES) begin
                clear_write_outputs();
                wr_drive_slot = -1;
                owns_channels = 0;
                timed_out = 1;
                poisoned = 1;
                $display("AXI master write request timeout; reset required before reuse");
              end
            end
          end

          cycles = 0;
          while (allocated && !wr_slot_done[slot] && !aborted && !timed_out && !poisoned) begin
            @(negedge ACLK);
            if (!ARESETn) begin
              aborted = 1;
              poisoned = 0;
            end else if (poisoned) aborted = 1;
            else begin
              cycles = cycles + 1;
              if (cycles >= TIMEOUT_CYCLES) begin
                timed_out = 1;
                poisoned = 1;
                $display("AXI master write response timeout; reset required before reuse");
              end
            end
          end
        end

        if (allocated) begin
          response = wr_response_q[slot];
          response_user = wr_user_q[slot];
          if (wr_slot_done[slot]) write_response_id = wr_id_q[slot];
          success = wr_slot_done[slot] &&
                    (response === 2'b00 || response === 2'b01) &&
                    !aborted && !timed_out && !poisoned;
          wr_slot_valid[slot] = 0;
          wr_slot_aw_done[slot] = 0;
          wr_slot_w_done[slot] = 0;
          wr_slot_done[slot] = 0;
          wr_active_count = wr_active_count - 1;
          write_busy = (wr_active_count != 0);
        end
        if (!ARESETn) poisoned = 0;
      end
    end
  endtask

  task automatic read_burst(
    input [ADDR_WIDTH-1:0] addr,
    input [7:0] len,
    input [2:0] size,
    input [1:0] burst,
    input [ID_WIDTH-1:0] id,
    input [USER_WIDTH-1:0] addr_user,
    input lock,
    output reg success,
    output reg [DATA_WIDTH*MAX_BEATS-1:0] read_data,
    output reg [USER_WIDTH*MAX_BEATS-1:0] read_user,
    output reg [2*MAX_BEATS-1:0] read_response,
    output reg [USER_WIDTH-1:0] response_user
  );
    integer beat;
    integer cycles;
    integer ticket;
    integer slot;
    reg taken, aborted, timed_out, owns_ar, allocated;
    begin
      success = 0;
      read_data = 0;
      read_user = 0;
      read_response = 0;
      response_user = 0;
      aborted = 0;
      timed_out = 0;
      owns_ar = 0;
      allocated = 0;
      ticket = -1;
      slot = -1;
      if (poisoned || (({1'b0, len} + 1) > MAX_BEATS) ||
          !burst_is_valid(addr, len, size, burst) ||
          (lock && ((addr % (64'd1 << size)) != 0))) begin
        if (({1'b0, len} + 1) > MAX_BEATS)
          $display("AXI master burst length exceeds MAX_BEATS");
        else if (!burst_is_valid(addr, len, size, burst))
          $display("AXI master rejected burst outside the Caliptra profile");
      end else begin
        ticket = rd_alloc_ticket;
        rd_alloc_ticket = rd_alloc_ticket + 1;
        slot = ticket % MAX_OUTSTANDING;
        cycles = 0;
        while (((rd_reserve_ticket != ticket) || rd_slot_valid[slot]) &&
               !aborted && !timed_out && !poisoned) begin
          @(posedge ACLK);
          if (!ARESETn) aborted = 1;
          else if (poisoned) aborted = 1;
          cycles = cycles + 1;
          if (cycles >= TIMEOUT_CYCLES && !aborted && !poisoned) begin
            timed_out = 1;
            poisoned = 1;
            $display("AXI master read slot timeout; reset required before reuse");
          end
        end

        if (!aborted && !timed_out && !poisoned) begin
          allocated = 1;
          rd_slot_valid[slot] = 1;
          rd_reserve_ticket = rd_reserve_ticket + 1;
          rd_slot_issued[slot] = 0;
          rd_slot_done[slot] = 0;
          rd_slot_success[slot] = 1;
          rd_len_q[slot] = len;
          rd_id_q[slot] = id;
          rd_data_q[slot] = '0;
          rd_user_data_q[slot] = '0;
          rd_response_q[slot] = '0;
          rd_order_q[slot] = ticket;
          rd_received_q[slot] = 0;
          rd_active_count = rd_active_count + 1;
          read_busy = 1;

          cycles = 0;
          while ((rd_issue_ticket != ticket) && !aborted && !timed_out && !poisoned) begin
            @(posedge ACLK);
            if (!ARESETn) aborted = 1;
            else if (poisoned) aborted = 1;
            cycles = cycles + 1;
            if (cycles >= TIMEOUT_CYCLES && !aborted && !poisoned) begin
              timed_out = 1;
              poisoned = 1;
              $display("AXI master read issue queue timeout; reset required before reuse");
            end
          end

          if (!aborted && !timed_out && !poisoned) begin
            @(negedge ACLK);
            if (!ARESETn) aborted = 1;
            else if (poisoned) aborted = 1;
            else begin
              ARID = id; ARADDR = addr; ARLEN = len; ARSIZE = size;
              ARBURST = burst; ARLOCK = lock; ARUSER = addr_user; ARVALID = 1;
              rd_slot_issued[slot] = 1;
              owns_ar = 1;
            end
          end

          taken = 0;
          cycles = 0;
          while (owns_ar && !taken && !aborted && !timed_out && !poisoned) begin
            @(posedge ACLK);
            if (!ARESETn) aborted = 1;
            else if (poisoned) aborted = 1;
            else if (ARVALID && (ARREADY !== 1'b0) && (ARREADY !== 1'b1)) begin
              poisoned = 1'b1;
              $display("AXI master read request has unknown ARREADY");
            end else if (ARVALID && ARREADY) taken = 1;
            cycles = cycles + 1;
            @(negedge ACLK);
            if (aborted || !ARESETn || poisoned) begin
              ARVALID = 0;
              owns_ar = 0;
              if (!ARESETn) begin poisoned = 0; aborted = 1; end
              else aborted = 1;
            end else if (taken) begin
              ARVALID = 0;
              owns_ar = 0;
              rd_issue_ticket = rd_issue_ticket + 1;
            end else if (cycles >= TIMEOUT_CYCLES) begin
              ARVALID = 0;
              owns_ar = 0;
              timed_out = 1;
              poisoned = 1;
              $display("AXI master read address timeout; reset required before reuse");
            end
          end

          cycles = 0;
          while (allocated && !rd_slot_done[slot] && !aborted && !timed_out && !poisoned) begin
            @(negedge ACLK);
            if (!ARESETn) begin
              aborted = 1;
              poisoned = 0;
            end else if (poisoned) aborted = 1;
            else begin
              cycles = cycles + 1;
              if (cycles >= TIMEOUT_CYCLES) begin
                timed_out = 1;
                poisoned = 1;
                $display("AXI master read data timeout; reset required before reuse");
              end
            end
          end
        end

        if (allocated) begin
          read_data = rd_data_q[slot];
          read_user = rd_user_data_q[slot];
          read_response = rd_response_q[slot];
          response_user = rd_user_data_q[slot][0 +: USER_WIDTH];
          success = rd_slot_done[slot] && rd_slot_success[slot] &&
                    !aborted && !timed_out && !poisoned;
          rd_slot_valid[slot] = 0;
          rd_slot_issued[slot] = 0;
          rd_slot_done[slot] = 0;
          rd_slot_success[slot] = 0;
          rd_active_count = rd_active_count - 1;
          read_busy = (rd_active_count != 0);
        end
        if (!ARESETn) poisoned = 0;
      end
    end
  endtask
endmodule
