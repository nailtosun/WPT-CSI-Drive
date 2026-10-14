# Conventional two-level CSI modulations

Code: [`two-level-conventional/csiGatesConventional.m`](../two-level-conventional/csiGatesConventional.m), demo [`demo_conventional.m`](../two-level-conventional/demo_conventional.m). Names and measures are defined in [01-csi-basics.md](01-csi-basics.md).

These are the space-vector sequences of the literature [1]–[5]. Each one leaves some switches off for a whole sector or more. The sequences that avoid this are in [03-bigan-compatible.md](03-bigan-compatible.md).

## Sequences

The nine sequences differ in which zero vectors they use and where the states sit inside the sampling period. The table gives the slots of one sampling period, with dwell times as fractions of $T_s$, and the Sector 1 example ($S_k = I_6$, $S_n = I_1$, $Z_x = I_7$, $Z_k = I_8$).

| Method | Slots in one sampling period | Sector 1 | $n_c$ | Code |
|---|---|---|---|---|
| FSM | $Z_x\,\tfrac{d_0}{2},\ S_k\,d_k,\ S_n\,d_n,\ Z_x\,\tfrac{d_0}{2}$ | $I_7, I_6, I_1, I_7$ | 3 | `'FSM'` |
| HSM | $S_k\,\tfrac{d_k}{2},\ Z_x\,\tfrac{d_0}{2},\ S_n\,d_n,\ Z_x\,\tfrac{d_0}{2},\ S_k\,\tfrac{d_k}{2}$ | $I_6, I_7, I_1, I_7, I_6$ | 4 | `'HSM'` |
| MHSM | $Z_x\,\tfrac{d_0}{2},\ S_k\,\tfrac{d_k}{2},\ S_n\,d_n,\ S_k\,\tfrac{d_k}{2},\ Z_x\,\tfrac{d_0}{2}$ | $I_7, I_6, I_1, I_6, I_7$ | 4 | `'MHSM'` |
| DPWM-A | $S_k\,\tfrac{d_k}{2},\ S_n\,\tfrac{d_n}{2},\ Z_x\,\tfrac{d_0}{2},\ S_k\,\tfrac{d_k}{2},\ S_n\,\tfrac{d_n}{2},\ Z_x\,\tfrac{d_0}{2}$ | $I_6, I_1, I_7, I_6, I_1, I_7$ | 6 | `'DPWM_A'` |
| DPWM-B | $S_k\,\tfrac{d_k}{2},\ S_n\,\tfrac{d_n}{2},\ Z_x\,d_0,\ S_n\,\tfrac{d_n}{2},\ S_k\,\tfrac{d_k}{2}$ | $I_6, I_1, I_7, I_1, I_6$ | 4 | `'DPWM_B'` |
| DPWM-C | $Z_x\,\tfrac{d_0}{4},\ S_k\,\tfrac{d_k}{2},\ S_n\,\tfrac{d_n}{2},\ Z_x\,\tfrac{d_0}{2},\ S_n\,\tfrac{d_n}{2},\ S_k\,\tfrac{d_k}{2},\ Z_x\,\tfrac{d_0}{4}$ | $I_7, I_6, I_1, I_7, I_1, I_6, I_7$ | 6 | `'DPWM_C'` |
| DPWM-D | $S_k\,\tfrac{d_k}{2},\ Z_x\,\tfrac{d_0}{4},\ S_n\,\tfrac{d_n}{2},\ Z_x\,\tfrac{d_0}{2},\ S_n\,\tfrac{d_n}{2},\ Z_x\,\tfrac{d_0}{4},\ S_k\,\tfrac{d_k}{2}$ | $I_6, I_7, I_1, I_7, I_1, I_7, I_6$ | 6 | `'DPWM_D'` |
| CSVM | $Z_k\,\tfrac{d_0}{4},\ S_k\,\tfrac{d_k}{2},\ S_n\,\tfrac{d_n}{2},\ Z_x\,\tfrac{d_0}{2},\ S_n\,\tfrac{d_n}{2},\ S_k\,\tfrac{d_k}{2},\ Z_k\,\tfrac{d_0}{4}$ | $I_8, I_6, I_1, I_7, I_1, I_6, I_8$ | 6 | `'CSVM'` |
| NSPWM | $S_\mathrm{out}\,\tfrac{d_\mathrm{out}}{2},\ S_k\,\tfrac{d_k}{2},\ S_n\,d_n,\ S_k\,\tfrac{d_k}{2},\ S_\mathrm{out}\,\tfrac{d_\mathrm{out}}{2}$ | $I_2, I_1, I_6, I_1, I_2$ | 4 | `'NSPWM'` |

- **FSM, HSM, MHSM** are full-wave symmetric, half-wave symmetric and modified half-wave symmetric modulation [1].
- **DPWM-A to DPWM-D** are the discontinuous sequences of the unified space-vector PWM of Lei et al. [3].
- **CSVM**, centered space-vector modulation [2], uses two zero vectors so that every transition commutates one switch pair: $Z_k$ at the ends of the period and $Z_x$ in the middle.
- **NSPWM**, near-state PWM [4], [5], uses three adjacent active vectors and no zero vector. It needs $M \ge 2/3$, and its sectors are shifted by $30^\circ$ against those of the other sequences. The Sector 1 example is for a reference within $\pm30^\circ$ of $I_1$. Its dwell times are $d_\mathrm{out} = 1-M\sin(\tfrac{\pi}{6}+\theta_2)$, $d_k = M\sin(\tfrac{\pi}{6}+\theta_2)+M\cos\theta_2-1$ and $d_n = 1-M\cos\theta_2$, with $\theta_2\in[0,\tfrac{\pi}{3}]$ measured back from the end of the NSPWM sector.

