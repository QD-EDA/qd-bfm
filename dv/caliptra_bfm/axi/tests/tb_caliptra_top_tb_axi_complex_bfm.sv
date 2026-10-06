// SPDX-License-Identifier: Apache-2.0
`timescale 1ns/1ps

module tb_caliptra_top_tb_axi_complex_bfm;
  localparam [47:0] SRAM_BASE = 48'h0001_2344_0000;
  localparam [47:0] FIFO_BASE = 48'h0000_fa57_0000;
  reg core_clk = 0;
  reg cptra_rst_b = 0;
  reg axi_error_inj_en = 1;
  wire recovery_data_avail;
  caliptra_top_tb_pkg::axi_complex_ctrl_t ctrl = '0;
  axi_if #(.AW(48), .DW(32), .IW(5), .UW(32)) m_axi_if
      (.clk(core_clk), .rst_n(cptra_rst_b));
  integer timeout;
  reg [31:0] read_data;
  reg [1:0] read_resp;
  reg [1:0] write_resp;

  always #5 core_clk = ~core_clk;

  caliptra_top_tb_axi_complex dut (
    .core_clk(core_clk),
    .cptra_rst_b(cptra_rst_b),
    .m_axi_if(m_axi_if),
    .recovery_data_avail(recovery_data_avail),
    .ctrl(ctrl),
    .axi_error_inj_en(axi_error_inj_en)
  );

  task automatic init_manager;
    begin
      m_axi_if.araddr = 0; m_axi_if.arburst = 0; m_axi_if.arsize = 2;
      m_axi_if.arlen = 0; m_axi_if.aruser = 0; m_axi_if.arid = 0;
      m_axi_if.arlock = 0; m_axi_if.arvalid = 0; m_axi_if.rready = 0;
      m_axi_if.awaddr = 0; m_axi_if.awburst = 1; m_axi_if.awsize = 2;
      m_axi_if.awlen = 0; m_axi_if.awuser = 0; m_axi_if.awid = 0;
      m_axi_if.awlock = 0; m_axi_if.awvalid = 0;
      m_axi_if.wdata = 0; m_axi_if.wstrb = 4'hf; m_axi_if.wuser = 0;
      m_axi_if.wvalid = 0; m_axi_if.wlast = 1; m_axi_if.bready = 0;
    end
  endtask

  task automatic read_one(
    input [47:0] addr,
    input [7:0] burst_len,
    output [31:0] data,
    output [1:0] resp
  );
    reg accepted;
    reg [31:0] first_data;
    reg [1:0] first_resp;
    reg first_last;
    integer beat;
    begin
      @(negedge core_clk);
      m_axi_if.araddr = addr;
      m_axi_if.arlen = burst_len;
      m_axi_if.arid = 5'h13;
      m_axi_if.aruser = 32'h1234_5678;
      m_axi_if.arvalid = 1;
      m_axi_if.rready = 0;
      accepted = 0;
      timeout = 0;
      while (!accepted && timeout < 1000) begin
        @(posedge core_clk);
        if (m_axi_if.arready) accepted = 1;
        timeout = timeout + 1;
      end
      if (!accepted) $fatal(1, "AR timeout at %h", addr);
      @(negedge core_clk);
      m_axi_if.arvalid = 0;
      timeout = 0;
      while (!m_axi_if.rvalid && timeout < 2000) begin
        @(posedge core_clk);
        timeout = timeout + 1;
      end
      if (!m_axi_if.rvalid) $fatal(1, "RVALID timeout at %h", addr);
      first_data = m_axi_if.rdata;
      first_resp = m_axi_if.rresp;
      first_last = m_axi_if.rlast;
      if (m_axi_if.rid != 5'h13 || m_axi_if.ruser != 32'h1234_5678 ||
          first_last != (burst_len == 0))
        $fatal(1, "Bad first R payload at %h", addr);
      repeat (3) begin
        @(posedge core_clk);
        if (!m_axi_if.rvalid || m_axi_if.rdata !== first_data ||
            m_axi_if.rresp !== first_resp || m_axi_if.rlast !== first_last ||
            m_axi_if.rid !== 5'h13 || m_axi_if.ruser !== 32'h1234_5678)
          $fatal(1, "R payload changed under backpressure at %h", addr);
      end
      @(negedge core_clk);
      m_axi_if.rready = 1;
      for (beat = 0; beat <= burst_len; beat = beat + 1) begin
        accepted = 0;
        timeout = 0;
        while (!accepted && timeout < 2000) begin
          @(posedge core_clk);
          if (m_axi_if.rvalid) begin
            if (m_axi_if.rlast != (beat == burst_len) ||
                m_axi_if.rid != 5'h13 || m_axi_if.ruser != 32'h1234_5678)
              $fatal(1, "Bad R metadata/LAST at %h beat %0d", addr, beat);
            if (beat == 0) begin
              data = m_axi_if.rdata;
              resp = m_axi_if.rresp;
            end else if (m_axi_if.rresp != resp) begin
              $fatal(1, "Read response changed within burst at %h", addr);
            end
            accepted = 1;
          end
          timeout = timeout + 1;
        end
        if (!accepted) $fatal(1, "R timeout at %h beat %0d", addr, beat);
      end
      @(negedge core_clk);
      m_axi_if.rready = 0;
    end
  endtask

  task automatic write_two_beat_error(output [1:0] resp);
    reg aw_accepted, first_w_accepted, second_w_accepted;
    begin
      @(negedge core_clk);
      m_axi_if.awaddr = SRAM_BASE;
      m_axi_if.awburst = 2'b01;
      m_axi_if.awlen = 1;
      m_axi_if.awid = 5'h0b;
      m_axi_if.awuser = 32'h8765_4321;
      m_axi_if.awvalid = 1;
      m_axi_if.wdata = 32'h1111_aaaa;
      m_axi_if.wuser = 32'h8765_4321;
      m_axi_if.wlast = 0;
      m_axi_if.wvalid = 1;
      m_axi_if.bready = 0;
      aw_accepted = 0;
      first_w_accepted = 0;
      timeout = 0;
      while ((!aw_accepted || !first_w_accepted) && timeout < 2000) begin
        @(posedge core_clk);
        if (!aw_accepted && m_axi_if.awready) aw_accepted = 1;
        if (!first_w_accepted && m_axi_if.wready) first_w_accepted = 1;
        @(negedge core_clk);
        if (aw_accepted) m_axi_if.awvalid = 0;
        if (first_w_accepted) begin
          m_axi_if.wdata = 32'h2222_bbbb;
          m_axi_if.wlast = 1;
        end
        timeout = timeout + 1;
      end
      if (!aw_accepted || !first_w_accepted)
        $fatal(1, "Two-beat error AW/first-W timeout");

      second_w_accepted = 0;
      timeout = 0;
      while (!second_w_accepted && timeout < 2000) begin
        @(posedge core_clk);
        if (m_axi_if.wready) second_w_accepted = 1;
        @(negedge core_clk);
        if (second_w_accepted) m_axi_if.wvalid = 0;
        timeout = timeout + 1;
      end
      if (!second_w_accepted) $fatal(1, "Two-beat error second-W timeout");

      timeout = 0;
      while (!m_axi_if.bvalid && timeout < 2000) begin
        @(posedge core_clk);
        timeout = timeout + 1;
      end
      if (!m_axi_if.bvalid || m_axi_if.bresp != 2'b10 ||
          m_axi_if.bid != 5'h0b || m_axi_if.buser != 32'h8765_4321)
        $fatal(1, "Two-beat error B response mismatch");
      @(negedge core_clk);
      repeat (3) begin
        @(posedge core_clk);
        if (!m_axi_if.bvalid || m_axi_if.bresp != 2'b10 ||
            m_axi_if.bid != 5'h0b || m_axi_if.buser != 32'h8765_4321)
          $fatal(1, "B payload changed under backpressure");
      end
      @(negedge core_clk);
      m_axi_if.bready = 1;
      @(posedge core_clk);
      if (!m_axi_if.bvalid || !m_axi_if.bready)
        $fatal(1, "Error B response was not accepted");
      @(negedge core_clk);
      m_axi_if.bready = 0;
    end
  endtask

  task automatic write_one(
    input [47:0] addr,
    input [31:0] data,
    output [1:0] resp
  );
    reg aw_accepted, w_accepted;
    begin
      @(negedge core_clk);
      m_axi_if.awaddr = addr;
      m_axi_if.awburst = (addr[47:18] == FIFO_BASE[47:18]) ? 2'b00 : 2'b01;
      m_axi_if.awlen = 0;
      m_axi_if.awid = 5'h0b;
      m_axi_if.awuser = 32'h8765_4321;
      m_axi_if.awvalid = 1;
      m_axi_if.wdata = data;
      m_axi_if.wuser = 32'h8765_4321;
      m_axi_if.wvalid = 1;
      m_axi_if.wlast = 1;
      m_axi_if.bready = 1;
      aw_accepted = 0;
      w_accepted = 0;
      timeout = 0;
      while ((!aw_accepted || !w_accepted) && timeout < 2000) begin
        @(posedge core_clk);
        if (!aw_accepted && m_axi_if.awready) aw_accepted = 1;
        if (!w_accepted && m_axi_if.wready) w_accepted = 1;
        @(negedge core_clk);
        if (aw_accepted) m_axi_if.awvalid = 0;
        if (w_accepted) m_axi_if.wvalid = 0;
        timeout = timeout + 1;
      end
      if (!aw_accepted || !w_accepted)
        $fatal(1, "AW/W timeout at %h aw=%b w=%b", addr, aw_accepted, w_accepted);
      w_accepted = 0;
      timeout = 0;
      while (!w_accepted && timeout < 2000) begin
        @(posedge core_clk);
        if (m_axi_if.bvalid) begin
          if (m_axi_if.bid != 5'h0b || m_axi_if.buser != 32'h8765_4321)
            $fatal(1, "Bad B metadata at %h", addr);
          resp = m_axi_if.bresp;
          w_accepted = 1;
        end
        timeout = timeout + 1;
      end
      if (!w_accepted) $fatal(1, "B timeout at %h", addr);
      @(negedge core_clk);
      m_axi_if.bready = 0;
    end
  endtask

  initial begin
    init_manager();
    ctrl.dma_gen_done = 1'b1;
    ctrl.dma_gen_block_size = 'x;
    axi_error_inj_en = 0;
    repeat (3) @(posedge core_clk);
    @(negedge core_clk);
    cptra_rst_b = 1;

    dut.i_axi_sram.i_sram.ram[0][0] = 8'hd4;
    dut.i_axi_sram.i_sram.ram[0][1] = 8'hc3;
    dut.i_axi_sram.i_sram.ram[0][2] = 8'hb2;
    dut.i_axi_sram.i_sram.ram[0][3] = 8'ha1;
    read_one(SRAM_BASE, 0, read_data, read_resp);
    if (read_resp != 2'b00 || read_data != 32'ha1b2_c3d4)
      $fatal(1, "SRAM backdoor seed path or disabled error injection failed");
    axi_error_inj_en = 1;
    read_one(SRAM_BASE, 1, read_data, read_resp);
    if (read_resp != 2'b10 || read_data != 32'ha1b2_c3d4)
      $fatal(1, "First range-matched read was not synthetic SLVERR");
    read_one(SRAM_BASE, 0, read_data, read_resp);
    if (read_resp != 2'b00 || read_data != 32'ha1b2_c3d4)
      $fatal(1, "Range injection did not remain one-shot");

    @(negedge core_clk);
    cptra_rst_b = 0;
    repeat (2) @(posedge core_clk);
    @(negedge core_clk);
    cptra_rst_b = 1;
    write_two_beat_error(write_resp);
    if (write_resp != 2'b10)
      $fatal(1, "First range-matched write was not synthetic SLVERR");
    read_one(SRAM_BASE, 0, read_data, read_resp);
    if (read_resp != 2'b00 || read_data != 32'ha1b2_c3d4)
      $fatal(1, "Injected write modified the target SRAM");

    @(negedge core_clk);
    cptra_rst_b = 0;
    repeat (2) @(posedge core_clk);
    @(negedge core_clk);
    cptra_rst_b = 1;
    axi_error_inj_en = 0;
    write_one(FIFO_BASE, 32'hface_cafe, write_resp);
    if (write_resp != 2'b00) $fatal(1, "FIFO preload for read-error test failed");
    axi_error_inj_en = 1;
    read_one(FIFO_BASE, 0, read_data, read_resp);
    if (read_resp != 2'b10 || read_data != 32'hface_cafe)
      $fatal(1, "Range-matched FIFO read did not preserve data and return SLVERR");

    ctrl.rand_delays = 1;
    write_one(SRAM_BASE + 4, 32'h1234_abcd, write_resp);
    if (write_resp != 2'b00) $fatal(1, "Normal write failed under random stalls");
    read_one(SRAM_BASE + 4, 0, read_data, read_resp);
    if (read_resp != 2'b00 || read_data != 32'h1234_abcd)
      $fatal(1, "Normal read failed under random stalls");

    ctrl.rand_delays = 0;
    write_one(FIFO_BASE, 32'hface_cafe, write_resp);
    if (write_resp != 2'b00) $fatal(1, "FIFO write failed");
    read_one(FIFO_BASE, 0, read_data, read_resp);
    if (read_resp != 2'b00 || read_data != 32'hface_cafe)
      $fatal(1, "FIFO write/read mapping failed");

    ctrl.fifo_auto_push = 1;
    read_one(FIFO_BASE, 0, read_data, read_resp);
    ctrl.fifo_auto_push = 0;
    if (read_resp != 2'b00)
      $fatal(1, "Caliptra fifo_auto_push did not provide a FIFO word");
    ctrl.fifo_clear = 1;
    repeat (2) @(negedge core_clk);
    ctrl.fifo_clear = 0;
    repeat (2) @(posedge core_clk);

    ctrl.dma_gen_block_size[0] = 12'd8;
    ctrl.dma_gen_done = 1;
    repeat (2) @(posedge core_clk);
    @(negedge core_clk);
    ctrl.en_recovery_emulation = 1;
    ctrl.fifo_auto_push = 1;
    timeout = 0;
    while (!recovery_data_avail && timeout < 2000) begin
      @(negedge core_clk);
      timeout = timeout + 1;
    end
    if (!recovery_data_avail)
      $fatal(1, "Recovery availability did not follow FIFO auto-push");

    ctrl.fifo_auto_push = 0;
    ctrl.fifo_auto_pop = 1;
    timeout = 0;
    while (recovery_data_avail && timeout < 2000) begin
      @(negedge core_clk);
      timeout = timeout + 1;
    end
    if (recovery_data_avail)
      $fatal(1, "Recovery availability did not deassert after FIFO auto-pop");
    ctrl.fifo_auto_pop = 0;

    write_one(FIFO_BASE, 32'h0bad_f00d, write_resp);
    if (write_resp != 2'b00 || !recovery_data_avail)
      $fatal(1, "Recovery availability did not follow a FIFO write");
    ctrl.fifo_clear = 1;
    repeat (2) @(negedge core_clk);
    ctrl.fifo_clear = 0;
    repeat (2) @(negedge core_clk);
    if (recovery_data_avail)
      $fatal(1, "Recovery availability did not deassert after fifo_clear");
    ctrl.en_recovery_emulation = 0;

    $display("PASS: Caliptra AXI complex BFM errors, SRAM/FIFO traffic, FIFO controls, recovery availability, and randomized stalls");
    $finish;
  end
endmodule
