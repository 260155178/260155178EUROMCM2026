% 1.4 RSI
% =====================================================================
clear; clc; close all;

% PHYSICAL PARAMETERS
p.I0     = 415;                  % data center consumption 2024 (TWh/yr)
p.E0     = 27700;                % global electricity 2024 (TWh/yr)
p.Emax   = 1e5;                  % ceiling (TWh/yr)
p.gE     = -log((p.Emax/33600 - 1) / ((p.Emax - p.E0)/p.E0)) / 6;   % E_tot(2030) = 33600 TWh
p.H0     = 8.1;                  % 2024 population (*10^9)
p.PH0    = (p.E0 - p.I0)/p.H0;   % energy consumed by individual in 2024 (TWh/yr for 10^9)

% INTRINSIC GROWTH RATES
p.rI     = 0.12;                 % RSI growth (IEA: ~12%/yr)
p.rH     = 0.010;                % human growth
p.rhoEta = 0.10;                 % RSI initial autoimprovement efficiency
p.nuH    = 0.01;                 % human initial efficiency

% RSI CAPACITY (C) RETROALIMENTATION
p.theta  = 0.2;                 % feedback on growth
p.phi    = 0.1;                 % feedback on efficiency
p.etaImax = 1e4;                % RSI efficiency ceiling
p.etaHmax = 3;                  % human efficiency ceiling

% ALIGNMENT AND HUMAN DEPENDANCE
p.alpha  = 0.25;                 % fraction of E_tot reserved for humans; % RSI ceiling = (1-alpha)*E_tot
p.deltaH = 0.30;                 % human dependance RSI: multiplies the effect of RSI over humanos (0 = null)
p.epsE   = 1e-5;                 % leftover numeric floor: E_rem >= epsE*E_tot (avoid dividing by 0)

% RSI DEPENDANCE ON HUMANS
p.gD     = 1.0;                 % human help to RSI when D=1
p.kD     = 0.033;               % independance speed

% ATTACKS AND RESISTANCE
p.muI    = 0.15;                % damage of an attack (R=0, A=1)
p.muEta  = 0.10;                % damage of an attack to etaI
p.rR     = 0.10;                % R increase thanks to etaI
p.ag     = 0.60;                % attack intensity
p.ad     = 0.30;                % wear off: the attack dissipates
p.Amax   = 1;
p.tA     = 10;                  % first attack (years since 2024)
p.TA     = 15;                  % period between attacks (years)
p.nP     = 8;                   % attack acuity (greater = shorter attack)

% INITIAL CONDITIONS
R0 = 0.1;  D0 = 1;  A0 = 0;  etaI0 = 1;  etaH0 = 1;
y0 = [p.I0; R0; D0; A0; p.H0; etaI0; etaH0];

% ODEs SYSTEM (function defined at the end)
ode_sys = @(t, y) rsi_ode(t, y, p);

% RESOLUTION WITH ode15s
% If we use a standard solver like ode45, the algorithm would be forced to take incredibly small time steps
% to maintain numerical stability during the rapid transitions, that would keep these tiny steps even when
% the system is behaving smoothly, causing the simulation to stall, slow down dramatically, or crash.
% In contrast, ode15s is a variable-order solver specifically designed for stiff systems based on Numerical
% Differentiation, it maintains stability while dynamically adjusting and increasing the time step during
% stable phases. This allows the simulation to run efficiently and converge to a solution in a fraction
% of the time required by standard explicit methods.

tspan = [0 150];
opts  = odeset('RelTol', 1e-6, 'AbsTol', 1e-8, 'MaxStep', 0.5);   % don't skip attacks
[t, y] = ode15s(ode_sys, tspan, y0, opts);
I = y(:,1); R = y(:,2); D = y(:,3); A = y(:,4); H = y(:,5); etaI = y(:,6); etaH = y(:,7);

% EXTINCTION TIME
% "Extinction" = human population below 10^7 persons (0.01*10^9)
H_ext = 0.01;
extinction_idx = find(H < H_ext, 1);
if isempty(extinction_idx)
    fprintf('Humanity HAS NOT extinguished after %.0f years (final H = %.2f x10^9).\n', tspan(2), H(end));
else
    fprintf('Humanity HAS extinguished on year %.0f.\n', 2024 + t(extinction_idx));
end
fprintf('Final I = %.0f TWh | Final D = %.3f | Final R = %.3f | Final etaI = %.0f\n', ...
        I(end), D(end), R(end), etaI(end));

