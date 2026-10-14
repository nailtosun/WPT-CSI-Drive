# Modulation of the open-end winding CSI

Code: [`open-end-csi/oewCellGates.m`](../open-end-csi/oewCellGates.m), demo [`demo_oew.m`](../open-end-csi/demo_oew.m).

## The converter

In the series-connected open-end winding (OEW) CSI of Yi et al. [1], three H-bridge CSI cells are in series on the DC side and share one DC-link inductor. Each cell feeds one open winding of the machine, with a filter capacitor $C_f$ across the winding. In cell $x$:

| Switch | Connects |
|---|---|
| $S_1$ | upper cell node $P_x$ to winding terminal $X_1$ |
| $S_2$ | $P_x$ to $X_2$ |
| $S_3$ | $X_1$ to lower cell node $N_x$ |
| $S_4$ | $X_2$ to $N_x$ |

As in the two-level CSI, each switch carries current in one direction and blocks both polarities, which suits a monolithic bidirectional GaN switch (BDS). The cell voltage is $u = v_{X1}-v_{X2}$.

## States

The DC-link current must never be interrupted, so one switch of the top pair and one of the bottom pair conduct. With $s_2 = 1-s_1$ and $s_4 = 1-s_3$ this leaves four states:

| State | On | Switching function $p$ | $v_{S1}$ | $v_{S2}$ | $v_{S3}$ | $v_{S4}$ |
|---|---|---|---|---|---|---|
| $A^+$ | $S_1$, $S_4$ | +1 | 0 | $u$ | $u$ | 0 |
| $A^-$ | $S_2$, $S_3$ | −1 | $-u$ | 0 | 0 | $-u$ |
| $Z_L$ | $S_1$, $S_3$ | 0 | 0 | $u$ | 0 | $-u$ |
| $Z_R$ | $S_2$, $S_4$ | 0 | $-u$ | 0 | $u$ | 0 |

The cell injects $p\,I_\mathrm{dc}$ into the winding, with $p = s_1 - s_3$. An off switch always blocks the full cell voltage $|u|$. The modulation decides only when, and for how long, each switch is off.

Over a carrier period the reference is $m = i^*/I_\mathrm{dc}$, and over a fundamental period $m = M\sin\omega t$. Writing $\delta_k$ for the off fraction of $S_k$, every modulation satisfies

$$\delta_1+\delta_4 = 1-m,\qquad \delta_2+\delta_3 = 1+m .$$

So when $|m| = M$, one switch is off for at least $(1+M)/2$ of the carrier period. If no switch turns on more often than $f_s$ times per second, the longest off interval is therefore at least $(1+M)/(2f_s)$.

## Methods

$f_c$ is the output pulse rate, which equals the carrier frequency of the reference method. $c$ is a carrier in $[0, 1]$. For the triangle methods, the valley is at the period start.

| Method | Carrier | Gate logic | Code |
|---|---|---|---|
| RM, reference modulation [1] | sawtooth at $f_c$ | $s_1 = [m>0]$; $s_3 = [m>0]\oplus[\,|m|>c\,]$ | `'Paper'` |
| AST, alternating shoot-through | triangle at $f_c/2$ | $s_1 = [c > \tfrac{1-m}{2}]$, $s_3 = [c > \tfrac{1+m}{2}]$ | `'AST'` |
| AST-ZC | triangle at $f_c/2$ | AST, with a pulse pair for $|m| < m_\min$ | `'ASTzc'` |
| AST-ZC 2× | triangle at $f_c$ | AST-ZC with the carrier doubled | `'ASTzc'` |
| Bipolar | triangle at $f_c/2$ | $s_1 = [c > \tfrac{1-m}{2}]$, $s_3 = 1-s_1$ | `'Bipolar'` |
| PSC, phase-shifted carriers | triangle at $f_c/2$ | AST, with the carrier of the bottom pair shifted | `'PSC'` |
| Rot-$N$, zero-state rotation | sawtooth at $f_c$ | RM, with the other zero state in every $N$th period | `'Rotation'` |

