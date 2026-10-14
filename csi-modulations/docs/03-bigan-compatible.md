# Two-level CSI modulations for bidirectional GaN switches

Code: [`bigan-compatible/csiGatesBigan.m`](../bigan-compatible/csiGatesBigan.m), [`csiCarrierCSVMA.m`](../bigan-compatible/csiCarrierCSVMA.m), [`csiZVPLambda.m`](../bigan-compatible/csiZVPLambda.m), demo [`demo_bigan.m`](../bigan-compatible/demo_bigan.m). Names and measures are defined in [01-csi-basics.md](01-csi-basics.md).

These sequences turn every switch on in every sector. No switch then stays off for longer than a few sampling periods, at any fundamental frequency.

## Why the off interval matters

A monolithic bidirectional GaN (BiGaN) switch blocks both polarities in one device, which suits the CSI [1]. Its substrate cannot be tied to either source, so commercial devices clamp it on chip [2]. Even so, the datasheets give no rating for continuous DC blocking. For the Infineon IGLT65R055B2 [3]:

| Rating | Value | Condition |
|---|---|---|
| Continuous blocking voltage | 340 V rms | AC, frequency at least 45 Hz |
| Transient blocking voltage | ±650 V | at most 5 ms |
| Surge blocking voltage | ±850 V | at most 1 µs |

The conventional sequences leave a switch off for $T_1/6$, and NSPWM for $T_1/3$ ([02-two-level-conventional.md](02-two-level-conventional.md)). $T_1/6$ exceeds 5 ms below 33 Hz, and $T_1/3$ below 67 Hz. Start-up and low speed are therefore outside the rating.

## The cause and the remedy

In every sector three switches belong to neither active vector, and each is turned on by a different zero vector:

| Sector | $\omega t$ | $S_k$ | $S_n$ | Only $Z_x$ turns on | Only $Z_k$ turns on | Only $Z_n$ turns on |
|---|---|---|---|---|---|---|
| 1 | 60°–120° | $I_6$ | $I_1$ | $S_2$ | $S_3$ | $S_5$ |
| 2 | 120°–180° | $I_1$ | $I_2$ | $S_5$ | $S_2$ | $S_4$ |
| 3 | 180°–240° | $I_2$ | $I_3$ | $S_4$ | $S_5$ | $S_1$ |
| 4 | 240°–300° | $I_3$ | $I_4$ | $S_1$ | $S_4$ | $S_6$ |
| 5 | 300°–360° | $I_4$ | $I_5$ | $S_6$ | $S_1$ | $S_3$ |
| 6 | 0°–60° | $I_5$ | $I_6$ | $S_3$ | $S_6$ | $S_2$ |

A sequence in which no switch stays off for a whole sector must use all three zero vectors in every sector. The conventional sequences use only $Z_x$, or $Z_x$ and $Z_k$, or none. The three zero vectors are interchangeable for the output, so adding the missing ones changes only the common-mode voltage and which switches conduct. The order is restricted only by the wish to commutate one switch pair at a time: $Z_x$ may sit next to $S_k$ or $S_n$, $Z_k$ only next to $S_k$, and $Z_n$ only next to $S_n$.

## Sequences

