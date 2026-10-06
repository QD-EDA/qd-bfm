// SPDX-License-Identifier: Apache-2.0
// Bounded synchronous model for Caliptra's 32-bit + ECC mailbox SRAM port.
module caliptra_mbox_sram_subordinate #(
  parameter integer DEPTH_WORDS = soc_ifc_pkg::CPTRA_MBOX_DEPTH,
  parameter INIT_FILE = "",
  parameter bit ZERO_INIT = 1'b1,
  parameter bit ENABLE_WRITE_XOR_MASK = 1'b0,
  parameter bit ENABLE_ECC_INJECTION = 1'b0
) (
  input wire clk_i,
  input wire rst_b,
  input wire soc_ifc_pkg::cptra_mbox_sram_req_t req,
  output wire soc_ifc_pkg::cptra_mbox_sram_resp_t resp,
  input wire soc_ifc_pkg::cptra_mbox_sram_data_t write_xor_mask,
  input wire [1:0] inject_ecc_error,
  output reg access_error
);
  import soc_ifc_pkg::*;

  localparam integer ADDR_WIDTH = CPTRA_MBOX_ADDR_W;
  localparam integer DATA_ECC_WIDTH = CPTRA_MBOX_DATA_AND_ECC_W;

  cptra_mbox_sram_data_t memory [0:DEPTH_WORDS-1];
  bit [DEPTH_WORDS-1:0] initialized = '0;
  cptra_mbox_sram_data_t read_data_q;
  cptra_mbox_sram_data_t write_data;
  cptra_mbox_sram_data_t injection_mask;
  integer index;
  integer init_index;

  // Caliptra's SRAM response is registered; the response data is visible
  // immediately after the sampling edge for a read request.
  assign resp = read_data_q;

  function automatic cptra_mbox_sram_data_t make_ecc_injection_mask(
    input logic [ADDR_WIDTH-1:0] address,
    input logic [1:0] mode
  );
    cptra_mbox_sram_data_t mask;
    integer first_bit;
    integer second_bit;
    begin
      mask = '0;
      first_bit = address % DATA_ECC_WIDTH;
      second_bit = (first_bit + 1) % DATA_ECC_WIDTH;
      if (mode[1] === 1'b1) begin
        if (first_bit < CPTRA_MBOX_DATA_W)
          mask.data[first_bit] = 1'b1;
        else
          mask.ecc[first_bit-CPTRA_MBOX_DATA_W] = 1'b1;
        if (second_bit < CPTRA_MBOX_DATA_W)
          mask.data[second_bit] = 1'b1;
        else
          mask.ecc[second_bit-CPTRA_MBOX_DATA_W] = 1'b1;
      end else if (mode[0] === 1'b1) begin
        if (first_bit < CPTRA_MBOX_DATA_W)
          mask.data[first_bit] = 1'b1;
        else
          mask.ecc[first_bit-CPTRA_MBOX_DATA_W] = 1'b1;
      end
      make_ecc_injection_mask = mask;
    end
  endfunction

  initial begin
    if (DEPTH_WORDS < 1 || DEPTH_WORDS > (1 << ADDR_WIDTH))
      $fatal(1, "Caliptra mailbox SRAM depth %0d does not fit %0d-bit addresses",
             DEPTH_WORDS, ADDR_WIDTH);
    // Avoid a 65K-entry time-zero sweep for the common all-zero model. Reads
    // return zero until a word is written or explicitly preloaded. Preserve
    // eager initialization when a file is supplied, where partial files must
    // leave the remaining words at the configured ZERO_INIT value.
    if (INIT_FILE != "") begin
      if (ZERO_INIT)
        for (init_index = 0; init_index < DEPTH_WORDS; init_index = init_index + 1)
          memory[init_index] = '0;
      $readmemh(INIT_FILE, memory);
    end
  end

  always @(posedge clk_i or negedge rst_b) begin
    if (!rst_b) begin
      read_data_q <= '0;
      access_error <= 1'b0;
    end else begin
      access_error <= 1'b0;
      if (req.cs === 1'b1) begin
        if ((^req.addr) === 1'bx) begin
          access_error <= 1'b1;
          if (req.we === 1'b0) read_data_q <= 'x;
        end else begin
          index = req.addr;
          if (index >= DEPTH_WORDS) begin
            access_error <= 1'b1;
            if (req.we === 1'b0) read_data_q <= 'x;
          end else if (req.we === 1'b1) begin
            write_data = req.wdata;
            if (ENABLE_WRITE_XOR_MASK)
              write_data = write_data ^ write_xor_mask;
            if (ENABLE_ECC_INJECTION) begin
              injection_mask = make_ecc_injection_mask(req.addr, inject_ecc_error);
              write_data = write_data ^ injection_mask;
            end
            memory[index] <= write_data;
            initialized[index] <= 1'b1;
          end else if (req.we === 1'b0) begin
            if (ZERO_INIT && INIT_FILE == "" && !initialized[index])
              read_data_q <= '0;
            else
              read_data_q <= memory[index];
          end else begin
            access_error <= 1'b1;
          end
        end
      end else if (req.cs !== 1'b0) begin
        access_error <= 1'b1;
      end
    end
  end

  task automatic load_word(
    input logic [ADDR_WIDTH-1:0] address,
    input cptra_mbox_sram_data_t value
  );
    integer load_index;
    begin
      load_index = address;
      if ((^address) === 1'bx || load_index >= DEPTH_WORDS)
        $fatal(1, "Caliptra mailbox SRAM preload address 0x%0h is out of range", address);
      memory[load_index] = value;
      initialized[load_index] = 1'b1;
    end
  endtask

  task automatic peek_word(
    input logic [ADDR_WIDTH-1:0] address,
    output cptra_mbox_sram_data_t value
  );
    integer peek_index;
    begin
      peek_index = address;
      if ((^address) === 1'bx || peek_index >= DEPTH_WORDS)
        $fatal(1, "Caliptra mailbox SRAM peek address 0x%0h is out of range", address);
      if (ZERO_INIT && INIT_FILE == "" && !initialized[peek_index])
        value = '0;
      else
        value = memory[peek_index];
    end
  endtask
endmodule
