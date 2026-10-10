// SPDX-License-Identifier: Apache-2.0
`include "uvm_macros.svh"
package uvmf_transaction_key_test_pkg;
  import uvm_pkg::*;
  import uvmf_base_pkg::*;

  class record_probe extends uvmf_transaction_base;
    int payload;
    `uvm_object_utils(record_probe)

    function new(string name = "record_probe");
      super.new(name);
    endfunction

    virtual function void do_record(uvm_recorder recorder);
      super.do_record(recorder);
      recorder.record_field("payload", payload, $bits(payload), UVM_DEC);
    endfunction

    virtual function string convert2string();
      return "DO_NOT_RECORD_SENTINEL";
    endfunction
  endclass

  class field_automation_probe extends uvmf_transaction_base;
    int generated_payload;
    `uvm_object_utils_begin(field_automation_probe)
      `uvm_field_int(generated_payload, UVM_DEFAULT)
    `uvm_object_utils_end

    function new(string name = "field_automation_probe");
      super.new(name);
    endfunction
  endclass
endpackage

module tb_uvmf_transaction_key;
  import uvm_pkg::*;
  import uvmf_transaction_key_test_pkg::*;

  record_probe source;
  record_probe copy;
  field_automation_probe generated_source;
  field_automation_probe generated_copy;
  uvm_text_tr_database record_db;
  uvm_tr_stream record_stream;
  string record_file;
  int record_handle;

  initial begin
    source = new("source");
    copy = new("copy");
    source.set_key(32'h89ab_cdef);
    source.start_time = 64'h1234;
    source.end_time = 64'h5678;
    source.payload = 32'hcafe_1234;
    copy.copy(source);
    if (copy.get_key() !== 32'h89ab_cdef)
      $fatal(1, "copy did not preserve the key");
    if (!$value$plusargs("BFM_LITE_RECORD_FILE=%s", record_file))
      $fatal(1, "transaction record output path was not provided");
    record_db = new("record_db");
    record_db.set_file_name(record_file);
    record_stream = record_db.open_stream("uvmf_transactions", "test", "record_probe");
    if (record_stream == null)
      $fatal(1, "could not open transaction record stream");
    source.enable_recording(record_stream);
    record_handle = source.begin_tr();
    if (record_handle == 0)
      $fatal(1, "UVM did not create a transaction record");
    source.end_tr();
    record_stream.close();

    generated_source = new("generated_source");
    generated_copy = new("generated_copy");
    generated_source.start_time = 64'h2345;
    generated_source.end_time = 64'h6789;
    generated_source.generated_payload = 32'hbeef_5678;
    generated_copy.copy(generated_source);
    if (generated_copy.generated_payload !== generated_source.generated_payload)
      $fatal(1, "generated-style field automation did not copy the payload");
    record_stream = record_db.open_stream(
      "uvmf_transactions", "test", "field_automation_probe");
    if (record_stream == null)
      $fatal(1, "could not open generated-style transaction record stream");
    generated_source.enable_recording(record_stream);
    record_handle = generated_source.begin_tr();
    if (record_handle == 0)
      $fatal(1, "UVM did not create a generated-style transaction record");
    generated_source.end_tr();
    record_stream.close();

    if (!record_db.close_db())
      $fatal(1, "could not close transaction record database");

    $display("PASS: UVMF transaction key and generated-style field recording");
    $finish;
  end
endmodule
