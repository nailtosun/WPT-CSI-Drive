%% demo_bigan.m
% Two-level CSI sequences that turn every switch on in every sector
% (csiGatesBigan.m), for monolithic bidirectional GaN switches.
%   1. commutations per sampling period and the longest off interval of any
%      switch, in sampling periods Ts, against the closed forms of
%      ../docs/03-bigan-compatible.md;
%   2. zero-vector placement (ZVP): outer zero share per period from
%      csiZVPLambda.m;
%   3. carrier-based CSVM-A (csiCarrierCSVMA.m) against the sequence model;
%   4. timing diagram of two sampling periods in Sector 1, 10 deg before the
%      crest of the phase-a current.

clear; close all; clc;
here = fileparts(mfilename('fullpath'));  addpath(here);

M   = 0.8;                                      % modulation index (NSPWM-R needs M >= 2/3)
opt = struct('eps', 0.02, 'N', 4);              % refresh pulses: 0.02 Ts in every 4th period
phi = 30;                                       % power-factor angle for ZVP [deg]

%% 1. commutations and longest off interval
% 800 sampling periods per fundamental period: a sector holds 133.3 periods, so
% sector changes fall at every position of the even/odd and refresh patterns, as
% with asynchronous sampling. That gives the worst cases of the closed forms.
Np = 800;  Nppc = 200;  N = Np*Nppc;  th = (0:N-1)'/N*2*pi;
[lam, Astar] = csiZVPLambda(M, phi, Np, 0.9, 0.97);
oz = opt;  oz.lambda = lam;
cases = { % name, method, options, closed form of the longest off interval [Ts]
    'CSVM-A',  'CSVM_A',  opt, 5/2 + sqrt(3)/4*M
    '3Z-SVM',  '3Z',      opt, (3 + M)/4
    'FSM-R',   'FSM_R',   opt, opt.N + sqrt(3)/2*M
    'NSPWM-R', 'NSPWM_R', opt, opt.N + 1/2 - opt.eps
    'ZVP',     'CSVM_Z',  oz,  NaN };
fprintf('M = %.2f, %d sampling periods per fundamental period, refresh %.2f Ts every %d periods\n\n', ...
        M, Np, opt.eps, opt.N);
fprintf('%-8s %24s %22s %14s\n', 'method', 'commutations per period', 'longest off [Ts]', 'closed form');
for c = 1:size(cases, 1)
    g  = csiGatesBigan(cases{c, 2}, th, Np, M, cases{c, 3});
    S  = double(g.S);
    nc = sum(abs(diff([S; S(1, :)])), 'all')/2/Np;
    fprintf('%-8s %24.2f %22.2f %14.2f\n', cases{c, 1}, nc, longestOff(g.S)/Nppc, cases{c, 4});
end

%% 2. ZVP
fprintf('\nZVP at phi = %d deg: outer zero share %.2f to %.2f, flat switching-frequency harmonic %.3f V_LL\n', ...
        phi, min(lam), max(lam), Astar);

%% 3. carrier-based CSVM-A
Sc = csiCarrierCSVMA(th, Np, M);
g  = csiGatesBigan('CSVM_A', th, Np, M);
fprintf('Carrier-based CSVM-A: %d of %d samples differ from the sequence model\n', sum(any(Sc ~= g.S, 2)), N);

%% 4. timing diagrams
NpD = 360;  Nw = 2000;                          % one degree per sampling period
thw = (80 + (0:2*Nw-1)'/Nw)*pi/180;             % sampling periods 80 and 81, Sector 1
tw  = (0:2*Nw-1)'/Nw;
od  = struct('eps', 0.05, 'N', 2, 'lambda', 0.8);   % wider, more frequent refresh pulses to make them visible
f = figure('Name', 'BiGaN-compatible sequences', 'Units', 'inches', 'Position', [1 1 9 5.2], 'Color', 'w');
if isprop(f, 'Theme'), f.Theme = 'light'; end
f.Color = 'w';
tl = tiledlayout(f, 2, 3, 'TileSpacing', 'compact', 'Padding', 'compact');
show = {'CSVM-A', 'CSVM_A'; '3Z-SVM', '3Z'; 'FSM-R (refresh in the first period)', 'FSM_R'; ...
        'NSPWM-R (refresh in the first period)', 'NSPWM_R'; 'ZVP, outer zero share 0.8', 'CSVM_Z'};
for c = 1:size(show, 1)
    g = csiGatesBigan(show{c, 2}, thw, NpD, M, od);
    csiTimingDiagram(nexttile(tl), tw, g.state, show{c, 1});
end
xlabel(tl, 'Time (sampling periods T_s)');
title(tl, sprintf('Two sampling periods in Sector 1, M = %.1f; grey: active vectors, colour: zero vector', M), ...
      'FontSize', 9);

%% -------------------------------------------------------------------------
function L = longestOff(S)
    % longest run of samples in which a switch does not conduct, any switch, periodic
    L = 0;
    for j = 1:size(S, 2)
        z = ~[S(:, j); S(:, j)];
        d = diff([0; z; 0]);  a = find(d == 1);  e = find(d == -1);
        if ~isempty(a), L = max(L, max(e - a)); end
    end
    L = min(L, size(S, 1));
end
