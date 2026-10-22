# Intern log triage, checked

The intern correctly identified the first logged hard error at `pv_rst_configuration.svh:149` (`$psprintf` argument error) and representative generated-source problems: nested class-property paths at `pv_predictor.svh:156`, dynamic-array slicing at `pv_env_configuration.svh:152`, and response assignments through input modport directions in the PV read/write driver BFMs.

The intern also called the QD-BFM predictor member errors “structural/design errors.” That is not yet established. The compatibility package intentionally parameterizes `ahb_reg_predictor` over the generated transfer type, whose declared fields include `RnW`, `address`, `size`, `data`, and `resp`; Icarus reports several of those fields absent in this environment. A focused compile of the generic type path is needed before changing that BFM or assigning the errors to Icarus.
