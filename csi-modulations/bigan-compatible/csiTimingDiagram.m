function csiTimingDiagram(ax, t, state, ttl)
%CSITIMINGDIAGRAM  Vector sequence and gate signals of the two-level CSI as a
% timing diagram: a strip with the applied vectors I1..I9 on top and one row
% per switch below, S1 S3 S5 (rail P) and S2 S4 S6 (rail N).
%
%   ax    : axes
%   t     : time, column (for example in sampling periods)
%   state : vector 1..9 at every sample (field state of the gate functions)
%   ttl   : title (optional)
%
% Active vectors are grey, zero vectors take the colour of the phase they
% short (a teal, b plum, c indigo). A dark bar means that the switch conducts.

    top  = [1 2 2 3 3 1 1 2 3];  bot = [3 3 1 1 2 2 1 2 3];
    cAct = [0.86 0.85 0.82];
    cZ   = [15 139 141; 184 51 106; 74 58 167]/255;      % zero vector shorting a, b, c
    cBar = [0.23 0.24 0.27];
    name = {'S_1', 'S_3', 'S_5', 'S_2', 'S_4', 'S_6'};
    ph   = [1 2 3 1 2 3];  rail = [1 1 1 2 2 2];          % phase and rail (1 = P, 2 = N) of each row
    yRow = [6 5 4 2.6 1.6 0.6];

    t = t(:);  state = state(:);
    dt = median(diff(t));  tEnd = t(end) + dt;  span = tEnd - t(1);
    hold(ax, 'on');

    % period boundaries
    for p = ceil(t(1)):floor(tEnd)
        plot(ax, [p p], [0.3 8.4], ':', 'Color', [0.65 0.65 0.65], 'LineWidth', 0.5);
    end

    % vector strip
    chg  = [1; find(diff(state) ~= 0) + 1];
    ends = [t(chg(2:end)); tEnd];
    for r = 1:numel(chg)
        v = state(chg(r));  a = t(chg(r));  b = ends(r);
        if v <= 6, c = cAct; else, c = cZ(v - 6, :); end
        patch(ax, [a b b a], [7.2 7.2 8.4 8.4], c, 'EdgeColor', 'w', 'LineWidth', 0.5);
        if b - a > 0.04*span
            text(ax, (a + b)/2, 7.8, sprintf('I_%d', v), 'HorizontalAlignment', 'center', 'FontSize', 8);
        end
    end

    % gate signals
    for j = 1:6
        if rail(j) == 1, on = top(state)' == ph(j); else, on = bot(state)' == ph(j); end
        plot(ax, [t(1) tEnd], yRow(j)*[1 1], '-', 'Color', [0.82 0.82 0.82], 'LineWidth', 0.3);
        d = diff([0; on; 0]);  s = find(d == 1);  e = find(d == -1);
        for q = 1:numel(s)
            a = t(s(q));
            if e(q) <= numel(t), b = t(e(q)); else, b = tEnd; end
            patch(ax, [a b b a], yRow(j) + [0.06 0.06 0.75 0.75], cBar, 'EdgeColor', 'none');
        end
        text(ax, t(1) - 0.01*span, yRow(j) + 0.4, name{j}, 'HorizontalAlignment', 'right', 'FontSize', 8);
    end

    set(ax, 'XLim', [t(1) tEnd], 'YLim', [0.3 8.6], 'YTick', [], 'Box', 'off', 'FontSize', 8);
    ax.YAxis.Visible = 'off';
    if nargin > 3, title(ax, ttl, 'FontWeight', 'normal', 'FontSize', 9); end
end
