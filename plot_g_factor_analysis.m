clear;
clc;

%% plot of results
slice_modulation = [0.999 0.99 0.98 0.97 0.96 0.95 0.93 0.90 0.85 0.80 0.70 0.60 0.50 0.3 ...
    0.25 0.21 0.205 0.201 0.2 0.199 0.19 0.15 0.14 0.10 0];
g_uni_SENSE = [999.5 90.57 45.11 29.95 22.38 17.8 13.8 8.75 6.21 4.23 2.75 2.02 1.61 1.18 ...
    1.12 1.08 1.08 1.08 1.08 1.07 1.07 1.04 1.04 1.02 1];
g_uni_CAIPI = [999.5 59.76 29.93 19.99 15.02 12.04 8.02 6.09 4.00 3.12 2.15 1.67 1.40 1.12 ...
    1.08 1.06 1.05 1.05 1.05 1.05 1.04 1.03 1.02 1.01 1];
g_exp_SENSE = [1957.3 194.6 105.1 64.3 48 38.2 27 18.6 12.1 8.8 5.6 3.9 2.9 1.71 ...
    1.52 1.38 1.37 1.36 1.35 1.35 1.32 1.21 1.19 1.1 1];
g_exp_CAIPI = [1.07 1.07 1.07 1.07 1.07 1.07 1.07 1.07 1.08 1.08 1.09 1.12 1.16 1.61 ...
    2.33 8.27 16.14 101.22 258 56.78 7.55 1.96 1.72 1.26 1];

figure(1)
semilogy(slice_modulation, g_uni_SENSE, LineWidth=2)
hold on
semilogy(slice_modulation, g_uni_CAIPI, LineWidth=2)
semilogy(slice_modulation, g_exp_SENSE, LineWidth=2)
semilogy(slice_modulation, g_exp_CAIPI, LineWidth=2)
legend('uniform sensitivity - SENSE', 'uniform sensitivity - CAIPI', 'exponential sensitivity - SENSE','exponential sensitivity - CAIPI')
xlabel('Slice modulation')
ylabel('g-factor')

%% peak for exponential CAIPI
sm = [0.90 0.80 0.70 0.60 0.50 0.3 0.25 0.21 0.205 0.201 0.2 0.199 0.19 0.15 0.14 0.10 0.01 0];
gCAIPI = [1.07 1.08 1.09 1.12 1.16 1.61 2.33 8.27 16.14 101.22 258 56.78 7.55 1.96 1.72 1.26 1 1];

figure(2)
semilogy(sm, gCAIPI)
xlabel('Slice modulation')
ylabel('g-factor')