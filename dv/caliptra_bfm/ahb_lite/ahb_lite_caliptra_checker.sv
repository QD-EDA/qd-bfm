// SPDX-License-Identifier: Apache-2.0
// Caliptra AHB-Lite profile checks on a selected 64-bit responder path.
module ahb_lite_caliptra_checker #(
  parameter integer ADDR_WIDTH = 32,
  parameter integer DATA_WIDTH = 64,
  parameter integer CALIPTRA_FORBIDS_BUSY = 1
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
  output reg                   error,
  output reg  [3:0]            error_code,
  output reg  [31:0]           error_count
);
  localparam integer DATA_BYTES = DATA_WIDTH / 8;

  reg stall_active;
  reg [ADDR_WIDTH+1+1+2+3-1:0] stalled_address;
  reg stalled_write_data_active;
  reg [DATA_WIDTH-1:0] stalled_write_data;
  reg pending_write;
  reg pending_transfer;
  reg burst_context;
  reg expect_error_second_cycle;
  reg [3:0] current_error;
  integer bytes_per_transfer;

  always @(posedge HCLK) begin
    if (!HRESETn) begin
      error <= 1'b0;
      error_code <= 4'd0;
      error_count <= 32'd0;
      stall_active <= 1'b0;
      stalled_address <= '0;
      stalled_write_data_active <= 1'b0;
      stalled_write_data <= '0;
      pending_write <= 1'b0;
      pending_transfer <= 1'b0;
      burst_context <= 1'b0;
      expect_error_second_cycle <= 1'b0;
    end else begin
      current_error = 4'd0;

      if ((^HREADY === 1'bx) || (^HRESP === 1'bx) ||
          (^HSEL === 1'bx) || (^HTRANS === 1'bx) ||
          (^HWRITE === 1'bx) || (^HSIZE === 1'bx) ||
          (^HADDR === 1'bx) ||
          (pending_write && (^HWDATA === 1'bx))) begin
        current_error = 4'd1;
      end else if (CALIPTRA_FORBIDS_BUSY && HSEL && (HTRANS == 2'b01)) begin
        current_error = 4'd2;
      end else if (HSEL && HTRANS == 2'b11 && !burst_context) begin
        // HBURST is not present on Caliptra's reduced interface, so the
        // checker only verifies that SEQ follows a selected NONSEQ/SEQ chain.
        current_error = 4'd9;
      end else if (HSEL && HTRANS[1] && (HSIZE > $clog2(DATA_BYTES))) begin
        current_error = 4'd3;
      end else if (HSEL && HTRANS[1] && (HSIZE <= $clog2(DATA_BYTES))) begin
        bytes_per_transfer = 1 << HSIZE;
        if ((HADDR % bytes_per_transfer) != 0) current_error = 4'd4;
      end

      if ((current_error == 0) && !HREADY) begin
        if (stall_active &&
            (stalled_address !== {HADDR, HSEL, HWRITE, HTRANS, HSIZE}))
          current_error = 4'd5;
        if (pending_write &&
            stalled_write_data_active && (stalled_write_data !== HWDATA))
          current_error = 4'd6;
        stall_active <= 1'b1;
        stalled_address <= {HADDR, HSEL, HWRITE, HTRANS, HSIZE};
        if (pending_write) begin
          stalled_write_data_active <= 1'b1;
          stalled_write_data <= HWDATA;
        end
      end else if (HREADY) begin
        if (pending_write && stalled_write_data_active &&
            (stalled_write_data !== HWDATA))
          current_error = 4'd6;
        stall_active <= 1'b0;
        stalled_write_data_active <= 1'b0;
      end

      if (current_error == 0) begin
        if (expect_error_second_cycle) begin
          if (!pending_transfer || !(HRESP && HREADY)) current_error = 4'd7;
          expect_error_second_cycle <= 1'b0;
        end else if (HRESP) begin
          if (!pending_transfer)
            current_error = 4'd10;
          else if (HREADY)
            current_error = 4'd8;
          else
            expect_error_second_cycle <= 1'b1;
        end
      end

      if (HREADY) begin
        pending_write <= (HSEL === 1'b1) && (HTRANS[1] === 1'b1) &&
                         (HWRITE === 1'b1);
        pending_transfer <= (HSEL === 1'b1) && (HTRANS[1] === 1'b1);
        if (HSEL && HTRANS == 2'b10)
          burst_context <= 1'b1;
        else if (!HSEL || HTRANS == 2'b00)
          burst_context <= 1'b0;
      end

      if (current_error != 0) begin
        error <= 1'b1;
        error_code <= current_error;
        error_count <= error_count + 1'b1;
        $error("Caliptra AHB-Lite checker error code %0d", current_error);
      end
    end
  end
endmodule