- **RM** keeps the top pair on one switch for each half-wave of $m$. Only the bottom pair switches at the carrier rate, between an active state and a zero state. A top switch is therefore off for half a fundamental period at a time.
- **AST** compares two levels with one triangle. Around each valley it applies $Z_R$, and around each peak $Z_L$, so the zero state alternates between the two legs. In between, it applies one active pulse of width $|m|/f_c$ in each half triangle period. The pulse rate is $f_c$, as in RM, but every switch turns on once per triangle period.
- **AST-ZC** handles the minimum pulse width. Near the current zero crossing an AST pulse becomes shorter than the minimum on-time, $|m| < m_\min$. Dropping these pulses would hold one zero state across the zero crossing for $2\arcsin(m_\min/M)/\omega$. AST-ZC instead applies a pulse of $(2|m|+m_\min)/f_c$ of the wanted active state and a pulse of $m_\min/f_c$ of the opposite one. That keeps the mean at $m$ and every pulse at least $m_\min/f_c$ long.
- **Bipolar PWM** uses only $A^+$ and $A^-$, so every transition commutates both pairs at once.
- **PSC** drives the bottom pair from a shifted triangle. A shift of 180° reproduces AST.
- **Rot-$N$** keeps RM but uses the other zero state in every $N$th period, in which the top pair switches instead of the bottom pair.

## Off interval and switching loss

$P_0$ is the hard-switching loss of an RM bottom switch.

| Method | Turn-on rate, top / bottom pair | Longest off interval × $f_c$ | Loss per switch, $S_1, S_2$ / $S_3, S_4$ ($P_0$) | Cell total ($P_0$) |
|---|---|---|---|---|
| RM | $f_1$ / $f_c$ | $f_c/(2f_1)$ | ≈ 0 / 1 | 2 |
| AST, AST-ZC | $f_c/2$ / $f_c/2$ | $1+M$ | 1/2 / 1/2 | 2 |
| AST-ZC 2× | $f_c$ / $f_c$ | $(1+M)/2$ | 1 / 1 | 4 |
| Bipolar, PSC | $f_c/2$ / $f_c/2$ | $1+M$ | 1/2 / 1/2 | 2 |
| Rot-$N$ | $f_c/N$ / $(N-1)f_c/N$ | ≈ $N-1+M$ | $1/N$ / $(N-1)/N$ | 2 |

AST and its variants meet the bound with equality. All methods except AST-ZC 2× keep the switching loss of RM, because every carrier period still contains one commutation and its reverse per cell. AST spreads that loss equally over the four switches, which halves the loss of the most loaded device. It also removes the fundamental-frequency temperature swing of the RM top switches. Unlike the line-to-line commutation of the two-level CSI, a cell commutates against its own voltage $u$, so the switching loss does not depend on the power factor.

`demo_oew.m` prints the measured off intervals. With ideal pulses they match the table. With a minimum pulse of $0.05/f_c$, AST and Rot-3 hold a zero state across the current zero crossing, and AST-ZC does not.

## Ripple

The winding inductance keeps the winding current at its local mean $m I_\mathrm{dc}$, so the capacitor takes the difference, and $\Delta u_{pp} = I_\mathrm{dc}\rho/C_f$ with:

| Method | $\rho$ |
|---|---|
| RM, AST, AST-ZC, Rot-$N$ | $|m|(1-|m|)/f_c$, largest $1/(4f_c)$ at $|m| = 1/2$ |
| AST-ZC 2× | half of the above |
| Bipolar | $(1-m^2)/f_c$, largest $1/f_c$ at $m = 0$ |
| PSC, 45° | up to $0.39/f_c$ |

The DC-link inductor sees the source voltage minus $\sum_x p_x u_x$. For balanced cells the local mean is constant, so all of the DC-link ripple is at the carrier rate. With one common carrier, RM and AST produce the same staircase of cell voltages, only arranged differently in time, and so the same DC-link ripple. Bipolar PWM roughly doubles it. PSC raises it by about 40 %, AST-ZC by about 10 %, and AST-ZC 2× lowers it by about 35 %. In a machine with a third-harmonic back-EMF, bipolar PWM adds markedly more DC-link ripple, because the zero-sequence voltage is weighted by $\sum_x (p_x - m_x)$, which swings widely under bipolar switching.

## Choice

AST-ZC is the practical choice. It keeps the switching loss of RM, spreads it evenly over the four switches, and limits the off interval to $(1+M)/f_c$ at any speed, including the current zero crossing. It needs one up-down counter and two compare values per cell. Where a shorter off interval is worth twice the switching loss, AST-ZC 2× halves it.

## References

1. S. Yi, D. Luo, W. Liao, S. Huang and S. Huang, "Research on drive circuit and control system for open-end winding PMSM fed by current source inverters with common DC-link," *IEEE J. Emerg. Sel. Topics Power Electron.*, early access, 2026, doi: 10.1109/JESTPE.2026.3688277.
