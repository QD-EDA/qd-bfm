// SPDX-License-Identifier: Apache-2.0
// The pinned generated source imports these namespaces. Only observed names
// needed by the SoC-IFC environment are defined; these are not replacements
// for the Avery xactor, test, or PLL packages.
`ifndef CALIPTRA_BFM_EXTERNAL_AVERY
package aaxi_pkg_xactor;
endpackage

package aaxi_pkg_test;
  // Only the constructor is used by the pinned SoC-IFC environment.
  class aaxi_log;
    function new(string name = "aaxi_log");
    endfunction
  endclass
endpackage

package aaxi_pll;
endpackage

// UVMF utility import used by the generated environment; its symbols are not
// referenced by this Caliptra consumer.
package rw_txn_pkg;
endpackage
`endif
