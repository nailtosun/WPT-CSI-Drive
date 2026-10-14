%% demo_oew.m
% Modulation of the series-connected open-end winding CSI (oewCellGates.m):
% one H-bridge cell per open winding, the three cells in series on one DC link.
%   1. commutations per pulse period of each switch pair and the longest off
%      interval of any switch of a cell, in pulse periods 1/fc: with ideal
%      pulses against the closed forms of ../docs/04-open-end-csi.md, and with
%      a minimum pulse width, below which a pulse is dropped;
%   2. timing diagram of six pulse periods around m = 0.5.

clear; close all; clc;
here = fileparts(mfilename('fullpath'));  addpath(here);

M     = 0.8;                % modulation index
fc    = 50e3;  f1 = 50;     % output pulse rate and fundamental frequency [Hz]
m_min = 0.05;               % smallest pulse as a fraction of 1/fc (second column)
meth  = { % name, scheme, carrier periods per pulse period, extra options, closed form of the longest off interval [1/fc]
    'RM (Yi et al.)', 'Paper',    1,   struct(),                fc/(2*f1)
    'AST',            'AST',      0.5, struct(),                1 + M
    'AST-ZC',         'ASTzc',    0.5, struct(),                1 + M
    'AST-ZC 2x',      'ASTzc',    1,   struct(),                (1 + M)/2
    'Bipolar',        'Bipolar',  0.5, struct(),                1 + M
    'PSC, 45 deg',    'PSC',      0.5, struct('phi', 45/360),   1 + M
    'Rot-3',          'Rotation', 1,   struct('N_rot', 3),      3 - 1 + M };

%% 1. commutations and longest off interval
Np = round(fc/f1);  Nppc = 100;  N = Np*Nppc;  th = (0:N-1)'/N*2*pi;
fprintf('M = %.2f, %d pulse periods per fundamental period\n\n', M, Np);
fprintf('%-15s %26s | %-36s\n', '', '', 'longest off interval [1/fc]');
fprintf('%-15s %26s | %12s %12s %15s\n', 'method', 'commutations top / bottom', 'ideal', 'closed form', ...
        sprintf('pulses >= %.2f', m_min));
G = cell(size(meth, 1), 1);
for k = 1:size(meth, 1)
    g0 = oewCellGates(meth{k, 2}, th, round(Np*meth{k, 3}), M, 0, options(meth{k, 2}, 0, meth{k, 4}));
    G{k} = oewCellGates(meth{k, 2}, th, round(Np*meth{k, 3}), M, 0, options(meth{k, 2}, m_min, meth{k, 4}));
    S = double(g0.S);
    nT = sum(abs(diff([S(:, 1); S(1, 1)])))/Np;     % top pair: one commutation per change of S1
    nB = sum(abs(diff([S(:, 3); S(1, 3)])))/Np;
    fprintf('%-15s %15.2f / %6.2f | %12.2f %12.2f %15.2f\n', meth{k, 1}, nT, nB, ...
            longestOff(g0.S)/Nppc, meth{k, 5}, longestOff(G{k}.S)/Nppc);
end
fprintf(['\nWith a minimum pulse, AST and Rot-3 drop the pulses near the current zero crossing and hold\n' ...
         'one zero state for about 2*asin(m_min/M)/omega = %.1f pulse periods; AST-ZC replaces them by\n' ...
         'pulse pairs and keeps 1 + M. The Rot-N closed form is approximate (up to N near the zero crossing).\n'], ...
        2*asin(m_min/M)/(2*pi)*Np);

