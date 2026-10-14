function [Sap San Sbp Sbn Scp Scn Vinv Vsw] = SVPWM_Modulator(Idq, comp, m, fc, t, w, iq, Lq, id, idq, eq, vector_length, deltat, R, mod_technique)
% Space Vector Modulation Implementation for CSI
% Based on paper: doi: 10.1109/PESC.2000.878821
%
% Supported modulation techniques:
%   'FSM'    - Full Symmetrical Modulation     [Z0][Sk][Sk][Sn][Sn][Z0]
%   'HSM'    - Half Symmetrical Modulation     [Sk][Z0][Sn][Sn][Z0][Sk]
%   'MHSM'   - Modified Half Symmetrical       [Z0][Sk][Sn][Sn][Sk][Z0]
%   'DPWM_A' - Discontinuous PWM A             [Sk][Sn][Z0][Sk][Sn][Z0]
%   'DPWM_B' - Discontinuous PWM B             [Sk][Sn][Z0][Z0][Sn][Sk]
%   'DPWM_C' - Discontinuous PWM C (8 states)  [Z0][Sk][Sn][Z0][Z0][Sn][Sk][Z0]
%   'DPWM_D' - Discontinuous PWM D (8 states)  [Sk][Z0][Sn][Z0][Z0][Sn][Z0][Sk]
%   'CSVM'   - Continuous SVM (7 states)        [Z0a][Sk][Sn][Z0b][Sn][Sk][Z0a]
%              Uses 2 distinct zero vectors per sector for single-commutation transitions
%   'NSPWM'  - Near-State PWM (no zero vectors) [Sout][Sk][Sn][Sn][Sk][Sout]
%              Only active vectors — valid for 2/3 <= m <= 1
%              Sectors: [k*pi/3, (k+1)*pi/3], angle th2 measured from sector trailing edge
%              4 commutations/period; V_dc/Vt = 3m/2 (same as SVM at delta=0)
if nargin < 15
    mod_technique = 'FSM';
end

Ts = 1/fc; % switching period (s)
L = Lq; 

% Switching state matrices stored in 3D array S(:,:,idx)
S = zeros(2,3,9);
S(:,:,1) = [1 0 0; 0 0 1]; % S1
S(:,:,2) = [0 1 0; 0 0 1]; % S2
S(:,:,3) = [0 1 0; 1 0 0]; % S3
S(:,:,4) = [0 0 1; 1 0 0]; % S4
S(:,:,5) = [0 0 1; 0 1 0]; % S5
S(:,:,6) = [1 0 0; 0 1 0]; % S6
S(:,:,7) = [1 0 0; 1 0 0]; % S7 (zero)
S(:,:,8) = [0 1 0; 0 1 0]; % S8 (zero)
S(:,:,9) = [0 0 1; 0 0 1]; % S9 (zero)

% Back-EMF and terminal voltage calculation
ea = eq*cos(w*t);
eb = eq*cos(w*t-2*pi/3);
ec = eq*cos(w*t+2*pi/3);

ia = iq*cos(w*t); ib = iq*cos(w*t-2*pi/3); ic = iq*cos(w*t+2*pi/3);

VTa = ea + R*ia - w*L*iq*sin(w*t);
VTb = eb + R*ib - w*L*iq*sin(w*t-2*pi/3);
VTc = ec + R*ic - w*L*iq*sin(w*t+2*pi/3); 

VTa_normalized = VTa./max(VTa);
VTb_normalized = VTb./max(VTb);
VTc_normalized = VTc./max(VTc);

Ia = cos(w*t+comp); Ib = cos(w*t-2*pi/3+comp); Ic = cos(w*t+2*pi/3+comp);

Ialpha = 2/3*(Ia - Ib/2 - Ic/2);
Ibeta = 1/sqrt(3)*(Ib - Ic);
thlist = mod(atan2(Ibeta, Ialpha), 2*pi);

% Initialize outputs
Sap = zeros(vector_length,1); San = zeros(vector_length,1);
Sbp = zeros(vector_length,1); Sbn = zeros(vector_length,1);
Scp = zeros(vector_length,1); Scn = zeros(vector_length,1);
Vinv = zeros(1,vector_length); Vsw = zeros(1,vector_length);

% Sample-and-hold: latch the reference angle once per switching period.
% Using the instantaneous angle at every sample causes sector-boundary
% spikes because tk/tn can jump mid-period when th crosses a sector edge.
prev_sw_period = -1;
th_held        = thlist(1);

