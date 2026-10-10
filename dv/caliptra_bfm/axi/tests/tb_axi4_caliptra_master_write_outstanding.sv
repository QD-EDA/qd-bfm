// SPDX-License-Identifier: Apache-2.0
`timescale 1ns/1ps
module tb_axi4_caliptra_master_write_outstanding #(
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
  wire [DATA_WIDTH-1:0] WDATA;
  wire [DATA_WIDTH/8-1:0] WSTRB;
  wire [USER_WIDTH-1:0] WUSER;
  wire WLAST;
  wire WVALID;
  wire WREADY;
  reg [ID_WIDTH-1:0] BID = 0;
  reg [1:0] BRESP = 0;
  reg [USER_WIDTH-1:0] BUSER = 0;
  reg BVALID = 0;
  wire BREADY;
  wire [ID_WIDTH-1:0] ARID;
  wire [ADDR_WIDTH-1:0] ARADDR;
  wire [7:0] ARLEN;
  wire [2:0] ARSIZE;
  wire [1:0] ARBURST;
  wire ARLOCK;
  wire [USER_WIDTH-1:0] ARUSER;
  wire ARVALID;
  wire ARREADY = 0;
  wire [ID_WIDTH-1:0] RID = 0;
  wire [DATA_WIDTH-1:0] RDATA = 0;
  wire [1:0] RRESP = 0;
  wire [USER_WIDTH-1:0] RUSER = 0;
  wire RLAST = 0;
  wire RVALID = 0;
  wire RREADY;
  wire [ID_WIDTH-1:0] write_response_id;
  wire [ID_WIDTH-1:0] read_response_id;

  reg w_enabled = 0;
  integer aw_count = 0;
  integer w_count = 0;
  reg [ID_WIDTH-1:0] accepted_id [0:4];
  reg [ADDR_WIDTH-1:0] accepted_addr [0:4];
  reg [USER_WIDTH-1:0] accepted_awuser [0:4];
  reg [DATA_WIDTH-1:0] accepted_data [0:4];
  reg [DATA_WIDTH/8-1:0] accepted_strb [0:4];
  reg [USER_WIDTH-1:0] accepted_wuser [0:4];
  reg accepted_last [0:4];
  reg [1:0] sent_response [0:4];
  reg [USER_WIDTH-1:0] sent_response_user [0:4];
  reg response_sent [0:4];
  reg w_stalled = 0;
  reg [DATA_WIDTH-1:0] stalled_data;
  reg [DATA_WIDTH/8-1:0] stalled_strb;
  reg [USER_WIDTH-1:0] stalled_user;
  reg stalled_last;
  reg write_success [0:4];
  reg [1:0] write_response_result [0:4];
  reg [USER_WIDTH-1:0] write_response_user_result [0:4];

  assign AWREADY = ARESETn;
  assign WREADY = ARESETn && w_enabled;

  axi4_caliptra_master #(
    .ADDR_WIDTH(ADDR_WIDTH), .DATA_WIDTH(DATA_WIDTH), .ID_WIDTH(ID_WIDTH),
    .USER_WIDTH(USER_WIDTH), .MAX_BEATS(MAX_BEATS), .TIMEOUT_CYCLES(64),
    .MAX_OUTSTANDING(MAX_OUTSTANDING)
  ) bfm (.*);

  function automatic integer caller_for_awuser(input [USER_WIDTH-1:0] awuser);
    begin
      caller_for_awuser = awuser[2:0];
      if (caller_for_awuser > 4) caller_for_awuser = -1;
    end
  endfunction

  always @(posedge ACLK) begin
    if (!ARESETn) begin
      aw_count <= 0;
      w_count <= 0;
      w_stalled = 0;
    end else begin
      if (AWVALID && AWREADY) begin
        if (aw_count >= 5) $fatal(1, "target accepted too many AW requests");
        accepted_id[aw_count] <= AWID;
        accepted_addr[aw_count] <= AWADDR;
        accepted_awuser[aw_count] <= AWUSER;
        aw_count <= aw_count + 1;
      end
      if (WVALID && WREADY) begin
        if (w_count >= 5) $fatal(1, "target accepted too many W transactions");
        if (w_stalled && ((WDATA !== stalled_data) || (WSTRB !== stalled_strb) ||
                          (WUSER !== stalled_user) || (WLAST !== stalled_last)))
          $fatal(1, "write payload changed while stalled");
        accepted_data[w_count] <= WDATA;
        accepted_strb[w_count] <= WSTRB;
        accepted_wuser[w_count] <= WUSER;
        accepted_last[w_count] <= WLAST;
        w_count <= w_count + 1;
        w_stalled = 0;
      end else if (WVALID) begin
        if (!w_stalled) begin
          stalled_data = WDATA;
          stalled_strb = WSTRB;
          stalled_user = WUSER;
          stalled_last = WLAST;
        end else if ((WDATA !== stalled_data) || (WSTRB !== stalled_strb) ||
                     (WUSER !== stalled_user) || (WLAST !== stalled_last))
          $fatal(1, "write payload changed while stalled");
        w_stalled = 1;
      end else begin
        w_stalled = 0;
      end
    end
  end

  task automatic launch_write(input integer index, input [ADDR_WIDTH-1:0] addr,
                              input [ID_WIDTH-1:0] id);
    reg success;
    reg [MAX_BEATS*DATA_WIDTH-1:0] data;
    reg [MAX_BEATS*(DATA_WIDTH/8)-1:0] strb;
    reg [MAX_BEATS*USER_WIDTH-1:0] user;
    reg [1:0] response;
    reg [USER_WIDTH-1:0] response_user;
    begin
      data = 0;
      data[31:0] = 32'hface_0000 | index;
      strb = 0;
      strb[0 +: 4] = 4'hf;
      user = 0;
      user[31:0] = 32'hcafe_0000 | index;
      bfm.write_burst(addr, 0, 2, 2'b01, id, 32'hab00_0000 | index, 1'b0,
        data, strb, user, success, response, response_user);
      write_success[index] = success;
      write_response_result[index] = response;
      write_response_user_result[index] = response_user;
    end
  endtask

  task automatic wait_counts(input integer expected);
    integer cycles;
    begin
      cycles = 0;
      while (((aw_count < expected) || (w_count < expected)) && (cycles < 128)) begin
        @(posedge ACLK);
        cycles = cycles + 1;
      end
      if ((aw_count < expected) || (w_count < expected))
        $fatal(1, "timed out waiting for AW/W count %0d (got %0d/%0d)",
               expected, aw_count, w_count);
    end
  endtask

  task automatic send_response(input integer index, input [1:0] response);
    begin
      @(negedge ACLK);
      BID = accepted_id[index];
      BRESP = response;
      BUSER = 32'hbeef_0000 | index;
      sent_response[index] = response;
      sent_response_user[index] = BUSER;
      BVALID = 1;
      do @(posedge ACLK); while (!BREADY);
      @(negedge ACLK);
      BVALID = 0;
    end
  endtask

  initial begin
    repeat (2) @(posedge ACLK);
    @(negedge ACLK); ARESETn = 1;
    repeat (3) @(posedge ACLK);
    @(negedge ACLK); w_enabled = 1;
  end

  initial begin
    integer i;
    integer caller;
    reg [DATA_WIDTH-1:0] expected_data;
    reg [DATA_WIDTH/8-1:0] expected_strb;
    reg [ID_WIDTH-1:0] expected_id;
    for (i = 0; i < 5; i = i + 1) response_sent[i] = 0;
    wait (ARESETn === 1'b1);
    fork
      launch_write(0, 48'h40, 8'h11);
      launch_write(1, 48'h50, 8'h22);
      launch_write(2, 48'h60, 8'h33);
      launch_write(3, 48'h70, 8'h44);
      launch_write(4, 48'h80, 8'h55);
    join

    if (aw_count != 5 || w_count != 5)
      $fatal(1, "target accepted AW=%0d W=%0d, expected five of each", aw_count, w_count);
    for (i = 0; i < 5; i = i + 1) begin
      caller = caller_for_awuser(accepted_awuser[i]);
      if (caller < 0) $fatal(1, "target accepted unknown AWUSER %h", accepted_awuser[i]);
      expected_id = 8'h11 * (caller + 1);
      if (accepted_id[i] !== expected_id ||
          accepted_addr[i] !== (48'h40 + (caller * 16)) ||
          accepted_awuser[i] !== (32'hab00_0000 | caller))
        $fatal(1, "caller %0d AW channel was mismatched", caller);
      if (caller == 3 && sent_response[i] !== 2'b10)
        $fatal(1, "caller 3 did not receive its expected SLVERR response");
      if (write_response_result[caller] !== sent_response[i] ||
          write_response_user_result[caller] !== sent_response_user[i] ||
          write_success[caller] !== (sent_response[i] === 2'b00 || sent_response[i] === 2'b01))
        $fatal(1, "write caller %0d was mismatched to its accepted BID response", caller);
    end
    expected_strb = 0;
    expected_strb[0 +: 4] = 4'hf;
    for (i = 0; i < 5; i = i + 1) begin
      caller = accepted_wuser[i][2:0];
      if (caller > 4) $fatal(1, "target accepted unknown WUSER %h", accepted_wuser[i]);
      expected_data = 32'hface_0000 | caller;
      if (accepted_data[i] !== expected_data || accepted_strb[i] !== expected_strb ||
          accepted_wuser[i] !== (32'hcafe_0000 | caller) || accepted_last[i] !== 1'b1)
        $fatal(1, "caller %0d W channel was mismatched", caller);
    end
    if (bfm.write_busy) $fatal(1, "manager remained busy after all writes completed");
    $display("PASS: AXI MAX_OUTSTANDING=%0d queues writes and routes BID responses",
      MAX_OUTSTANDING);
    $finish;
  end

  initial begin
    integer i;
    integer caller;
    integer prior;
    integer candidate;
    integer responses_sent;
    reg blocked;
    reg [1:0] response_code;
    wait (ARESETn === 1'b1);
    wait_counts(MAX_OUTSTANDING);
    repeat (2) @(posedge ACLK);
    if (aw_count != MAX_OUTSTANDING || w_count != MAX_OUTSTANDING)
      $fatal(1, "manager exceeded MAX_OUTSTANDING=%0d before a response",
             MAX_OUTSTANDING);
    responses_sent = 0;
    while (responses_sent < 5) begin
      if ((aw_count > responses_sent) && (w_count > responses_sent)) begin
        candidate = -1;
        for (i = 0; i < aw_count; i = i + 1) begin
          if (!response_sent[i]) begin
            blocked = 0;
            for (prior = 0; prior < i; prior = prior + 1)
              if (!response_sent[prior] && accepted_id[prior] == accepted_id[i])
                blocked = 1;
            if (!blocked) candidate = i;
          end
        end
        if (candidate < 0) $fatal(1, "no eligible outstanding BID response");
        caller = caller_for_awuser(accepted_awuser[candidate]);
        response_code = caller == 3 ? 2'b10 : ((candidate % 2) ? 2'b01 : 2'b00);
        send_response(candidate, response_code);
        response_sent[candidate] = 1;
        responses_sent = responses_sent + 1;
      end else begin
        @(posedge ACLK);
      end
    end
  end

  initial begin
    repeat (256) @(posedge ACLK);
    $fatal(1, "write outstanding regression timed out");
  end
endmodule
