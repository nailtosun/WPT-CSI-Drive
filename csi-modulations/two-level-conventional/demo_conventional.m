%% demo_conventional.m
% Conventional space-vector sequences of the two-level CSI (csiGatesConventional.m).
%   1. commutations per sampling period and the longest interval in which a
%      switch does not conduct, over one fundamental period T1. Every one of
%      these sequences leaves some switches off for a whole sector.
%   2. timing diagram of two sampling periods in Sector 1, 10 deg before the
%      crest of the phase-a current.

clear; close all; clc;
here = fileparts(mfilename('fullpath'));  addpath(here);

M    = 0.8;                 % modulation index (NSPWM needs M >= 2/3)
meth = {'FSM', 'HSM', 'MHSM', 'DPWM_A', 'DPWM_B', 'DPWM_C', 'DPWM_D', 'CSVM', 'NSPWM'};

%% 1. commutations and longest off interval
Np = 600;  Nppc = 200;  N = Np*Nppc;  th = (0:N-1)'/N*2*pi;
fprintf('M = %.2f, %d sampling periods per fundamental period T1\n\n', M, Np);
fprintf('%-8s %24s %28s\n', 'method', 'commutations per period', 'longest off interval [T1]');
for m = 1:numel(meth)
    g  = csiGatesConventional(meth{m}, th, Np, M);
    S  = double(g.S);
    nc = sum(abs(diff([S; S(1, :)])), 'all')/2/Np;   % each commutation changes two gates
    fprintf('%-8s %24.2f %28.3f\n', strrep(meth{m}, '_', '-'), nc, longestOff(g.S)/N);
end
fprintf('\nT1/6 = %.3f, T1/3 = %.3f\n', 1/6, 1/3);

%% 2. timing diagrams
NpD = 360;  Nw = 2000;                          % one degree per sampling period
thw = (80 + (0:2*Nw-1)'/Nw)*pi/180;             % sampling periods 80 and 81, Sector 1
tw  = (0:2*Nw-1)'/Nw;                           % time in sampling periods
f = figure('Name', 'Conventional sequences', 'Units', 'inches', 'Position', [1 1 9 7.5], 'Color', 'w');
if isprop(f, 'Theme'), f.Theme = 'light'; end
f.Color = 'w';
tl = tiledlayout(f, 3, 3, 'TileSpacing', 'compact', 'Padding', 'compact');
for m = 1:numel(meth)
    g = csiGatesConventional(meth{m}, thw, NpD, M);
    csiTimingDiagram(nexttile(tl), tw, g.state, strrep(meth{m}, '_', '-'));
end
xlabel(tl, 'Time (sampling periods T_s)');
title(tl, sprintf('Two sampling periods in Sector 1, M = %.1f; grey: active vectors, colour: zero vector', M), ...
      'FontSize', 9);

%% -------------------------------------------------------------------------
function L = longestOff(S)
    % longest run of samples in which a switch does not conduct, any switch, periodic
    L = 0;
    for j = 1:size(S, 2)
        z = ~[S(:, j); S(:, j)];                    % twice: runs across the period end
        d = diff([0; z; 0]);  a = find(d == 1);  e = find(d == -1);
        if ~isempty(a), L = max(L, max(e - a)); end
    end
    L = min(L, size(S, 1));
end
