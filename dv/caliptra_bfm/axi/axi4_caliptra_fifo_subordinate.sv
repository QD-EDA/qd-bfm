// SPDX-License-Identifier: Apache-2.0
// Bounded fixed-burst AXI FIFO endpoint for Caliptra-style stream windows.
module axi4_caliptra_fifo_subordinate #(
  parameter integer ADDR_WIDTH = 48,
  parameter integer DATA_WIDTH = 32,
  parameter integer ID_WIDTH = 8,
  parameter integer USER_WIDTH = 32,
  parameter [ADDR_WIDTH-1:0] BASE_ADDR = 48'h0000_fa57_0000,
  parameter integer FIFO_CAPACITY_BYTES = 65536,
  parameter integer DECODE_LOW_BITS = 18
) (
  input wire ACLK,
  input wire ARESETn,
  input wire fifo_clear,
  input wire auto_push,
  input wire auto_pop,
  input wire stall_aw,
  input wire stall_w,
  input wire stall_b,
  input wire stall_ar,
  input wire stall_r,
  input wire inject_error,
  output wire [31:0] fifo_level,
  output wire fifo_push_event,
  output wire fifo_pop_event,
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
  localparam integer FIFO_DEPTH = FIFO_CAPACITY_BYTES / DATA_BYTES;
  localparam integer PTR_WIDTH = (FIFO_DEPTH <= 1) ? 1 : $clog2(FIFO_DEPTH);
  localparam integer COUNT_WIDTH = (FIFO_DEPTH <= 1) ? 1 : $clog2(FIFO_DEPTH + 1);

  reg [DATA_WIDTH-1:0] fifo_mem [0:FIFO_DEPTH-1];
  reg [PTR_WIDTH-1:0] fifo_read_ptr, fifo_write_ptr;
  reg [COUNT_WIDTH-1:0] fifo_count;
  reg fifo_under_reset;
  reg [11:0] auto_stall_count;
  reg [DATA_WIDTH-1:0] auto_wdata;
  reg auto_wvalid;
  reg auto_rready;

  reg wr_active, wr_bad, b_pending;
  reg [7:0] wr_len, wr_beat;
  reg [ID_WIDTH-1:0] wr_id;
  reg [USER_WIDTH-1:0] wr_user;
  reg [1:0] wr_resp;

  reg rd_active, rd_bad;
  reg [7:0] rd_len, rd_beat;
  reg [ID_WIDTH-1:0] rd_id;
  reg [USER_WIDTH-1:0] rd_user;
  reg [1:0] rd_resp;

  integer init_word;
  wire fifo_clear_active = (fifo_clear === 1'b1);
  wire stall_aw_active = (stall_aw === 1'b1);
  wire stall_w_active = (stall_w === 1'b1);
  wire stall_b_active = (stall_b === 1'b1);
  wire stall_ar_active = (stall_ar === 1'b1);
  wire stall_r_active = (stall_r === 1'b1);
  wire auto_wready = ARESETn && !fifo_under_reset && !fifo_clear_active &&
                      (fifo_count < FIFO_DEPTH);
  wire fifo_axi_push = WVALID && WREADY && !wr_bad;
  wire fifo_push = (auto_wvalid && auto_wready) ||
                   (!auto_wvalid && fifo_axi_push);
  wire fifo_axi_load = !fifo_under_reset && !RVALID && rd_active &&
                       !stall_r_active &&
                       (rd_bad || (!fifo_clear_active && (fifo_count != 0)));
  wire fifo_axi_pop = fifo_axi_load && !rd_bad;
  wire fifo_pop = ARESETn && (fifo_axi_pop ||
                  (!fifo_clear_active && auto_rready && (fifo_count != 0)));

  assign fifo_level = fifo_count;
  assign fifo_push_event = fifo_push;
  assign fifo_pop_event = fifo_pop;
  assign AWREADY = ARESETn && !stall_aw_active && !wr_active &&
                   !b_pending && !BVALID;
  assign WREADY = ARESETn && !fifo_under_reset && !stall_w_active &&
                  wr_active && !b_pending && !BVALID &&
                  (wr_bad || (!fifo_clear_active && (fifo_count < FIFO_DEPTH)));
  assign ARREADY = ARESETn && !stall_ar_active && !rd_active;

  function automatic address_in_decode_region(input [ADDR_WIDTH-1:0] addr);
    reg [63:0] addr64;
    reg [63:0] base64;
    begin
      addr64 = addr;
      base64 = BASE_ADDR;
      address_in_decode_region = (addr64 >> DECODE_LOW_BITS) ==
                                 (base64 >> DECODE_LOW_BITS);
    end
  endfunction

  function automatic stream_request_valid(
    input [ADDR_WIDTH-1:0] addr,
    input [7:0] len,
    input [2:0] size,
    input [1:0] burst
  );
    begin
      if ((^addr === 1'bx) || (^len === 1'bx) ||
          (^size === 1'bx) || (^burst === 1'bx))
        stream_request_valid = 1'b0;
      else
        stream_request_valid = address_in_decode_region(addr) &&
                                ((addr % DATA_BYTES) == 0) &&
                                (size == $clog2(DATA_BYTES)) &&
                                (burst == 2'b00) &&
                                (len <= 8'd15);
    end
  endfunction

  function automatic [PTR_WIDTH-1:0] next_ptr(input [PTR_WIDTH-1:0] ptr);
    begin
      next_ptr = (ptr == FIFO_DEPTH - 1) ? {PTR_WIDTH{1'b0}} : ptr + 1'b1;
    end
  endfunction

  // Integer sampling equivalent to the pinned dist {0..1 :/ 500,
  // 2..7 :/ 75, 8..31 :/ 3, 32..255 :/ 1} group weights.
  function automatic [11:0] choose_auto_stall_count;
    integer draw;
    begin
      draw = $urandom_range(129695, 0);
      if (draw < 56000)
        choose_auto_stall_count = 0;
      else if (draw < 112000)
        choose_auto_stall_count = 1;
      else if (draw < 128800)
        choose_auto_stall_count = 2 + ((draw - 112000) / 2800);
      else if (draw < 129472)
        choose_auto_stall_count = 8 + ((draw - 128800) / 28);
      else
        choose_auto_stall_count = 32 + (draw - 129472);
    end
  endfunction

  initial begin
    auto_stall_count = choose_auto_stall_count();
    fifo_under_reset = 1'b1;
    if (ADDR_WIDTH < 32 || ADDR_WIDTH > 64 || DATA_WIDTH < 8 ||
        (DATA_WIDTH % 8) != 0 ||
        (DATA_BYTES & (DATA_BYTES - 1)) != 0 || FIFO_DEPTH < 1 ||
        DATA_BYTES > 128 ||
        DECODE_LOW_BITS < 0 || DECODE_LOW_BITS >= ADDR_WIDTH ||
        FIFO_CAPACITY_BYTES < DATA_BYTES ||
        (FIFO_CAPACITY_BYTES % DATA_BYTES) != 0 ||
        (BASE_ADDR % DATA_BYTES) != 0)
      $fatal(1, "Invalid Caliptra AXI FIFO subordinate parameters");
    for (init_word = 0; init_word < FIFO_DEPTH; init_word = init_word + 1)
      fifo_mem[init_word] = 0;
  end

  always @(posedge ACLK) begin
    if ((auto_push === 1'b1) || (auto_pop === 1'b1)) begin
      if (auto_stall_count != 0)
        auto_stall_count <= auto_stall_count - 1'b1;
      else
        auto_stall_count <= choose_auto_stall_count();
    end
  end

  always @(posedge ACLK or negedge ARESETn) begin
    if (!ARESETn) begin
      fifo_under_reset <= 1'b1;
      wr_active <= 0;
      wr_bad <= 0;
      b_pending <= 0;
      wr_len <= 0;
      wr_beat <= 0;
      wr_id <= 0;
      wr_user <= 0;
      wr_resp <= 0;
      rd_active <= 0;
      rd_bad <= 0;
      rd_len <= 0;
      rd_beat <= 0;
      rd_id <= 0;
      rd_user <= 0;
      rd_resp <= 0;
      fifo_read_ptr <= 0;
      fifo_write_ptr <= 0;
      fifo_count <= 0;
      auto_wdata <= 0;
      auto_wvalid <= 0;
      auto_rready <= 0;
      BID <= 0;
      BRESP <= 0;
      BUSER <= 0;
      BVALID <= 0;
      RID <= 0;
      RDATA <= 0;
      RRESP <= 0;
      RUSER <= 0;
      RLAST <= 0;
      RVALID <= 0;
    end else begin
      fifo_under_reset <= 1'b0;
      if (fifo_clear_active) begin
        fifo_read_ptr <= 0;
        fifo_write_ptr <= 0;
        fifo_count <= 0;
      end else begin
        case ({fifo_push, fifo_pop})
          2'b10: fifo_count <= fifo_count + 1'b1;
          2'b01: fifo_count <= fifo_count - 1'b1;
          default: fifo_count <= fifo_count;
        endcase
        if (fifo_push) begin
          // Caliptra's pinned FIFO wrapper leaves axi_sub.wstrb unconnected.
          fifo_mem[fifo_write_ptr] <= auto_wvalid ? auto_wdata : WDATA;
          fifo_write_ptr <= next_ptr(fifo_write_ptr);
        end
        if (fifo_pop) fifo_read_ptr <= next_ptr(fifo_read_ptr);
      end

      if (AWVALID && AWREADY) begin
        wr_active <= 1;
        wr_len <= AWLEN;
        wr_beat <= 0;
        wr_id <= AWID;
        wr_user <= AWUSER;
        wr_bad <= !stream_request_valid(AWADDR, AWLEN, AWSIZE, AWBURST) ||
                  (inject_error === 1'b1);
        if (!stream_request_valid(AWADDR, AWLEN, AWSIZE, AWBURST))
          wr_resp <= 2'b11;
        else if (inject_error === 1'b1)
          wr_resp <= 2'b10;
        else
          wr_resp <= 2'b00;
      end

      if (WVALID && WREADY) begin
        if (WLAST !== (wr_beat == wr_len))
          $fatal(1, "AXI FIFO subordinate received WLAST inconsistent with AWLEN");
        if (wr_beat == wr_len) begin
          wr_active <= 0;
          b_pending <= 1;
          BID <= wr_id;
          BRESP <= wr_resp;
          BUSER <= wr_user;
        end else begin
          wr_beat <= wr_beat + 1'b1;
        end
      end

      if (BVALID && BREADY) begin
        BVALID <= 0;
        b_pending <= 0;
      end else if (!BVALID && b_pending && !stall_b_active) begin
        BVALID <= 1;
      end

      if (((auto_push === 1'b1) || (auto_pop === 1'b1)) &&
          (!auto_wvalid || auto_wready))
        auto_wdata <= $urandom;
      auto_wvalid <= !fifo_clear_active &&
                     (((auto_push === 1'b1) && (auto_stall_count == 0)) ||
                      (auto_wvalid && !auto_wready));
      auto_rready <= !fifo_under_reset && (auto_pop === 1'b1) &&
                     (auto_stall_count == 0) && (fifo_count != 0);

      if (ARVALID && ARREADY) begin
        rd_active <= 1;
        rd_bad <= !stream_request_valid(ARADDR, ARLEN, ARSIZE, ARBURST) ||
                  (inject_error === 1'b1);
        rd_len <= ARLEN;
        rd_beat <= 0;
        rd_id <= ARID;
        rd_user <= ARUSER;
        if (!stream_request_valid(ARADDR, ARLEN, ARSIZE, ARBURST))
          rd_resp <= 2'b11;
        else if (inject_error === 1'b1)
          rd_resp <= 2'b10;
        else
          rd_resp <= 2'b00;
      end

      if (RVALID && RREADY) begin
        RVALID <= 0;
        if (RLAST) begin
          rd_active <= 0;
          rd_beat <= 0;
        end else begin
          rd_beat <= rd_beat + 1'b1;
        end
      end else if (fifo_axi_load) begin
        RID <= rd_id;
        RDATA <= rd_bad ? {DATA_WIDTH{1'b0}} : fifo_mem[fifo_read_ptr];
        RRESP <= rd_resp;
        RUSER <= rd_user;
        RLAST <= (rd_beat == rd_len);
        RVALID <= 1;
      end
    end
  end
endmodule
