// SPDX-License-Identifier: Apache-2.0
// Caliptra-profile constants observed in generated SoC-IFC consumers.
`ifndef CALIPTRA_BFM_EXTERNAL_AVERY
package aaxi_pkg;
  parameter integer AAXI_ADDR_WIDTH = 64;
  parameter integer AAXI_DATA_WIDTH = 32;
  parameter integer AAXI_ID_WIDTH = 8;
  parameter integer AAXI_AWUSER_WIDTH = 32;
  parameter integer AAXI_WUSER_WIDTH = 32;
  parameter integer AAXI_BUSER_WIDTH = 32;
  parameter integer AAXI_ARUSER_WIDTH = 32;
  parameter integer AAXI_RUSER_WIDTH = 32;

  typedef logic [1:0] aaxi_resp_t;
  localparam aaxi_resp_t AAXI_RESP_OKAY   = 2'b00;
  localparam aaxi_resp_t AAXI_RESP_EXOKAY = 2'b01;
  localparam aaxi_resp_t AAXI_RESP_SLVERR = 2'b10;
  localparam aaxi_resp_t AAXI_RESP_DECERR = 2'b11;

  // The generated top passes these through to the interface. The lower-bound
  // interface does not model clock-control payloads.
  parameter integer AAXI_MCB_INPUT = 0;
  parameter integer AAXI_MCB_OUTPUT = 0;
  parameter integer AAXI_SCB_INPUT = 0;
  parameter integer AAXI_SCB_OUTPUT = 0;

  typedef logic [AAXI_ADDR_WIDTH-1:0] aaxi_addr_t;
  typedef enum logic [1:0] {AAXI3 = 2'd0, AAXI4 = 2'd1} aaxi_protocol_version;
endpackage
`endif
