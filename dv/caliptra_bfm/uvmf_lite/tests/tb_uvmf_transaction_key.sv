// SPDX-License-Identifier: Apache-2.0
module tb_uvmf_transaction_key;
  import uvmf_base_pkg::*;

  uvmf_transaction_base source;
  uvmf_transaction_base copy;

  initial begin
    source = new("source");
    copy = new("copy");
    source.set_key(32'h89ab_cdef);
    if (source.get_key() !== 32'h89ab_cdef)
      $fatal(1, "set_key/get_key did not preserve the key");
    copy.copy(source);
    if (copy.get_key() !== 32'h89ab_cdef)
      $fatal(1, "copy did not preserve the key");
    $display("PASS: UVMF transaction key set/get/copy");
    $finish;
  end
endmodule
