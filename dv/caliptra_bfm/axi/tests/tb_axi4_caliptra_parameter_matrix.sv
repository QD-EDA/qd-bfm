// SPDX-License-Identifier: Apache-2.0
`timescale 1ns/1ps
module tb_axi4_caliptra_parameter_matrix #(
  parameter integer DATA_WIDTH = 32,
  parameter integer ID_WIDTH = 8
);
  localparam integer ADDR_WIDTH = 48;
  localparam integer USER_WIDTH = 8;
  localparam integer DATA_BYTES = DATA_WIDTH / 8;
  localparam integer MAX_BEATS = 8;
  localparam [ADDR_WIDTH-1:0] UNALIGNED_ADDR = 48'h100 + DATA_BYTES - 1;
  localparam [ADDR_WIDTH-1:0] WRAP_START = 48'h180 + 3 * DATA_BYTES;

  reg ACLK = 0;
  always #5 ACLK = ~ACLK;
  reg ARESETn = 0;
  reg stall_aw = 0, stall_w = 0, stall_b = 0, stall_ar = 0, stall_r = 0;
  reg inject_error = 0;

  wire [ID_WIDTH-1:0] AWID, BID, ARID, RID;
  wire [ADDR_WIDTH-1:0] AWADDR, ARADDR;
  wire [7:0] AWLEN, ARLEN;
  wire [2:0] AWSIZE, ARSIZE;
  wire [1:0] AWBURST, ARBURST, BRESP, RRESP;
  wire AWLOCK, ARLOCK, AWVALID, AWREADY, WLAST, WVALID, WREADY;
  wire [USER_WIDTH-1:0] AWUSER, WUSER, BUSER, ARUSER, RUSER;
  wire [DATA_WIDTH-1:0] WDATA, RDATA;
  wire [DATA_BYTES-1:0] WSTRB;
  wire BVALID, BREADY, ARVALID, ARREADY, RLAST, RVALID, RREADY;
  wire [ID_WIDTH-1:0] write_response_id, read_response_id;

  axi4_caliptra_master #(
    .ADDR_WIDTH(ADDR_WIDTH), .DATA_WIDTH(DATA_WIDTH), .ID_WIDTH(ID_WIDTH),
    .USER_WIDTH(USER_WIDTH), .MAX_BEATS(MAX_BEATS), .MAX_OUTSTANDING(2),
    .TIMEOUT_CYCLES(64)
  ) manager (.*);

  axi4_caliptra_memory_subordinate #(
    .ADDR_WIDTH(ADDR_WIDTH), .DATA_WIDTH(DATA_WIDTH), .ID_WIDTH(ID_WIDTH),
    .USER_WIDTH(USER_WIDTH), .BASE_ADDR({ADDR_WIDTH{1'b0}}),
    .MEM_BYTES(4096), .MAX_OUTSTANDING(2)
  ) memory (.*);

  axi4_caliptra_checker #(
    .ADDR_WIDTH(ADDR_WIDTH), .DATA_WIDTH(DATA_WIDTH), .ID_WIDTH(ID_WIDTH),
    .USER_WIDTH(USER_WIDTH)
  ) checker_inst (.*);

  wire [31:0] aw_count, w_count, b_count, ar_count, r_count;
  wire [31:0] aw_burst_incr_count, aw_burst_wrap_count;
  wire [31:0] ar_burst_incr_count, ar_burst_wrap_count;
  wire [31:0] w_strb_partial_count, w_last_count, r_last_count;

  axi4_caliptra_monitor #(
    .ADDR_WIDTH(ADDR_WIDTH), .DATA_WIDTH(DATA_WIDTH), .ID_WIDTH(ID_WIDTH),
    .USER_WIDTH(USER_WIDTH)
  ) monitor_inst (
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
    .RREADY(RREADY), .aw_count(aw_count), .w_count(w_count),
    .b_count(b_count), .ar_count(ar_count), .r_count(r_count),
    .aw_burst_incr_count(aw_burst_incr_count),
    .aw_burst_wrap_count(aw_burst_wrap_count),
    .ar_burst_incr_count(ar_burst_incr_count),
    .ar_burst_wrap_count(ar_burst_wrap_count),
    .w_strb_partial_count(w_strb_partial_count),
    .w_last_count(w_last_count), .r_last_count(r_last_count)
  );

  wire transaction_write_complete, transaction_write_error;
  wire [3:0] transaction_write_status;
  wire [ID_WIDTH-1:0] transaction_write_id, transaction_write_response_id;
  wire [ADDR_WIDTH-1:0] transaction_write_addr;
  wire [7:0] transaction_write_len;
  wire [2:0] transaction_write_size;
  wire [1:0] transaction_write_burst, transaction_write_response;
  wire transaction_write_lock;
  wire [USER_WIDTH-1:0] transaction_write_awuser, transaction_write_buser;
  wire [8:0] transaction_write_beat_count;
  wire [MAX_BEATS*DATA_WIDTH-1:0] transaction_write_data;
  wire [MAX_BEATS*DATA_BYTES-1:0] transaction_write_strb;
  wire [MAX_BEATS*USER_WIDTH-1:0] transaction_write_wuser;
  wire [MAX_BEATS-1:0] transaction_write_last_mask;
  wire transaction_read_complete, transaction_read_error;
  wire [3:0] transaction_read_status;
  wire [ID_WIDTH-1:0] transaction_read_id;
  wire [ADDR_WIDTH-1:0] transaction_read_addr;
  wire [7:0] transaction_read_len;
  wire [2:0] transaction_read_size;
  wire [1:0] transaction_read_burst;
  wire transaction_read_lock;
  wire [USER_WIDTH-1:0] transaction_read_aruser;
  wire [8:0] transaction_read_beat_count;
  wire [MAX_BEATS*DATA_WIDTH-1:0] transaction_read_data;
  wire [MAX_BEATS*2-1:0] transaction_read_resp;
  wire [MAX_BEATS*USER_WIDTH-1:0] transaction_read_ruser;
  wire [MAX_BEATS-1:0] transaction_read_last_mask;
  integer transaction_write_complete_count = 0;
  integer transaction_read_complete_count = 0;

  axi4_caliptra_transaction_monitor #(
    .ADDR_WIDTH(ADDR_WIDTH), .DATA_WIDTH(DATA_WIDTH), .ID_WIDTH(ID_WIDTH),
    .USER_WIDTH(USER_WIDTH), .MAX_BEATS(MAX_BEATS), .MAX_OUTSTANDING(2)
  ) transaction_monitor_inst (
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
    .RREADY(RREADY), .write_complete(transaction_write_complete),
    .write_error(transaction_write_error), .write_status(transaction_write_status),
    .write_id(transaction_write_id), .write_addr(transaction_write_addr),
    .write_len(transaction_write_len), .write_size(transaction_write_size),
    .write_burst(transaction_write_burst), .write_lock(transaction_write_lock),
    .write_awuser(transaction_write_awuser),
    .write_beat_count(transaction_write_beat_count),
    .write_data(transaction_write_data), .write_strb(transaction_write_strb),
    .write_wuser(transaction_write_wuser),
    .write_last_mask(transaction_write_last_mask),
    .write_response_id(transaction_write_response_id),
    .write_response(transaction_write_response),
    .write_buser(transaction_write_buser),
    .read_complete(transaction_read_complete), .read_error(transaction_read_error),
    .read_status(transaction_read_status), .read_id(transaction_read_id),
    .read_addr(transaction_read_addr), .read_len(transaction_read_len),
    .read_size(transaction_read_size), .read_burst(transaction_read_burst),
    .read_lock(transaction_read_lock), .read_aruser(transaction_read_aruser),
    .read_beat_count(transaction_read_beat_count),
    .read_data(transaction_read_data), .read_resp(transaction_read_resp),
    .read_ruser(transaction_read_ruser),
    .read_last_mask(transaction_read_last_mask)
  );

  always @(posedge ACLK) begin
    if (!ARESETn) begin
      transaction_write_complete_count <= 0;
      transaction_read_complete_count <= 0;
    end else begin
      if (transaction_write_complete)
        transaction_write_complete_count <= transaction_write_complete_count + 1;
      if (transaction_read_complete)
        transaction_read_complete_count <= transaction_read_complete_count + 1;
    end
  end

  reg [DATA_WIDTH*MAX_BEATS-1:0] write_data, read_data;
  reg [DATA_BYTES*MAX_BEATS-1:0] write_strb;
  reg [USER_WIDTH*MAX_BEATS-1:0] write_user, read_user;
  reg [2*MAX_BEATS-1:0] read_response;
  reg [ID_WIDTH-1:0] transaction_id;
  reg success;
  reg [1:0] response;
  reg [USER_WIDTH-1:0] response_user;
  reg [DATA_WIDTH-1:0] expected_data;
  reg [4*USER_WIDTH-1:0] expected_transaction_ruser;
  integer beat, lane;

  task automatic check(input condition, input [8*100-1:0] message);
    if (condition !== 1'b1) $fatal(1, "%0s", message);
  endtask

  initial begin
    transaction_id = {ID_WIDTH{1'b1}};
    repeat (2) @(posedge ACLK);
    @(negedge ACLK); manager.reset_master(); ARESETn = 1;

    write_data = 0;
    write_strb = 0;
    write_user = 0;
    write_data[DATA_WIDTH-8 +: 8] = 8'ha5;
    write_data[DATA_WIDTH +: 16] = 16'hc7b6;
    write_strb[DATA_BYTES-1] = 1'b1;
    write_strb[DATA_BYTES +: 2] = 2'b11;
    write_user[0 +: USER_WIDTH] = 8'h51;
    write_user[USER_WIDTH +: USER_WIDTH] = 8'h52;
    manager.write_burst(UNALIGNED_ADDR, 1, 1, 2'b01, transaction_id,
      8'ha1, 1'b0, write_data, write_strb, write_user,
      success, response, response_user);
    check(success && response == 0 && write_response_id === transaction_id,
      "unaligned write failed for parameter configuration");
    manager.read_burst(UNALIGNED_ADDR, 1, 1, 2'b01, transaction_id,
      8'ha2, 1'b0, success, read_data, read_user, read_response,
      response_user);
    expected_data = 0;
    expected_data[DATA_WIDTH-8 +: 8] = 8'ha5;
    check(success && read_response_id === transaction_id &&
      read_data[0 +: DATA_WIDTH] === expected_data &&
      read_user[0 +: USER_WIDTH] === 8'ha2 &&
      read_response[0 +: 2] === 2'b00,
      "unaligned first beat or ID failed for parameter configuration");
    expected_data = 0;
    expected_data[15:0] = 16'hc7b6;
    check(read_data[DATA_WIDTH +: DATA_WIDTH] === expected_data &&
      read_user[USER_WIDTH +: USER_WIDTH] === 8'ha2 &&
      read_response[2 +: 2] === 2'b00,
      "aligned follow-up beat failed for parameter configuration");

    write_data = 0;
    write_strb = 0;
    write_user = 0;
    for (beat = 0; beat < 4; beat = beat + 1) begin
      for (lane = 0; lane < DATA_BYTES; lane = lane + 1) begin
        write_data[beat*DATA_WIDTH + lane*8 +: 8] =
          8'h40 + beat*DATA_BYTES + lane;
        write_strb[beat*DATA_BYTES + lane] = 1'b1;
      end
      write_user[beat*USER_WIDTH +: USER_WIDTH] = 8'h60 + beat;
    end
    manager.write_burst(WRAP_START, 3, $clog2(DATA_BYTES), 2'b10,
      transaction_id, 8'ha3, 1'b0, write_data, write_strb, write_user,
      success, response, response_user);
    check(success && response == 0 && write_response_id === transaction_id,
      "WRAP write failed for parameter configuration");
    manager.read_burst(WRAP_START, 3, $clog2(DATA_BYTES), 2'b10,
      transaction_id, 8'ha4, 1'b0, success, read_data, read_user,
      read_response, response_user);
    check(success && read_response_id === transaction_id,
      "WRAP read failed for parameter configuration");
    for (beat = 0; beat < 4; beat = beat + 1)
      check(read_data[beat*DATA_WIDTH +: DATA_WIDTH] ===
            write_data[beat*DATA_WIDTH +: DATA_WIDTH] &&
            read_user[beat*USER_WIDTH +: USER_WIDTH] === 8'ha4 &&
            read_response[beat*2 +: 2] === 2'b00,
        "WRAP payload, USER, or response failed for parameter configuration");

    checker_inst.check_idle();
    repeat (2) @(posedge ACLK);
    check(aw_count == 2 && w_count == 6 && b_count == 2 &&
      ar_count == 2 && r_count == 6 && w_last_count == 2 && r_last_count == 2,
      "monitor channel or last-beat counts failed for parameter configuration");
    check(aw_burst_incr_count == 1 && aw_burst_wrap_count == 1 &&
      ar_burst_incr_count == 1 && ar_burst_wrap_count == 1 &&
      w_strb_partial_count == 2,
      "monitor burst or strobe counts failed for parameter configuration");
    check(transaction_write_complete_count == 2 &&
      transaction_read_complete_count == 2,
      "transaction monitor missed a completed matrix read or write");
    check(!transaction_write_error && transaction_write_status == 0 &&
      transaction_write_id === transaction_id &&
      transaction_write_addr === WRAP_START && transaction_write_len == 3 &&
      transaction_write_size == $clog2(DATA_BYTES) &&
      transaction_write_burst == 2'b10 && !transaction_write_lock &&
      transaction_write_awuser == 8'ha3 && transaction_write_beat_count == 4 &&
      transaction_write_data[0 +: 4*DATA_WIDTH] === write_data[0 +: 4*DATA_WIDTH] &&
      transaction_write_strb[0 +: 4*DATA_BYTES] === write_strb[0 +: 4*DATA_BYTES] &&
      transaction_write_wuser[0 +: 4*USER_WIDTH] === write_user[0 +: 4*USER_WIDTH] &&
      transaction_write_last_mask[3:0] == 4'b1000 &&
      transaction_write_response_id === transaction_id &&
      transaction_write_response == 0 && transaction_write_buser == 8'ha3,
      "transaction monitor WRAP write record failed for parameter configuration");
    expected_transaction_ruser = 0;
    for (beat = 0; beat < 4; beat = beat + 1)
      expected_transaction_ruser[beat*USER_WIDTH +: USER_WIDTH] = 8'ha4;
    check(!transaction_read_error && transaction_read_status == 0 &&
      transaction_read_id === transaction_id &&
      transaction_read_addr === WRAP_START && transaction_read_len == 3 &&
      transaction_read_size == $clog2(DATA_BYTES) &&
      transaction_read_burst == 2'b10 && !transaction_read_lock &&
      transaction_read_aruser == 8'ha4 && transaction_read_beat_count == 4 &&
      transaction_read_data[0 +: 4*DATA_WIDTH] === write_data[0 +: 4*DATA_WIDTH] &&
      transaction_read_resp[0 +: 8] == 0 &&
      transaction_read_ruser[0 +: 4*USER_WIDTH] === expected_transaction_ruser &&
      transaction_read_last_mask[3:0] == 4'b1000,
      "transaction monitor WRAP read record failed for parameter configuration");
    $display("PASS: AXI DATA_WIDTH=%0d ID_WIDTH=%0d parameter matrix",
      DATA_WIDTH, ID_WIDTH);
    $finish;
  end
endmodule