% FATE CLASSIFICATION:
%   Extinction            : H below H_ext at any moment
%   Marginal survival     : No extinction but H final < 50% of H0 (H_marg)
%   Coexistance           : Final H >= 50% of H0
H_marg = 0.5 * p.H0;
nombres = {'EXTINCTION', 'MARGINAL SURVIVAL', 'COEXISTENCE'};
fate = classify_destiny(H, H_ext, H_marg);
fprintf('FATE: %s  (H_min = %.2f, H_final = %.2f, H_marg = %.2f; unidades 10^9)\n', ...
        nombres{fate}, min(H), H(end), H_marg);

% GRAPH 1: EVOLUTION OVER TIME
figure('Color', 'w', 'Position', [50, 50, 1400, 750]);
tt = 2024 + t;

subplot(2,3,1);
plot(tt, H, 'b-', 'LineWidth', 2); hold on;
plot([tt(1) tt(end)], [H_ext H_ext], 'k--', 'LineWidth', 1.2);
xlabel('Year'); ylabel('Humans H (10^9)'); title('Human population'); grid on;

subplot(2,3,2);
Et = arrayfun(@(s) total(s, p), t);
K  = max((1 - p.alpha) * Et, 1);                          % RSI ceiling
Er = max(Et - (1 + p.deltaH) * I, p.epsE * Et);           % Leftovers
semilogy(tt, I, 'r-', 'LineWidth', 2); hold on;
semilogy(tt, Et, 'k-', 'LineWidth', 1.5);
semilogy(tt, K, 'k--', 'LineWidth', 1.2);
semilogy(tt, Er, 'b-', 'LineWidth', 1.5);
xlabel('Year'); ylabel('TWh/yr'); title('Energy budget');
legend('RSI energy I', 'E_{tot}', 'Ceiling K', 'Leftover E_{rem}', 'Location', 'southeast'); grid on;

subplot(2,3,3);
plot(tt, R, 'g-', 'LineWidth', 2); hold on;
plot(tt, D, 'm-', 'LineWidth', 2);
plot(tt, A, 'r-', 'LineWidth', 1.2);
xlabel('Year'); ylabel('[0-1]'); title('Resistance, dependence, attacks');
legend('Resistance R', 'Dependence D', 'Attacks A', 'Location', 'east'); grid on;

subplot(2,3,4);
semilogy(tt, etaI, 'r-', 'LineWidth', 2); hold on;
semilogy(tt, etaH, 'b-', 'LineWidth', 2);
xlabel('Year'); ylabel('Efficiency'); title('Efficiencies');
legend('RSI \eta_I', 'Human \eta_H', 'Location', 'northwest'); grid on;

subplot(2,3,5);
dano = p.muI * (1 - R) .* A;                 
plot(tt, dano, 'r-', 'LineWidth', 2);
xlabel('Year'); ylabel('\mu_I (1-R) A  (1/yr)'); title('Damage dealt to the RSI'); grid on;

% GRAPH 2: PHASE-SPACE DIAGRAM (H, I)
subplot(2,3,6);
plot(H, I, 'k-', 'LineWidth', 2); hold on;
plot(H(1), I(1), 'go', 'MarkerSize', 8, 'MarkerFaceColor', 'g');
plot(H(end), I(end), 'ro', 'MarkerSize', 8, 'MarkerFaceColor', 'r');

t_ref = 50;
y_ref = interp1(t, y, t_ref);
h_vals = linspace(0, max(H)*1.1, 15);
i_vals = linspace(0, max(I)*1.1, 15);
[H_grid, I_grid] = meshgrid(h_vals, i_vals);
dH_grid = zeros(size(H_grid)); dI_grid = zeros(size(I_grid));
for k = 1:numel(H_grid)
    yy = y_ref(:); yy(5) = H_grid(k); yy(1) = I_grid(k);
    dy = rsi_ode(t_ref, yy, p);
    dH_grid(k) = dy(5); dI_grid(k) = dy(1);
end
Hs = max(H)*1.1;  Is = max(I)*1.1;                  
u = dH_grid / Hs;  v = dI_grid / Is;                
L = sqrt(u.^2 + v.^2);  L(L==0) = 1;                
quiver(H_grid, I_grid, 0.04*Hs*(u./L), 0.04*Is*(v./L), 0, 'Color', [0.7 0.7 0.7]);
xlabel('Human population (H)'); ylabel('RSI energy (I)'); title('Phase-Space Diagram'); grid on;

set(gcf, 'Color', 'w');