## Long off intervals

A switch turns on only in a vector that uses it. In a sector, the four switches of $S_k$ and $S_n$ are used by the active vectors, and $Z_x$ adds the opposite switch of the shared phase. The two remaining switches are not used at all.

| Method | Switches that never turn on in Sector 1 | Longest off interval |
|---|---|---|
| FSM, HSM, MHSM, DPWM-A to D | $S_3$, $S_5$ | $T_1/6$, twice per fundamental period |
| CSVM | $S_5$ | $T_1/6$, once per fundamental period |
| NSPWM | $S_2$, $S_5$ | $T_1/3$ |

The interval is a fixed share of the fundamental period. It does not depend on $M$, $\varphi$ or the sampling frequency. At 50 Hz it lasts 3.3 ms ($T_1/6$) or 6.7 ms ($T_1/3$), and it grows as the motor slows down. `demo_conventional.m` prints the measured values.

During such an interval the switch blocks one line voltage without interruption under the single-zero-vector sequences. Under CSVM and NSPWM the voltage steps between the two line voltages in every period, but the switch still does not conduct.

## Cost at an equal number of commutations per second

The table gives the ideal gate model at $M = 0.8$, with every sequence at $n_c f_s = 4f_b$ and $f_b/f_1 = 1200$.

| Method | $n_c$ | $\bar v_c/V_{LL}$, $\varphi = 0^\circ$ / $30^\circ$ | $\Delta I\,L_\mathrm{dc}f_b/V_t$, $\varphi = 0^\circ$ / $30^\circ$ | $\Delta u\,C_f f_b/I_\mathrm{dc}$ | $v_\mathrm{cm}/V_{LL}$, rms / peak |
|---|---|---|---|---|---|
| FSM | 3 | 0.64 / 0.64 | 0.28 / 0.27 | 0.19 | 0.29 / 0.58 |
| HSM | 4 | 0.83 / 0.72 | 0.37 / 0.36 | 0.25 | 0.29 / 0.58 |
| MHSM | 4 | 0.54 / 0.48 | 0.37 / 0.36 | 0.25 | 0.29 / 0.58 |
| DPWM-A | 6 | 0.64 / 0.64 | 0.28 / 0.27 | 0.19 | 0.29 / 0.58 |
| DPWM-B | 4 | 0.54 / 0.72 | 0.37 / 0.32 | 0.25 | 0.29 / 0.58 |
| DPWM-C | 6 | 0.64 / 0.64 | 0.28 / 0.36 | 0.30 | 0.29 / 0.58 |
| DPWM-D | 6 | 0.83 / 0.80 | 0.55 / 0.47 | 0.38 | 0.29 / 0.58 |
| CSVM | 6 | 0.64 / 0.64 | 0.28 / 0.36 | 0.30 | 0.24 / 0.58 |
| NSPWM | 4 | 0.48 / 0.54 | 0.24 / 0.42 | 0.36 | 0.19 / 0.29 |

- **Switching loss.** FSM, DPWM-A, DPWM-C and CSVM commutate through the three line voltages equally often, so their mean commutation voltage is the same, $2/\pi$ of the peak line voltage. MHSM, DPWM-B and NSPWM have the lowest mean commutation voltage at unity power factor; the ranking changes with the power factor.
- **DC-side voltage.** FSM and DPWM-A produce the same DC-side voltage at an equal commutation rate: DPWM-A repeats the FSM pattern twice per period. CSVM and DPWM-C also produce the same DC-side voltage, because only the identity of the zero vector differs, and that does not change $v_{PN}$.
- **Common-mode voltage.** NSPWM has the lowest, because it uses no zero vector.

## Legacy code

[`legacy/`](../two-level-conventional/legacy) holds the original time-domain modulators, copied unchanged: `SVPWM_Modulator.m` (the nine sequences, with a built-in machine model for the terminal voltages), `SPWM_Modulator.m` (a carrier-based modulator) and `NSPWM_Modulator.m`. `csiGatesConventional.m` replaces them for analysis. The legacy files are not used by the demo and have not been checked against it.

## References

1. T. Halkosaari and H. Tuusa, "Optimal vector modulation of a PWM current source converter according to minimal switching losses," in *Proc. IEEE PESC*, 2000, pp. 127–132.
2. T. Halkosaari and H. Tuusa, "Optimal vector modulation of a PWM current source converter according to minimum distortion constraint," in *Proc. IPEC*, 2000, pp. 958–963.
3. Q. Lei, B. Wang and F. Z. Peng, "Unified space vector PWM control for current source inverter," in *Proc. IEEE ECCE*, 2012, pp. 4696–4702.
4. E. Ün and A. M. Hava, "A near-state PWM method with reduced switching losses and reduced common-mode voltage for three-phase voltage source inverters," *IEEE Trans. Ind. Appl.*, vol. 45, no. 2, pp. 782–793, 2009.
5. N. Tosun, D. Molligoda, X. Deng and B. Mecrow, "Utilizing integrated GaN half bridges for an integrated single-stage current-source inverter motor drive," *IEEE J. Emerg. Sel. Topics Power Electron.*, vol. 14, no. 4, pp. 4222–4235, 2026.
