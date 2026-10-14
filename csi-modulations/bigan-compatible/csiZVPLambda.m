function [lam, Astar, aHi] = csiZVPLambda(M, phiDeg, Np, lamHi, frac)
%CSIZVPLAMBDA  Zero-vector placement (ZVP) for csiGatesBigan 'CSVM_Z': outer zero-time
% share lambda per sampling period such that the f_s harmonic of v_PN is the same
% in every period. Closed form of one symmetric period [Zk Sk Sn Z Sn Sk Zk]:
%   a1 = 2/pi*(vn*(sin 2pi u1 - sin 2pi u0) + vk*(sin 2pi u2 - sin 2pi u1)),
%   u0 = (1-lambda)*d0/2, u1 = u0 + dn/2, u2 = u1 + dk/2 (from the period centre).
% For vk = vn = V: |a1| = 4V/pi*cos(pi*d0/2)*|sin(pi*d0*(lambda - 1/2))|.
%
%   lamHi : largest outer share (the inner zero keeps (1 - lamHi)*d0); lambda is
%           searched in [1 - lamHi, lamHi]
%   frac  : target = frac x the largest level every period can reach
%   lam   : Np x 1;  Astar : flat level (per unit V_LL), NaN if none is reachable
%   aHi   : a1 per period at lambda = lamHi

    top = [1 2 2 3 3 1 1 2 3]';  bot = [3 3 1 1 2 2 1 2 3]';
    kk  = (0:Np-1)';  thc = (kk + 0.5)/Np*2*pi;     % angle at the middle of each period
    a   = mod(thc - pi/2, 2*pi);                    % current-vector angle, as csiGatesBigan
    x   = mod(a + pi/6, 2*pi);  s = min(floor(x/(pi/3)), 5) + 1;  x = x - (s - 1)*pi/3;
    dk  = M*sin(pi/3 - x);  dn = M*sin(x);  d0 = 1 - dk - dn;
    Sk  = mod(s - 2, 6) + 1;  Sn = s;
    ph  = phiDeg*pi/180;
    V   = [sin(thc + ph), sin(thc + ph - 2*pi/3), sin(thc + ph + 2*pi/3)]/sqrt(3);
    pick = @(p) V(sub2ind(size(V), kk + 1, p));
    vk  = pick(top(Sk)) - pick(bot(Sk));  vn = pick(top(Sn)) - pick(bot(Sn));
    a1  = @(L) 2/pi*(vn.*(sin(2*pi*((1 - L).*d0/2 + dn/2)) - sin(2*pi*(1 - L).*d0/2)) + ...
                     vk.*(sin(2*pi*((1 - L).*d0/2 + dn/2 + dk/2)) - sin(2*pi*((1 - L).*d0/2 + dn/2))));
    aHi = a1(lamHi);
    Lg = linspace(1 - lamHi, lamHi, 1601);
    A  = zeros(Np, numel(Lg));
    for j = 1:numel(Lg), A(:, j) = a1(Lg(j)); end
    lo = max(min(A, [], 2));  hi = min(max(A, [], 2));   % levels that every period can reach
    if hi < 0.02 || hi <= lo
        Astar = NaN;  lam = 0.5*ones(Np, 1);  return
    end
    Astar = max(lo, frac*hi);
    [~, j] = min(abs(A - Astar), [], 2);
    lam = Lg(j)';
end