| Method | Slots in one sampling period ($T_s$) | $n_c$ | Code |
|---|---|---|---|
| CSVM-A | $Z_k\,\tfrac{d_0}{4},\ S_k\,\tfrac{d_k}{2},\ S_n\,\tfrac{d_n}{2},\ Z\,\tfrac{d_0}{2},\ S_n\,\tfrac{d_n}{2},\ S_k\,\tfrac{d_k}{2},\ Z_k\,\tfrac{d_0}{4}$, with $Z = Z_x$ in even and $Z_n$ in odd periods | 6 | `'CSVM_A'` |
| 3Z-SVM | $Z_k\,\tfrac{d_0}{8},\ S_k\,\tfrac{d_k}{2},\ Z_x\,\tfrac{d_0}{4},\ S_n\,\tfrac{d_n}{2},\ Z_n\,\tfrac{d_0}{4},\ S_n\,\tfrac{d_n}{2},\ Z_x\,\tfrac{d_0}{4},\ S_k\,\tfrac{d_k}{2},\ Z_k\,\tfrac{d_0}{8}$ | 8 | `'3Z'` |
| FSM-R, refresh period | $Z_x\,(\tfrac{d_0}{2}-\varepsilon),\ S_k\,\tfrac{d_k}{2},\ Z_k\,\varepsilon,\ S_k\,\tfrac{d_k}{2},\ S_n\,\tfrac{d_n}{2},\ Z_n\,\varepsilon,\ S_n\,\tfrac{d_n}{2},\ Z_x\,(\tfrac{d_0}{2}-\varepsilon)$ | 7 | `'FSM_R'` |
| FSM-R, other periods | FSM: $Z_x\,\tfrac{d_0}{2},\ S_k\,d_k,\ S_n\,d_n,\ Z_x\,\tfrac{d_0}{2}$ | 3 | |
| NSPWM-R, refresh period | $Z_1\,\varepsilon,\ S_\mathrm{out}\,(\tfrac{d_\mathrm{out}}{2}-\varepsilon),\ S_k\,(\tfrac{d_k}{2}+\varepsilon),\ S_n\,(\tfrac{d_n}{2}-\varepsilon),\ Z_2\,\varepsilon,\ S_n\,(\tfrac{d_n}{2}-\varepsilon),\ S_k\,(\tfrac{d_k}{2}+\varepsilon),\ S_\mathrm{out}\,(\tfrac{d_\mathrm{out}}{2}-\varepsilon)$ | 8 | `'NSPWM_R'` |
| NSPWM-R, other periods | NSPWM | 4 | |
| ZVP | CSVM-A with outer slots $\lambda\tfrac{d_0}{2}$ and inner slot $(1-\lambda)\,d_0$ | 6 | `'CSVM_Z'` |

- **CSVM-A** keeps the CSVM pattern but alternates the inner zero vector between $Z_x$ and $Z_n$. The pulse timing is the same in every period, so the line currents, the DC-side voltage and the ripple are those of CSVM.
- **3Z-SVM** applies all three zero vectors in every period. It has the shortest off interval, at the price of eight commutations per period.
- **FSM-R** keeps FSM and, in every $N$th period, places a short pulse of $Z_k$ in the middle of $S_k$ and of $Z_n$ in the middle of $S_n$. Their time $2\varepsilon T_s$ is taken from $Z_x$, so the active times do not change. On average it has $3+4/N$ commutations per period.
- **NSPWM-R** adds two zero pulses to NSPWM in every $N$th period. $Z_1$ shorts the phase shared by $S_\mathrm{out}$ and $S_k$, and $Z_2$ the phase shared by $S_k$ and $S_n$. On average it has $4+4/N$ commutations per period and keeps the range $M \ge 2/3$.
- **ZVP**, zero-vector placement, is CSVM-A with a free split $\lambda$ of the zero time between the outer slots and the inner slot ($\lambda = 1/2$ is CSVM-A). It is described below.

One simpler idea was examined and dropped: one zero vector per period in the order $Z_k, Z_x, Z_n, Z_x$. It needs only three commutations per period, but it moves the active pulses from period to period, and the line current then contains a component of $0.18\,I_\mathrm{dc}$ at $0.75 f_s$.

## Longest off interval

The intervals follow from the slot durations. All are fixed in sampling periods and do not depend on the fundamental frequency.

