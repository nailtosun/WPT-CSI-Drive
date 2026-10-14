function g = csiGatesConventional(method, th, Np, M)
%CSIGATESCONVENTIONAL  Ideal gate signals of the two-level CSI (six switches)
% over one fundamental period, for the conventional space-vector sequences.
%
%   'FSM'     full-wave symmetric modulation   [Zx Sk Sn Zx]
%   'HSM'     half-wave symmetric modulation   [Sk Zx Sn Zx Sk]
%   'MHSM'    modified HSM                      [Zx Sk Sn Sk Zx]
%   'DPWM_A'  discontinuous PWM A               [Sk Sn Zx Sk Sn Zx]
%   'DPWM_B'  discontinuous PWM B               [Sk Sn Zx Sn Sk]
%   'DPWM_C'  discontinuous PWM C               [Zx Sk Sn Zx Sn Sk Zx]
%   'DPWM_D'  discontinuous PWM D               [Sk Zx Sn Zx Sn Zx Sk]
%   'CSVM'    centered space-vector modulation  [Zk Sk Sn Zx Sn Sk Zk]
%   'NSPWM'   near-state PWM, no zero vector    [Sout Sk Sn Sk Sout], M >= 2/3
%
% Sk and Sn are the two active vectors next to the reference; Zx shorts the
% phase they share, Zk the other phase of Sk. All of these sequences leave
% some switches off for a whole sector (T1/6, NSPWM T1/3); see
% ../bigan-compatible for sequences that turn every switch on in every sector.
%
%   th  : column of angles in [0, 2*pi), phase-a current reference
%         i_a* = M*Idc*sin(th); Sector 1 is centred on its crest (th = 90 deg)
%   Np  : sampling periods per fundamental period
%   M   : modulation index (NSPWM needs M >= 2/3)
%
%   g.S     : N x 6 logical, columns [Sap San Sbp Sbn Scp Scn] = [S1 S2 S3 S4 S5 S6]
%   g.state : N x 1, vector 1..9 (1..6 active I1..I6, 7/8/9 = I7/I8/I9 short phase a/b/c)
%
% The dwell times of a sampling period come from the reference angle at the
% middle of that period. Split from csiGates.m of the CSI-Analytical-Calculations
% repository; gives identical gate signals.

    % vector table: top phase, bottom phase (1 = a, 2 = b, 3 = c)
    top = [1 2 2 3 3 1 1 2 3];
    bot = [3 3 1 1 2 2 1 2 3];
    Z0  = [7 9 8 7 9 8];            % zero vector per sector (shorts the common phase)
    Z0a = [8 7 9 8 7 9];            % CSVM outer zero vector (Zk, next to Sk)
    Z0b = [7 9 8 7 9 8];            % CSVM inner zero vector (Zx, shorts the common phase)

    N   = numel(th);
    kp  = min(floor(th/(2*pi)*Np), Np - 1);          % sampling period index
    tl  = th/(2*pi)*Np - kp;                         % position inside the period, [0, 1)
    thI = mod((kp + 0.5)/Np*2*pi - pi/2, 2*pi);      % current-vector angle (i_a* = M cos thI)
    st  = zeros(N, 1);

    for k = 0:Np-1
        idx = find(kp == k);
        if isempty(idx), continue; end
        a = thI(idx(1));
        if strcmp(method, 'NSPWM')
            s   = min(floor(a/(pi/3)), 5);  th2 = (s + 1)*pi/3 - a;
            dk  = max(0, M*sin(pi/6 + th2) + M*cos(th2) - 1);
            dn  = max(0, 1 - M*cos(th2));
            d0  = 1 - dk - dn;                        % outer active vector
            so  = mod(s + 1, 6) + 1;  sk = s + 1;  sn = mod(s - 1, 6) + 1;
            vec = [so sk sn];
            seq = [1 2 3 3 2 1];
            dur = [d0 dk dn dn dk d0]/2;
        else
            x   = mod(a + pi/6, 2*pi);
            s   = min(floor(x/(pi/3)), 5) + 1;  x = x - (s - 1)*pi/3;
            dk  = M*sin(pi/3 - x);  dn = M*sin(x);  d0 = 1 - dk - dn;
            Sk  = mod(s - 2, 6) + 1;  Sn = s;
            vec = [Z0(s), Sk, Sn, Z0a(s), Z0b(s)];   % [Zx Sk Sn Z0a Z0b]
            switch method
                case 'FSM',    seq = [1 2 2 3 3 1];      dur = [d0 dk dk dn dn d0]/2;
                case 'HSM',    seq = [2 1 3 3 1 2];      dur = [dk d0 dn dn d0 dk]/2;
                case 'MHSM',   seq = [1 2 3 3 2 1];      dur = [d0 dk dn dn dk d0]/2;
                case 'DPWM_A', seq = [2 3 1 2 3 1];      dur = [dk dn d0 dk dn d0]/2;
                case 'DPWM_B', seq = [2 3 1 1 3 2];      dur = [dk dn d0 d0 dn dk]/2;
                case 'DPWM_C', seq = [1 2 3 1 1 3 2 1];  dur = [d0/2 dk dn d0/2 d0/2 dn dk d0/2]/2;
                case 'DPWM_D', seq = [2 1 3 1 1 3 1 2];  dur = [dk d0/2 dn d0/2 d0/2 dn d0/2 dk]/2;
                case 'CSVM',   seq = [4 2 3 5 3 2 4];    dur = [d0/2 dk dn d0 dn dk d0/2]/2;
                otherwise, error('csiGatesConventional: unknown method %s', method);
            end
        end
        keep  = dur > 0;  seq = seq(keep);              % drop empty slots
        edges = [0, cumsum(dur(keep))];
        slot  = sum(tl(idx) >= edges(1:end-1), 2);      % last slot that has started
        st(idx) = vec(seq(slot));
    end

    S = false(N, 6);
    for x = 1:3
        S(:, 2*x - 1) = top(st)' == x;
        S(:, 2*x)     = bot(st)' == x;
    end
    g.S = S;  g.state = st;
end
