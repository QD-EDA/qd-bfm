// SPDX-License-Identifier: Apache-2.0
`timescale 1ns/1ps

module tb_ahb_lite_caliptra_checker;
  reg HCLK = 0;
  reg HRESETn = 0;
  reg [31:0] HADDR = 0;
  reg [63:0] HWDATA = 0;
  reg HSEL = 0;
  reg HWRITE = 0;
  reg [1:0] HTRANS = 0;
  reg [2:0] HSIZE = 3;
  reg HREADY = 1;
  reg HRESP = 0;
  wire error;
  wire [3:0] error_code;
  wire [31:0] error_count;
  reg [8*32-1:0] test_case = "GOOD";
  reg [3:0] expected_code;

  always #5 HCLK = ~HCLK;

  ahb_lite_caliptra_checker #(.ADDR_WIDTH(32), .DATA_WIDTH(64)) dut (.*);

  task automatic step;
    begin
      @(posedge HCLK);
      #1;
    end
  endtask

  task automatic accept_transfer(input reg write_transfer);
    begin
      @(negedge HCLK);
      HADDR = 32'h1000_0000;
      HSEL = 1;
      HWRITE = write_transfer;
      HTRANS = 2'b10;
      HSIZE = 3;
      HREADY = 1;
      HRESP = 0;
      step();
    end
  endtask

  task automatic expect_rejection(input reg [3:0] code);
    begin
      step();
      if (error !== 1'b1 || error_count != 1 || error_code != code)
        $fatal(1, "CHECKER_MUTATION_NOT_DETECTED: case=%0s got error=%b code=%0d count=%0d expected_code=%0d",
               test_case, error, error_code, error_count, code);
      $display("EXPECTED_CHECKER_REJECTION case=%0s code=%0d", test_case, error_code);
      $fatal(1, "EXPECTED_NONZERO_FROM_INJECTED_AHB_PROTOCOL_ERROR");
    end
  endtask

  initial begin
    if (!$value$plusargs("CASE=%s", test_case)) test_case = "GOOD";
    repeat (2) step();
    @(negedge HCLK);
    HRESETn = 1;
    step();

    if (test_case == "GOOD") begin
      accept_transfer(1'b0);
      @(negedge HCLK);
      HSEL = 0;
      HTRANS = 2'b00;
      HREADY = 0;
      HRESP = 1;
      step();
      @(negedge HCLK);
      HREADY = 1;
      step();
      if (error !== 1'b0 || error_count != 0)
        $fatal(1, "AHB checker rejected a legal two-cycle ERROR response");
      $display("PASS: AHB checker accepts a legal transfer and two-cycle ERROR response");
      $finish;
    end

    if (test_case == "GOOD_IDLE_TO_NONSEQ") begin
      accept_transfer(1'b0);
      @(negedge HCLK);
      HADDR = 32'h1000_0008;
      HSEL = 0;
      HTRANS = 2'b00;
      HREADY = 0;
      step();
      @(negedge HCLK);
      HSEL = 1;
      HTRANS = 2'b10;
      step();
      @(negedge HCLK);
      HREADY = 1;
      step();
      if (error !== 1'b0 || error_count != 0)
        $fatal(1, "AHB checker rejected a legal IDLE-to-NONSEQ waited transition");
      $display("PASS: AHB checker accepts IDLE-to-NONSEQ while a transfer is waited");
      $finish;
    end

    case (test_case)
      "BAD_X_HREADY": begin
        HREADY = 1'bx;
        expected_code = 1;
      end
      "BAD_Z_HREADY": begin
        HREADY = 1'bz;
        expected_code = 1;
      end
      "BAD_X_HRESP": begin
        HRESP = 1'bx;
        expected_code = 1;
      end
      "BAD_Z_HRESP": begin
        HRESP = 1'bz;
        expected_code = 1;
      end
      "BAD_X_HSEL": begin
        HSEL = 1'bx;
        expected_code = 1;
      end
      "BAD_Z_HSEL": begin
        HSEL = 1'bz;
        expected_code = 1;
      end
      "BAD_X_HTRANS": begin
        HTRANS = 2'bxx;
        expected_code = 1;
      end
      "BAD_Z_HTRANS": begin
        HTRANS = 2'bzz;
        expected_code = 1;
      end
      "BAD_X_HWRITE": begin
        HWRITE = 1'bx;
        expected_code = 1;
      end
      "BAD_Z_HWRITE": begin
        HWRITE = 1'bz;
        expected_code = 1;
      end
      "BAD_X_HSIZE": begin
        HSIZE = 3'bxxx;
        expected_code = 1;
      end
      "BAD_Z_HSIZE": begin
        HSIZE = 3'bzzz;
        expected_code = 1;
      end
      "BAD_X_HADDR": begin
        HADDR = 'x;
        expected_code = 1;
      end
      "BAD_Z_HADDR": begin
        HADDR = 'z;
        expected_code = 1;
      end
      "BAD_X_HWDATA": begin
        accept_transfer(1'b1);
        @(negedge HCLK);
        HWDATA = 'x;
        expected_code = 1;
      end
      "BAD_Z_HWDATA": begin
        accept_transfer(1'b1);
        @(negedge HCLK);
        HWDATA = 'z;
        expected_code = 1;
      end
      "BAD_BUSY": begin
        HSEL = 1;
        HTRANS = 2'b01;
        expected_code = 2;
      end
      "BAD_SIZE": begin
        HSEL = 1;
        HTRANS = 2'b10;
        HSIZE = 4;
        expected_code = 3;
      end
      "BAD_ALIGN": begin
        HSEL = 1;
        HTRANS = 2'b10;
        HADDR = 32'h1000_0002;
        HSIZE = 2;
        expected_code = 4;
      end
      "BAD_ADDR_STABILITY": begin
        @(negedge HCLK);
        HSEL = 1;
        HTRANS = 2'b10;
        HADDR = 32'h1000_0000;
        HREADY = 0;
        step();
        @(negedge HCLK);
        HADDR = 32'h1000_0008;
        expected_code = 5;
      end
      "BAD_ADDR_COMPLETION": begin
        @(negedge HCLK);
        HSEL = 1;
        HTRANS = 2'b10;
        HADDR = 32'h1000_0000;
        HREADY = 0;
        step();
        @(negedge HCLK);
        HREADY = 1;
        HADDR = 32'h1000_0008;
        expected_code = 5;
      end
      "BAD_WDATA_STABILITY": begin
        accept_transfer(1'b1);
        @(negedge HCLK);
        HSEL = 0;
        HTRANS = 2'b00;
        HREADY = 0;
        HWDATA = 64'h1111;
        step();
        @(negedge HCLK);
        HWDATA = 64'h2222;
        expected_code = 6;
      end
      "BAD_ERROR_SECOND": begin
        accept_transfer(1'b0);
        @(negedge HCLK);
        HSEL = 0;
        HTRANS = 2'b00;
        HREADY = 0;
        HRESP = 1;
        step();
        @(negedge HCLK);
        HREADY = 1;
        HRESP = 0;
        expected_code = 7;
      end
      "BAD_ERROR_SINGLE": begin
        accept_transfer(1'b0);
        @(negedge HCLK);
        HSEL = 0;
        HTRANS = 2'b00;
        HREADY = 1;
        HRESP = 1;
        expected_code = 8;
      end
      "BAD_ORPHAN_SEQ": begin
        HSEL = 1;
        HTRANS = 2'b11;
        expected_code = 9;
      end
      "BAD_ORPHAN_ERROR": begin
        HREADY = 0;
        HRESP = 1;
        expected_code = 10;
      end
      default: $fatal(1, "Unknown checker test case %0s", test_case);
    endcase

    expect_rejection(expected_code);
  end
endmodule
