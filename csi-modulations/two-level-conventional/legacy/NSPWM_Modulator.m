function [STa STb STc SBa SBb SBc Vcm Vdc Vsw Vsw2] = NVPWM_Modulatorm(m)
% Space Vector Modulation Implementation for CSI
% Based on paper: doi: 10.1109/PESC.2000.878821
Fs = 50e3; % switching frequency (Hz)
Ts = 1/Fs;  % switching period (s)
TS = Ts/100; % sampling time (s)
f = 50; % fundamental frequency (Hz)
S1 = [1 0 0; 0 0 1];
S2 = [0 1 0; 0 0 1];
S3 = [0 1 0; 1 0 0];
S4 = [0 0 1; 1 0 0];
S5 = [0 0 1; 0 1 0];
S6 = [1 0 0; 0 1 0];
S7 = [1 0 0; 1 0 0];
S8 = [0 1 0; 0 1 0];
S9 = [0 0 1; 0 0 1];

t = linspace(0,1/f,1/f/TS); % time vector
STa = zeros(1/f/TS,1)';
STb = zeros(1/f/TS,1)';
STc = zeros(1/f/TS,1)';
SBa = zeros(1/f/TS,1)';
SBb = zeros(1/f/TS,1)';
SBc = zeros(1/f/TS,1)';
Vcm = zeros(1/f/TS,1)';
Vsw = zeros(1/f/TS,1)';
Vsw2 = zeros(1/f/TS,1)';
theta = 2*pi*f*t;
the = 0;
thlist = mod(theta,2*pi);
phase = 0;
ea = cos(2*pi*f*t+phase);
eb = cos(2*pi*f*t-2*pi/3+phase);
ec = cos(2*pi*f*t+2*pi/3+phase);
for i = 1:length(t)
    tl = mod(t(i),Ts);
    th = thlist(i);
    if (th > 0 && th <=pi/3)
        % sector 1 [2][1][6] [6][1][2]
        th2 = 1*pi/3-th;
        % switching time calculation
        tk = (m*sin(pi/6+th2)+m*cos(th2)-1)*Ts;
        tn = Ts-m*cos(th2)*Ts;
        t0 = Ts-tk-tn; 
        if tl >= 0 && tl < t0/2
            % [2]
            STa(i) = S2(1,1); STb(i) = S2(1,2); STc(i) = S2(1,3);
            SBa(i) = S2(2,1); SBb(i) = S2(2,2); SBc(i) = S2(2,3);
            Vcm(i) =-ea(i)/2;
            Vdc(i) = eb(i)-ec(i);
            Vsw(i) = eb(i)-ea(i);
            Vsw2(i) = ea(i)-ec(i);
        elseif tl>= t0/2 && tl< t0/2+tk/2
            % [1]
            STa(i) = S1(1,1); STb(i) = S1(1,2); STc(i) = S1(1,3);
            SBa(i) = S1(2,1); SBb(i) = S1(2,2); SBc(i) = S1(2,3);
            Vcm(i) = -eb(i)/2;
            Vdc(i) = ea(i)-ec(i);
            Vsw(i) = 0;
            Vsw2(i) = ea(i)-ec(i);
        elseif tl>=t0/2+tk/2 && tl< t0/2+tk/2+tn/2
            % [6]
            STa(i) = S6(1,1); STb(i) = S6(1,2); STc(i) = S6(1,3);
            SBa(i) = S6(2,1); SBb(i) = S6(2,2); SBc(i) = S6(2,3);
            Vcm(i) = -ec(i)/2;
            Vdc(i) = ea(i)-eb(i);
            Vsw(i) = 0;
            Vsw2(i) = ea(i)-eb(i);
        elseif tl>= t0/2+tk/2+tn/2 && tl< t0/2+tk/2+tn
            % [6]
            STa(i) = S6(1,1); STb(i) = S6(1,2); STc(i) = S6(1,3);
            SBa(i) = S6(2,1); SBb(i) = S6(2,2); SBc(i) = S6(2,3);
            Vcm(i) = -ec(i)/2;
            Vdc(i) = ea(i)-eb(i);
            Vsw(i) = 0;
            Vsw2(i) = ea(i)-eb(i);
        elseif tl>=  t0/2+tk/2+tn && tl <  t0/2+tk+tn
            % [1]
            STa(i) = S1(1,1); STb(i) = S1(1,2); STc(i) = S1(1,3);
            SBa(i) = S1(2,1); SBb(i) = S1(2,2); SBc(i) = S1(2,3);
            Vcm(i) = -eb(i)/2;
            Vdc(i) = ea(i)-ec(i);
            Vsw(i) = 0;
            Vsw2(i) = ea(i)-ec(i);
        elseif tl>= t0/2+tk+tn && tl < t0+tk+tn
            % [2]
            STa(i) = S2(1,1); STb(i) = S2(1,2); STc(i) = S2(1,3);
            SBa(i) = S2(2,1); SBb(i) = S2(2,2); SBc(i) = S2(2,3);
            Vcm(i) = -ea(i)/2;
            Vdc(i) = eb(i)-ec(i);
            Vsw(i) = eb(i)-ea(i);
            Vsw2(i) = ea(i)-ec(i);
        else
            disp('Houston')
        end
    elseif th > pi/3 && th <=2*pi/3
        % sector 2 [3][2][1] [1][2][3]
        th2 = 2*pi/3-th;
        % switching time calculation
        tk = (m*sin(pi/6+th2)+m*cos(th2)-1)*Ts;
        tn = Ts-m*cos(th2)*Ts;
        t0 = Ts-tk-tn; 
        
        if tl >= 0 && tl < t0/2
            % [3]
            STa(i) = S3(1,1); STb(i) = S3(1,2); STc(i) = S3(1,3);
            SBa(i) = S3(2,1); SBb(i) = S3(2,2); SBc(i) = S3(2,3);
            Vcm(i) = -ec(i)/2;
            Vdc(i) = eb(i)-ea(i);
            Vsw(i) = eb(i)-ea(i);
        elseif tl>= t0/2 && tl< t0/2+tk/2
            % [2]
            STa(i) = S2(1,1); STb(i) = S2(1,2); STc(i) = S2(1,3);
            SBa(i) = S2(2,1); SBb(i) = S2(2,2); SBc(i) = S2(2,3);
            Vcm(i) = -ea(i)/2;
            Vdc(i) = eb(i)-ec(i);
            Vsw(i) = eb(i)-ea(i);
            Vsw2(i) = ea(i)-ec(i);
        elseif tl>=t0/2+tk/2 && tl< t0/2+tk/2+tn/2
            % [1]
            STa(i) = S1(1,1); STb(i) = S1(1,2); STc(i) = S1(1,3);
            SBa(i) = S1(2,1); SBb(i) = S1(2,2); SBc(i) = S1(2,3);
            Vcm(i) = -eb(i)/2;
            Vdc(i) = ea(i)-ec(i);
            Vsw(i) = 0;
            Vsw2(i) = ea(i)-ec(i);
        elseif tl>= t0/2+tk/2+tn/2 && tl< t0/2+tk/2+tn
            % [1]
            STa(i) = S1(1,1); STb(i) = S1(1,2); STc(i) = S1(1,3);
            SBa(i) = S1(2,1); SBb(i) = S1(2,2); SBc(i) = S1(2,3);
            Vcm(i) = -eb(i)/2;
            Vdc(i) = ea(i)-ec(i);
            Vsw(i) = 0;
            Vsw2(i) = ea(i)-ec(i);
        elseif tl>=  t0/2+tk/2+tn && tl <  t0/2+tk+tn
            % [2]
            STa(i) = S2(1,1); STb(i) = S2(1,2); STc(i) = S2(1,3);
            SBa(i) = S2(2,1); SBb(i) = S2(2,2); SBc(i) = S2(2,3);
            Vcm(i) = -ea(i)/2;
            Vdc(i) = eb(i)-ec(i);
            Vsw(i) = eb(i)-ea(i);
            Vsw2(i) = ea(i)-ec(i);
        elseif tl>= t0/2+tk+tn && tl < t0+tk+tn
            % [3]
            STa(i) = S3(1,1); STb(i) = S3(1,2); STc(i) = S3(1,3);
            SBa(i) = S3(2,1); SBb(i) = S3(2,2); SBc(i) = S3(2,3);
            Vcm(i) = -ec(i)/2;
            Vdc(i) = eb(i)-ea(i);
            Vsw(i) = eb(i)-ea(i);
        else
            disp('Houston')
        end
    
    elseif th > 2*pi/3 && th <=3*pi/3
        % sector 3 [4][3][2] [2][3][4]
        th2 = 3*pi/3-th;
        % switching time calculation
        tk = (m*sin(pi/6+th2)+m*cos(th2)-1)*Ts;
        tn = Ts-m*cos(th2)*Ts;
        t0 = Ts-tk-tn; 

        if tl >= 0 && tl < t0/2
            % [4]
            STa(i) = S4(1,1); STb(i) = S4(1,2); STc(i) = S4(1,3);
            SBa(i) = S4(2,1); SBb(i) = S4(2,2); SBc(i) = S4(2,3);
            Vcm(i) = -eb(i)/2;
            Vdc(i) = ec(i)-ea(i);
            Vsw(i) = ec(i)-ea(i);
        elseif tl>= t0/2 && tl< t0/2+tk/2
            % [3]
            STa(i) = S3(1,1); STb(i) = S3(1,2); STc(i) = S3(1,3);
            SBa(i) = S3(2,1); SBb(i) = S3(2,2); SBc(i) = S3(2,3);
            Vcm(i) = -ec(i)/2;
            Vdc(i) = eb(i)-ea(i);
            Vsw(i) = eb(i)-ea(i);
        elseif tl>=t0/2+tk/2 && tl< t0/2+tk/2+tn/2
            % [2]
            STa(i) = S2(1,1); STb(i) = S2(1,2); STc(i) = S2(1,3);
            SBa(i) = S2(2,1); SBb(i) = S2(2,2); SBc(i) = S2(2,3);
            Vcm(i) = -ea(i)/2;
            Vdc(i) = eb(i)-ec(i);
            Vsw(i) = eb(i)-ea(i);
            Vsw2(i) = ea(i)-ec(i);
        elseif tl>= t0/2+tk/2+tn/2 && tl< t0/2+tk/2+tn
            % [2]
            STa(i) = S2(1,1); STb(i) = S2(1,2); STc(i) = S2(1,3);
            SBa(i) = S2(2,1); SBb(i) = S2(2,2); SBc(i) = S2(2,3);
            Vcm(i) = -ea(i)/2;
            Vdc(i) = eb(i)-ec(i);
            Vsw(i) = eb(i)-ea(i);
            Vsw2(i) = ea(i)-ec(i);
        elseif tl>=  t0/2+tk/2+tn && tl <  t0/2+tk+tn
            % [3]
            STa(i) = S3(1,1); STb(i) = S3(1,2); STc(i) = S3(1,3);
            SBa(i) = S3(2,1); SBb(i) = S3(2,2); SBc(i) = S3(2,3);
            Vcm(i) = -ec(i)/2;
            Vdc(i) = eb(i)-ea(i);
            Vsw(i) = eb(i)-ea(i);
        elseif tl>= t0/2+tk+tn && tl < t0+tk+tn
            % [4]
            STa(i) = S4(1,1); STb(i) = S4(1,2); STc(i) = S4(1,3);
            SBa(i) = S4(2,1); SBb(i) = S4(2,2); SBc(i) = S4(2,3);
            Vcm(i) = -eb(i)/2;
            Vdc(i) = ec(i)-ea(i);
            Vsw(i) = ec(i)-ea(i);
        else
            disp('Houston')
        end
    
    elseif th > 3*pi/3 && th <=4*pi/3
        % sector 4 [5][4][3] [3][4][5]
        th2 = 4*pi/3-th;
        % switching time calculation
        tk = (m*sin(pi/6+th2)+m*cos(th2)-1)*Ts;
        tn = Ts-m*cos(th2)*Ts;
        t0 = Ts-tk-tn;

        if tl >= 0 && tl < t0/2
            % [5]
            STa(i) = S5(1,1); STb(i) = S5(1,2); STc(i) = S5(1,3);
            SBa(i) = S5(2,1); SBb(i) = S5(2,2); SBc(i) = S5(2,3);
            Vcm(i) = -ea(i)/2;
            Vdc(i) = ec(i)-eb(i);
            Vsw(i) = ec(i)-ea(i);
            Vsw2(i) = ea(i)-eb(i);
        elseif tl>= t0/2 && tl< t0/2+tk/2
            % [4]
            STa(i) = S4(1,1); STb(i) = S4(1,2); STc(i) = S4(1,3);
            SBa(i) = S4(2,1); SBb(i) = S4(2,2); SBc(i) = S4(2,3);
            Vcm(i) = -eb(i)/2;
            Vdc(i) = ec(i)-ea(i);
            Vsw(i) = ec(i)-ea(i);
        elseif tl>=t0/2+tk/2 && tl< t0/2+tk/2+tn/2
            % [3]
            STa(i) = S3(1,1); STb(i) = S3(1,2); STc(i) = S3(1,3);
            SBa(i) = S3(2,1); SBb(i) = S3(2,2); SBc(i) = S3(2,3);
            Vcm(i) = -ec(i)/2;
            Vdc(i) = eb(i)-ea(i);
            Vsw(i) = eb(i)-ea(i);
        elseif tl>= t0/2+tk/2+tn/2 && tl< t0/2+tk/2+tn
            % [3]
            STa(i) = S3(1,1); STb(i) = S3(1,2); STc(i) = S3(1,3);
            SBa(i) = S3(2,1); SBb(i) = S3(2,2); SBc(i) = S3(2,3);
            Vcm(i) = -ec(i)/2;
            Vdc(i) = eb(i)-ea(i);
            Vsw(i) = eb(i)-ea(i);
        elseif tl>=  t0/2+tk/2+tn && tl <  t0/2+tk+tn
            % [4]
            STa(i) = S4(1,1); STb(i) = S4(1,2); STc(i) = S4(1,3);
            SBa(i) = S4(2,1); SBb(i) = S4(2,2); SBc(i) = S4(2,3);
            Vcm(i) = -eb(i)/2;
            Vdc(i) = ec(i)-ea(i);
            Vsw(i) = ec(i)-ea(i);
        elseif tl>= t0/2+tk+tn && tl < t0+tk+tn
            % [5]
            STa(i) = S5(1,1); STb(i) = S5(1,2); STc(i) = S5(1,3);
            SBa(i) = S5(2,1); SBb(i) = S5(2,2); SBc(i) = S5(2,3);
            Vcm(i) = -ea(i)/2;
            Vdc(i) = ec(i)-eb(i);
            Vsw(i) = ec(i)-ea(i);
            Vsw2(i) = ea(i)-eb(i);
        else
            disp('Houston')
        end
    elseif th > 4*pi/3 && th <=5*pi/3
        % sector 5 [6][5][4] [4][5][6]
       
        th2 = 5*pi/3-th;
        % switching time calculation
        tk = (m*sin(pi/6+th2)+m*cos(th2)-1)*Ts;
        tn = Ts-m*cos(th2)*Ts;
        t0 = Ts-tk-tn;

        if tl >= 0 && tl < t0/2
            % [6]
            STa(i) = S6(1,1); STb(i) = S6(1,2); STc(i) = S6(1,3);
            SBa(i) = S6(2,1); SBb(i) = S6(2,2); SBc(i) = S6(2,3);
            Vcm(i) = -ec(i)/2;
            Vdc(i) = ea(i)-eb(i);
            Vsw(i) = 0;
            Vsw2(i) = ea(i)-eb(i);
        elseif tl>= t0/2 && tl< t0/2+tk/2
            % [5]
            STa(i) = S5(1,1); STb(i) = S5(1,2); STc(i) = S5(1,3);
            SBa(i) = S5(2,1); SBb(i) = S5(2,2); SBc(i) = S5(2,3);
            Vcm(i) = -ea(i)/2;
            Vdc(i) = ec(i)-eb(i);
            Vsw(i) = ec(i)-ea(i);
            Vsw2(i) = ea(i)-eb(i);
        elseif tl>=t0/2+tk/2 && tl< t0/2+tk/2+tn/2
            % [4]
            STa(i) = S4(1,1); STb(i) = S4(1,2); STc(i) = S4(1,3);
            SBa(i) = S4(2,1); SBb(i) = S4(2,2); SBc(i) = S4(2,3);
            Vcm(i) = -eb(i)/2;
            Vdc(i) = ec(i)-ea(i);
            Vsw(i) = ec(i)-ea(i);
        elseif tl>= t0/2+tk/2+tn/2 && tl< t0/2+tk/2+tn
            % [4]
            STa(i) = S4(1,1); STb(i) = S4(1,2); STc(i) = S4(1,3);
            SBa(i) = S4(2,1); SBb(i) = S4(2,2); SBc(i) = S4(2,3);
            Vcm(i) = -eb(i)/2;
            Vdc(i) = ec(i)-ea(i);
            Vsw(i) = ec(i)-ea(i);
        elseif tl>=  t0/2+tk/2+tn && tl <  t0/2+tk+tn
            % [5]
            STa(i) = S5(1,1); STb(i) = S5(1,2); STc(i) = S5(1,3);
            SBa(i) = S5(2,1); SBb(i) = S5(2,2); SBc(i) = S5(2,3);
            Vcm(i) = -ea(i)/2;
            Vdc(i) = ec(i)-eb(i);
            Vsw(i) = ec(i)-ea(i);
            Vsw2(i) = ea(i)-eb(i);
        elseif tl>= t0/2+tk+tn && tl < t0+tk+tn
            % [6]
            STa(i) = S6(1,1); STb(i) = S6(1,2); STc(i) = S6(1,3);
            SBa(i) = S6(2,1); SBb(i) = S6(2,2); SBc(i) = S6(2,3);
            Vcm(i) = -ec(i)/2;
            Vdc(i) = ea(i)-eb(i);
            Vsw(i) = 0;
            Vsw2(i) = ea(i)-eb(i);
        else
            disp('Houston')
        end
    elseif th > 5*pi/3 && th <=2*pi
        % sector 6 [1][6][5] [5][6][1]
        th2 = 6*pi/3-th;
        % switching time calculation
        tk = (m*sin(pi/6+th2)+m*cos(th2)-1)*Ts;
        tn = Ts-m*cos(th2)*Ts;
        t0 = Ts-tk-tn;
        if tl >= 0 && tl < t0/2
            % [1]
            STa(i) = S1(1,1); STb(i) = S1(1,2); STc(i) = S1(1,3);
            SBa(i) = S1(2,1); SBb(i) = S1(2,2); SBc(i) = S1(2,3);
            Vcm(i) = -eb(i)/2;
            Vdc(i) = ea(i)-ec(i);
            Vsw(i) = 0;
            Vsw2(i) = ea(i)-ec(i);
        elseif tl>= t0/2 && tl< t0/2+tk/2
            % [6]
            STa(i) = S6(1,1); STb(i) = S6(1,2); STc(i) = S6(1,3);
            SBa(i) = S6(2,1); SBb(i) = S6(2,2); SBc(i) = S6(2,3);
            Vcm(i) = -ec(i)/2;
            Vdc(i) = ea(i)-eb(i);
            Vsw(i) = 0;
            Vsw2(i) = ea(i)-eb(i);
        elseif tl>=t0/2+tk/2 && tl< t0/2+tk/2+tn/2
            % [5]
            STa(i) = S5(1,1); STb(i) = S5(1,2); STc(i) = S5(1,3);
            SBa(i) = S5(2,1); SBb(i) = S5(2,2); SBc(i) = S5(2,3);
            Vcm(i) = -ea(i)/2;
            Vdc(i) = ec(i)-eb(i);
            Vsw(i) = ec(i)-ea(i);
            Vsw2(i) = ea(i)-eb(i);
        elseif tl>= t0/2+tk/2+tn/2 && tl< t0/2+tk/2+tn
            % [5]
            STa(i) = S5(1,1); STb(i) = S5(1,2); STc(i) = S5(1,3);
            SBa(i) = S5(2,1); SBb(i) = S5(2,2); SBc(i) = S5(2,3);
            Vcm(i) = -ea(i)/2;
            Vdc(i) = ec(i)-eb(i);
            Vsw(i) = ec(i)-ea(i);
            Vsw2(i) = ea(i)-eb(i);
        elseif tl>=  t0/2+tk/2+tn && tl <  t0/2+tk+tn
            % [6]
            STa(i) = S6(1,1); STb(i) = S6(1,2); STc(i) = S6(1,3);
            SBa(i) = S6(2,1); SBb(i) = S6(2,2); SBc(i) = S6(2,3);
            Vcm(i) = -ec(i)/2;
            Vdc(i) = ea(i)-eb(i);
            Vsw(i) = 0;
            Vsw2(i) = ea(i)-eb(i);
        elseif tl>= t0/2+tk+tn && tl < t0+tk+tn
            % [1]
            STa(i) = S1(1,1); STb(i) = S1(1,2); STc(i) = S1(1,3);
            SBa(i) = S1(2,1); SBb(i) = S1(2,2); SBc(i) = S1(2,3);
            Vcm(i) = -eb(i)/2;
            Vdc(i) = ea(i)-ec(i);
            Vsw(i) = 0;
            Vsw2(i) = ea(i)-ec(i);
        else
            disp('Houston')
        end
    
    end
end