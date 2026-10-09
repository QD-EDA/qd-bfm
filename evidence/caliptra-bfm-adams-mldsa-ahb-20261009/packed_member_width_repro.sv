package p;
  typedef enum logic [1:0] {RW_IDLE=2'b00, RW_READ=2'b01, RW_WRITE=2'b10} rw_e;
  typedef struct packed {rw_e rd_wr_en; logic [14:0] addr;} mem_if_t;
endpackage

module request_gen #(
  parameter bit SIZE_ADDRESS = 0
) (
  input logic clk,
  input logic [2:0] state,
  output p::mem_if_t req
);
  import p::*;
  logic [31:0] num_mem_operands = 0;
  logic [14:0] locked_src_addr = 0;

  always_ff @(posedge clk) begin
    if (state == 3'd1) begin
      if (SIZE_ADDRESS)
        req <= '{rd_wr_en: RW_READ, addr: 15'(locked_src_addr + num_mem_operands)};
      else
        req <= '{rd_wr_en: RW_READ, addr: locked_src_addr + num_mem_operands};
    end else if (state == 3'd2) begin
      if (SIZE_ADDRESS)
        req <= '{rd_wr_en: RW_READ, addr: 15'(locked_src_addr + num_mem_operands + 1)};
      else
        req <= '{rd_wr_en: RW_READ, addr: locked_src_addr + num_mem_operands + 1};
    end else begin
      req <= '{rd_wr_en: RW_IDLE, addr: '0};
    end
  end
endmodule

module top;
  import p::*;
  logic clk = 0;
  logic [2:0] state = 0;
  mem_if_t raw_req, sized_req;

  request_gen #(.SIZE_ADDRESS(0)) raw(.clk, .state, .req(raw_req));
  request_gen #(.SIZE_ADDRESS(1)) sized(.clk, .state, .req(sized_req));
  always #5 clk = ~clk;

  initial begin
    #7 state = 1;
    #10 state = 2;
    #10 $display("raw_en=%0d raw_addr=%0d sized_en=%0d sized_addr=%0d",
                 raw_req.rd_wr_en, raw_req.addr, sized_req.rd_wr_en, sized_req.addr);
    $finish;
  end
endmodule
