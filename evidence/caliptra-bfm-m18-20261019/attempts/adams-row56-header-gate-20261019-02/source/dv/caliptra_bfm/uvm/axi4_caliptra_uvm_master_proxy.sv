// SPDX-License-Identifier: Apache-2.0
// Bridges bounded UVM command slots to the task-based pin-level AXI manager.
module axi4_caliptra_uvm_master_proxy #(
  parameter integer ADDR_WIDTH = 48,
  parameter integer DATA_WIDTH = 32,
  parameter integer ID_WIDTH = 8,
  parameter integer USER_WIDTH = 32,
  parameter integer MAX_BEATS = 256,
  parameter integer MAX_OUTSTANDING = 4,
  parameter integer TIMEOUT_CYCLES = 1024
) (
  axi4_caliptra_master_cmd_if cmd_if,
  input wire ACLK,
  input wire ARESETn,
  output wire [ID_WIDTH-1:0] AWID,
  output wire [ADDR_WIDTH-1:0] AWADDR,
  output wire [7:0] AWLEN,
  output wire [2:0] AWSIZE,
  output wire [1:0] AWBURST,
  output wire AWLOCK,
  output wire [USER_WIDTH-1:0] AWUSER,
  output wire AWVALID,
  input wire AWREADY,
  output wire [DATA_WIDTH-1:0] WDATA,
  output wire [DATA_WIDTH/8-1:0] WSTRB,
  output wire [USER_WIDTH-1:0] WUSER,
  output wire WLAST,
  output wire WVALID,
  input wire WREADY,
  input wire [ID_WIDTH-1:0] BID,
  input wire [1:0] BRESP,
  input wire [USER_WIDTH-1:0] BUSER,
  input wire BVALID,
  output wire BREADY,
  output wire [ID_WIDTH-1:0] ARID,
  output wire [ADDR_WIDTH-1:0] ARADDR,
  output wire [7:0] ARLEN,
  output wire [2:0] ARSIZE,
  output wire [1:0] ARBURST,
  output wire ARLOCK,
  output wire [USER_WIDTH-1:0] ARUSER,
  output wire ARVALID,
  input wire ARREADY,
  input wire [ID_WIDTH-1:0] RID,
  input wire [DATA_WIDTH-1:0] RDATA,
  input wire [1:0] RRESP,
  input wire [USER_WIDTH-1:0] RUSER,
  input wire RLAST,
  input wire RVALID,
  output wire RREADY
);
  reg [ID_WIDTH-1:0] write_response_id;
  reg [ID_WIDTH-1:0] read_response_id;

  axi4_caliptra_master #(
    .ADDR_WIDTH(ADDR_WIDTH), .DATA_WIDTH(DATA_WIDTH), .ID_WIDTH(ID_WIDTH),
    .USER_WIDTH(USER_WIDTH), .MAX_BEATS(MAX_BEATS),
    .MAX_OUTSTANDING(MAX_OUTSTANDING), .TIMEOUT_CYCLES(TIMEOUT_CYCLES)
  ) pin_manager (
    .ACLK(ACLK), .ARESETn(ARESETn),
    .AWID(AWID), .AWADDR(AWADDR), .AWLEN(AWLEN), .AWSIZE(AWSIZE),
    .AWBURST(AWBURST), .AWLOCK(AWLOCK), .AWUSER(AWUSER), .AWVALID(AWVALID),
    .AWREADY(AWREADY), .WDATA(WDATA), .WSTRB(WSTRB), .WUSER(WUSER),
    .WLAST(WLAST), .WVALID(WVALID), .WREADY(WREADY), .BID(BID),
    .BRESP(BRESP), .BUSER(BUSER), .BVALID(BVALID), .BREADY(BREADY),
    .ARID(ARID), .ARADDR(ARADDR), .ARLEN(ARLEN), .ARSIZE(ARSIZE),
    .ARBURST(ARBURST), .ARLOCK(ARLOCK), .ARUSER(ARUSER), .ARVALID(ARVALID),
    .ARREADY(ARREADY), .RID(RID), .RDATA(RDATA), .RRESP(RRESP),
    .RUSER(RUSER), .RLAST(RLAST), .RVALID(RVALID), .RREADY(RREADY),
    .write_response_id(write_response_id), .read_response_id(read_response_id)
  );

  genvar slot;
  generate
    for (slot = 0; slot < MAX_OUTSTANDING; slot = slot + 1) begin : gen_command_slot
      reg request_write_q;
      reg [ADDR_WIDTH-1:0] request_addr_q;
      reg [7:0] request_len_q;
      reg [2:0] request_size_q;
      reg [1:0] request_burst_q;
      reg [ID_WIDTH-1:0] request_id_q;
      reg [USER_WIDTH-1:0] request_user_q;
      reg request_lock_q;
      reg [DATA_WIDTH*MAX_BEATS-1:0] request_write_data_q;
      reg [(DATA_WIDTH/8)*MAX_BEATS-1:0] request_write_strb_q;
      reg [USER_WIDTH*MAX_BEATS-1:0] request_write_user_q;
      reg response_success_q;
      reg [1:0] response_code_q;
      reg [USER_WIDTH-1:0] response_user_q;
      reg [DATA_WIDTH*MAX_BEATS-1:0] response_read_data_q;
      reg [USER_WIDTH*MAX_BEATS-1:0] response_read_user_q;
      reg [2*MAX_BEATS-1:0] response_read_code_q;

      initial begin
        cmd_if.request_ack[slot] = 1'b0;
        cmd_if.response_valid[slot] = 1'b0;
        forever begin
          wait (cmd_if.request_valid[slot] === 1'b1);
          request_write_q = cmd_if.request_write[slot];
          request_addr_q = cmd_if.request_addr[slot];
          request_len_q = cmd_if.request_len[slot];
          request_size_q = cmd_if.request_size[slot];
          request_burst_q = cmd_if.request_burst[slot];
          request_id_q = cmd_if.request_id[slot];
          request_user_q = cmd_if.request_user[slot];
          request_lock_q = cmd_if.request_lock[slot];
          request_write_data_q = cmd_if.request_write_data[slot];
          request_write_strb_q = cmd_if.request_write_strb[slot];
          request_write_user_q = cmd_if.request_write_user[slot];
          cmd_if.request_ack[slot] = 1'b1;
          wait (cmd_if.request_valid[slot] === 1'b0);
          cmd_if.request_ack[slot] = 1'b0;

          if (request_write_q) begin
            pin_manager.write_burst(
              request_addr_q, request_len_q, request_size_q, request_burst_q,
              request_id_q, request_user_q, request_lock_q,
              request_write_data_q, request_write_strb_q, request_write_user_q,
              response_success_q, response_code_q, response_user_q);
            cmd_if.response_read_data[slot] = '0;
            cmd_if.response_read_user[slot] = '0;
            cmd_if.response_read_code[slot] = '0;
          end else begin
            pin_manager.read_burst(
              request_addr_q, request_len_q, request_size_q, request_burst_q,
              request_id_q, request_user_q, request_lock_q, response_success_q,
              response_read_data_q, response_read_user_q, response_read_code_q,
              response_user_q);
            response_code_q = response_read_code_q[1:0];
            cmd_if.response_read_data[slot] = response_read_data_q;
            cmd_if.response_read_user[slot] = response_read_user_q;
            cmd_if.response_read_code[slot] = response_read_code_q;
          end
          cmd_if.response_success[slot] = response_success_q;
          cmd_if.response_id[slot] = request_id_q;
          cmd_if.response_code[slot] = response_code_q;
          cmd_if.response_user[slot] = response_user_q;
          cmd_if.response_valid[slot] = 1'b1;
          wait (cmd_if.response_ready[slot] === 1'b1);
          cmd_if.response_valid[slot] = 1'b0;
          wait (cmd_if.response_ready[slot] === 1'b0);
        end
      end
    end
  endgenerate
endmodule
