// SPDX-License-Identifier: Apache-2.0
`timescale 1ns/1ps
module tb_axi4_caliptra_dma_if;
  import axi_pkg::*;

  localparam integer MAX_BEATS = 256;
  reg clk = 0;
  reg rst_n = 0;
  logic write_ok, read_ok;
  logic [1:0] write_resp;
  logic [31:0] write_resp_user, read_resp_user;
  logic [8191:0] request_data, request_user;
  logic [1023:0] request_strb;
  logic [8191:0] read_data, read_user;
  logic [511:0] read_resp;
  wire [31:0] fifo_level;
  wire fifo_push_event, fifo_pop_event, recovery_data_avail;

  axi_if #(.AW(48), .DW(32), .IW(8), .UW(32)) m_axi_if (
    .clk(clk), .rst_n(rst_n)
  );
  axi4_caliptra_record_if record_if(clk);

  always #5 clk = ~clk;

  axi4_caliptra_master_if_manager #(
    .ADDR_WIDTH(48), .DATA_WIDTH(32), .ID_WIDTH(8), .USER_WIDTH(32),
    .MAX_BEATS(MAX_BEATS)
  ) manager (
    .ACLK(clk), .ARESETn(rst_n),
    .m_axi_w_if(m_axi_if.w_mgr), .m_axi_r_if(m_axi_if.r_mgr)
  );

  axi4_caliptra_dma_if_subordinate target (
    .ACLK(clk), .ARESETn(rst_n),
    .m_axi_w_if(m_axi_if.w_sub), .m_axi_r_if(m_axi_if.r_sub),
    .fifo_clear(1'b0),
    .auto_fifo_push(1'b0),
    .auto_fifo_pop(1'b0),
    .use_dma_gen_sequence(1'b0),
    .dma_gen_done(1'b0),
    .dma_gen_block_size_bytes(1200'b0),
    .en_recovery_emulation(1'b0),
    .recovery_threshold_words(32'd2),
    .recovery_block_words(32'd8),
    .inject_error(1'b0),
    .stall_sram_aw(1'b0),
    .stall_sram_w(1'b0),
    .stall_sram_b(1'b0),
    .stall_sram_ar(1'b0),
    .stall_sram_r(1'b0),
    .stall_fifo_aw(1'b0),
    .stall_fifo_w(1'b0),
    .stall_fifo_b(1'b0),
    .stall_fifo_ar(1'b0),
    .stall_fifo_r(1'b0),
    .fifo_level(fifo_level),
    .fifo_push_event(fifo_push_event),
    .fifo_pop_event(fifo_pop_event),
    .recovery_data_avail(recovery_data_avail)
  );

  axi4_caliptra_dma_if_monitor monitor (
    .ACLK(clk), .ARESETn(rst_n),
    .m_axi_w_if(m_axi_if.w_sub), .m_axi_r_if(m_axi_if.r_sub),
    .record_if(record_if)
  );

  initial begin : run_test
    integer beat;
    for (beat = 0; beat < MAX_BEATS; beat = beat + 1) begin
      request_data[beat*32 +: 32] = 32'hc001_0000 ^ beat;
      request_strb[beat*4 +: 4] = 4'hf;
      request_user[beat*32 +: 32] = 32'h600d_0000 ^ beat;
    end

    manager.reset_master();
    repeat (2) @(posedge clk);
    @(negedge clk);
    rst_n = 1;

    manager.write_burst(
      48'h0001_2344_0020, 8'hff, 3'd2, AXI_BURST_INCR, 8'h31,
      32'h1122_3344, 1'b0, request_data, request_strb, request_user,
      write_ok, write_resp, write_resp_user
    );
    #1ns;
    if (!write_ok || write_resp != AXI_RESP_OKAY ||
        write_resp_user != 32'h1122_3344 || !record_if.write_complete ||
        record_if.write_error || record_if.write_addr != 48'h0001_2344_0020 ||
        record_if.write_id != 8'h31 || record_if.write_len != 8'hff ||
        record_if.write_beat_count != MAX_BEATS ||
        record_if.write_awuser != 32'h1122_3344 ||
        record_if.write_data !== request_data ||
        record_if.write_strb !== request_strb ||
        record_if.write_wuser !== request_user ||
        !record_if.write_last_mask[255] ||
        record_if.write_last_mask[254:0] !== '0 ||
        record_if.write_response != AXI_RESP_OKAY ||
        record_if.write_buser != 32'h1122_3344)
      $fatal(1, "Caliptra axi_if manager write did not traverse target and monitor");

    manager.read_burst(
      48'h0001_2344_0020, 8'hff, 3'd2, AXI_BURST_INCR, 8'h42,
      32'h89ab_cdef, 1'b0, read_ok, read_data, read_user, read_resp,
      read_resp_user
    );
    #1ns;
    if (!read_ok || read_data !== request_data ||
        read_user !== {MAX_BEATS{32'h89ab_cdef}} || read_resp !== '0 ||
        read_resp_user != 32'h89ab_cdef || !record_if.read_complete ||
        record_if.read_error || record_if.read_addr != 48'h0001_2344_0020 ||
        record_if.read_id != 8'h42 || record_if.read_len != 8'hff ||
        record_if.read_beat_count != MAX_BEATS ||
        record_if.read_aruser != 32'h89ab_cdef ||
        record_if.read_data !== request_data ||
        record_if.read_ruser !== {MAX_BEATS{32'h89ab_cdef}} ||
        record_if.read_resp !== '0 || !record_if.read_last_mask[255] ||
        record_if.read_last_mask[254:0] !== '0)
      $fatal(1, "Caliptra axi_if manager read did not traverse target and monitor");

    $display("PASS: Caliptra axi_if manager/subordinate complete a monitored 256-beat round trip");
    $finish;
  end
endmodule
