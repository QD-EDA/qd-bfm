# DOE reset-release timing trace

Jobs 2109, 2111, 2113, and 2115 show the DOE assertion still fails, even though firmware passes at mcycle 62,260. Job 2115 records one DOE SVA error after reset assertion/deassertion at cycles 244628/244638, but its bounded monitor emitted no samples. The antecedent and status values at failure remain unobserved.

The next diagnostic build changes only the DOE assertion's failure action: it prints the prior-cycle antecedent and DOE status alongside current reset, clear, and status values. The property expression and pass criteria remain unchanged. A self-check confirms the replacement is limited to that error action.

Run-02's completed tree was removed after its gate output and checksums were archived, freeing 698 MiB on DAN-DESKTOP.
