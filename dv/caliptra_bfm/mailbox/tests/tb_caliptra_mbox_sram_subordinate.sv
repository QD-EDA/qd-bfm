// SPDX-License-Identifier: Apache-2.0
module tb_caliptra_mbox_sram_subordinate;
  import soc_ifc_pkg::*;

  logic clk = 1'b0;
  logic rst_b = 1'b0;
  cptra_mbox_sram_req_t req = '0;
  cptra_mbox_sram_resp_t resp;
  cptra_mbox_sram_data_t write_xor_mask = '0;
  logic [1:0] inject_ecc_error = '0;
  logic access_error;
  localparam integer TEST_DEPTH = 16;

  always #5 clk = ~clk;

  caliptra_mbox_sram_subordinate #(
    .DEPTH_WORDS(TEST_DEPTH),
    .ENABLE_WRITE_XOR_MASK(1'b1),
    .ENABLE_ECC_INJECTION(1'b1)
  ) dut (
    .clk_i(clk), .rst_b(rst_b), .req(req), .resp(resp),
    .write_xor_mask(write_xor_mask), .inject_ecc_error(inject_ecc_error),
    .access_error(access_error)
  );

  task automatic issue(
    input bit write_enable,
    input logic [CPTRA_MBOX_ADDR_W-1:0] address,
    input cptra_mbox_sram_data_t data
  );
    begin
      @(negedge clk);
      req.cs = 1'b1;
      req.we = write_enable;
      req.addr = address;
      req.wdata = data;
      @(posedge clk);
      #1;
      req.cs = 1'b0;
      req.we = 1'b0;
    end
  endtask

  task automatic expect_read(
    input logic [CPTRA_MBOX_ADDR_W-1:0] address,
    input cptra_mbox_sram_data_t expected
  );
    cptra_mbox_sram_data_t unused;
    begin
      issue(1'b0, address, unused);
      if (access_error || resp.rdata !== expected)
        $fatal(1, "mailbox read 0x%0h got %0h expected %0h error=%b",
               address, resp.rdata, expected, access_error);
    end
  endtask

  initial begin
    cptra_mbox_sram_data_t first_word;
    cptra_mbox_sram_data_t last_word;
    cptra_mbox_sram_data_t observed;
    logic [CPTRA_MBOX_DATA_AND_ECC_W-1:0] delta;
    integer flipped_bits;
    integer bit_index;

    first_word.data = 32'hcafe_1248;
    first_word.ecc = 7'h53;
    last_word.data = 32'h7654_3210;
    last_word.ecc = 7'h2d;

    repeat (2) @(posedge clk);
    #1;
    if (resp.rdata !== '0)
      $fatal(1, "reset did not clear the mailbox SRAM response register");
    @(negedge clk);
    rst_b = 1'b1;

    expect_read(0, '0);
    issue(1'b1, 0, first_word);
    expect_read(0, first_word);

    issue(1'b1, TEST_DEPTH-1, last_word);
    expect_read(TEST_DEPTH-1, last_word);

    write_xor_mask.data = 32'h0000_0001;
    write_xor_mask.ecc = 7'h04;
    issue(1'b1, 3, first_word);
    write_xor_mask = '0;
    observed = first_word ^ {7'h04, 32'h0000_0001};
    expect_read(3, first_word ^ {7'h04, 32'h0000_0001});
    dut.peek_word(3, observed);
    if (observed !== (first_word ^ {7'h04, 32'h0000_0001}))
      $fatal(1, "mailbox write fault mask was not stored with data and ECC");

    inject_ecc_error = 2'b01;
    issue(1'b1, 5, first_word);
    inject_ecc_error = '0;
    dut.peek_word(5, observed);
    delta = {observed.ecc ^ first_word.ecc, observed.data ^ first_word.data};
    flipped_bits = 0;
    for (bit_index = 0; bit_index < CPTRA_MBOX_DATA_AND_ECC_W; bit_index = bit_index + 1)
      flipped_bits = flipped_bits + delta[bit_index];
    if (flipped_bits != 1)
      $fatal(1, "single-bit ECC injection flipped %0d bits", flipped_bits);

    inject_ecc_error = 2'b10;
    issue(1'b1, 6, first_word);
    inject_ecc_error = '0;
    dut.peek_word(6, observed);
    delta = {observed.ecc ^ first_word.ecc, observed.data ^ first_word.data};
    flipped_bits = 0;
    for (bit_index = 0; bit_index < CPTRA_MBOX_DATA_AND_ECC_W; bit_index = bit_index + 1)
      flipped_bits = flipped_bits + delta[bit_index];
    if (flipped_bits != 2)
      $fatal(1, "double-bit ECC injection flipped %0d bits", flipped_bits);

    @(negedge clk);
    rst_b = 1'b0;
    @(posedge clk);
    #1;
    @(negedge clk);
    rst_b = 1'b1;
    expect_read(TEST_DEPTH-1, last_word);

    issue(1'b1, TEST_DEPTH, first_word);
    if (!access_error)
      $fatal(1, "out-of-range mailbox write was not reported");
    expect_read(0, first_word);

    issue(1'b0, TEST_DEPTH, '0);
    if (!access_error || (^resp.rdata) !== 1'bx)
      $fatal(1, "out-of-range mailbox read did not report an unknown response");

    expect_read(3, first_word ^ {7'h04, 32'h0000_0001});
    $display("PASS: Caliptra mailbox SRAM model covers sync read/write, XOR fault mask, ECC injection, reset retention, and bounds");
    $finish;
  end
endmodule
