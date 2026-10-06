// SPDX-License-Identifier: Apache-2.0
// A task-based AXI4 manager allowing one outstanding operation per direction.
module axi4_caliptra_master #(
  parameter integer ADDR_WIDTH = 19,
  parameter integer DATA_WIDTH = 32,
  parameter integer ID_WIDTH = 8,
  parameter integer USER_WIDTH = 32,
  parameter integer MAX_BEATS = 256,
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
    begin
      burst_is_valid = 0;
      bytes_per_beat = 64'd1 << size;
      beats = {56'd0, len} + 1;
      if ((size <= $clog2(DATA_WIDTH/8)) && ((addr % bytes_per_beat) == 0)) begin
        case (burst)
          2'b00: burst_is_valid = (beats <= 16);
          2'b01: begin
            span = beats * bytes_per_beat;
            burst_is_valid = ((addr[11:0] + span) <= 4096);
          end
          2'b10: begin
            if (beats == 2 || beats == 4 || beats == 8 || beats == 16) begin
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
    WVALID = 0; BREADY = 0; ARID = 0; ARADDR = 0; ARLEN = 0; ARSIZE = 0;
    ARBURST = 0; ARLOCK = 0; ARUSER = 0; ARVALID = 0; RREADY = 0;
    write_response_id = 0; read_response_id = 0;
    if (ADDR_WIDTH < 12 || MAX_BEATS < 1 || MAX_BEATS > 256 || TIMEOUT_CYCLES < 1 ||
        DATA_WIDTH < 8 || (DATA_WIDTH % 8) != 0 ||
        (((DATA_WIDTH/8) & ((DATA_WIDTH/8)-1)) != 0))
      $fatal(1, "Invalid Caliptra AXI master parameters");
  end

  task automatic clear_write_outputs;
    begin
      AWVALID = 0;
      WVALID = 0;
      BREADY = 0;
    end
  endtask

  task automatic clear_read_outputs;
    begin
      ARVALID = 0;
      RREADY = 0;
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
    reg aw_done, w_done, aw_taken, w_taken;
    reg aborted, timed_out, got_response;
    begin
      success = 0;
      response = 0;
      response_user = 0;
      write_response_id = 0;
      aborted = 0;
      timed_out = 0;
      got_response = 0;
      if (poisoned || write_busy || (({1'b0, len} + 1) > MAX_BEATS) ||
          !burst_is_valid(addr, len, size, burst)) begin
        if (({1'b0, len} + 1) > MAX_BEATS)
          $display("AXI master burst length exceeds MAX_BEATS");
        else if (!burst_is_valid(addr, len, size, burst))
          $display("AXI master rejected burst outside the Caliptra profile");
      end else begin
        write_busy = 1;
        aw_done = 0;
        w_done = 0;
        beat = 0;
        cycles = 0;
        @(negedge ACLK);
        if (!ARESETn) begin clear_write_outputs(); poisoned = 0; aborted = 1; end
        else begin
          AWID = id; AWADDR = addr; AWLEN = len; AWSIZE = size;
          AWBURST = burst; AWLOCK = lock; AWUSER = addr_user; AWVALID = 1;
          WDATA = write_data[0 +: DATA_WIDTH];
          WSTRB = write_strb[0 +: DATA_WIDTH/8];
          WUSER = write_user[0 +: USER_WIDTH];
          WLAST = (len == 0); WVALID = 1;
        end

        while ((!aw_done || !w_done) && !aborted && !timed_out) begin
          aw_taken = 0;
          w_taken = 0;
          @(posedge ACLK);
          if (!ARESETn) aborted = 1;
          else begin
            if (AWVALID && AWREADY) aw_taken = 1;
            if (WVALID && WREADY) w_taken = 1;
          end
          cycles = cycles + 1;
          @(negedge ACLK);
          if (aborted || !ARESETn) begin
            clear_write_outputs();
            poisoned = 0;
            aborted = 1;
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
            if ((!aw_done || !w_done) && cycles >= TIMEOUT_CYCLES) begin
              timed_out = 1;
              poisoned = 1;
              $display("AXI master write request timeout; reset required before reuse");
            end
          end
        end

        if (!aborted && !timed_out) begin
          cycles = 0;
          @(negedge ACLK); BREADY = 1;
          while (!got_response && !aborted && !timed_out) begin
            @(posedge ACLK);
            if (!ARESETn) aborted = 1;
            else if (BVALID && BREADY) begin
              got_response = 1;
              write_response_id = BID;
              response = BRESP;
              response_user = BUSER;
              if (BID !== id) begin
                success = 0;
                poisoned = 1;
                $display("AXI master write response ID mismatch");
              end else begin
                case (BRESP)
                  2'b00, 2'b01: success = 1;
                  default: success = 0;
                endcase
              end
            end
            cycles = cycles + 1;
            @(negedge ACLK);
            if (aborted || !ARESETn) begin
              clear_write_outputs(); poisoned = 0; aborted = 1;
            end else if (got_response) BREADY = 0;
            else if (cycles >= TIMEOUT_CYCLES) begin
              BREADY = 0; timed_out = 1; poisoned = 1;
              $display("AXI master write response timeout; reset required before reuse");
            end
          end
        end
        write_busy = 0;
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
    reg taken, aborted, timed_out, got_beat, beat_ok, all_responses_ok;
    begin
      success = 0;
      read_data = 0;
      read_user = 0;
      read_response = 0;
      response_user = 0;
      read_response_id = 0;
      aborted = 0;
      timed_out = 0;
      all_responses_ok = 1;
      if (poisoned || read_busy || (({1'b0, len} + 1) > MAX_BEATS) ||
          !burst_is_valid(addr, len, size, burst)) begin
        if (({1'b0, len} + 1) > MAX_BEATS)
          $display("AXI master burst length exceeds MAX_BEATS");
        else if (!burst_is_valid(addr, len, size, burst))
          $display("AXI master rejected burst outside the Caliptra profile");
      end else begin
        read_busy = 1;
        cycles = 0;
        @(negedge ACLK);
        if (!ARESETn) begin clear_read_outputs(); poisoned = 0; aborted = 1; end
        else begin
          ARID = id; ARADDR = addr; ARLEN = len; ARSIZE = size;
          ARBURST = burst; ARLOCK = lock; ARUSER = addr_user; ARVALID = 1;
          RREADY = 0;
        end

        taken = 0;
        while (!taken && !aborted && !timed_out) begin
          @(posedge ACLK);
          if (!ARESETn) aborted = 1;
          else if (ARVALID && ARREADY) taken = 1;
          cycles = cycles + 1;
          @(negedge ACLK);
          if (aborted || !ARESETn) begin
            clear_read_outputs(); poisoned = 0; aborted = 1;
          end else if (taken) begin ARVALID = 0; RREADY = 1; end
          else if (cycles >= TIMEOUT_CYCLES) begin
            timed_out = 1; poisoned = 1;
            $display("AXI master read address timeout; reset required before reuse");
          end
        end

        for (beat = 0; beat <= len && !aborted && !timed_out; beat = beat + 1) begin
          cycles = 0;
          got_beat = 0;
          beat_ok = 1;
          while (!got_beat && !aborted && !timed_out) begin
            @(posedge ACLK);
            if (!ARESETn) aborted = 1;
            else if (RVALID && RREADY) begin
              got_beat = 1;
              read_response_id = RID;
              read_data[beat*DATA_WIDTH +: DATA_WIDTH] = RDATA;
              read_user[beat*USER_WIDTH +: USER_WIDTH] = RUSER;
              read_response[beat*2 +: 2] = RRESP;
              if (RRESP !== 2'b00 && RRESP !== 2'b01) all_responses_ok = 0;
              if ((RID !== id) || (RLAST !== (beat == len))) beat_ok = 0;
            end
            cycles = cycles + 1;
            @(negedge ACLK);
            if (aborted || !ARESETn) begin
              clear_read_outputs(); poisoned = 0; aborted = 1;
            end else if (got_beat && !beat_ok) begin
              RREADY = 0; poisoned = 1; aborted = 1;
              $display("AXI master read response ID or RLAST mismatch");
            end else if (got_beat && beat == len) begin
              RREADY = 0;
              success = all_responses_ok;
            end else if (cycles >= TIMEOUT_CYCLES && !got_beat) begin
              RREADY = 0; timed_out = 1; poisoned = 1;
              $display("AXI master read data timeout; reset required before reuse");
            end
          end
        end
        if (success) response_user = read_user[0 +: USER_WIDTH];
        read_busy = 0;
      end
    end
  endtask
endmodule
