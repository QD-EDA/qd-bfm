# Row 97 internal ML-DSA trace, retry 2

Fresh one-row diagnostic after job 3228 emitted only four time-zero samples. This observer records the process flag but does not gate on it, so sampler data, verify-valid, destination, write/clear controls, and result-register value can be observed if the controller process flag is low.

Pinned source/compiler unchanged. Resources: 1 CPU / 2 GiB; runner timeout 1,800 seconds; Slurm limit 2,100 seconds. This run is diagnostic; the base testcase remains subject to its original classification.