| Method | Longest off interval | At $M = 0.8$ | In $T_b = 4/(n_c f_s)$ |
|---|---|---|---|
| CSVM-A | $(\tfrac52+\tfrac{\sqrt3}{4}M)\,T_s$ | $2.85\,T_s$ | 4.27 |
| 3Z-SVM | $\tfrac{3+M}{4}\,T_s$ | $0.95\,T_s$ | 1.90 |
| FSM-R | $(N+\tfrac{\sqrt3}{2}M)\,T_s$ | $4.69\,T_s$ ($N = 4$) | 4.69 |
| NSPWM-R | $(N+\tfrac12-\varepsilon)\,T_s$ | $4.48\,T_s$ ($N = 4$, $\varepsilon = 0.02$) | 5.60 |

The worst case of CSVM-A occurs when a sector change shifts a switch from the even to the odd periods, so that it misses one turn. That happens when the sector boundaries fall at varying positions of the period pattern, as with asynchronous sampling. `demo_bigan.m` reproduces all four values to 0.01 $T_s$.

## Cost at an equal number of commutations per second

The table gives the ideal gate model at $M = 0.8$, with $f_b/f_1 = 1200$, $\varepsilon = 0.02$ and $N = 4$, in the units of [02-two-level-conventional.md](02-two-level-conventional.md).

| Method | $n_c$ | $\bar v_c/V_{LL}$, $\varphi = 0^\circ$ / $30^\circ$ | $\Delta I\,L_\mathrm{dc}f_b/V_t$, $\varphi = 0^\circ$ / $30^\circ$ | $\Delta u\,C_f f_b/I_\mathrm{dc}$ | $v_\mathrm{cm}/V_{LL}$, rms / peak |
|---|---|---|---|---|---|
| CSVM (reference) | 6 | 0.64 / 0.64 | 0.28 / 0.36 | 0.30 | 0.24 / 0.58 |
| CSVM-A | 6 | 0.64 / 0.64 | 0.28 / 0.36 | 0.30 | 0.21 / 0.58 |
| 3Z-SVM | 8 | 0.83 / 0.71 | 0.55 / 0.60 | 0.45 | 0.24 / 0.58 |
| FSM-R | 4 | 0.69 / 0.66 | 0.38 / 0.36 | 0.25 | 0.28 / 0.58 |
| NSPWM-R | 5 | 0.48 / 0.54 | 0.32 / 0.53 | 0.46 | 0.20 / 0.58 |

- **CSVM-A costs nothing against CSVM.** Commutation voltage, DC-link ripple and capacitor ripple are the same, because only the identity of the inner zero vector changes. Its rms common-mode voltage is 11 % lower at unity power factor and equal within 2 % at power factor 0.83.
- **3Z-SVM** brings the off interval below one sampling period, but it has about twice the DC-link ripple of CSVM, 1.5 times its capacitor ripple and a 30 % higher commutation voltage at unity power factor.
- **FSM-R and NSPWM-R** keep the pattern of FSM and NSPWM in $N-1$ of $N$ periods. FSM-R raises the mean commutation voltage by 3 to 7 %. Their refresh pulses add a line-current component at $0.75 f_s$ of 0.9 % of $I_\mathrm{dc}$ (FSM-R) and 1.5 % (NSPWM-R). CSVM-A and 3Z-SVM add none, because their pulse timing repeats in every period.

## Simulation check

A permanent-magnet synchronous machine (PMSM) drive was simulated in PLECS [4] at 1500 rpm and 10 N m ($M = 0.777$, power factor 0.83, $V_{LL} = 474$ V, $I_\mathrm{dc} = 6.875$ A, $L_\mathrm{dc} = 128$ mH, $C_f = 1.56$ µF), with all sequences at 200 000 commutations per second:

| Method | $T_s$ (µs) | $n_c$ | $\bar v_c$ (V) | Switching loss, rel. to FSM | $\Delta u$ (V) | $\Delta I$ (mA) | $v_\mathrm{cm}$ rms / peak (V) |
|---|---|---|---|---|---|---|---|
| FSM | 15 | 3 | 301 | 1.00 | 16.1 | 11.8 | 133 / 280 |
| CSVM | 30 | 6 | 301 | 1.00 | 25.9 | 16.1 | 112 / 280 |
| NSPWM | 20 | 4 | 265 | 0.88 | 32.9 | 19.7 | 96 / 142 |
| FSM-R | 20 | 4 | 306 | 1.02 | 21.8 | 15.9 | 131 / 284 |
| CSVM-A | 30 | 6 | 301 | 1.00 | 25.9 | 16.1 | 114 / 281 |

