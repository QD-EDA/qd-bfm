// SPDX-License-Identifier: Apache-2.0
// Reconstructs completed AHB-Lite transfers from the address/data pipeline.
module ahb_lite_caliptra_monitor #(
  parameter integer ADDR_WIDTH = 32,
  parameter integer DATA_WIDTH = 64
) (
  input  wire                  HCLK,
  input  wire                  HRESETn,
  input  wire [ADDR_WIDTH-1:0] HADDR,
  input  wire [DATA_WIDTH-1:0] HWDATA,
  input  wire                  HSEL,
  input  wire                  HWRITE,
  input  wire [1:0]            HTRANS,
  input  wire [2:0]            HSIZE,
  input  wire                  HREADY,
  input  wire                  HRESP,
  input  wire [DATA_WIDTH-1:0] HRDATA,
  output reg                   address_phase_fire,
  output reg                   address_phase_selected,
  output reg  [1:0]            address_phase_trans,
  output reg                   address_fire,
  output reg                   transfer_fire,
  output reg                   transfer_protocol_error,
  output reg  [ADDR_WIDTH-1:0] transfer_addr,
  output reg                   transfer_write,
  output reg  [1:0]            transfer_trans,
  output reg  [2:0]            transfer_size,
  output reg  [DATA_WIDTH-1:0] transfer_data,
  output reg                   transfer_error,
  output reg  [63:0]           cycle_count,
  output reg  [31:0]           address_count,
  output reg  [31:0]           transfer_count,
  output reg                   protocol_error,
  output reg  [31:0]           protocol_error_count,
  output reg  [31:0]           read_address_count,
  output reg  [31:0]           write_address_count,
  output reg  [31:0]           size_1byte_count,
  output reg  [31:0]           size_2byte_count,
  output reg  [31:0]           size_4byte_count,
  output reg  [31:0]           size_8byte_count,
  output reg  [31:0]           pending_wait_cycle_count,
  output reg  [31:0]           error_transfer_count
);
  reg pending;
  reg [ADDR_WIDTH-1:0] pending_addr;
  reg pending_write;
  reg [1:0] pending_trans;
  reg [2:0] pending_size;
  reg expect_error_second_cycle;
  reg response_bad;

  always @(posedge HCLK) begin
    if (!HRESETn) begin
      address_phase_fire <= 1'b0;
      address_phase_selected <= 1'b0;
      address_phase_trans <= 2'b00;
      address_fire <= 1'b0;
      transfer_fire <= 1'b0;
      transfer_protocol_error <= 1'b0;
      transfer_addr <= '0;
      transfer_write <= 1'b0;
      transfer_trans <= '0;
      transfer_size <= '0;
      transfer_data <= '0;
      transfer_error <= 1'b0;
      cycle_count <= '0;
      address_count <= '0;
      transfer_count <= '0;
      protocol_error <= 1'b0;
      protocol_error_count <= '0;
      read_address_count <= '0;
      write_address_count <= '0;
      size_1byte_count <= '0;
      size_2byte_count <= '0;
      size_4byte_count <= '0;
      size_8byte_count <= '0;
      pending_wait_cycle_count <= '0;
      error_transfer_count <= '0;
      pending <= 1'b0;
      pending_addr <= '0;
      pending_write <= 1'b0;
      pending_trans <= '0;
      pending_size <= '0;
      expect_error_second_cycle <= 1'b0;
    end else begin
      cycle_count <= cycle_count + 1'b1;
      address_phase_fire <= 1'b0;
      address_fire <= 1'b0;
      transfer_fire <= 1'b0;
      transfer_protocol_error <= 1'b0;
      response_bad = 1'b0;

      if ((HREADY !== 1'b0) && (HREADY !== 1'b1)) begin
        response_bad = 1'b1;
        expect_error_second_cycle <= 1'b0;
      end else if ((HRESP !== 1'b0) && (HRESP !== 1'b1)) begin
        response_bad = 1'b1;
        expect_error_second_cycle <= 1'b0;
      end else if (expect_error_second_cycle) begin
        if (!pending || (HRESP !== 1'b1) || (HREADY !== 1'b1))
          response_bad = 1'b1;
        expect_error_second_cycle <= 1'b0;
      end else if (HRESP === 1'b1) begin
        if (!pending) begin
          response_bad = 1'b1;
        end else if (HREADY === 1'b1) begin
          response_bad = 1'b1;
        end else if (HREADY === 1'b0) begin
          expect_error_second_cycle <= 1'b1;
        end
      end

      if (response_bad) begin
        protocol_error <= 1'b1;
        protocol_error_count <= protocol_error_count + 1'b1;
      end
      if (pending && (HREADY === 1'b0))
        pending_wait_cycle_count <= pending_wait_cycle_count + 1'b1;

      // HREADY completes the old data phase and accepts the current address
      // phase on the same edge, so publish old metadata before replacing it.
      if (HREADY === 1'b1) begin
        address_phase_fire <= 1'b1;
        address_phase_selected <= HSEL;
        address_phase_trans <= HTRANS;
        if (pending) begin
          transfer_fire <= 1'b1;
          transfer_addr <= pending_addr;
          transfer_write <= pending_write;
          transfer_trans <= pending_trans;
          transfer_size <= pending_size;
          transfer_data <= pending_write ? HWDATA : HRDATA;
          transfer_error <= HRESP;
          transfer_protocol_error <= response_bad;
          transfer_count <= transfer_count + 1'b1;
          if (HRESP === 1'b1)
            error_transfer_count <= error_transfer_count + 1'b1;
        end

        pending <= (HSEL === 1'b1) && (HTRANS[1] === 1'b1);
        if ((HSEL === 1'b1) && (HTRANS[1] === 1'b1)) begin
          address_fire <= 1'b1;
          address_count <= address_count + 1'b1;
          if (HWRITE === 1'b1)
            write_address_count <= write_address_count + 1'b1;
          else if (HWRITE === 1'b0)
            read_address_count <= read_address_count + 1'b1;
          // ponytail: raw Caliptra-profile bins; add cross bins if a consumer needs them.
          case (HSIZE)
            3'd0: size_1byte_count <= size_1byte_count + 1'b1;
            3'd1: size_2byte_count <= size_2byte_count + 1'b1;
            3'd2: size_4byte_count <= size_4byte_count + 1'b1;
            3'd3: size_8byte_count <= size_8byte_count + 1'b1;
            default: ;
          endcase
          pending_addr <= HADDR;
          pending_write <= HWRITE;
          pending_trans <= HTRANS;
          pending_size <= HSIZE;
        end
      end
    end
  end
endmodule