% GRAPH 3: EFFECT OF ALPHA AND HUMAN DEPENDANCE
figure('Color', 'w', 'Position', [100, 100, 1100, 420]);
alphas  = [0.2 0.5 0.8];
deltas  = [0 1];
colores = {'b', [0 0.6 0], 'r'};
for j = 1:numel(deltas)
    subplot(1,2,j); hold on;
    for i = 1:numel(alphas)
        q = p;  q.alpha = alphas(i);  q.deltaH = deltas(j);
        [tq, yq] = ode15s(@(t,y) rsi_ode(t, y, q), tspan, y0, opts);
        plot(2024 + tq, max(yq(:,5), 1e-6), 'Color', colores{i}, 'LineWidth', 2);
    end
    plot([2024 2174], [H_ext H_ext], 'k--', 'LineWidth', 1.2);
    set(gca, 'YScale', 'log');
    xlabel('Year'); ylabel('Human population H (10^9)');
    title(sprintf('Dependence \\delta_H = %.1f', deltas(j)));
    legend('\\alpha = 0.2', '\\alpha = 0.5', '\\alpha = 0.8', 'Extinction threshold', 'Location', 'southwest'); grid on;
end
set(gcf, 'Color', 'w');

% FATE MAP
alphas_map = [0 0.1 0.25 0.5 0.75 1];
deltas_map = [0 0.3 1 1.5];
corto = {'EXT', 'MARG', 'COEX'};
fprintf('\nFATE MAP  (EXT = extinction, MARG = marginal survival, COEX = coexistence)\n');
fprintf('%-12s', 'deltaH/alpha'); fprintf('%8.2f', alphas_map); fprintf('\n');
for j = 1:numel(deltas_map)
    fprintf('%-12.2f', deltas_map(j));
    for i = 1:numel(alphas_map)
        q = p;  q.alpha = alphas_map(i);  q.deltaH = deltas_map(j);
        [~, yq] = ode15s(@(t,y) rsi_ode(t, y, q), tspan, y0, opts);
        fprintf('%8s', corto{classify_destiny(yq(:,5), H_ext, H_marg)});
    end
    fprintf('\n');
end

% CRITICAL ALIGNMENT
% alpha_crit: lowest alpha where extinction doesn't happen
fprintf('\nCRITICAL ALIGNMENT (lowest alpha without extinction en %d years)\n', tspan(2));
fprintf('%-8s %-18s %-18s\n', 'deltaH', 'alpha_crit (num)', 'alpha_crit (teor)');
for j = 1:numel(deltas_map)
    lo = 0;  hi = 1;                             
    for k = 1:10
        mid = (lo + hi)/2;
        q = p;  q.alpha = mid;  q.deltaH = deltas_map(j);
        [~, yq] = ode15s(@(t,y) rsi_ode(t, y, q), tspan, y0, opts);
        if min(yq(:,5)) < H_ext, lo = mid; else, hi = mid; end
    end
    teor = (deltas_map(j) + (p.PH0/p.etaHmax) * H_ext / p.Emax) / (1 + deltas_map(j));
    if hi < 2e-3
        txt = '< 0.002 (*)';                       
    else
        txt = sprintf('%.4f', hi);
    end
    fprintf('%-8.2f %-18s %-18.4f\n', deltas_map(j), txt, teor);
end

fprintf('(*) With deltaH = 0 population decays hiperbolically, would take centuries to cross H_ext.\n');

% ======================================================================
%  LOCAL FUNCTIONS
%  =====================================================================
function E = total(t, p)
E = p.Emax / (1 + ((p.Emax - p.E0)/p.E0) * exp(-p.gE * t));
end

function dy = rsi_ode(t, y, p)
I = y(1);  R = y(2);  D = y(3);  A = y(4);  H = y(5);  etaI = y(6);  etaH = y(7);

% AUXILIAR
E    = total(t, p);                    
C    = etaI * I / p.I0;                        
PH   = p.PH0 / etaH;                           
K    = max((1 - p.alpha) * E, 1);              
Erem = max(E - (1 + p.deltaH) * I, p.epsE * E);   
help = 1 + p.gD * D;                          
P    = (0.5 * (1 + cos(2*pi*(t - p.tA)/p.TA)))^p.nP;

% SYSTEM
dI    = p.rI * help * C^p.theta * I * (1 - I/K) - p.muI * (1 - R) * A * I;
dR    = p.rR * (1 - 1/etaI) * (1 - R);
dD    = -p.kD * etaI * D;
dA    = p.ag * (H/p.H0) * etaH * P * (p.Amax - A) - p.ad * A;
dH    = p.rH * H * (1 - PH * H / Erem);        
detaI = p.rhoEta * help * C^p.phi * etaI * (1 - etaI/p.etaImax) - p.muEta * (1 - R) * A * etaI;
detaH = p.nuH * (H/p.H0) * etaH * (1 - etaH/p.etaHmax);

dy = [dI; dR; dD; dA; dH; detaI; detaH];
end

function k = classify_destiny(H, H_ext, H_marg)
% 1 = extinction, 2 = marginal survival, 3 = coexistance
if min(H) < H_ext
    k = 1;
elseif H(end) < H_marg
    k = 2;
else
    k = 3;
end
end