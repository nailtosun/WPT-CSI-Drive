function [Sap San Sbp Sbn Scp Scn Vinv Vsw] = SPWM_Modulator(Va,Vb,Vc,fc,t,w,iq,Lq,id,idq,deltat)
% Carrier waves
Vcp = (-sawtooth(2*pi*fc*t,1/2)+1)/2;
Vcn = (sawtooth(2*pi*fc*t,1/2)-1)/2;
lambda = 0.0059; % flux linkage (Vs) 

% Switching signals initialization
Sap = zeros(deltat,1); San = zeros(deltat,1);
Sbp = zeros(deltat,1); Sbn = zeros(deltat,1);
Scp = zeros(deltat,1); Scn = zeros(deltat,1);
ea = lambda*w*sin(w*t);
eb = lambda*w*sin(w*t-2*pi/3);
ec = lambda*w*sin(w*t+2*pi/3);
R = 1.19; % Stator Resistance
Vta = ea+R*iq*sin(w*t)+w*Lq*iq*sin(w*t+pi/2)+w*Lq*id*sin(w*t)+R*id*sin(w*t-pi/2);
Vtb = eb+R*iq*sin(w*t-2*pi/3)+w*Lq*iq*sin(w*t+pi/2-2*pi/3)+w*Lq*id*sin(w*t-2*pi/3)+R*id*sin(w*t-2*pi/3-pi/2);
Vtc = ec+R*iq*sin(w*t+2*pi/3)+w*Lq*iq*sin(w*t+pi/2+2*pi/3)+w*Lq*id*sin(w*t+2*pi/3)+R*id*sin(w*t+2*pi/3-pi/2);
Vta = Vta./max(Vta);
Vtb = Vtb./max(Vtb);
Vtc = Vtc./max(Vtc);
ea = Vta;
eb = Vtb;
ec = Vtc;
m = iq/idq;
Va = m*Va;
Vb = m*Vb;
Vc = m*Vc;
% Interval determination 
for i = 1:length(Va)
    if abs(Va(i)) == max([abs(Va(i)),abs(Vb(i)),abs(Vc(i))])
        if Va(i) > 0
            % Sector Ap
            % Master calculations
            Sap(i) = 1; % master switch
            Sbp(i) = 0; % complementary rule
            Scp(i) = 0; % complementary rule
            if Vcp(i) > Va(i) % check zero or active
                % it is zero state
                San(i) = 1; % zero state
                Sbn(i) = 0; % complementary rule
                Scn(i) = 0; % complementary rule
                Vinv(i) = 0; % inverter input voltage
                Vsw(i) = 0;
            else % Active state
                % Slave calculation
                if Vc(i) < Vcn(i) % c selected as slave
                    San(i) = 0; % complementary rule
                    Sbn(i) = 0; % complementary rule
                    Scn(i) = 1; % slave switch
                    Vinv(i) = ea(i)-ec(i); % inverter input voltage
                    Vsw(i) = 0;
                else
                    San(i) = 0; % complementary rule
                    Sbn(i) = 1; % complementary rule
                    Scn(i) = 0; % complementary rule
                    Vinv(i) = ea(i)-eb(i); % inverter input voltage
                    Vsw(i) = 0;
                end
            end
        else
            % Sector An
            San(i) = 1; % master switch
            Sbn(i) = 0; % complementary rule
            Scn(i) = 0; % complementary rule
            if Va(i) > Vcn(i)
                Sap(i) = 1; % master switch
                Sbp(i) = 0; % complementary rule
                Scp(i) = 0; % complementary rule
                Vinv(i) = 0; % inverter input voltage
                Vsw(i) = 0;
            else
                if Vc(i) > Vcp(i)
                    Sap(i) = 0; % complementary rule
                    Sbp(i) = 0; % complementary rule
                    Scp(i) = 1; % slave switch
                    Vinv(i) = ec(i)-ea(i); % inverter input voltage
                    Vsw(i) = ec(i)-ea(i);
                else
                    Sap(i) = 0; % complementary rule
                    Sbp(i) = 1; % slave switch
                    Scp(i) = 0; % complementary rule
                    Vinv(i) = eb(i)-ea(i); % inverter input voltage
                    Vsw(i) = eb(i)-ea(i);
                end
            end
        end
    elseif abs(Vb(i)) == max([abs(Va(i)),abs(Vb(i)),abs(Vc(i))])
        if Vb(i) > 0 
            % Sector Bp
            Sap(i) = 0; % complementary rule
            Sbp(i) = 1; % master switch
            Scp(i) = 0; % complementary rule
            if Vcp(i) > Vb(i)
                San(i) = 0; % complementary rule
                Sbn(i) = 1; % zero state 
                Scn(i) = 0; % complementary rule
                Vinv(i) = 0; % inverter input voltage
                Vsw(i) = 0;
            else
                % Slave calculation
                if Va(i) < Vcn(i) % a selected as slave
                    San(i) = 1; % slave switch
                    Sbn(i) = 0; % complementary rule
                    Scn(i) = 0; % complementary rule 
                    Vinv(i) = eb(i)-ea(i); % inverter input voltage
                    Vsw(i) = eb(i)-ea(i);
                else
                    San(i) = 0; % complementary rule
                    Sbn(i) = 0; % complementary rule
                    Scn(i) = 1; % slave switch
                    Vinv(i) = eb(i)-ec(i); % inverter input voltage
                    Vsw(i) = eb(i)-ea(i);
                end
            end
        else
            % Sector Bn
            San(i) = 0; % complementary rule
            Sbn(i) = 1; % master switch
            Scn(i) = 0; % complementary rule
            if Vb(i) > Vcn(i)
                Sap(i) = 0; % complementary rule
                Sbp(i) = 1; % zero state
                Scp(i) = 0; % complementary rule
                Vinv(i) = 0;
                Vsw(i) = 0;
            else
                if Va(i) > Vcp(i)
                    Sap(i) = 1; % slave switch
                    Sbp(i) = 0; % complementary rule
                    Scp(i) = 0; % complementary rule
                    Vinv(i) = ea(i)-eb(i); % inverter input voltage
                    Vsw(i) = 0;
                else
                    Sap(i) = 0; % complementary rule
                    Sbp(i) = 0; % complementary rule
                    Scp(i) = 1; % slave switch
                    Vinv(i) = ec(i)-eb(i); % inverter input voltage
                    Vsw(i) = ec(i)-ea(i); 
                end
            end
        end
    elseif abs(Vc(i)) == max([abs(Va(i)),abs(Vb(i)),abs(Vc(i))])
        if Vc(i) > 0 
            % Sector Cp
            Sap(i) = 0; % complementary rule
            Sbp(i) = 0; % complementary rule
            Scp(i) = 1; % master switch
            if Vcp(i) > Vc(i)
                San(i) = 0; % complementary rule
                Sbn(i) = 0; % complementary rule
                Scn(i) = 1; % zero state
                Vinv(i) = 0; % inverter input voltage
                Vsw(i) = 0;
            else
                if Vb(i) < Vcn(i) % b selected as slave
                    San(i) = 0; % complementary rule
                    Sbn(i) = 1; % slave switch
                    Scn(i) = 0; % complementary rule
                    Vinv(i) = ec(i)-eb(i); % inverter input voltage
                    Vsw(i) = ec(i)-ea(i);
                else
                    San(i) = 1; % slave switch
                    Sbn(i) = 0; % complementary rule
                    Scn(i) = 0; % complementary rule
                    Vinv(i) = ec(i)-ea(i); % inverter input voltage
                    Vsw(i) = ec(i)-ea(i);
                end
            end
        else
            % Sector Cn
            San(i) = 0; % complementary rule
            Sbn(i) = 0; % complementary rule
            Scn(i) = 1; % master switch
            if Vc(i) > Vcn(i)
                Sap(i) = 0; % complementary rule
                Sbp(i) = 0; % complementary rule
                Scp(i) = 1; % zero state
                Vinv(i) = 0; % inverter input voltage
                Vsw(i) = 0;
            else
                if Vb(i) > Vcp(i)
                    Sap(i) = 0; % complementary rule
                    Sbp(i) = 1; % slave switch
                    Scp(i) = 0; % complementary rule
                    Vinv(i) = eb(i)-ec(i); % inverter input voltage
                    Vsw(i) = eb(i)-ea(i);
                else
                    Sap(i) = 1; % slave switch
                    Sbp(i) = 0; % complementary rule
                    Scp(i) = 0; % complementary rule
                    Vinv(i) = ea(i)-ec(i); % inverter input voltage
                    Vsw(i) = 0;
                end
            end
        end
    else
        disp('Opps!')
    end
    
end