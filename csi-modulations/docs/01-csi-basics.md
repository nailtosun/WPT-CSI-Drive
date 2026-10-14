# CSI modulation basics

This note sets out the circuit, the names and the measures that the other notes and the code use. It covers the two-level current source inverter (CSI). The open-end winding CSI has its own note, [04-open-end-csi.md](04-open-end-csi.md).

## The converter

A DC-link inductor $L_\mathrm{dc}$ carries the DC-link current $I_\mathrm{dc}$. Six switches distribute it to the three phases, and a filter capacitor $C_f$ on each phase takes the switched current.

| Switch | Connects | Code column |
|---|---|---|
| $S_1$ | rail $P$ to phase $a$ | 1 (`Sap`) |
| $S_2$ | phase $a$ to rail $N$ | 2 (`San`) |
| $S_3$ | rail $P$ to phase $b$ | 3 (`Sbp`) |
| $S_4$ | phase $b$ to rail $N$ | 4 (`Sbn`) |
| $S_5$ | rail $P$ to phase $c$ | 5 (`Scp`) |
| $S_6$ | phase $c$ to rail $N$ | 6 (`Scn`) |

The numbering follows Halkosaari and Tuusa [1]. A switch carries current in one direction only, from its input terminal ($P$ for $S_1$, $S_3$, $S_5$, the phase for $S_2$, $S_4$, $S_6$) to its output terminal, but it must block voltage of either polarity. With a monolithic bidirectional switch (BDS), such as a bidirectional GaN (BiGaN) device, one transistor with two gates does both jobs. Gate $F$ sits next to the output terminal and holds forward voltage; gate $R$ sits next to the input terminal and holds reverse voltage [2].

## Vectors

$I_\mathrm{dc}$ must never be interrupted, so exactly one top switch and one bottom switch conduct at any time. That gives nine states.

| Vector | Conducting pair | Code state | Kind |
|---|---|---|---|
| $I_1$ | $S_1$, $S_6$ | 1 | active |
| $I_2$ | $S_3$, $S_6$ | 2 | active |
| $I_3$ | $S_3$, $S_2$ | 3 | active |
| $I_4$ | $S_5$, $S_2$ | 4 | active |
| $I_5$ | $S_5$, $S_4$ | 5 | active |
| $I_6$ | $S_1$, $S_4$ | 6 | active |
| $I_7$ | $S_1$, $S_2$ | 7 | zero, shorts phase $a$ |
| $I_8$ | $S_3$, $S_4$ | 8 | zero, shorts phase $b$ |
| $I_9$ | $S_5$, $S_6$ | 9 | zero, shorts phase $c$ |

An active vector carries $I_\mathrm{dc}$ from one phase to another. A zero vector shorts the DC link through the two switches of one phase.

## Reference, sectors and dwell times

The code uses the phase-$a$ current reference

$$i_a^* = M\,I_\mathrm{dc}\sin\omega t ,$$

with modulation index $M \le 1$ (`th` $=\omega t$ in the code). The capacitor voltage of phase $a$ is $V_t\sin(\omega t+\varphi)$, where $\varphi$ is the angle between the phase voltage and the phase current; the power factor is $\cos\varphi$. The peak line-to-line voltage is $V_{LL}=\sqrt3\,V_t$.

The reference vector turns through six sectors per fundamental period $T_1$. Sector 1 spans $\omega t = 60^\circ$ to $120^\circ$, centred on the crest of $i_a$, and lies between $I_6$ and $I_1$. In every sector the reference lies between two active vectors, called $S_k$ (the one it leaves) and $S_n$ (the one it approaches). In Sector 1, $S_k = I_6$ and $S_n = I_1$. Their dwell times, as fractions of the sampling period $T_s$, are

$$d_k = M\sin\left(\tfrac{\pi}{6}-\theta\right),\qquad d_n = M\sin\left(\tfrac{\pi}{6}+\theta\right),\qquad d_0 = 1-d_k-d_n ,$$

where $\theta\in[-30^\circ, 30^\circ]$ is the angle of the reference from the centre of the sector. The code samples the reference once per sampling period, at the middle of the period. The zero time $d_0$ is smallest at the sector centre, $1-M$.

## Zero vectors

$S_k$ and $S_n$ share one switch; call its phase $x$. In Sector 1 the shared switch is $S_1$ and $x = a$. The three zero vectors then play different roles:

| Name | Shorts | Sector 1 | Neighbours with one commutation |
|---|---|---|---|
| $Z_x$ | the shared phase | $I_7$ | $S_k$ and $S_n$ |
| $Z_k$ | the other phase of $S_k$ | $I_8$ | $S_k$ only |
| $Z_n$ | the other phase of $S_n$ | $I_9$ | $S_n$ only |

All three give zero output current and zero DC-side voltage, so one can replace another without changing the output. They differ in the common-mode voltage and in which switches conduct. This freedom is what the sequences in [03-bigan-compatible.md](03-bigan-compatible.md) use.

## What an off switch blocks

An off switch blocks the line voltage between its own phase and the phase that conducts on the same rail. While $S_3$ conducts, $S_1$ blocks $v_b-v_a$; while $S_5$ conducts, it blocks $v_c-v_a$. The modulation cannot change these voltages. It decides only which of the two is applied, for how long the switch stays off, and how often it turns on in between.

## Commutation of a BDS pair

Every change of vector moves $I_\mathrm{dc}$ from one switch to another on the same rail, against the line voltage between their phases. Two BDSs of a rail must never conduct with both gates on at once, so the transfer from switch $X$ to switch $Y$ uses four steps [3]:

1. $R_X$ off; $X$ keeps conducting through its $R$ channel in the third quadrant.
2. $F_Y$ on.
3. $F_X$ off.
4. $R_Y$ on.

If $Y$ blocks forward voltage before the transfer, the current moves at step 2. This is a natural commutation: $F_Y$ turns on hard, and $R_X$ turns off capacitively. If $Y$ blocks reverse voltage, nothing happens until $F_X$ turns off hard at step 3. This is a forced commutation, and $Y$ turns on at zero voltage. Either way, every commutation has exactly one hard event in an $F$ channel, at the line voltage between the two phases.

## Measures

- **Commutations per sampling period, $n_c$.** Each vector change is one commutation. Sequences are compared at the same number of commutations per second, $n_c f_s$, so a sequence with more commutations per period runs at a lower sampling frequency $f_s = 1/T_s$.
- **Switching loss.** With the usual energy model $E = k_1 I_\mathrm{dc}V + k_2V^2$ per commutation, the switching loss at an equal number of commutations per second is proportional to the mean commutation voltage $\bar v_c$.
- **DC-link current ripple.** The DC-link inductor sees the source voltage minus the DC-side voltage of the bridge, $v_{PN}$: a line voltage during an active vector, zero during a zero vector. The ripple is $\Delta I = \tfrac{1}{L_\mathrm{dc}}\,\mathrm{pk\text{-}pk}\int(\bar v_{PN}-v_{PN})\,dt$.
- **Capacitor-voltage ripple.** The capacitor of phase $x$ takes the difference between the switched current and its local mean: $\Delta u = \tfrac{I_\mathrm{dc}}{C_f}\,\mathrm{pk\text{-}pk}\int(s_{xp}-s_{xn}-i_x^*/I_\mathrm{dc})\,dt$.
- **Common-mode voltage.** $v_\mathrm{cm} = (v_P+v_N)/2$, measured from the capacitor star point.
- **Longest off interval.** The longest time in which a switch does not conduct. It matters for BDSs whose blocking rating is given only for AC voltage; see [03-bigan-compatible.md](03-bigan-compatible.md).

## A bound on the off interval

Let switch $j$ conduct for the fraction $d_j$ of the time and turn on $r_j$ times per second. Its off intervals then last $(1-d_j)/r_j$ on average. One top and one bottom switch always conduct, so $\sum_j(1-d_j)=4$. Each commutation turns exactly one switch on, so $\sum_j r_j = n_c f_s$. Hence, for any modulation,

$$T_\mathrm{off} \ \ge\ \frac{4}{n_c f_s} = T_b .$$

$T_b$ is the sampling period of a sequence with four commutations per period at the same number of commutations per second. It is a convenient time unit when sequences with different $n_c$ are compared.

## References

1. T. Halkosaari and H. Tuusa, "Optimal vector modulation of a PWM current source converter according to minimal switching losses," in *Proc. IEEE PESC*, 2000, pp. 127–132.
2. J. Huber and J. W. Kolar, "Monolithic bidirectional power transistors – opening new horizons in power electronics," *IEEE Power Electronics Magazine*, vol. 10, no. 1, pp. 28–38, 2023.
3. B. Wu, *High-Power Converters and AC Drives*. Hoboken, NJ, USA: Wiley-IEEE Press, 2006.
