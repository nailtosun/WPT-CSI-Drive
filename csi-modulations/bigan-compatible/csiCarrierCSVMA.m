function [S, lev, c] = csiCarrierCSVMA(th, Np, M, varargin)
%CSICARRIERCSVMA  Carrier-based realisation of CSVM-A (and CSVM).
%
% One symmetric triangular carrier c per switching period (0 at the period
% start, 1 at the centre, 0 at the end). Each of the six gate signals is a
% window comparison
%       g = (L <= c) & (c < U),
% with two compare levels L and U per switch and per period, exactly what an
% up-down counting PWM unit with two compare registers (ePWM CMPA/CMPB with
% set/clear actions on the up and down count) produces. No sector table and
% no VSI-to-CSI logic mapping are needed; the levels follow from the three
% phase-current references sampled once per period:
%
%   x = phase with the largest |i*|  (shared phase, conducts in both active vectors)
%   k = next phase in the order a->b->c, n = the remaining phase
%   d_k = |i_k*|, d_n = |i_n*|, d_0 = 1 - |i_x*|          (duty ratios of SVM)
%   A = d_0/2, B = d_0/2 + d_k, Cc = 1 - d_0/2                (carrier levels of the slot edges)
%
% The carrier runs through the CSVM-A sequence [Z_k | S_k | S_n | Z | S_n | S_k | Z_k]
% with slot edges at the levels 0, A, B, Cc, 1. The inner zero vector Z is Z_x in
% even periods and Z_n in odd periods ('CSVM' option: always Z_x).
%
%   th  : column of angles [0, 2*pi), i_a* = M*Idc*sin(th)
%   Np  : switching periods per fundamental period
%   M   : modulation index
%   options: 'mode' 'CSVM_A' (default) | 'CSVM';  'sample' 'mid' (default, as csiGatesBigan) | 'start'
%
%   S   : N x 6 logical, columns [Sap San Sbp Sbn Scp Scn]
%   lev : Np x 12 compare levels [L U] of the six switches per period
%   c   : the carrier at every sample
%
% Equivalent to csiGatesBigan('CSVM_A', ...) and to the conventional CSVM
% (checked by demo_bigan.m). It is the dual of carrier-based VSI PWM with the
% logic mapping of Espinoza/Joos and Ojo/Vanaparthy, with the zero-state
% (shorting-leg) selection built into the compare levels.

    p = inputParser;
    addParameter(p, 'mode', 'CSVM_A');  addParameter(p, 'sample', 'mid');
    parse(p, varargin{:});  mode = p.Results.mode;  sample = p.Results.sample;

    N  = numel(th);
    kp = min(floor(th/(2*pi)*Np), Np - 1);              % period index
    tl = th/(2*pi)*Np - kp;                              % position in the period [0, 1)
    c  = 1 - abs(2*tl - 1);                              % triangular carrier 0 -> 1 -> 0
    S  = false(N, 6);  lev = zeros(Np, 12);
    nxt = [2 3 1];  prv = [3 1 2];                       % cyclic order a -> b -> c
    for q = 0:Np-1
        idx = find(kp == q);
        if isempty(idx), continue; end
        if strcmp(sample, 'mid'), ts = (q + 0.5)/Np; else, ts = q/Np; end
        thS = ts*2*pi;
        i3  = M*[sin(thS), sin(thS - 2*pi/3), sin(thS + 2*pi/3)];   % current references / Idc
        [~, x] = max(abs(i3));  k = nxt(x);  n = prv(x);
        d0 = 1 - abs(i3(x));  dk = abs(i3(k));
        A = d0/2;  B = d0/2 + dk;  Cc = 1 - d0/2;
        odd = strcmp(mode, 'CSVM_A') && mod(q, 2) == 1;  % inner zero vector Z_n instead of Z_x
        % levels [L U] per switch, for i_x* > 0 (shared switch on the upper rail)
        if odd
            Lx = [A Cc];  Lxo = [1 1];  Lno = [Cc 1];  Ln = [B 1];
        else
            Lx = [A 1];   Lxo = [Cc 1]; Lno = [1 1];   Ln = [B Cc];
        end
        Lk = [0 A];  Lko = [0 B];
        % up: same-rail switches of x, k, n; op: opposite-rail switches of x, k, n
        up = {Lx, Lk, Lno};  op = {Lxo, Lko, Ln};
        L = zeros(1, 12);
        for ph = [x k n]
            if ph == x, u = up{1}; o = op{1}; elseif ph == k, u = up{2}; o = op{2}; else, u = up{3}; o = op{3}; end
            if i3(x) > 0, Lp = u; Ln2 = o; else, Lp = o; Ln2 = u; end   % i_x* < 0: shared switch on the lower rail
            L(2*(2*ph-1)-1 : 2*(2*ph-1)) = Lp;                           % S_{ph}p -> column 2*ph-1
            L(2*(2*ph)-1   : 2*(2*ph))   = Ln2;                          % S_{ph}n -> column 2*ph
        end
        lev(q+1, :) = L;
        cc = c(idx);
        for s = 1:6                                      % window [L, U); U = 1 includes the carrier peak, [1 1] = never
            S(idx, s) = (L(2*s-1) <= cc) & (cc < L(2*s) | (L(2*s) >= 1 & L(2*s-1) < 1));
        end
    end
end