%% 2. timing diagrams
NpD = 24;  Nw = 1000;  thc = asin(0.5/M);           % m = M sin(th) = 0.5
th0 = floor(thc/(2*pi)*NpD);                          % first pulse period shown
thw = ((th0 + (0:6*Nw-1)'/Nw)/NpD)*2*pi;  tw = (0:6*Nw-1)'/Nw;
f = figure('Name', 'Open-end CSI', 'Units', 'inches', 'Position', [1 1 9 6], 'Color', 'w');
if isprop(f, 'Theme'), f.Theme = 'light'; end
f.Color = 'w';
tl = tiledlayout(f, 3, 3, 'TileSpacing', 'compact', 'Padding', 'compact');
for k = 1:size(meth, 1)
    o = options(meth{k, 2}, m_min, meth{k, 4});
    g = oewCellGates(meth{k, 2}, thw, round(NpD*meth{k, 3}), M, 0, o);
    cellDiagram(nexttile(tl), tw, g.S, meth{k, 1});
end
xlabel(tl, 'Time (pulse periods 1/f_c)');
title(tl, 'One cell, six pulse periods around m = 0.5; states A^+ A^- Z_L Z_R', 'FontSize', 9);

%% -------------------------------------------------------------------------
function o = options(scheme, m_min, extra)
    % minimum pulse: m_min = tmin_car on the sawtooth, 2*tmin_car on the triangle
    o = struct('tmin_car', m_min/2, 'phi', 45/360, 'N_rot', 3, 'rot_offset', 0);
    if any(strcmp(scheme, {'Paper', 'Rotation'})), o.tmin_car = m_min; end
    for fn = fieldnames(extra)', o.(fn{1}) = extra.(fn{1}); end
end

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

function cellDiagram(ax, t, S, ttl)
    % state strip (A+, A-, Z_L, Z_R) and the gate signals S1..S4 of one cell
    cSt  = [0.86 0.85 0.82; 0.70 0.69 0.66; [15 139 141]/255; [184 51 106]/255];   % A+ A- ZL ZR
    lbl  = {'A^+', 'A^-', 'Z_L', 'Z_R'};
    st   = 1*(S(:, 1) & S(:, 4)) + 2*(S(:, 2) & S(:, 3)) + 3*(S(:, 1) & S(:, 3)) + 4*(S(:, 2) & S(:, 4));
    dt   = median(diff(t));  tEnd = t(end) + dt;  span = tEnd - t(1);
    hold(ax, 'on');
    chg  = [1; find(diff(st) ~= 0) + 1];  ends = [t(chg(2:end)); tEnd];
    for r = 1:numel(chg)
        a = t(chg(r));  b = ends(r);  v = st(chg(r));
        patch(ax, [a b b a], [5.2 5.2 6.2 6.2], cSt(v, :), 'EdgeColor', 'w', 'LineWidth', 0.5);
        if b - a > 0.05*span, text(ax, (a + b)/2, 5.7, lbl{v}, 'HorizontalAlignment', 'center', 'FontSize', 7); end
    end
    yRow = [4 3 1.8 0.8];  name = {'S_1', 'S_2', 'S_3', 'S_4'};
    for j = 1:4
        plot(ax, [t(1) tEnd], yRow(j)*[1 1], '-', 'Color', [0.82 0.82 0.82], 'LineWidth', 0.3);
        d = diff([0; S(:, j); 0]);  s = find(d == 1);  e = find(d == -1);
        for q = 1:numel(s)
            a = t(s(q));  if e(q) <= numel(t), b = t(e(q)); else, b = tEnd; end
            patch(ax, [a b b a], yRow(j) + [0.06 0.06 0.75 0.75], [0.23 0.24 0.27], 'EdgeColor', 'none');
        end
        text(ax, t(1) - 0.01*span, yRow(j) + 0.4, name{j}, 'HorizontalAlignment', 'right', 'FontSize', 8);
    end
    set(ax, 'XLim', [t(1) tEnd], 'YLim', [0.5 6.4], 'YTick', [], 'Box', 'off', 'FontSize', 8);
    ax.YAxis.Visible = 'off';
    title(ax, ttl, 'FontWeight', 'normal', 'FontSize', 9);
end
