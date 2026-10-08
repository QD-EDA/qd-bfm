// SPDX-License-Identifier: Apache-2.0
`timescale 1ns/1ps

module tb_axi4_caliptra_transaction_monitor;
  localparam integer ADDR_WIDTH = 48;
  localparam integer DATA_WIDTH = 32;
  localparam integer ID_WIDTH = 8;
  localparam integer USER_WIDTH = 32;
  localparam integer MAX_BEATS = 4;

  reg ACLK = 0;
  reg ARESETn = 0;
  reg [ID_WIDTH-1:0] AWID = 0;
  reg [ADDR_WIDTH-1:0] AWADDR = 0;
  reg [7:0] AWLEN = 0;
  reg [2:0] AWSIZE = 2;
  reg [1:0] AWBURST = 1;
  reg AWLOCK = 0;
  reg [USER_WIDTH-1:0] AWUSER = 0;
  reg AWVALID = 0;
  reg AWREADY = 1;
  reg [DATA_WIDTH-1:0] WDATA = 0;
  reg [DATA_WIDTH/8-1:0] WSTRB = 0;
  reg [USER_WIDTH-1:0] WUSER = 0;
  reg WLAST = 0;
  reg WVALID = 0;
  reg WREADY = 1;
  reg [ID_WIDTH-1:0] BID = 0;
  reg [1:0] BRESP = 0;
  reg [USER_WIDTH-1:0] BUSER = 0;
  reg BVALID = 0;
  reg BREADY = 1;
  reg [ID_WIDTH-1:0] ARID = 0;
  reg [ADDR_WIDTH-1:0] ARADDR = 0;
  reg [7:0] ARLEN = 0;
  reg [2:0] ARSIZE = 2;
  reg [1:0] ARBURST = 1;
  reg ARLOCK = 0;
  reg [USER_WIDTH-1:0] ARUSER = 0;
  reg ARVALID = 0;
  reg ARREADY = 1;
  reg [ID_WIDTH-1:0] RID = 0;
  reg [DATA_WIDTH-1:0] RDATA = 0;
  reg [1:0] RRESP = 0;
  reg [USER_WIDTH-1:0] RUSER = 0;
  reg RLAST = 0;
  reg RVALID = 0;
  reg RREADY = 1;
  integer context_index;

  wire [63:0] cycle_count;
  wire write_complete;
  wire write_request_complete;
  wire write_request_error;
  wire [3:0] write_request_status;
  wire [ID_WIDTH-1:0] write_request_id;
  wire [ADDR_WIDTH-1:0] write_request_addr;
  wire [8:0] write_request_beat_count;
  wire [MAX_BEATS*DATA_WIDTH-1:0] write_request_data;
  wire write_error;
  wire [3:0] write_error_code;
  wire [3:0] write_status;
  wire [63:0] write_cycle;
  wire [ID_WIDTH-1:0] write_id;
  wire [ADDR_WIDTH-1:0] write_addr;
  wire [7:0] write_len;
  wire [2:0] write_size;
  wire [1:0] write_burst;
  wire write_lock;
  wire [USER_WIDTH-1:0] write_awuser;
  wire [8:0] write_beat_count;
  wire [MAX_BEATS*DATA_WIDTH-1:0] write_data;
  wire [MAX_BEATS*(DATA_WIDTH/8)-1:0] write_strb;
  wire [MAX_BEATS*USER_WIDTH-1:0] write_wuser;
  wire [MAX_BEATS-1:0] write_last_mask;
  wire [ID_WIDTH-1:0] write_response_id;
  wire [1:0] write_response;
  wire [USER_WIDTH-1:0] write_buser;
  wire read_complete;
  wire read_error;
  wire [3:0] read_error_code;
  wire [3:0] read_status;
  wire [63:0] read_cycle;
  wire [ID_WIDTH-1:0] read_id;
  wire [ADDR_WIDTH-1:0] read_addr;
  wire [7:0] read_len;
  wire [2:0] read_size;
  wire [1:0] read_burst;
  wire read_lock;
  wire [USER_WIDTH-1:0] read_aruser;
  wire [8:0] read_beat_count;
  wire [MAX_BEATS*DATA_WIDTH-1:0] read_data;
  wire [MAX_BEATS*2-1:0] read_resp;
  wire [MAX_BEATS*USER_WIDTH-1:0] read_ruser;
  wire [MAX_BEATS-1:0] read_last_mask;

  always #5 ACLK = ~ACLK;

  task automatic send_aw(input [7:0] id, input [47:0] addr,
                         input [7:0] len, input [31:0] user);
    begin
      @(negedge ACLK);
      AWID = id;
      AWADDR = addr;
      AWLEN = len;
      AWUSER = user;
      AWVALID = 1;
      @(posedge ACLK);
      @(negedge ACLK);
      AWVALID = 0;
    end
  endtask

  task automatic send_b(input [7:0] id, input [1:0] resp,
                        input [31:0] user);
    begin
      @(negedge ACLK);
      BID = id;
      BRESP = resp;
      BUSER = user;
      BVALID = 1;
      @(posedge ACLK);
      @(negedge ACLK);
      BVALID = 0;
    end
  endtask

  axi4_caliptra_transaction_monitor #(
    .ADDR_WIDTH(ADDR_WIDTH), .DATA_WIDTH(DATA_WIDTH), .ID_WIDTH(ID_WIDTH),
    .USER_WIDTH(USER_WIDTH), .MAX_BEATS(MAX_BEATS)
  ) dut (
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
    .RREADY(RREADY), .cycle_count(cycle_count),
    .write_complete(write_complete),
    .write_request_complete(write_request_complete),
    .write_request_error(write_request_error),
    .write_request_status(write_request_status),
    .write_request_id(write_request_id), .write_request_addr(write_request_addr),
    .write_request_beat_count(write_request_beat_count),
    .write_request_data(write_request_data),
    .write_error(write_error),
    .write_error_code(write_error_code), .write_status(write_status),
    .write_cycle(write_cycle), .write_id(write_id), .write_addr(write_addr),
    .write_len(write_len), .write_size(write_size), .write_burst(write_burst),
    .write_lock(write_lock), .write_awuser(write_awuser),
    .write_beat_count(write_beat_count), .write_data(write_data),
    .write_strb(write_strb), .write_wuser(write_wuser),
    .write_last_mask(write_last_mask), .write_response_id(write_response_id),
    .write_response(write_response), .write_buser(write_buser),
    .read_complete(read_complete), .read_error(read_error),
    .read_error_code(read_error_code), .read_status(read_status),
    .read_cycle(read_cycle), .read_id(read_id), .read_addr(read_addr),
    .read_len(read_len), .read_size(read_size), .read_burst(read_burst),
    .read_lock(read_lock), .read_aruser(read_aruser),
    .read_beat_count(read_beat_count), .read_data(read_data),
    .read_resp(read_resp), .read_ruser(read_ruser),
    .read_last_mask(read_last_mask)
  );

  task automatic send_w(input [31:0] data, input [3:0] strb,
                        input [31:0] user, input reg last);
    begin
      @(negedge ACLK);
      WDATA = data;
      WSTRB = strb;
      WUSER = user;
      WLAST = last;
      WVALID = 1;
      @(posedge ACLK);
      @(negedge ACLK);
      WVALID = 0;
    end
  endtask

  task automatic send_r(input [31:0] data, input [1:0] resp,
                        input [31:0] user, input reg last);
    begin
      @(negedge ACLK);
      RDATA = data;
      RRESP = resp;
      RUSER = user;
      RLAST = last;
      RVALID = 1;
      @(posedge ACLK);
      @(negedge ACLK);
      RVALID = 0;
    end
  endtask

  initial begin
    repeat (2) @(posedge ACLK);
    @(negedge ACLK);
    ARESETn = 1;

    // Exercise W-before-AW buffering, then verify the completed flattened record.
    send_w(32'h1122_3344, 4'hf, 32'h101, 1'b0);
    send_w(32'h5566_7788, 4'h3, 32'h202, 1'b1);
    @(negedge ACLK);
    AWID = 8'h2a;
    AWADDR = 48'h0000_1234_0000;
    AWLEN = 1;
    AWLOCK = 1;
    AWUSER = 32'hface_cafe;
    AWVALID = 1;
    @(posedge ACLK);
    @(negedge ACLK);
    AWVALID = 0;
    #1;
    if (!write_request_complete || write_complete ||
        write_request_id != 8'h2a ||
        write_request_addr != 48'h0000_1234_0000 ||
        write_request_beat_count != 2 ||
        write_request_data[63:0] != 64'h5566_7788_1122_3344)
      $fatal(1, "W-before-AW request event missing or malformed");
    BID = AWID;
    BRESP = 2'b10;
    BUSER = 32'hb000_0001;
    BVALID = 1;
    @(posedge ACLK);
    @(negedge ACLK);
    BVALID = 0;
    #1;
    if (!write_complete || write_error || write_status != 0 ||
        write_id != 8'h2a || write_addr != 48'h0000_1234_0000 ||
        write_beat_count != 2 || write_data[63:0] != 64'h5566_7788_1122_3344 ||
        write_strb[7:0] != 8'h3f || write_wuser[63:0] != 64'h0000_0202_0000_0101 ||
        write_last_mask[1:0] != 2'b10 || write_response_id != 8'h2a ||
        write_response != 2'b10 || write_buser != 32'hb000_0001 ||
        !write_lock || write_awuser != 32'hface_cafe)
      $fatal(1, "Completed write record mismatch");

    // Two complete W frames may precede their AWs; pair them in channel order.
    send_w(32'h2a00_0001, 4'hf, 32'h2a01, 1'b1);
    send_w(32'h2b00_0002, 4'h3, 32'h2b02, 1'b1);
    if (write_error)
      $fatal(1, "Second legal W-before-AW frame was rejected");
    send_aw(8'h2b, 48'h0000_1250_0000, 0, 32'h2b00_0001);
    if (!write_request_complete || write_request_error || write_request_status != 0 ||
        write_request_id != 8'h2b || write_request_data[31:0] != 32'h2a00_0001)
      $fatal(1, "First queued W-before-AW frame did not pair with the first AW");
    send_aw(8'h2c, 48'h0000_1260_0000, 0, 32'h2c00_0002);
    if (!write_request_complete || write_request_error || write_request_status != 0 ||
        write_request_id != 8'h2c || write_request_data[31:0] != 32'h2b00_0002)
      $fatal(1, "Second queued W-before-AW frame did not pair with the second AW");
    send_b(8'h2c, 2'b00, 32'hb000_002c);
    if (!write_complete || write_error || write_id != 8'h2c ||
        write_data[31:0] != 32'h2b00_0002)
      $fatal(1, "Second queued W-before-AW response was not retained");
    send_b(8'h2b, 2'b00, 32'hb000_002b);
    if (!write_complete || write_error || write_id != 8'h2b ||
        write_data[31:0] != 32'h2a00_0001)
      $fatal(1, "First queued W-before-AW response was not retained");

    // AW may arrive in the middle of a W-before-AW frame.
    send_w(32'h2d00_0001, 4'hf, 32'h2d01, 1'b0);
    send_aw(8'h2d, 48'h0000_1270_0000, 1, 32'h2d00_0001);
    if (write_request_complete)
      $fatal(1, "Partial W-before-AW frame completed before its final beat");
    send_w(32'h2d00_0002, 4'h3, 32'h2d02, 1'b1);
    if (!write_request_complete || write_request_error || write_request_status != 0 ||
        write_request_id != 8'h2d || write_request_beat_count != 2 ||
        write_request_data[63:0] != 64'h2d00_0002_2d00_0001)
      $fatal(1, "Partial W-before-AW frame did not resume after AW");
    send_b(8'h2d, 2'b00, 32'hb000_002d);
    if (!write_complete || write_error || write_id != 8'h2d)
      $fatal(1, "Partial W-before-AW response was not retained");

    // A first AW and its first W beat may handshake on the same edge.
    @(negedge ACLK);
    AWID = 8'h2e;
    AWADDR = 48'h0000_1280_0000;
    AWLEN = 0;
    AWUSER = 32'h2e00_0001;
    AWVALID = 1;
    WDATA = 32'h2e00_0002;
    WSTRB = 4'hf;
    WUSER = 32'h2e02;
    WLAST = 1;
    WVALID = 1;
    @(posedge ACLK);
    @(negedge ACLK);
    AWVALID = 0;
    WVALID = 0;
    #1;
    if (!write_request_complete || write_request_error || write_request_id != 8'h2e ||
        write_request_data[31:0] != 32'h2e00_0002)
      $fatal(1, "Simultaneous AW/W handshake was not captured");
    send_b(8'h2e, 2'b00, 32'hb000_002e);
    if (!write_complete || write_error || write_id != 8'h2e)
      $fatal(1, "Simultaneous AW/W response was not retained");

    // A two-beat read record preserves response, USER, and terminal markers.
    @(negedge ACLK);
    ARID = 8'h35;
    ARADDR = 48'h0000_4321_0000;
    ARLEN = 1;
    ARUSER = 32'h1234_5678;
    ARVALID = 1;
    @(posedge ACLK);
    @(negedge ACLK);
    ARVALID = 0;
    RID = ARID;
    send_r(32'hdead_beef, 2'b00, 32'h1111_0001, 1'b0);
    send_r(32'hcafe_babe, 2'b10, 32'h2222_0002, 1'b1);
    #1;
    if (!read_complete || read_error || read_status != 0 ||
        read_id != 8'h35 || read_addr != 48'h0000_4321_0000 ||
        read_beat_count != 2 || read_data[63:0] != 64'hcafe_babe_dead_beef ||
        read_resp[3:0] != 4'b1000 ||
        read_ruser[63:0] != 64'h2222_0002_1111_0001 ||
        read_last_mask[1:0] != 2'b10 || read_aruser != 32'h1234_5678)
      $fatal(1, "Completed read record mismatch");

    // A mismatched B ID is retained and marked with the monitor's ID status.
    @(negedge ACLK);
    AWID = 8'h41;
    AWADDR = 48'h0000_8000;
    AWLEN = 0;
    AWVALID = 1;
    @(posedge ACLK);
    @(negedge ACLK);
    AWVALID = 0;
    send_w(32'h0102_0304, 4'hf, 32'h0, 1'b1);
    BID = 8'h42;
    BVALID = 1;
    @(posedge ACLK);
    @(negedge ACLK);
    BVALID = 0;
    #1;
    if (!write_complete || !write_error || write_status != 3 ||
        write_error_code != 3 || write_id != 8'h41 || write_response_id != 8'h42)
      $fatal(1, "Mismatched write response ID was not marked");

    // AW contexts retain their data independently; different IDs may return B out of order.
    send_aw(8'h71, 48'h0000_a100, 1, 32'h7100_0001);
    send_aw(8'h72, 48'h0000_a200, 0, 32'h7200_0002);
    send_w(32'h7100_0001, 4'hf, 32'h7101, 1'b0);
    send_w(32'h7100_0002, 4'h3, 32'h7102, 1'b1);
    send_w(32'h7200_0001, 4'hc, 32'h7201, 1'b1);
    send_b(8'h72, 2'b00, 32'hb000_0072);
    #1;
    if (!write_complete || write_error || write_status != 0 ||
        write_id != 8'h72 || write_addr != 48'h0000_a200 ||
        write_awuser != 32'h7200_0002 || write_beat_count != 1 ||
        write_data[31:0] != 32'h7200_0001 || write_strb[3:0] != 4'hc ||
        write_wuser[31:0] != 32'h7201 || write_last_mask[0] != 1'b1 ||
        write_response_id != 8'h72 || write_buser != 32'hb000_0072)
      $fatal(1, "Out-of-order write response did not select the matching context");
    send_b(8'h71, 2'b10, 32'hb000_0071);
    #1;
    if (!write_complete || write_error || write_status != 0 ||
        write_id != 8'h71 || write_addr != 48'h0000_a100 ||
        write_beat_count != 2 || write_data[63:0] != 64'h7100_0002_7100_0001 ||
        write_strb[7:0] != 8'h3f || write_wuser[63:0] != 64'h0000_7102_0000_7101 ||
        write_last_mask[1:0] != 2'b10 || write_response_id != 8'h71)
      $fatal(1, "Interleaved write context was not preserved");

    // Responses sharing one ID retire in AW acceptance order.
    send_aw(8'h73, 48'h0000_a300, 0, 32'h7300_0001);
    send_aw(8'h73, 48'h0000_a400, 0, 32'h7300_0002);
    send_w(32'h7300_0001, 4'hf, 32'h7301, 1'b1);
    send_w(32'h7300_0002, 4'hf, 32'h7302, 1'b1);
    send_b(8'h73, 2'b00, 32'hb000_0073);
    #1;
    if (!write_complete || write_error || write_id != 8'h73 ||
        write_addr != 48'h0000_a300 || write_data[31:0] != 32'h7300_0001)
      $fatal(1, "Same-ID write response did not retire the older request first");
    send_b(8'h73, 2'b00, 32'hb000_0073);
    #1;
    if (!write_complete || write_error || write_id != 8'h73 ||
        write_addr != 48'h0000_a400 || write_data[31:0] != 32'h7300_0002)
      $fatal(1, "Second same-ID write context was not retained");

    // Early terminal read beat records a framing error while still completing.
    @(negedge ACLK);
    ARID = 8'h52;
    ARADDR = 48'h0000_9000;
    ARLEN = 1;
    ARVALID = 1;
    @(posedge ACLK);
    @(negedge ACLK);
    ARVALID = 0;
    RID = ARID;
    send_r(32'h7654_3210, 2'b00, 32'h0, 1'b1);
    #1;
    if (!read_complete || !read_error || read_status != 1 ||
        read_error_code != 1 || read_beat_count != 1 || read_last_mask[0] != 1'b1)
      $fatal(1, "Early RLAST was not marked as a shape error");

    // Track two outstanding read IDs and allow their responses to complete out of order.
    @(negedge ACLK);
    ARID = 8'h61;
    ARADDR = 48'h0000_a000;
    ARLEN = 1;
    ARUSER = 32'h6100_0001;
    ARVALID = 1;
    @(posedge ACLK);
    @(negedge ACLK);
    ARID = 8'h62;
    ARADDR = 48'h0000_b000;
    ARLEN = 1;
    ARUSER = 32'h6200_0002;
    ARVALID = 1;
    @(posedge ACLK);
    @(negedge ACLK);
    ARVALID = 0;

    RID = 8'h61;
    send_r(32'h6161_0001, 2'b00, 32'h6100_0001, 1'b0);
    if (read_complete)
      $fatal(1, "Nonterminal read beat completed a transaction");
    RID = 8'h62;
    send_r(32'h6262_0001, 2'b00, 32'h6200_0001, 1'b0);
    send_r(32'h6262_0002, 2'b10, 32'h6200_0002, 1'b1);
    #1;
    if (!read_complete || read_error || read_status != 0 ||
        read_id != 8'h62 || read_addr != 48'h0000_b000 ||
        read_beat_count != 2 || read_data[63:0] != 64'h6262_0002_6262_0001 ||
        read_resp[3:0] != 4'b1000 || read_ruser[63:0] != 64'h6200_0002_6200_0001 ||
        read_last_mask[1:0] != 2'b10 || read_aruser != 32'h6200_0002)
      $fatal(1, "Out-of-order read response did not complete the matching ID");

    RID = 8'h61;
    send_r(32'h6161_0002, 2'b10, 32'h6100_0002, 1'b1);
    #1;
    if (!read_complete || read_error || read_status != 0 ||
        read_id != 8'h61 || read_addr != 48'h0000_a000 ||
        read_beat_count != 2 || read_data[63:0] != 64'h6161_0002_6161_0001 ||
        read_resp[3:0] != 4'b1000 || read_aruser != 32'h6100_0001)
      $fatal(1, "Interleaved read context was not preserved");

    // Multiple requests with one ID retire in their original AXI order.
    @(negedge ACLK);
    ARID = 8'h63;
    ARADDR = 48'h0000_c000;
    ARLEN = 0;
    ARVALID = 1;
    @(posedge ACLK);
    @(negedge ACLK);
    ARADDR = 48'h0000_d000;
    ARVALID = 1;
    @(posedge ACLK);
    @(negedge ACLK);
    ARVALID = 0;
    RID = 8'h63;
    send_r(32'h6363_0001, 2'b00, 32'h0, 1'b1);
    #1;
    if (!read_complete || read_error || read_id != 8'h63 ||
        read_addr != 48'h0000_c000 || read_data[31:0] != 32'h6363_0001)
      $fatal(1, "Same-ID read response did not retire the older request first");
    send_r(32'h6363_0002, 2'b00, 32'h0, 1'b1);
    #1;
    if (!read_complete || read_error || read_id != 8'h63 ||
        read_addr != 48'h0000_d000 || read_data[31:0] != 32'h6363_0002)
      $fatal(1, "Second same-ID read context was not retained");

    // The configured context bound reports overflow instead of aliasing a live read.
    for (context_index = 0; context_index < 8; context_index = context_index + 1) begin
      @(negedge ACLK);
      ARID = 8'h70 + context_index;
      ARADDR = 48'h0000_e000 + (context_index * 4);
      ARLEN = 0;
      ARVALID = 1;
      @(posedge ACLK);
    end
    @(negedge ACLK);
    ARID = 8'h78;
    ARADDR = 48'h0000_f000;
    ARVALID = 1;
    @(posedge ACLK);
    @(negedge ACLK);
    ARVALID = 0;
    #1;
    if (!read_error || read_error_code != 2)
      $fatal(1, "Read context capacity overflow was not reported");

    // The write-side outstanding-context bound reports overflow as well.
    for (context_index = 0; context_index < 8; context_index = context_index + 1)
      send_aw(8'h80 + context_index, 48'h0001_0000 + (context_index * 4),
              0, 32'h8000_0000 + context_index);
    send_aw(8'h88, 48'h0001_1000, 0, 32'h8800_0000);
    #1;
    if (!write_error || write_error_code != 2 || write_complete)
      $fatal(1, "Write context capacity overflow was not reported");

    // W-before-AW storage is bounded too; overflow must not alias a live slot.
    @(negedge ACLK);
    ARESETn = 0;
    repeat (2) @(posedge ACLK);
    @(negedge ACLK);
    ARESETn = 1;
    for (context_index = 0; context_index < 8; context_index = context_index + 1)
      send_w(32'h9000_0000 + context_index, 4'hf,
             32'h9000_0000 + context_index, 1'b1);
    send_w(32'h9000_0008, 4'hf, 32'h9000_0008, 1'b1);
    if (!write_error || write_error_code != 2)
      $fatal(1, "W-before-AW context capacity overflow was not reported");
    send_aw(8'h90, 48'h0002_0000, 0, 32'h9000_0000);
    if (!write_error || write_error_code != 2 || write_request_complete)
      $fatal(1, "W-before-AW overflow did not stop write pairing");

    $display("PASS: AXI records, W-before-AW, concurrent reads/writes, and capacity/error checks");
    $finish;
  end
endmodule
