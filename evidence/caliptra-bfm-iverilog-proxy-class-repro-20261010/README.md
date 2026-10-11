# Minimal Icarus reproducer: package-qualified parameterized class handle

The tracked reducer
[`package_scoped_parameterized_class.sv`](../../dv/caliptra_bfm/uvmf_lite/tests/reducers/package_scoped_parameterized_class.sv)
was compiled unchanged on Slurm with clean published Icarus
`c339b9f2287a743aeb7ab6de6528e8d34a4dd602`. Compilation exited 2 at line 10
with `syntax error` and `Invalid module item`. Peak RSS was 8,180 KiB. The
source hash is `66d1510b0b7c752f4478bb2b7ddb665fda250cedf0a1bccee949dbefa9c0e87d`.

The run checked out no Icarus code and made no simulator changes. The same
declaration form appears in generated Caliptra ECC input/output BFM interfaces,
where the clean compile stops before VVP or a UVM test starts; see the
[generated ECC evidence](../caliptra-bfm-generated-ecc-c339-pilot-20261010/README.md).

Duplicate search covered Icarus issues for “parameterized class”, “Invalid
module item”, and “package scoped class”. Issue [#497](https://github.com/dsellerbrock/iverilog-uvm/issues/497)
tracks package-qualified static method calls in expressions, a separate form;
closed issue [#19](https://github.com/dsellerbrock/iverilog-uvm/issues/19) is a
broad language-edge-case tracker and does not resolve this declaration case.
No exact duplicate was found. The requested label did not exist, so it was
created, then the report was filed as
[issue #533](https://github.com/dsellerbrock/iverilog-uvm/issues/533) with
`from-caliptra-dv`.

The exact command, compiler version/hash, source hash, exit code, and resource
log are preserved beside this report. See [`job.sbatch`](job.sbatch),
[`compile.log`](compile.log), [`result.txt`](result.txt),
[`source-revisions.txt`](source-revisions.txt),
[`tool-binary.sha256`](tool-binary.sha256),
[`iverilog-version.txt`](iverilog-version.txt), and [`resource.log`](resource.log).
