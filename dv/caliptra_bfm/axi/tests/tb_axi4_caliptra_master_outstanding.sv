// SPDX-License-Identifier: Apache-2.0
`timescale 1ns/1ps
module tb_axi4_caliptra_master_outstanding #(
  parameter integer DATA_WIDTH = 32,
  parameter integer ID_WIDTH = 8,
  parameter integer MAX_OUTSTANDING = 4
);
  localparam integer ADDR_WIDTH = 48;
  localparam integer USER_WIDTH = 32;
  localparam integer MAX_BEATS = 16;

  reg ACLK = 0;
  always #5 ACLK = ~ACLK;
  reg ARESETn = 0;

  wire [ID_WIDTH-1:0] AWID;
  wire [ADDR_WIDTH-1:0] AWADDR;
  wire [7:0] AWLEN;
  wire [2:0] AWSIZE;
  wire [1:0] AWBURST;
  wire AWLOCK;
  wire [USER_WIDTH-1:0] AWUSER;
  wire AWVALID;
  wire AWREADY;
  wire WREADY;
  wire WVALID;
  wire [DATA_WIDTH-1:0] WDATA;
  wire [DATA_WIDTH/8-1:0] WSTRB;
  wire [USER_WIDTH-1:0] WUSER;
  wire WLAST;
  wire BREADY;
  wire [ID_WIDTH-1:0] BID;
  wire [1:0] BRESP;
  wire [USER_WIDTH-1:0] BUSER;
  wire BVALID;
  wire [ID_WIDTH-1:0] ARID;
  wire [ADDR_WIDTH-1:0] ARADDR;
  wire [7:0] ARLEN;
  wire [2:0] ARSIZE;
  wire [1:0] ARBURST;
  wire ARLOCK;
  wire [USER_WIDTH-1:0] ARUSER;
  wire ARVALID;
  wire ARREADY;
  wire RREADY;
  reg RVALID = 0;
  reg [ID_WIDTH-1:0] RID = 0;
  reg [DATA_WIDTH-1:0] RDATA = 0;
  reg [1:0] RRESP = 0;
  reg [USER_WIDTH-1:0] RUSER = 0;
  reg RLAST = 0;
  wire [ID_WIDTH-1:0] write_response_id;
  wire [ID_WIDTH-1:0] read_response_id;
  integer ar_count = 0;
  reg [ID_WIDTH-1:0] accepted_id [0:4];
  reg [ADDR_WIDTH-1:0] accepted_addr [0:4];
  reg response_sent [0:4];
  reg read_success [0:4];
  reg [MAX_BEATS*DATA_WIDTH-1:0] read_data_result [0:4];
  reg [USER_WIDTH-1:0] read_response_user_result [0:4];

  assign AWREADY = 1'b0;
  assign WREADY = 1'b0;
  assign BID = {ID_WIDTH{1'b0}};
  assign BRESP = 2'b0;
  assign BUSER = {USER_WIDTH{1'b0}};
  assign BVALID = 1'b0;
  assign ARREADY = ARESETn && (ar_count < 5);

  axi4_caliptra_master #(
    .ADDR_WIDTH(ADDR_WIDTH), .DATA_WIDTH(DATA_WIDTH), .ID_WIDTH(ID_WIDTH),
    .USER_WIDTH(USER_WIDTH), .MAX_BEATS(MAX_BEATS), .TIMEOUT_CYCLES(32),
    .MAX_OUTSTANDING(MAX_OUTSTANDING)
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
      RDATA = accepted_addr[request_index];
      RUSER = 32'hd000_0000 | accepted_id[request_index];
      RRESP = 2'b00;
      RLAST = 1'b1;
      RVALID = 1'b1;
      do @(posedge ACLK); while (!RREADY);
      @(negedge ACLK);
      RVALID = 1'b0;
    end
  endtask

  task automatic run_read(input integer index, input [ADDR_WIDTH-1:0] addr,
                          input [ID_WIDTH-1:0] id);
    reg success;
    reg [MAX_BEATS*DATA_WIDTH-1:0] data;
    reg [MAX_BEATS*USER_WIDTH-1:0] user;
    reg [2*MAX_BEATS-1:0] response;
    reg [USER_WIDTH-1:0] response_user;
    begin
      bfm.read_burst(addr, 0, 2, 2'b01, id, id, 1'b0,
        success, data, user, response, response_user);
      read_success[index] = success;
      read_data_result[index] = data;
      read_response_user_result[index] = response_user;
    end
  endtask

  initial begin
    integer i;
    reg [DATA_WIDTH-1:0] expected_data;
    for (i = 0; i < 5; i = i + 1) response_sent[i] = 0;
    repeat (2) @(posedge ACLK);
    @(negedge ACLK); ARESETn = 1'b1;
    fork
      run_read(0, 48'h40, 8'h11);
      run_read(1, 48'h80, 8'h22);
      run_read(2, 48'hc0, 8'h33);
      run_read(3, 48'h100, 8'h44);
      run_read(4, 48'h140, 8'h55);
    join

    if (ar_count != 5) $fatal(1, "target saw %0d AR handshakes, expected 5", ar_count);
    if (!read_success[0] || !read_success[1] || !read_success[2] ||
        !read_success[3] || !read_success[4])
      $fatal(1, "one or more queued read tasks failed");
    for (i = 0; i < 5; i = i + 1) begin
      expected_data = accepted_addr[i];
      if (read_data_result[i][0 +: DATA_WIDTH] !== expected_data)
        $fatal(1, "response data was misrouted to read task %0d", i);
      if (read_response_user_result[i] !== (32'hd000_0000 | accepted_id[i]))
        $fatal(1, "RUSER was misrouted to read task %0d", i);
    end
    if (bfm.read_busy) $fatal(1, "manager remained busy after both reads completed");
    $display("PASS: AXI DATA_WIDTH=%0d ID_WIDTH=%0d MAX_OUTSTANDING=%0d queued reads",
      DATA_WIDTH, ID_WIDTH, MAX_OUTSTANDING);
    $finish;
  end

  initial begin
    integer i;
    integer prior;
    integer candidate;
    integer responses_sent;
    reg blocked;
    wait (ARESETn === 1'b1);
    wait (ar_count >= MAX_OUTSTANDING);
    repeat (2) @(posedge ACLK);
    if (ar_count != MAX_OUTSTANDING)
      $fatal(1, "manager exceeded MAX_OUTSTANDING=%0d before a response", MAX_OUTSTANDING);
    responses_sent = 0;
    while (responses_sent < 5) begin
      if (ar_count > responses_sent) begin
        candidate = -1;
        for (i = 0; i < ar_count; i = i + 1) begin
          if (!response_sent[i]) begin
            blocked = 0;
            for (prior = 0; prior < i; prior = prior + 1)
              if (!response_sent[prior] && accepted_id[prior] == accepted_id[i])
                blocked = 1;
            if (!blocked) candidate = i;
          end
        end
        if (candidate < 0) $fatal(1, "no eligible outstanding ID response");
        send_response(candidate);
        response_sent[candidate] = 1;
        responses_sent = responses_sent + 1;
      end else begin
        @(posedge ACLK);
      end
    end
  end
endmodule
