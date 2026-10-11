# VVP flag limit on unpacked-array equality

The SystemVerilog array equality expression is legal for unpacked arrays (IEEE 1800-2017 §7.4.3; see [Accellera committee discussion](https://accellera.org/images/eda/sv-bc/10724.html)). The 505-element control compiles; increasing both operands by one element causes c339 VVP code generation to exit 1 with `Exceeded the maximum flag count of 512`.

```sh
iverilog -g2017 -s t -o out.vvp array-eq-506.sv
```

Host: macOS 27.0, arm64. Icarus source revision: `c339b9f2287a743aeb7ab6de6528e8d34a4dd602`; source archive SHA256: `140225a678f61a31725a6850d66671fc7737fd744257982f53d3d91b77a06133`. Compiler binary SHA256: `8fe4c77928f9ee6c08d4e403514fba7efb04501c4ce332ddafbbfdc2a41d2441`.

The pinned Adams Bridge `butterfly_top_tb` hits the same diagnostic comparing its two 1,021-element output arrays. Its full compile log and source/tool provenance are in `../..` under `local-mac/tasks/adams-bridge-v2-0-3-butterfly_top_tb/`.
