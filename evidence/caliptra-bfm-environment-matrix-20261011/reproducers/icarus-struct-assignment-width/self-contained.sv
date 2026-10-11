typedef enum logic [1:0] {RW_IDLE = 2'b00, RW_READ = 2'b01} mode_t;
typedef struct packed { mode_t rd_wr_en; logic [13:0] addr; } mem_if_t;
module probe(input logic clk, reset_n, enable, output mem_if_t bad, good);
  logic [13:0] locked_src_addr = 0;
  logic [31:0] num_mem_operands = 2;
  always_ff @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      bad <= '{rd_wr_en: RW_IDLE, addr: '0};
      good <= '{rd_wr_en: RW_IDLE, addr: '0};
    end else if (enable) begin
      bad <= '{rd_wr_en: RW_READ, addr: locked_src_addr + num_mem_operands};
      good <= '{rd_wr_en: RW_READ, addr: 14'(locked_src_addr + num_mem_operands)};
    end
  end
endmodule
module tb;
  logic clk=0, reset_n=0, enable=0;
  mem_if_t bad, good;
  probe dut(.*);
  always #5 clk=~clk;
  initial begin
    @(negedge clk); reset_n=1; enable=1;
    @(negedge clk); #1;
    $display("RESULT bad=%h bad_en=%b bad_addr=%h good=%h good_en=%b good_addr=%h", bad, bad.rd_wr_en, bad.addr, good, good.rd_wr_en, good.addr);
    $finish;
  end
endmodule
