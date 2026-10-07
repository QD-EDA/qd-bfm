// SPDX-License-Identifier: Apache-2.0
// Emits one-cycle records for each accepted AXI channel beat.
module axi4_caliptra_monitor #(
  parameter integer ADDR_WIDTH = 19,
  parameter integer DATA_WIDTH = 32,
  parameter integer ID_WIDTH = 8,
  parameter integer USER_WIDTH = 32
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
  input wire RREADY,
  output reg aw_fire,
  output reg [ID_WIDTH+ADDR_WIDTH+8+3+2+1+USER_WIDTH-1:0] aw_record,
  output reg w_fire,
  output reg [DATA_WIDTH+DATA_WIDTH/8+USER_WIDTH:0] w_record,
  output reg b_fire,
  output reg [ID_WIDTH+1+1+USER_WIDTH-1:0] b_record,
  output reg ar_fire,
  output reg [ID_WIDTH+ADDR_WIDTH+8+3+2+1+USER_WIDTH-1:0] ar_record,
  output reg r_fire,
  output reg [ID_WIDTH+DATA_WIDTH+1+1+1+USER_WIDTH-1:0] r_record,
  output reg [63:0] cycle_count,
  output reg [31:0] aw_count,
  output reg [31:0] w_count,
  output reg [31:0] b_count,
  output reg [31:0] ar_count,
  output reg [31:0] r_count,
  output reg [31:0] aw_valid_cycles,
  output reg [31:0] aw_stall_cycles,
  output reg [31:0] w_valid_cycles,
  output reg [31:0] w_stall_cycles,
  output reg [31:0] b_valid_cycles,
  output reg [31:0] b_stall_cycles,
  output reg [31:0] ar_valid_cycles,
  output reg [31:0] ar_stall_cycles,
  output reg [31:0] r_valid_cycles,
  output reg [31:0] r_stall_cycles,
  output reg [31:0] aw_burst_fixed_count,
  output reg [31:0] aw_burst_incr_count,
  output reg [31:0] aw_burst_wrap_count,
  output reg [31:0] aw_burst_reserved_count,
  output reg [31:0] aw_burst_unknown_count,
  output reg [31:0] aw_lock_clear_count,
  output reg [31:0] aw_lock_set_count,
  output reg [31:0] aw_lock_unknown_count,
  output reg [31:0] ar_burst_fixed_count,
  output reg [31:0] ar_burst_incr_count,
  output reg [31:0] ar_burst_wrap_count,
  output reg [31:0] ar_burst_reserved_count,
  output reg [31:0] ar_burst_unknown_count,
  output reg [31:0] ar_lock_clear_count,
  output reg [31:0] ar_lock_set_count,
  output reg [31:0] ar_lock_unknown_count,
  output reg [31:0] b_resp_okay_count,
  output reg [31:0] b_resp_exokay_count,
  output reg [31:0] b_resp_slverr_count,
  output reg [31:0] b_resp_decerr_count,
  output reg [31:0] b_resp_unknown_count,
  output reg [31:0] r_resp_okay_count,
  output reg [31:0] r_resp_exokay_count,
  output reg [31:0] r_resp_slverr_count,
  output reg [31:0] r_resp_decerr_count,
  output reg [31:0] r_resp_unknown_count,
  output reg [31:0] w_strb_full_count,
  output reg [31:0] w_strb_partial_count,
  output reg [31:0] w_strb_zero_count,
  output reg [31:0] w_strb_unknown_count,
  output reg [31:0] w_last_count,
  output reg [31:0] r_last_count
);
  localparam integer STRB_WIDTH = DATA_WIDTH / 8;

  always @(posedge ACLK) begin
    if (!ARESETn) begin
      aw_fire <= 0; w_fire <= 0; b_fire <= 0; ar_fire <= 0; r_fire <= 0;
      cycle_count <= 0; aw_count <= 0; w_count <= 0; b_count <= 0;
      ar_count <= 0; r_count <= 0;
      aw_record <= 0; w_record <= 0; b_record <= 0; ar_record <= 0; r_record <= 0;
      aw_valid_cycles <= 0; aw_stall_cycles <= 0;
      w_valid_cycles <= 0; w_stall_cycles <= 0;
      b_valid_cycles <= 0; b_stall_cycles <= 0;
      ar_valid_cycles <= 0; ar_stall_cycles <= 0;
      r_valid_cycles <= 0; r_stall_cycles <= 0;
      aw_burst_fixed_count <= 0; aw_burst_incr_count <= 0;
      aw_burst_wrap_count <= 0; aw_burst_reserved_count <= 0;
      aw_burst_unknown_count <= 0;
      aw_lock_clear_count <= 0; aw_lock_set_count <= 0;
      aw_lock_unknown_count <= 0;
      ar_burst_fixed_count <= 0; ar_burst_incr_count <= 0;
      ar_burst_wrap_count <= 0; ar_burst_reserved_count <= 0;
      ar_burst_unknown_count <= 0;
      ar_lock_clear_count <= 0; ar_lock_set_count <= 0;
      ar_lock_unknown_count <= 0;
      b_resp_okay_count <= 0; b_resp_exokay_count <= 0;
      b_resp_slverr_count <= 0; b_resp_decerr_count <= 0;
      b_resp_unknown_count <= 0;
      r_resp_okay_count <= 0; r_resp_exokay_count <= 0;
      r_resp_slverr_count <= 0; r_resp_decerr_count <= 0;
      r_resp_unknown_count <= 0;
      w_strb_full_count <= 0; w_strb_partial_count <= 0;
      w_strb_zero_count <= 0; w_strb_unknown_count <= 0;
      w_last_count <= 0; r_last_count <= 0;
    end else begin
      cycle_count <= cycle_count + 1'b1;
      aw_fire <= AWVALID && AWREADY;
      w_fire <= WVALID && WREADY;
      b_fire <= BVALID && BREADY;
      ar_fire <= ARVALID && ARREADY;
      r_fire <= RVALID && RREADY;
      if (AWVALID === 1'b1) begin
        aw_valid_cycles <= aw_valid_cycles + 1'b1;
        if (AWREADY === 1'b0)
          aw_stall_cycles <= aw_stall_cycles + 1'b1;
      end
      if (WVALID === 1'b1) begin
        w_valid_cycles <= w_valid_cycles + 1'b1;
        if (WREADY === 1'b0)
          w_stall_cycles <= w_stall_cycles + 1'b1;
      end
      if (BVALID === 1'b1) begin
        b_valid_cycles <= b_valid_cycles + 1'b1;
        if (BREADY === 1'b0)
          b_stall_cycles <= b_stall_cycles + 1'b1;
      end
      if (ARVALID === 1'b1) begin
        ar_valid_cycles <= ar_valid_cycles + 1'b1;
        if (ARREADY === 1'b0)
          ar_stall_cycles <= ar_stall_cycles + 1'b1;
      end
      if (RVALID === 1'b1) begin
        r_valid_cycles <= r_valid_cycles + 1'b1;
        if (RREADY === 1'b0)
          r_stall_cycles <= r_stall_cycles + 1'b1;
      end
      if (AWVALID && AWREADY) begin
        aw_count <= aw_count + 1'b1;
        aw_record <= {AWID, AWADDR, AWLEN, AWSIZE, AWBURST, AWLOCK, AWUSER};
        case (AWBURST)
          2'b00: aw_burst_fixed_count <= aw_burst_fixed_count + 1'b1;
          2'b01: aw_burst_incr_count <= aw_burst_incr_count + 1'b1;
          2'b10: aw_burst_wrap_count <= aw_burst_wrap_count + 1'b1;
          2'b11: aw_burst_reserved_count <= aw_burst_reserved_count + 1'b1;
          default: aw_burst_unknown_count <= aw_burst_unknown_count + 1'b1;
        endcase
        case (AWLOCK)
          1'b0: aw_lock_clear_count <= aw_lock_clear_count + 1'b1;
          1'b1: aw_lock_set_count <= aw_lock_set_count + 1'b1;
          default: aw_lock_unknown_count <= aw_lock_unknown_count + 1'b1;
        endcase
      end
      if (WVALID && WREADY) begin
        w_count <= w_count + 1'b1;
        w_record <= {WDATA, WSTRB, WUSER, WLAST};
        if ((^WSTRB) === 1'bx)
          w_strb_unknown_count <= w_strb_unknown_count + 1'b1;
        else if (WSTRB == {STRB_WIDTH{1'b1}})
          w_strb_full_count <= w_strb_full_count + 1'b1;
        else if (WSTRB == {STRB_WIDTH{1'b0}})
          w_strb_zero_count <= w_strb_zero_count + 1'b1;
        else
          w_strb_partial_count <= w_strb_partial_count + 1'b1;
        if (WLAST === 1'b1)
          w_last_count <= w_last_count + 1'b1;
      end
      if (BVALID && BREADY) begin
        b_count <= b_count + 1'b1;
        b_record <= {BID, BRESP, BUSER};
        case (BRESP)
          2'b00: b_resp_okay_count <= b_resp_okay_count + 1'b1;
          2'b01: b_resp_exokay_count <= b_resp_exokay_count + 1'b1;
          2'b10: b_resp_slverr_count <= b_resp_slverr_count + 1'b1;
          2'b11: b_resp_decerr_count <= b_resp_decerr_count + 1'b1;
          default: b_resp_unknown_count <= b_resp_unknown_count + 1'b1;
        endcase
      end
      if (ARVALID && ARREADY) begin
        ar_count <= ar_count + 1'b1;
        ar_record <= {ARID, ARADDR, ARLEN, ARSIZE, ARBURST, ARLOCK, ARUSER};
        case (ARBURST)
          2'b00: ar_burst_fixed_count <= ar_burst_fixed_count + 1'b1;
          2'b01: ar_burst_incr_count <= ar_burst_incr_count + 1'b1;
          2'b10: ar_burst_wrap_count <= ar_burst_wrap_count + 1'b1;
          2'b11: ar_burst_reserved_count <= ar_burst_reserved_count + 1'b1;
          default: ar_burst_unknown_count <= ar_burst_unknown_count + 1'b1;
        endcase
        case (ARLOCK)
          1'b0: ar_lock_clear_count <= ar_lock_clear_count + 1'b1;
          1'b1: ar_lock_set_count <= ar_lock_set_count + 1'b1;
          default: ar_lock_unknown_count <= ar_lock_unknown_count + 1'b1;
        endcase
      end
      if (RVALID && RREADY) begin
        r_count <= r_count + 1'b1;
        r_record <= {RID, RDATA, RRESP, RUSER, RLAST};
        case (RRESP)
          2'b00: r_resp_okay_count <= r_resp_okay_count + 1'b1;
          2'b01: r_resp_exokay_count <= r_resp_exokay_count + 1'b1;
          2'b10: r_resp_slverr_count <= r_resp_slverr_count + 1'b1;
          2'b11: r_resp_decerr_count <= r_resp_decerr_count + 1'b1;
          default: r_resp_unknown_count <= r_resp_unknown_count + 1'b1;
        endcase
        if (RLAST === 1'b1)
          r_last_count <= r_last_count + 1'b1;
      end
    end
  end
endmodule
