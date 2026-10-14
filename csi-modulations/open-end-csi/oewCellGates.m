function G = oewCellGates(scheme, th, Nc, M, phase, opt)
%OEWCELLGATES Gate signals of one H-bridge cell of the series-connected
% open-end winding CSI (three H-bridge cells in series on one DC link) for
% the modulation methods of ../docs/04-open-end-csi.md (demo: demo_oew.m).
%
%   G = oewCellGates(scheme, th, Nc, M, phase, opt)
%
%   scheme : 'Paper'    Yi et al., JESTPE 2026, Table II (sawtooth)
%            'AST'      alternating shoot-through PWM (triangle)
%            'ASTzc'    AST + A+/A- pulse pair near the i* zero crossing
%            'Bipolar'  A+ and A- only (S3 = ~S1)
%            'PSC'      AST references, bottom-pair carrier shifted by opt.phi
%            'Rotation' Paper scheme, other zero state in 1 of opt.N_rot periods
%   th     : electrical angle [rad], column vector over one fundamental period
%   Nc     : carrier periods per fundamental period
%   M      : modulation index Ihat/Idc
%   phase  : phase of this cell's current reference [rad]
%   opt    : .tmin_car  minimum pulse as a fraction of the carrier period
%            .N_rot     'Rotation' period count
%            .rot_offset 'Rotation' index of the first rotated period (default 0)
%            .phi       'PSC' carrier shift as a fraction of the period
%
%   G.S    : [N x 4] logical gates S1..S4 (S2 = ~S1, S4 = ~S3 always)
%   G.p    : cell switching function, +1 (A+), -1 (A-), 0 (Z_L, Z_R)
%   G.ms   : signed reference m_s = i*/Idc, sampled at each period centre
%   G.car  : carrier of the top pair in [0,1]
%   G.carB : carrier of the bottom pair in [0,1]
%   G.refT : compare level of the top pair (NaN where it follows no carrier)
%   G.refB : compare level of the bottom pair (NaN where it follows no carrier)
%   G.kc   : carrier period index

kc   = floor(th*Nc/(2*pi));
mc   = th*Nc/(2*pi) - kc;                   % position in the period, [0,1)
ms   = M*sin((kc + 0.5)*2*pi/Nc + phase);
pos  = ms >= 0;
tri  = 1 - abs(1 - 2*mc);                   % triangle, valley at period start
carB = [];
refT = nan(size(ms));
refB = nan(size(ms));

switch scheme
    case 'Paper'
        car  = mc;                          % sawtooth
        m_min = opt.tmin_car;
        act  = abs(ms) > car & abs(ms) >= m_min;
        g1   = pos;
        g3   = (pos & ~act) | (~pos & act);
        refB = abs(ms).*(abs(ms) >= m_min);

    case 'AST'
        car  = tri;
        m_min = 2*opt.tmin_car;
        g1   = car > (1 - ms)/2;
        g3   = car > (1 + ms)/2;
        lowm = abs(ms) < m_min;             % hold Z_R
        g1(lowm) = false;
        g3(lowm) = false;
        refT = (1 - ms)/2;
        refB = (1 + ms)/2;
        refT(lowm) = 1;
        refB(lowm) = 1;

    case 'ASTzc'
        car  = tri;
        m_min = 2*opt.tmin_car;
        sg   = 2*pos - 1;
        a    = abs(ms)/2;                   % rising-half active width
        b    = abs(ms)/2;                   % falling-half active width (signed)
        lowm = abs(ms) < m_min;
        a(lowm) = abs(ms(lowm)) + m_min/2;
        b(lowm) = -m_min/2;                 % opposite active state
        up   = mc < 0.5;
        w    = up.*a + ~up.*b;
        refT = 0.5 - sg.*w;
        refB = 0.5 + sg.*w;
        g1   = car > refT;
        g3   = car > refB;

    case 'Bipolar'
        car  = tri;
        g1   = car > (1 - ms)/2;
        g3   = ~g1;
        carB = 1 - tri;                     % same as S3 = carB > (1 + m_s)/2
        refT = (1 - ms)/2;
        refB = (1 + ms)/2;

    case 'PSC'
        car  = tri;
        carB = 1 - abs(1 - 2*mod(mc + opt.phi, 1));
        refT = (1 - ms)/2;
        refB = (1 + ms)/2;
        g1   = car > refT;
        g3   = carB > refB;

    case 'Rotation'
        car  = mc;
        m_min = opt.tmin_car;
        act  = abs(ms) > car & abs(ms) >= m_min;
        k0   = 0;
        if isfield(opt, 'rot_offset'), k0 = opt.rot_offset; end
        alt  = mod(kc - k0, opt.N_rot) == 0 & abs(ms) >= m_min;
        zL   = ~act & (pos ~= alt);         % home zero state: Z_L (pos), Z_R (neg)
        g1   = (pos & act) | zL;
        g3   = (~pos & act) | zL;
        lvl  = abs(ms).*(abs(ms) >= m_min);
        refT(alt)  = lvl(alt);              % rotated period: the top pair switches
        refB(~alt) = lvl(~alt);             % home period: the bottom pair switches

    otherwise
        error('oewCellGates: unknown scheme ''%s''', scheme);
end
if isempty(carB)
    carB = car;
end

G.S    = [g1, ~g1, g3, ~g3];
G.p    = double(g1 & ~g3) - double(~g1 & g3);
G.ms   = ms;
G.car  = car;
G.carB = carB;
G.refT = refT;
G.refB = refB;
G.kc   = kc;
end