for i = 1:length(t)-1
    tl        = mod(t(i), Ts);
    sw_period = floor(t(i) / Ts);
    if sw_period ~= prev_sw_period      % new switching period started
        th_held        = thlist(i);
        prev_sw_period = sw_period;
    end
    th = th_held;

    % ===== NSPWM: separate code path — no zero vectors =====
    if strcmp(mod_technique, 'NSPWM')
        % Sectors aligned to voltage: [k*pi/3, (k+1)*pi/3]
        % th2 = angle from sector trailing edge (0 .. pi/3)
        % State-index lookup: top_ph/bot_ph map s_idx 1..6 to phase indices (1=A,2=B,3=C)
        top_ph = [1,2,2,3,3,1];  bot_ph = [3,3,1,1,2,2];  % S1..S6

        if     th > 0      && th <= pi/3,    th2=pi/3-th;    so=2; sk=1; sn=6;
        elseif th > pi/3   && th <= 2*pi/3,  th2=2*pi/3-th;  so=3; sk=2; sn=1;
        elseif th > 2*pi/3 && th <= pi,      th2=pi-th;      so=4; sk=3; sn=2;
        elseif th > pi     && th <= 4*pi/3,  th2=4*pi/3-th;  so=5; sk=4; sn=3;
        elseif th > 4*pi/3 && th <= 5*pi/3,  th2=5*pi/3-th;  so=6; sk=5; sn=4;
        else,                                 th2=2*pi-th;    so=1; sk=6; sn=5;
        end

        tk_ns = max(0, (m*sin(pi/6+th2) + m*cos(th2) - 1)) * Ts;
        tn_ns = max(0,  1 - m*cos(th2))                     * Ts;
        t0_ns = Ts - tk_ns - tn_ns;   % outer active-vector duration

        seq_ns = [so, sk, sn, sn, sk, so];
        cum_ns = cumsum([t0_ns/2, tk_ns/2, tn_ns/2, tn_ns/2, tk_ns/2, t0_ns/2]);
        slot_ns = find(tl < cum_ns, 1, 'first');
        if isempty(slot_ns), slot_ns = 6; end
        s_idx = seq_ns(slot_ns);

        Sap(i)=S(1,1,s_idx); Sbp(i)=S(1,2,s_idx); Scp(i)=S(1,3,s_idx);
        San(i)=S(2,1,s_idx); Sbn(i)=S(2,2,s_idx); Scn(i)=S(2,3,s_idx);

        VTn = [VTa_normalized(i), VTb_normalized(i), VTc_normalized(i)];
        Vinv(i) = VTn(top_ph(s_idx)) - VTn(bot_ph(s_idx));
        Vsw(i)  = 0;
        continue;   % skip SVM code path
    end
    % ===== END NSPWM =====

    % --- Determine sector, angle bounds, and vector indices ---
    if (th >= 0 && th <= pi/6) || (th > 11*pi/6 && th < 2*pi)
        thetak = -pi/6; thetan = pi/6;
        Z0_idx = 7; Sk_idx = 6; Sn_idx = 1; Z0a_idx = 8; Z0b_idx = 7; sector = 1;
    elseif th > pi/6 && th <= pi/2
        thetak = pi/6; thetan = pi/2;
        Z0_idx = 9; Sk_idx = 1; Sn_idx = 2; Z0a_idx = 7; Z0b_idx = 9; sector = 2;
    elseif th > pi/2 && th <= 5*pi/6
        thetak = pi/2; thetan = 5*pi/6;
        Z0_idx = 8; Sk_idx = 2; Sn_idx = 3; Z0a_idx = 9; Z0b_idx = 8; sector = 3;
    elseif th > 5*pi/6 && th <= 7*pi/6
        thetak = 5*pi/6; thetan = 7*pi/6;
        Z0_idx = 7; Sk_idx = 3; Sn_idx = 4; Z0a_idx = 8; Z0b_idx = 7; sector = 4;
    elseif th > 7*pi/6 && th <= 3*pi/2
        thetak = 7*pi/6; thetan = 3*pi/2;
        Z0_idx = 9; Sk_idx = 4; Sn_idx = 5; Z0a_idx = 7; Z0b_idx = 9; sector = 5;
    else % th > 3*pi/2 && th <= 11*pi/6
        thetak = 3*pi/2; thetan = 11*pi/6;
        Z0_idx = 8; Sk_idx = 5; Sn_idx = 6; Z0a_idx = 9; Z0b_idx = 8; sector = 6;
    end

    % --- Switching time calculation ---
    tk = m*Ts*sin(thetan-th);
    tn = m*Ts*sin(th-thetak);
    t0 = Ts-tk-tn;

    % --- Switching sequence and durations per modulation technique ---
    % vec_seq values: 0 = Z0, 1 = Sk, 2 = Sn, 3 = Z0a (CSVM outer), 4 = Z0b (CSVM inner)
    switch mod_technique
        case 'FSM'
            vec_seq = [0 1 1 2 2 0];
            dur = [t0/2, tk/2, tk/2, tn/2, tn/2, t0/2];
        case 'HSM'
            vec_seq = [1 0 2 2 0 1];
            dur = [tk/2, t0/2, tn/2, tn/2, t0/2, tk/2];
        case 'MHSM'
            vec_seq = [0 1 2 2 1 0];
            dur = [t0/2, tk/2, tn/2, tn/2, tk/2, t0/2];
        case 'DPWM_A'
            vec_seq = [1 2 0 1 2 0];
            dur = [tk/2, tn/2, t0/2, tk/2, tn/2, t0/2];
        case 'DPWM_B'
            vec_seq = [1 2 0 0 2 1];
            dur = [tk/2, tn/2, t0/2, t0/2, tn/2, tk/2];
        case 'DPWM_C'
            vec_seq = [0 1 2 0 0 2 1 0];
            dur = [t0/4, tk/2, tn/2, t0/4, t0/4, tn/2, tk/2, t0/4];
        case 'DPWM_D'
            vec_seq = [1 0 2 0 0 2 0 1];
            dur = [tk/2, t0/4, tn/2, t0/4, t0/4, tn/2, t0/4, tk/2];
        case 'CSVM'
            vec_seq = [3 1 2 4 2 1 3];
            dur = [t0/4, tk/2, tn/2, t0/2, tn/2, tk/2, t0/4];
        otherwise
            error('Unknown modulation technique: %s', mod_technique);
    end

    % --- Find active slot ---
    cum_dur = cumsum(dur);
    slot = find(tl < cum_dur, 1, 'first');
    if isempty(slot)
        disp('Houston');
        continue;
    end

    % --- Map vector type to switching state index ---
    vec_type = vec_seq(slot); % 0=Z0, 1=Sk, 2=Sn, 3=Z0a, 4=Z0b
    if vec_type == 0
        s_idx = Z0_idx;
    elseif vec_type == 1
        s_idx = Sk_idx;
    elseif vec_type == 2
        s_idx = Sn_idx;
    elseif vec_type == 3
        s_idx = Z0a_idx;
    else % vec_type == 4
        s_idx = Z0b_idx;
    end

    % --- Apply switching states ---
    Sap(i) = S(1,1,s_idx); Sbp(i) = S(1,2,s_idx); Scp(i) = S(1,3,s_idx);
    San(i) = S(2,1,s_idx); Sbn(i) = S(2,2,s_idx); Scn(i) = S(2,3,s_idx);

    % --- Apply voltage formulas per sector and vector type ---
    switch sector
        case 1  % Z0=S7, Sk=S6, Sn=S1; CSVM: Z0a=S8, Z0b=S7
            if vec_type == 0 || vec_type == 3 || vec_type == 4
                Vinv(i) = 0; Vsw(i) = 0;
            elseif vec_type == 1
                Vinv(i) = VTa_normalized(i)-VTb_normalized(i); Vsw(i) = 0;
            else
                Vinv(i) = VTa_normalized(i)-VTc_normalized(i); Vsw(i) = 0;
            end
        case 2  % Z0=S9, Sk=S1, Sn=S2; CSVM: Z0a=S7, Z0b=S9
            if vec_type == 0 || vec_type == 3 || vec_type == 4
                Vinv(i) = 0; Vsw(i) = 0;
            elseif vec_type == 1
                Vinv(i) = VTa_normalized(i)-VTc_normalized(i); Vsw(i) = 0;
            else
                Vinv(i) = VTb_normalized(i)-VTc_normalized(i); Vsw(i) = VTb_normalized(i)-VTa_normalized(i);
            end
        case 3  % Z0=S8, Sk=S2, Sn=S3; CSVM: Z0a=S9, Z0b=S8
            if vec_type == 0 || vec_type == 3 || vec_type == 4
                Vinv(i) = 0; Vsw(i) = 0;
            elseif vec_type == 1
                Vinv(i) = VTb_normalized(i)-VTc_normalized(i); Vsw(i) = VTb_normalized(i)-VTa_normalized(i);
            else
                Vinv(i) = VTb_normalized(i)-VTa_normalized(i); Vsw(i) = VTb_normalized(i)-VTa_normalized(i);
            end
        case 4  % Z0=S7, Sk=S3, Sn=S4; CSVM: Z0a=S8, Z0b=S7
            if vec_type == 0 || vec_type == 3 || vec_type == 4
                Vinv(i) = 0; Vsw(i) = 0;
            elseif vec_type == 1
                Vinv(i) = VTb_normalized(i)-VTa_normalized(i); Vsw(i) = VTb_normalized(i)-VTa_normalized(i);
            else
                Vinv(i) = VTc_normalized(i)-VTa_normalized(i); Vsw(i) = VTc_normalized(i)-VTa_normalized(i);
            end
        case 5  % Z0=S9, Sk=S4, Sn=S5; CSVM: Z0a=S7, Z0b=S9
            if vec_type == 0 || vec_type == 3 || vec_type == 4
                Vinv(i) = 0; Vsw(i) = 0;
            elseif vec_type == 1
                Vinv(i) = VTc_normalized(i)-VTa_normalized(i); Vsw(i) = VTc_normalized(i)-VTa_normalized(i);
            else
                Vinv(i) = VTc_normalized(i)-VTb_normalized(i); Vsw(i) = VTc_normalized(i)-VTa_normalized(i);
            end
        case 6  % Z0=S8, Sk=S5, Sn=S6; CSVM: Z0a=S9, Z0b=S8
            if vec_type == 0 || vec_type == 3 || vec_type == 4
                Vinv(i) = 0; Vsw(i) = 0;
            elseif vec_type == 1
                Vinv(i) = VTc_normalized(i)-VTb_normalized(i); Vsw(i) = VTc_normalized(i)-VTa_normalized(i);
            else
                Vinv(i) = VTa_normalized(i)-VTb_normalized(i); Vsw(i) = 0;
            end
    end
end
end
