// SPDX-License-Identifier: Apache-2.0
// Compile-only proxy surface for generated HDL BFM interfaces.
// These classes preserve only names, the monitor callback, and mailbox ECC
// configuration fields consumed by the pinned HDL wrappers. They do not
// replace the generated UVMF transaction, agent, or environment classes.
package soc_ifc_ctrl_pkg;
  class soc_ifc_ctrl_driver;
  endclass
  class soc_ifc_ctrl_monitor;
    function void notify_transaction(input logic [4095:0] transaction);
    endfunction
  endclass
endpackage

package cptra_ctrl_pkg;
  class cptra_ctrl_driver;
  endclass
  class cptra_ctrl_monitor;
    function void notify_transaction(input logic [4095:0] transaction);
    endfunction
  endclass
endpackage

package ss_mode_ctrl_pkg;
  class ss_mode_ctrl_driver;
  endclass
  class ss_mode_ctrl_monitor;
    function void notify_transaction(input logic [4095:0] transaction);
    endfunction
  endclass
endpackage

package soc_ifc_status_pkg;
  class soc_ifc_status_driver;
  endclass
  class soc_ifc_status_monitor;
    function void notify_transaction(input logic [4095:0] transaction);
    endfunction
  endclass
endpackage

package cptra_status_pkg;
  class cptra_status_driver;
  endclass
  class cptra_status_monitor;
    function void notify_transaction(input logic [4095:0] transaction);
    endfunction
  endclass
endpackage

package ss_mode_status_pkg;
  class ss_mode_status_driver;
  endclass
  class ss_mode_status_monitor;
    function void notify_transaction(input logic [4095:0] transaction);
    endfunction
  endclass
endpackage

package mbox_sram_pkg;
  class mbox_sram_configuration;
    bit [1:0] inject_ecc_error;
    bit auto_clear_ecc_error_injection;
  endclass
  class mbox_sram_driver;
    mbox_sram_configuration configuration;
  endclass
  class mbox_sram_monitor;
    mbox_sram_configuration configuration;
    function void notify_transaction(input logic [4095:0] transaction);
    endfunction
  endclass
endpackage
