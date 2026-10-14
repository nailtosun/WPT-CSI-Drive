# CSI modulations

MATLAB code and notes for the modulation of current source inverters (CSIs) with monolithic bidirectional GaN (BiGaN) switches. It covers three groups:

- the conventional space-vector sequences of the two-level CSI;
- two-level sequences that turn every switch on in every sector, so that no switch blocks voltage for longer than a few sampling periods;
- the modulation methods of the series-connected open-end winding CSI.

The gate functions return ideal gate signals over one fundamental period. They are meant for analysis: switch voltages, off intervals, ripple and spectra. A C version of the two-level modulator for PLECS is included.

## Folders

| Folder | Contents |
|---|---|
| [`two-level-conventional/`](two-level-conventional) | `csiGatesConventional.m`: FSM, HSM, MHSM, DPWM-A to DPWM-D, CSVM, NSPWM. `demo_conventional.m`, `csiTimingDiagram.m`. `legacy/`: the original time-domain modulators. |
| [`bigan-compatible/`](bigan-compatible) | `csiGatesBigan.m`: CSVM-A, 3Z-SVM, FSM-R, NSPWM-R, zero-vector placement (ZVP). `csiCarrierCSVMA.m`: carrier-based CSVM-A. `csiZVPLambda.m`: zero-time split for ZVP. `demo_bigan.m`, `csiTimingDiagram.m`. |
| [`open-end-csi/`](open-end-csi) | `oewCellGates.m`: reference modulation of Yi et al., AST, AST-ZC, bipolar, phase-shifted carriers, zero-state rotation. `demo_oew.m`. |
| [`plecs-c-modulator/`](plecs-c-modulator) | `csiModulatorCode.m`: C code of a PLECS C-Script modulator for seven two-level methods (NSPWM, FSM, CSVM, CSVM-A, 3Z-SVM, FSM-R, NSPWM-R). `write_cscript_file.m` writes it to `csi_modulator_cscript.c`. |
| [`docs/`](docs) | Notes on the methods, listed below. |

Each folder runs on its own; none needs another folder on the MATLAB path.

## Notes

1. [CSI modulation basics](docs/01-csi-basics.md): switches, vectors, sectors, dwell times, zero vectors, commutation of a BDS pair, measures, and a bound on the off interval.
2. [Conventional two-level CSI modulations](docs/02-two-level-conventional.md): the nine sequences, their long off intervals and their cost.
3. [Two-level CSI modulations for BiGaN switches](docs/03-bigan-compatible.md): why the off interval matters, the zero-vector argument, CSVM-A, 3Z-SVM, FSM-R, NSPWM-R and ZVP, with closed forms, cost, PLECS results and the carrier-based realisation.
4. [Modulation of the open-end winding CSI](docs/04-open-end-csi.md): cell states, the seven methods, off interval, switching loss and ripple.

## Quick start

```matlab
cd two-level-conventional
demo_conventional                               % table and timing diagrams

Np = 600; Nppc = 200; N = Np*Nppc;              % sampling periods per fundamental period, samples per period
th = (0:N-1)'/N*2*pi;                           % i_a* = M*Idc*sin(th)
g  = csiGatesConventional('CSVM', th, Np, 0.8); % g.S: N x 6 gates [S1 .. S6], g.state: vector 1..9

cd ../bigan-compatible
g  = csiGatesBigan('FSM_R', th, Np, 0.8, struct('eps', 0.02, 'N', 4));
```

`demo_bigan.m` and `demo_oew.m` work the same way.

## Conventions

- **Switches.** $S_1$, $S_3$, $S_5$ connect rail $P$ to phases $a$, $b$, $c$; $S_2$, $S_4$, $S_6$ connect the phases to rail $N$. Gate matrix columns are `[S1 S2 S3 S4 S5 S6]` = `[Sap San Sbp Sbn Scp Scn]`.
- **Vectors.** $I_1$ to $I_6$ are active and $I_7$, $I_8$, $I_9$ short phase $a$, $b$, $c$. The code's state numbers are the same.
- **Reference.** $i_a^* = M I_\mathrm{dc}\sin\omega t$, with `th` $=\omega t$. Sector 1 spans $\omega t = 60^\circ$ to $120^\circ$, centred on the crest of $i_a$, between $I_6$ and $I_1$.
- **Sampling.** The dwell times of a sampling period $T_s$ are computed from the reference at the middle of the period.

## Verification

- **Split gate functions.** `csiGatesConventional.m` and `csiGatesBigan.m` were split from `csiGates.m` of the CSI-Analytical-Calculations repository. They give identical gate signals in all 474 test cases: every method, five modulation indices, three period counts and several option sets.
- **Demos.** `demo_bigan.m` and `demo_oew.m` reproduce the closed-form longest off intervals of the notes within 0.01 sampling periods. The carrier-based CSVM-A matches the sequence model in every sample.
- **PLECS.** The gate model reproduces the DC-link and capacitor ripple of PLECS simulations of a PMSM drive within 2 % for FSM, CSVM, NSPWM, FSM-R and CSVM-A. The C modulator is the one used in those simulations.
- **Copied files.** The other files are copies of that repository; only their comments were changed.

## Requirements

MATLAB R2019b or newer. No toolbox is needed, except the Signal Processing Toolbox for `legacy/SPWM_Modulator.m` (`sawtooth`).

## References

1. T. Halkosaari and H. Tuusa, "Optimal vector modulation of a PWM current source converter according to minimal switching losses," in *Proc. IEEE PESC*, 2000, pp. 127–132.
2. T. Halkosaari and H. Tuusa, "Optimal vector modulation of a PWM current source converter according to minimum distortion constraint," in *Proc. IPEC*, 2000, pp. 958–963.
3. Q. Lei, B. Wang and F. Z. Peng, "Unified space vector PWM control for current source inverter," in *Proc. IEEE ECCE*, 2012, pp. 4696–4702.
4. E. Ün and A. M. Hava, "A near-state PWM method with reduced switching losses and reduced common-mode voltage for three-phase voltage source inverters," *IEEE Trans. Ind. Appl.*, vol. 45, no. 2, pp. 782–793, 2009.
5. N. Tosun, D. Molligoda, X. Deng and B. Mecrow, "Utilizing integrated GaN half bridges for an integrated single-stage current-source inverter motor drive," *IEEE J. Emerg. Sel. Topics Power Electron.*, vol. 14, no. 4, pp. 4222–4235, 2026.
6. S. Yi, D. Luo, W. Liao, S. Huang and S. Huang, "Research on drive circuit and control system for open-end winding PMSM fed by current source inverters with common DC-link," *IEEE J. Emerg. Sel. Topics Power Electron.*, early access, 2026.
7. J. Huber and J. W. Kolar, "Monolithic bidirectional power transistors – opening new horizons in power electronics," *IEEE Power Electronics Magazine*, vol. 10, no. 1, pp. 28–38, 2023.
8. Infineon Technologies AG, "IGLT65R055B2 CoolGaN bi-directional switch 650 V G5," datasheet, rev. 1.0, May 2025.
