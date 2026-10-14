// SPDX-License-Identifier: Apache-2.0
package proxy_types_pkg;
  class proxy #(parameter int WIDTH = 32);
    function new();
    endfunction
  endclass
endpackage

interface proxy_bfm #(parameter int WIDTH = 32);
  proxy_types_pkg::proxy #(.WIDTH(WIDTH)) proxy_handle;
endinterface

module package_scoped_parameterized_class_top;
  proxy_bfm #(.WIDTH(8)) bfm();
endmodule
