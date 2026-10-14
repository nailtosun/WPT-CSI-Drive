# Legacy modulators

The original time-domain modulators of the two-level CSI, copied unchanged. They compute the gate signals sample by sample over a time vector and include their own terminal-voltage model of the machine. `csiGatesConventional.m` in the folder above replaces them for analysis. These files are not used by the demo and have not been checked against it.

| File | Contents |
|---|---|
| `SVPWM_Modulator.m` | The nine conventional sequences (FSM, HSM, MHSM, DPWM-A to DPWM-D, CSVM, NSPWM) after Halkosaari and Tuusa. Returns the six gate signals and the normalised DC-side voltage `Vinv`; its last output `Vsw` is always zero. |
| `SPWM_Modulator.m` | Carrier-based modulation with a master switch per 60° interval. Needs the Signal Processing Toolbox (`sawtooth`) and has machine parameters set inside. |
| `NSPWM_Modulator.m` | A standalone NSPWM script, originally `NSPWM_Modulator (1).m`. Its function name inside is `NVPWM_Modulatorm`. |
