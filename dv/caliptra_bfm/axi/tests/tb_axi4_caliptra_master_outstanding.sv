// SPDX-License-Identifier: Apache-2.0
`timescale 1ns/1ps
module tb_axi4_caliptra_master_outstanding;
  reg ACLK = 0;
  always #5 ACLK = ~ACLK;
  reg ARESETn = 0;

  wire [7:0] AWID;
  wire [18:0] AWADDR;
  wire [7:0] AWLEN;
  wire [2:0] AWSIZE;
  wire [1:0] AWBURST;
  wire AWLOCK;
  wire [31:0] AWUSER;
  wire AWVALID;
  wire AWREADY;
  wire WREADY;
  wire WVALID;
  wire [31:0] WDATA;
  wire [3:0] WSTRB;
  wire [31:0] WUSER;
  wire WLAST;
  wire BREADY;
  wire [7:0] BID;
  wire [1:0] BRESP;
  wire [31:0] BUSER;
  wire BVALID;
  wire [7:0] ARID;
  wire [18:0] ARADDR;
  wire [7:0] ARLEN;
  wire [2:0] ARSIZE;
  wire [1:0] ARBURST;
  wire ARLOCK;
  wire [31:0] ARUSER;
  wire ARVALID;
  wire ARREADY;
  wire RREADY;
  reg RVALID = 0;
  reg [7:0] RID = 0;
  reg [31:0] RDATA = 0;
  reg [1:0] RRESP = 0;
  reg [31:0] RUSER = 0;
  reg RLAST = 0;
  wire [7:0] write_response_id;
  wire [7:0] read_response_id;
  integer ar_count = 0;
  reg [7:0] accepted_id [0:4];
  reg [18:0] accepted_addr [0:4];
  reg read_success [0:4];
  reg [511:0] read_data_result [0:4];
  reg [31:0] read_response_user_result [0:4];

  assign AWREADY = 1'b0;
  assign WREADY = 1'b0;
  assign BID = 8'b0;
  assign BRESP = 2'b0;
  assign BUSER = 32'b0;
  assign BVALID = 1'b0;
  assign ARREADY = ARESETn && (ar_count < 5);

  axi4_caliptra_master #(
    .ADDR_WIDTH(19), .DATA_WIDTH(32), .ID_WIDTH(8), .USER_WIDTH(32),
    .MAX_BEATS(16), .TIMEOUT_CYCLES(32), .MAX_OUTSTANDING(4)
  ) bfm (.*);

  always @(posedge ACLK) begin
    if (!ARESETn) begin
      ar_count <= 0;
    end else if (ARVALID && ARREADY) begin
      if (ar_count >= 5) $fatal(1, "target accepted too many read addresses");
      accepted_id[ar_count] <= ARID;
      accepted_addr[ar_count] <= ARADDR;
      ar_count <= ar_count + 1;
    end
  end

  task automatic send_response(input integer request_index);
    begin
      @(negedge ACLK);
      RID = accepted_id[request_index];
      RDATA = {13'b0, accepted_addr[request_index]};
      RUSER = 32'hd000_0000 | accepted_id[request_index];
      RRESP = 2'b00;
      RLAST = 1'b1;
      RVALID = 1'b1;
      do @(posedge ACLK); while (!RREADY);
      @(negedge ACLK);
      RVALID = 1'b0;
    end
  endtask

  task automatic run_read(input integer index, input [18:0] addr, input [7:0] id);
    reg success;
    reg [511:0] data;
    reg [511:0] user;
    reg [31:0] response;
    reg [31:0] response_user;
    begin
      bfm.read_burst(addr, 0, 2, 2'b01, id, {24'b0, id}, 1'b0,
        success, data, user, response, response_user);
      read_success[index] = success;
      read_data_result[index] = data;
      read_response_user_result[index] = response_user;
    end
  endtask

  initial begin
    repeat (2) @(posedge ACLK);
    @(negedge ACLK); ARESETn = 1'b1;
    fork
      run_read(0, 19'h40, 8'h11);
      run_read(1, 19'h80, 8'h22);
      run_read(2, 19'hc0, 8'h33);
      run_read(3, 19'h100, 8'h44);
      run_read(4, 19'h140, 8'h55);
    join

    if (ar_count != 5) $fatal(1, "target saw %0d AR handshakes, expected 5", ar_count);
    if (!read_success[0] || !read_success[1] || !read_success[2] ||
        !read_success[3] || !read_success[4])
      $fatal(1, "one or more queued read tasks failed");
    if (read_data_result[0][31:0] !== 32'h40 ||
        read_data_result[1][31:0] !== 32'h80 ||
        read_data_result[2][31:0] !== 32'hc0 ||
        read_data_result[3][31:0] !== 32'h100 ||
        read_data_result[4][31:0] !== 32'h140)
      $fatal(1, "out-of-order responses were routed to the wrong read tasks");
    if (read_response_user_result[0] !== (32'hd000_0000 | 32'h11) ||
        read_response_user_result[1] !== (32'hd000_0000 | 32'h22) ||
        read_response_user_result[2] !== (32'hd000_0000 | 32'h33) ||
        read_response_user_result[3] !== (32'hd000_0000 | 32'h44) ||
        read_response_user_result[4] !== (32'hd000_0000 | 32'h55))
      $fatal(1, "RUSER was misrouted between queued reads");
    if (bfm.read_busy) $fatal(1, "manager remained busy after both reads completed");
    $display("PASS: AXI manager bounds queued reads and routes out-of-order responses by ID");
    $finish;
  end

  initial begin
    wait (ARESETn === 1'b1);
    wait (ar_count == 4);
    repeat (2) @(posedge ACLK);
    if (ar_count != 4) $fatal(1, "manager issued a fifth read before a slot was freed");
    send_response(3);
    send_response(0);
    send_response(2);
    send_response(1);
    wait (ar_count == 5);
    send_response(4);
  end
endmodule