The ideal gate model reproduces the ripple values within 2 %.

## Zero-vector placement (ZVP)

The split $\lambda$ of the zero time in CSVM-A does not change any dwell time, so it leaves the output untouched. It does set the harmonic of the DC-side voltage $v_{PN}$ at the sampling frequency. For two equal line voltages $V$ the amplitude of that harmonic is

$$|a_1| = \frac{4V}{\pi}\cos\frac{\pi d_0}{2}\,\left|\sin\!\left(\pi d_0\left(\lambda-\tfrac12\right)\right)\right| ,$$

which is zero for CSVM-A ($\lambda = 1/2$) and largest at $\lambda = 0$ or 1. `csiZVPLambda.m` solves the general form, with unequal line voltages, for one $\lambda$ per sampling period. That holds the harmonic at the same amplitude throughout the fundamental period. It was developed for wireless power transfer from the DC-link current ripple, where the flat amplitude gives a constant received power. It is the CSI counterpart of the carrier phase shift used for this purpose in voltage source inverters.

At $M = 0.777$ and power factor 0.83, with $\lambda$ kept between 0.1 and 0.9:

- **Flat harmonic.** It stays within ±1 %, with $\lambda$ between 0.61 and 0.89 over the fundamental period.
- **Commutations and off interval.** It keeps six commutations per period and an off interval of about $3\,T_s$.
- **Ripple.** The DC-link ripple is 16 % higher than with CSVM-A, and the capacitor ripple 7 % higher.
- **Range.** A flat level is reachable up to $M \approx 0.9$ at power factor 0.83, and up to $M \approx 0.75$ at power factor 0.5.

## Carrier-based CSVM-A

`csiCarrierCSVMA.m` realises CSVM-A, and CSVM with `'mode','CSVM'`, with one symmetric triangular carrier per sampling period. The carrier rises from 0 at the period start to 1 at the centre and falls back to 0. Each switch is driven by a window comparison $L \le c < U$ with two compare levels per period. That is what an up-down counter with two compare registers produces, for example the ePWM module of a C2000 microcontroller. The levels follow from the three current references, with no sector table. `demo_bigan.m` confirms that it gives the same gate signals as the sequence model in every sample.

## PLECS C-Script modulator

[`plecs-c-modulator/csiModulatorCode.m`](../plecs-c-modulator/csiModulatorCode.m) holds the C code of a PLECS C-Script block for seven two-level methods. They are selected by `mod_method`: 0 NSPWM, 1 FSM, 2 CSVM, 3 CSVM-A, 4 3Z-SVM, 5 FSM-R and 6 NSPWM-R. The block also takes the refresh pulse width and period, a minimum slot length and the number of reference updates per period. `write_cscript_file.m` writes the code to a plain C file for reading or porting. ZVP is not in it yet.

## References

1. J. Huber and J. W. Kolar, "Monolithic bidirectional power transistors – opening new horizons in power electronics," *IEEE Power Electronics Magazine*, vol. 10, no. 1, pp. 28–38, 2023.
2. A. Minetto *et al.*, "Impact of substrate bias on the switching behavior of GaN bidirectional switches," in *Proc. IEEE WiPDA*, 2025.
3. Infineon Technologies AG, "IGLT65R055B2 CoolGaN bi-directional switch 650 V G5," datasheet, rev. 1.0, May 2025.
4. N. Tosun and B. Mecrow, "Continuous PWMs for current source inverters considering bidirectional GaN limitations," conference paper draft, Newcastle University, 2026.
