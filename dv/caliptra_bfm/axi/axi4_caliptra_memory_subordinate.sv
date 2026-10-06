// SPDX-License-Identifier: Apache-2.0
// Bounded AXI memory target with queued requests in each direction.
module axi4_caliptra_memory_subordinate #(
  parameter integer ADDR_WIDTH = 19,
  parameter integer DATA_WIDTH = 32,
  parameter integer ID_WIDTH = 8,
  parameter integer USER_WIDTH = 32,
  parameter [ADDR_WIDTH-1:0] BASE_ADDR = 0,
  parameter integer MEM_BYTES = 4096,
  parameter integer MAX_OUTSTANDING = 4
) (
  input wire ACLK,
  input wire ARESETn,
  input wire stall_aw,
  input wire stall_w,
  input wire stall_b,
  input wire stall_ar,
  input wire stall_r,
  input wire inject_error,
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
  output reg [ID_WIDTH-1:0] BID,
  output reg [1:0] BRESP,
  output reg [USER_WIDTH-1:0] BUSER,
  output reg BVALID,
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
  output reg [ID_WIDTH-1:0] RID,
  output reg [DATA_WIDTH-1:0] RDATA,
  output reg [1:0] RRESP,
  output reg [USER_WIDTH-1:0] RUSER,
  output reg RLAST,
  output reg RVALID,
  input wire RREADY
);
  localparam integer DATA_BYTES = DATA_WIDTH / 8;
  localparam integer MEM_WORDS = MEM_BYTES / DATA_BYTES;
  localparam integer EXCLUSIVE_ID_COUNT = (1 << ID_WIDTH);
  // ram[word][byte] matches Caliptra's firmware preload hierarchy.
  reg [DATA_BYTES-1:0][7:0] ram [0:MEM_WORDS-1];
  wire stall_aw_active = (stall_aw === 1'b1);
  wire stall_w_active = (stall_w === 1'b1);
  wire stall_b_active = (stall_b === 1'b1);
  wire stall_ar_active = (stall_ar === 1'b1);
  wire stall_r_active = (stall_r === 1'b1);
  wire inject_error_active = (inject_error === 1'b1);
  wire aw_fire = AWVALID && AWREADY;
  wire w_fire = WVALID && WREADY;
  wire w_last_fire = w_fire && WLAST;
  wire b_fire = BVALID && BREADY;
  wire ar_fire = ARVALID && ARREADY;
  wire r_last_fire = RVALID && RREADY && RLAST;

  reg [ADDR_WIDTH-1:0] wr_addr_q [0:MAX_OUTSTANDING-1];
  reg [7:0] wr_len_q [0:MAX_OUTSTANDING-1];
  reg [7:0] wr_beat_q [0:MAX_OUTSTANDING-1];
  reg [2:0] wr_size_q [0:MAX_OUTSTANDING-1];
  reg [1:0] wr_burst_q [0:MAX_OUTSTANDING-1];
  reg [ID_WIDTH-1:0] wr_id_q [0:MAX_OUTSTANDING-1];
  reg [USER_WIDTH-1:0] wr_user_q [0:MAX_OUTSTANDING-1];
  reg wr_error_q [0:MAX_OUTSTANDING-1];
  reg wr_lock_q [0:MAX_OUTSTANDING-1];
  reg wr_exclusive_success_q [0:MAX_OUTSTANDING-1];
  integer wr_head, wr_tail, wr_count, wr_outstanding;

  reg exclusive_valid [0:EXCLUSIVE_ID_COUNT-1];
  reg [ADDR_WIDTH-1:0] exclusive_addr [0:EXCLUSIVE_ID_COUNT-1];
  reg [7:0] exclusive_len [0:EXCLUSIVE_ID_COUNT-1];
  reg [2:0] exclusive_size [0:EXCLUSIVE_ID_COUNT-1];
  reg [1:0] exclusive_burst [0:EXCLUSIVE_ID_COUNT-1];
  reg exclusive_write_active;

  reg [ID_WIDTH-1:0] b_id_q [0:MAX_OUTSTANDING-1];
  reg [1:0] b_resp_q [0:MAX_OUTSTANDING-1];
  reg [USER_WIDTH-1:0] b_user_q [0:MAX_OUTSTANDING-1];
  integer b_head, b_tail, b_count;

  reg [ADDR_WIDTH-1:0] rd_addr_q [0:MAX_OUTSTANDING-1];
  reg [7:0] rd_len_q [0:MAX_OUTSTANDING-1];
  reg [7:0] rd_beat_q [0:MAX_OUTSTANDING-1];
  reg [2:0] rd_size_q [0:MAX_OUTSTANDING-1];
  reg [1:0] rd_burst_q [0:MAX_OUTSTANDING-1];
  reg [ID_WIDTH-1:0] rd_id_q [0:MAX_OUTSTANDING-1];
  reg [USER_WIDTH-1:0] rd_user_q [0:MAX_OUTSTANDING-1];
  reg rd_request_bad_q [0:MAX_OUTSTANDING-1];
  reg rd_exclusive_q [0:MAX_OUTSTANDING-1];
  integer rd_head, rd_tail, rd_count;

  integer word_index;
  integer lane_index;
  integer init_word;
  integer exclusive_index;
  reg [ADDR_WIDTH-1:0] aligned_addr;
  reg [ADDR_WIDTH-1:0] byte_addr;
  reg beat_error;

  assign AWREADY = ARESETn && !stall_aw_active &&
                   (wr_outstanding < MAX_OUTSTANDING) && !exclusive_write_active &&
                   ((AWLOCK !== 1'b1) || (wr_outstanding == 0));
  assign WREADY  = ARESETn && !stall_w_active && (wr_count != 0);
  assign ARREADY = ARESETn && !stall_ar_active && (rd_count < MAX_OUTSTANDING) &&
                   ((ARLOCK !== 1'b1) || (wr_outstanding == 0));

  function automatic in_range(input [ADDR_WIDTH-1:0] addr);
    reg [63:0] addr64;
    reg [63:0] base64;
    begin
      addr64 = addr;
      base64 = BASE_ADDR;
      in_range = (addr64 >= base64) && (addr64 < (base64 + MEM_BYTES));
    end
  endfunction

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
      if ((size <= $clog2(DATA_BYTES)) && ((addr % bytes_per_beat) == 0)) begin
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

  function automatic [ADDR_WIDTH-1:0] increment_addr(
    input [ADDR_WIDTH-1:0] addr,
    input [7:0] len,
    input [2:0] size,
    input [1:0] burst
  );
    reg [63:0] bytes_per_beat;
    reg [63:0] span;
    reg [63:0] wrap_base;
    reg [63:0] candidate;
    begin
      bytes_per_beat = 64'd1 << size;
      candidate = addr;
      case (burst)
        2'b00: candidate = addr;
        2'b01: candidate = addr + bytes_per_beat;
        2'b10: begin
          span = ({56'd0, len} + 1) * bytes_per_beat;
          wrap_base = (addr / span) * span;
          candidate = addr + bytes_per_beat;
          if (candidate >= (wrap_base + span)) candidate = wrap_base;
        end
        default: candidate = addr;
      endcase
      increment_addr = candidate[ADDR_WIDTH-1:0];
    end
  endfunction

  function automatic burst_fits_memory(
    input [ADDR_WIDTH-1:0] addr,
    input [7:0] len,
    input [2:0] size,
    input [1:0] burst
  );
    reg [ADDR_WIDTH-1:0] current_addr;
    reg [63:0] current64;
    reg [63:0] limit64;
    reg [63:0] transfer_bytes;
    integer beat;
    begin
      burst_fits_memory = 1;
      current_addr = addr;
      limit64 = BASE_ADDR + MEM_BYTES;
      transfer_bytes = 64'd1 << size;
      for (beat = 0; beat <= len; beat = beat + 1) begin
        current64 = current_addr;
        if ((current64 < BASE_ADDR) || ((current64 + transfer_bytes) > limit64))
          burst_fits_memory = 0;
        current_addr = increment_addr(current_addr, len, size, burst);
      end
    end
  endfunction

  function automatic exclusive_is_valid(
    input [ADDR_WIDTH-1:0] addr,
    input [7:0] len,
    input [2:0] size,
    input [1:0] burst
  );
    reg [63:0] beat_bytes;
    reg [63:0] transfer_bytes;
    begin
      beat_bytes = 64'd1 << size;
      transfer_bytes = ({56'd0, len} + 1) * beat_bytes;
      exclusive_is_valid = (len < 16) && (transfer_bytes <= 128) &&
                           ((transfer_bytes & (transfer_bytes - 1)) == 0) &&
                           ((addr % transfer_bytes) == 0) &&
                           burst_is_valid(addr, len, size, burst);
    end
  endfunction

  function automatic exclusive_contains_byte(
    input [ADDR_WIDTH-1:0] addr,
    input [7:0] len,
    input [2:0] size,
    input [1:0] burst,
    input [ADDR_WIDTH-1:0] byte_addr
  );
    reg [ADDR_WIDTH-1:0] beat_addr;
    reg [63:0] beat_start;
    reg [63:0] target;
    reg [63:0] beat_bytes;
    integer beat;
    begin
      exclusive_contains_byte = 1'b0;
      beat_addr = addr;
      beat_bytes = 64'd1 << size;
      target = byte_addr;
      for (beat = 0; beat <= len; beat = beat + 1) begin
        beat_start = beat_addr;
        if ((target >= beat_start) && (target < (beat_start + beat_bytes)))
          exclusive_contains_byte = 1'b1;
        beat_addr = increment_addr(beat_addr, len, size, burst);
      end
    end
  endfunction

  function automatic [DATA_WIDTH-1:0] word_at(input integer index);
    integer lane;
    begin
      word_at = 0;
      if (index >= 0 && index < MEM_WORDS)
        for (lane = 0; lane < DATA_BYTES; lane = lane + 1)
          word_at[8*lane +: 8] = ram[index][lane];
    end
  endfunction

  function automatic [DATA_WIDTH-1:0] read_word(input [ADDR_WIDTH-1:0] addr);
    reg [63:0] addr64;
    reg [63:0] base64;
    reg [63:0] aligned64;
    integer index;
    begin
      read_word = 0;
      addr64 = addr;
      base64 = BASE_ADDR;
      aligned64 = (addr64 / DATA_BYTES) * DATA_BYTES;
      index = (aligned64 - base64) / DATA_BYTES;
      if (in_range(addr) && index >= 0 && index < MEM_WORDS)
        read_word = word_at(index);
    end
  endfunction

  initial begin
    if (ADDR_WIDTH < 12 || DATA_WIDTH < 8 || (DATA_WIDTH % 8) != 0 ||
        (DATA_BYTES & (DATA_BYTES - 1)) != 0 || MEM_BYTES < DATA_BYTES ||
        (MEM_BYTES % DATA_BYTES) != 0 || (BASE_ADDR % DATA_BYTES) != 0 ||
        MAX_OUTSTANDING < 1 || ID_WIDTH < 1 || ID_WIDTH > 8)
      $fatal(1, "Invalid Caliptra AXI memory subordinate parameters");
    for (init_word = 0; init_word < MEM_WORDS; init_word = init_word + 1)
      ram[init_word] = 0;
  end

  always @(posedge ACLK) begin
    if (!ARESETn) begin
      wr_head <= 0; wr_tail <= 0; wr_count <= 0; wr_outstanding <= 0;
      b_head <= 0; b_tail <= 0; b_count <= 0;
      rd_head <= 0; rd_tail <= 0; rd_count <= 0;
      exclusive_write_active <= 0;
      for (exclusive_index = 0; exclusive_index < EXCLUSIVE_ID_COUNT; exclusive_index = exclusive_index + 1)
        exclusive_valid[exclusive_index] <= 0;
      BID <= 0; BRESP <= 0; BUSER <= 0;
      BVALID <= 0;
      RVALID <= 0; RID <= 0; RDATA <= 0; RRESP <= 0; RUSER <= 0; RLAST <= 0;
    end else begin
      if (aw_fire) begin
        wr_addr_q[wr_tail] <= AWADDR;
        wr_len_q[wr_tail] <= AWLEN;
        wr_beat_q[wr_tail] <= 0;
        wr_size_q[wr_tail] <= AWSIZE;
        wr_burst_q[wr_tail] <= AWBURST;
        wr_id_q[wr_tail] <= AWID;
        wr_user_q[wr_tail] <= AWUSER;
        wr_lock_q[wr_tail] <= (AWLOCK === 1'b1);
        wr_error_q[wr_tail] <= !burst_is_valid(AWADDR, AWLEN, AWSIZE, AWBURST) ||
                               !burst_fits_memory(AWADDR, AWLEN, AWSIZE, AWBURST) ||
                               ((AWLOCK === 1'b1) &&
                                !exclusive_is_valid(AWADDR, AWLEN, AWSIZE, AWBURST)) ||
                               ((AWLOCK !== 1'b0) && (AWLOCK !== 1'b1));
        wr_exclusive_success_q[wr_tail] <= 0;
        if ((AWLOCK === 1'b1) && ((^AWID) !== 1'bx)) begin
          wr_exclusive_success_q[wr_tail] <= exclusive_valid[AWID] &&
            (exclusive_addr[AWID] == AWADDR) && (exclusive_len[AWID] == AWLEN) &&
            (exclusive_size[AWID] == AWSIZE) && (exclusive_burst[AWID] == AWBURST) &&
            burst_is_valid(AWADDR, AWLEN, AWSIZE, AWBURST) &&
            burst_fits_memory(AWADDR, AWLEN, AWSIZE, AWBURST) &&
            exclusive_is_valid(AWADDR, AWLEN, AWSIZE, AWBURST);
          exclusive_valid[AWID] <= 0;
          exclusive_write_active <= 1;
        end
        wr_tail <= (wr_tail == MAX_OUTSTANDING - 1) ? 0 : wr_tail + 1;
      end

      if (w_fire) begin
        if (WLAST !== (wr_beat_q[wr_head] == wr_len_q[wr_head]))
          $fatal(1, "AXI memory subordinate received WLAST inconsistent with AWLEN");
        beat_error = !in_range(wr_addr_q[wr_head]);
        aligned_addr = (wr_addr_q[wr_head] / DATA_BYTES) * DATA_BYTES;
        for (lane_index = 0; lane_index < DATA_BYTES; lane_index = lane_index + 1) begin
          if (WSTRB[lane_index]) begin
            byte_addr = aligned_addr + lane_index;
            if (wr_error_q[wr_head] || !in_range(byte_addr)) beat_error = 1;
            else if (!wr_lock_q[wr_head] || wr_exclusive_success_q[wr_head]) begin
              word_index = (byte_addr - BASE_ADDR) / DATA_BYTES;
              ram[word_index][lane_index] <= WDATA[8*lane_index +: 8];
              for (exclusive_index = 0; exclusive_index < EXCLUSIVE_ID_COUNT; exclusive_index = exclusive_index + 1) begin
                if (exclusive_valid[exclusive_index] &&
                    exclusive_contains_byte(exclusive_addr[exclusive_index],
                                            exclusive_len[exclusive_index],
                                            exclusive_size[exclusive_index],
                                            exclusive_burst[exclusive_index], byte_addr))
                  exclusive_valid[exclusive_index] <= 0;
              end
            end
          end
        end
        if (WLAST) begin
          b_id_q[b_tail] <= wr_id_q[wr_head];
          b_resp_q[b_tail] <= (wr_error_q[wr_head] || beat_error) ? 2'b11 :
                              (inject_error_active ? 2'b10 :
                               (wr_lock_q[wr_head] && wr_exclusive_success_q[wr_head]) ? 2'b01 : 2'b00);
          b_user_q[b_tail] <= wr_user_q[wr_head];
          b_tail <= (b_tail == MAX_OUTSTANDING - 1) ? 0 : b_tail + 1;
          wr_head <= (wr_head == MAX_OUTSTANDING - 1) ? 0 : wr_head + 1;
          if (wr_lock_q[wr_head]) exclusive_write_active <= 0;
        end else begin
          wr_error_q[wr_head] <= wr_error_q[wr_head] || beat_error;
          wr_addr_q[wr_head] <= increment_addr(wr_addr_q[wr_head],
                                               wr_len_q[wr_head],
                                               wr_size_q[wr_head],
                                               wr_burst_q[wr_head]);
          wr_beat_q[wr_head] <= wr_beat_q[wr_head] + 1'b1;
        end
      end

      if (b_fire) begin
        BVALID <= 0;
        b_head <= (b_head == MAX_OUTSTANDING - 1) ? 0 : b_head + 1;
      end
      if (!BVALID && (b_count != 0) && !stall_b_active) begin
        BID <= b_id_q[b_head];
        BRESP <= b_resp_q[b_head];
        BUSER <= b_user_q[b_head];
        BVALID <= 1;
      end

      if (aw_fire && !w_last_fire) wr_count <= wr_count + 1;
      else if (!aw_fire && w_last_fire) wr_count <= wr_count - 1;
      if (aw_fire && !b_fire) wr_outstanding <= wr_outstanding + 1;
      else if (!aw_fire && b_fire) wr_outstanding <= wr_outstanding - 1;
      if (w_last_fire && !b_fire) b_count <= b_count + 1;
      else if (!w_last_fire && b_fire) b_count <= b_count - 1;

      if (ar_fire) begin
        rd_request_bad_q[rd_tail] <= !burst_is_valid(ARADDR, ARLEN, ARSIZE, ARBURST) ||
                                     !burst_fits_memory(ARADDR, ARLEN, ARSIZE, ARBURST) ||
                                     ((ARLOCK === 1'b1) &&
                                      !exclusive_is_valid(ARADDR, ARLEN, ARSIZE, ARBURST)) ||
                                     ((ARLOCK !== 1'b0) && (ARLOCK !== 1'b1));
        rd_addr_q[rd_tail] <= ARADDR;
        rd_len_q[rd_tail] <= ARLEN;
        rd_beat_q[rd_tail] <= 0;
        rd_size_q[rd_tail] <= ARSIZE;
        rd_burst_q[rd_tail] <= ARBURST;
        rd_id_q[rd_tail] <= ARID;
        rd_user_q[rd_tail] <= ARUSER;
        rd_exclusive_q[rd_tail] <= (ARLOCK === 1'b1) &&
                                   exclusive_is_valid(ARADDR, ARLEN, ARSIZE, ARBURST) &&
                                   burst_fits_memory(ARADDR, ARLEN, ARSIZE, ARBURST);
        if ((ARLOCK === 1'b1) && ((^ARID) !== 1'bx)) begin
          exclusive_valid[ARID] <= 0;
          if (exclusive_is_valid(ARADDR, ARLEN, ARSIZE, ARBURST) &&
              burst_fits_memory(ARADDR, ARLEN, ARSIZE, ARBURST)) begin
            exclusive_valid[ARID] <= 1;
            exclusive_addr[ARID] <= ARADDR;
            exclusive_len[ARID] <= ARLEN;
            exclusive_size[ARID] <= ARSIZE;
            exclusive_burst[ARID] <= ARBURST;
          end
        end
        rd_tail <= (rd_tail == MAX_OUTSTANDING - 1) ? 0 : rd_tail + 1;
      end

      if (!RVALID && (rd_count != 0) && !stall_r_active) begin
        RID <= rd_id_q[rd_head];
        RDATA <= (rd_request_bad_q[rd_head] || !in_range(rd_addr_q[rd_head])) ?
                 {DATA_WIDTH{1'b0}} : read_word(rd_addr_q[rd_head]);
        RRESP <= (rd_request_bad_q[rd_head] || !in_range(rd_addr_q[rd_head])) ? 2'b11 :
                 (inject_error_active ? 2'b10 : rd_exclusive_q[rd_head] ? 2'b01 : 2'b00);
        RUSER <= rd_user_q[rd_head];
        RLAST <= (rd_beat_q[rd_head] == rd_len_q[rd_head]);
        RVALID <= 1;
      end else if (RVALID && RREADY) begin
        RVALID <= 0;
        if (RLAST) begin
          rd_head <= (rd_head == MAX_OUTSTANDING - 1) ? 0 : rd_head + 1;
        end else begin
          rd_beat_q[rd_head] <= rd_beat_q[rd_head] + 1'b1;
          rd_addr_q[rd_head] <= increment_addr(rd_addr_q[rd_head],
                                               rd_len_q[rd_head],
                                               rd_size_q[rd_head],
                                               rd_burst_q[rd_head]);
        end
      end
      if (ar_fire && !r_last_fire) rd_count <= rd_count + 1;
      else if (!ar_fire && r_last_fire) rd_count <= rd_count - 1;
    end
  end
endmodule
