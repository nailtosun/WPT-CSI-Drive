function g = csiGatesBigan(method, th, Np, M, opt)
%CSIGATESBIGAN  Ideal gate signals of the two-level CSI (six switches) over one
% fundamental period, for sequences that turn every switch on in every sector,
% so that no switch blocks voltage for longer than a few sampling periods
% (needed by monolithic bidirectional GaN switches, whose blocking rating is
% only given for AC voltage of a minimum frequency).
%
% In every sector three switches belong to neither active vector, and each is
% turned on by a different zero vector: Zx shorts the phase shared by Sk and
% Sn, Zk / Zn the other phase of Sk / Sn. Zk may only neighbour Sk and Zn only
% Sn (one commutation per transition).
%
%   'CSVM_A'  CSVM pattern [Zk Sk Sn Z Sn Sk Zk], inner Z = Zx in even and
%             Zn in odd sampling periods
%   'CSVM_Z'  CSVM_A with zero-vector placement (ZVP): outer Zk slots
%             lambda*d0/2 each, inner Z (1 - lambda)*d0; lambda = 1/2 is
%             CSVM_A. lambda sets the switching-frequency harmonic of the
%             DC-side voltage (csiZVPLambda.m holds it constant)
%   '3Z'      three zero vectors per period [Zk Sk Zx Sn Zn Sn Zx Sk Zk]
%   'FSM_R'   FSM [Zx Sk Sn Zx], with a short Zk pulse inside Sk and a short
%             Zn pulse inside Sn in every N-th period (refresh pulses)
%   'NSPWM_R' NSPWM, with two short zero pulses [Z1 Sout Sk Sn Z2 Sn Sk Sout]
%             in every N-th period (M >= 2/3)
%
%   th  : column of angles in [0, 2*pi), phase-a current reference
%         i_a* = M*Idc*sin(th); Sector 1 is centred on its crest (th = 90 deg)
%   Np  : sampling periods per fundamental period
%   M   : modulation index
%   opt : .zsplit  zero-time shares [Zk Zx Zn] of '3Z'          (default [1 2 1]/4)
%         .eps     refresh pulse width / Ts                      (default 0.02)
%         .N       refresh every N-th period                     (default 4)
%         .lambda  outer zero share of 'CSVM_Z', scalar or one
%                  value per sampling period                     (default 1/2)
%
%   g.S     : N x 6 logical, columns [Sap San Sbp Sbn Scp Scn] = [S1 S2 S3 S4 S5 S6]
%   g.state : N x 1, vector 1..9 (1..6 active I1..I6, 7/8/9 = I7/I8/I9 short phase a/b/c)
%
% The dwell times of a sampling period come from the reference angle at the
% middle of that period. Split from csiGates.m of the CSI-Analytical-Calculations
% repository; gives identical gate signals.

    if nargin < 5, opt = struct; end
    if ~isfield(opt, 'zsplit'), opt.zsplit = [1 2 1]/4; end
    if ~isfield(opt, 'eps'),    opt.eps = 0.02; end
    if ~isfield(opt, 'N'),      opt.N = 4; end
    if ~isfield(opt, 'lambda'), opt.lambda = 0.5; end

    % vector table: top phase, bottom phase (1 = a, 2 = b, 3 = c)
    top = [1 2 2 3 3 1 1 2 3];
    bot = [3 3 1 1 2 2 1 2 3];
    Z0  = [7 9 8 7 9 8];            % zero vector per sector (shorts the common phase, Zx)

    N   = numel(th);
    kp  = min(floor(th/(2*pi)*Np), Np - 1);          % sampling period index
    tl  = th/(2*pi)*Np - kp;                         % position inside the period, [0, 1)
    thI = mod((kp + 0.5)/Np*2*pi - pi/2, 2*pi);      % current-vector angle (i_a* = M cos thI)
    st  = zeros(N, 1);

    for k = 0:Np-1
        idx = find(kp == k);
        if isempty(idx), continue; end
        a = thI(idx(1));
        refresh = mod(k, opt.N) == 0;
        if strcmp(method, 'NSPWM_R')
            s   = min(floor(a/(pi/3)), 5);  th2 = (s + 1)*pi/3 - a;
            dk  = max(0, M*sin(pi/6 + th2) + M*cos(th2) - 1);
            dn  = max(0, 1 - M*cos(th2));
            d0  = 1 - dk - dn;                        % outer active vector
            so  = mod(s + 1, 6) + 1;  sk = s + 1;  sn = mod(s - 1, 6) + 1;
            if ~refresh
                vec = [so sk sn];
                seq = [1 2 3 3 2 1];
                dur = [d0 dk dn dn dk d0]/2;
            else
                % z of Sout and z of Sn are replaced by z of Sk and z of zero vector
                z   = min([2*opt.eps, d0/2, dn/2]);
                vec = [so, sk, sn, 6 + sharedPhase(so, sk), 6 + sharedPhase(sk, sn)];
                seq = [4 1 2 3 5 3 2 1];
                dur = [z, d0 - z, dk + z, dn - z, z, dn - z, dk + z, d0 - z]/2;
            end
        else
            x   = mod(a + pi/6, 2*pi);
            s   = min(floor(x/(pi/3)), 5) + 1;  x = x - (s - 1)*pi/3;
            dk  = M*sin(pi/3 - x);  dn = M*sin(x);  d0 = 1 - dk - dn;
            Sk  = mod(s - 2, 6) + 1;  Sn = s;  px = Z0(s) - 6;
            Zk  = 6 + sum([top(Sk) bot(Sk)]) - px;    % short of the other phase of Sk
            Zn  = 6 + sum([top(Sn) bot(Sn)]) - px;
            vec = [Z0(s), Sk, Sn, 0, 0, Zk, Zn];      % [Zx Sk Sn - - Zk Zn]
            switch method
                case 'CSVM_A'
                    inner = 1 + 6*mod(k, 2);              % Zx in even periods, Zn in odd periods
                    seq = [6 2 3 inner 3 2 6];            dur = [d0/2 dk dn d0 dn dk d0/2]/2;
                case 'CSVM_Z'
                    lam = opt.lambda;  if numel(lam) > 1, lam = lam(k + 1); end
                    inner = 1 + 6*mod(k, 2);              % as CSVM_A
                    seq = [6 2 3 inner 3 2 6];
                    dur = [lam*d0/2, dk/2, dn/2, (1 - lam)*d0, dn/2, dk/2, lam*d0/2];
                case '3Z'
                    w = opt.zsplit/sum(opt.zsplit)*d0;
                    seq = [6 2 1 3 7 3 1 2 6];
                    dur = [w(1) dk w(2) dn 2*w(3) dn w(2) dk w(1)]/2;
                case 'FSM_R'
                    if refresh
                        e   = min(opt.eps, d0/4);         % taken from the zero time of Zx
                        seq = [1 2 6 2 3 7 3 1];
                        dur = [d0/2 - e, dk/2, e, dk/2, dn/2, e, dn/2, d0/2 - e];
                    else
                        seq = [1 2 3 1];  dur = [d0/2 dk dn d0/2];
                    end
                otherwise, error('csiGatesBigan: unknown method %s', method);
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

    function p = sharedPhase(s1, s2)
        if top(s1) == top(s2), p = top(s1); else, p = bot(s1); end
    end
end
