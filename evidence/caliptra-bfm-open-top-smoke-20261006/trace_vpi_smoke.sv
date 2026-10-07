module caliptra_trace_dut;
  logic trace_rv_i_valid_ip = 1'b0;
  logic [31:0] trace_rv_i_address_ip = '0;
  logic [31:0] trace_rv_i_insn_ip = '0;
endmodule

module caliptra_trace_services;
  logic [7:0] WriteData = '0;
  logic mailbox_write = 1'b0;
  logic prandom_warm_rst = 1'b0;
  integer wait_time_to_rst = 0;
  integer rst_cyclecnt = 0;
  logic assert_rst_flag = 1'b0;
  logic deassert_rst_flag = 1'b0;
endmodule

module caliptra_trace_axi_if;
  logic arvalid = 1'b0;
  logic arready = 1'b0;
  logic [47:0] araddr = '0;
  logic rvalid = 1'b0;
  logic rready = 1'b0;
  logic awvalid = 1'b0;
  logic awready = 1'b0;
  logic [47:0] awaddr = '0;
  logic wvalid = 1'b0;
  logic wready = 1'b0;
  logic bvalid = 1'b0;
  logic bready = 1'b0;
endmodule

module caliptra_top_tb;
  logic core_clk = 1'b0;
  logic ready_for_mb_processing = 1'b0;
  logic cptra_rst_b = 1'b1;
  logic cptra_error_fatal = 1'b0;

  caliptra_trace_dut caliptra_top_dut();
  caliptra_trace_services tb_services_i();
  caliptra_trace_axi_if m_axi_if();

  always #5 core_clk = ~core_clk;

  initial begin
    @(negedge core_clk);
    tb_services_i.WriteData = 8'hee;
    tb_services_i.mailbox_write = 1'b1;
    @(negedge core_clk);
    tb_services_i.mailbox_write = 1'b0;
    tb_services_i.prandom_warm_rst = 1'b1;
    tb_services_i.wait_time_to_rst = 2;
    tb_services_i.rst_cyclecnt = 3;
    @(negedge core_clk);
    cptra_rst_b = 1'b0;
    tb_services_i.assert_rst_flag = 1'b1;
    @(negedge core_clk);
    cptra_rst_b = 1'b1;
    tb_services_i.assert_rst_flag = 1'b0;
    tb_services_i.deassert_rst_flag = 1'b1;
    tb_services_i.prandom_warm_rst = 1'b0;
    @(negedge core_clk);
    caliptra_top_dut.trace_rv_i_valid_ip = 1'b1;
    caliptra_top_dut.trace_rv_i_address_ip = 32'h0000_1234;
    caliptra_top_dut.trace_rv_i_insn_ip = 32'h00c5_0513;
    m_axi_if.awvalid = 1'b1;
    m_axi_if.awready = 1'b1;
    m_axi_if.awaddr = 48'h0000_0000_1234;
    @(negedge core_clk);
    caliptra_top_dut.trace_rv_i_valid_ip = 1'b0;
    m_axi_if.awvalid = 1'b0;
    m_axi_if.awready = 1'b0;
    #1 $finish;
  end
endmodule
