// SPDX-License-Identifier: Apache-2.0
// Clean-room HDL-side UVMF types required by generated BFM interfaces.
`ifndef CALIPTRA_BFM_EXTERNAL_UVMF
package uvmf_base_pkg_hdl;
  typedef enum { ACTIVE, PASSIVE } uvmf_active_passive_t;
  typedef enum { INITIATOR, RESPONDER } uvmf_initiator_responder_t;
  // Generated HDL tops use this config-db key without importing the HVL package.
  localparam string UVMF_VIRTUAL_INTERFACES = "UVMF_VIRTUAL_INTERFACES";
endpackage
`endif
