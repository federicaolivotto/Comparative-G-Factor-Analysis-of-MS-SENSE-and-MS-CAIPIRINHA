clc; clear; close all;

% Parameters 
slice_modulation = 1; % TO MODULATE SENSITIVITY CHANGE BETWEEN THE TWO SLICES: higher --> MORE SIMILAR
noise_level = 10; % TO MODULATE THE ADDED NOISE 

% this code works just for 2 slices and 2 coils
N_coils = 2;
N_slices = 2;
distance_each_slice = 30; 

caipishift = true;

%% LOAD FILE and get slices
fileName = 'T1_ICBM_normal_1mm_pn0_rf0.mnc';
data = loadminc(fileName);
[nx, ny, nz] = size(data);
targetSize = [200, 200, 200];
padding = max(0, targetSize - [nx, ny, nz]); 
cropping = max(0, [nx, ny, nz] - targetSize); 
dataPadded = padarray(data, floor(padding / 2), 'both'); 
dataPadded = padarray(dataPadded, ceil(padding / 2), 'post');
startIdx = floor(cropping / 2) + 1;
endIdx = startIdx + targetSize - 1;
dataReshaped = dataPadded(startIdx(1):endIdx(1), startIdx(2):endIdx(2), startIdx(3):endIdx(3));
[nx, ny, nz] = size(dataReshaped);
FOVx = nx; % [mm]
FOVy = ny; % [mm] 
FOVz = nz; % [mm]

%Selecting slices
slice = zeros(nx, ny, N_slices);
for i = 0:N_slices-1
    slice(:,:,i+1) = dataReshaped(:,:,nz/2 + distance_each_slice * i); 
end

%plot slices
figure(1);
for i = 1:N_slices
    subplot(ceil(N_slices/2), 2, i); 
    imagesc(slice(:, :, i));
    colormap(gray);
    axis image;
    axis off;
    title(['Slice ' num2str(i) ': Brain-like Phantom']);
end

% binary masks
brainmasks = slice>10;
for i = 1:N_slices
    brainmasks(:,:,i) = imclose(brainmasks(:,:,i),strel('disk',2));
end

figure(2);
for i = 1:N_slices
    subplot(ceil(N_slices/2), 2, i); 
    imagesc(brainmasks(:, :, i));
    colormap(gray);
    axis image;
    axis off;
    title(['Slice ' num2str(i) ': Brainmask']);
end

%% coil sensitivities
% Coordinate grids
[x, y] = meshgrid(linspace(-1, 1, nx), linspace(-1, 1, ny));

% uniform coil sensitivities
%C11 = ones(size(x)).*brainmasks(:,:,1);
%C12 = slice_modulation*ones(size(x)).*brainmasks(:,:,2);
%C21 = slice_modulation*ones(size(x)).*brainmasks(:,:,1);
%C22 = ones(size(x)).*brainmasks(:,:,2);

% exponential coil sensitivities
C11 = exp(-((x + 0.8).^2 + y.^2)).*brainmasks(:,:,1);
C12 = slice_modulation*exp(-((x + 0.8).^2 + y.^2)).*brainmasks(:,:,2);
C21 = slice_modulation*exp(-((x - 0.8).^2 + y.^2)).*brainmasks(:,:,1);
C22 = exp(-((x - 0.8).^2 + y.^2)).*brainmasks(:,:,2);

% Plot sensitivities
figure(3);
subplot(2, 2, 1);
imagesc(C11(:, :, 1), [0 1]); 
axis image;
axis off;
title('Left Coil 1 - Slice 1');

subplot(2, 2, 2);
imagesc(C12(:, :, 1), [0 1]); 
axis image;
axis off;
title('Left Coil 1 - Slice 2');

subplot(2, 2, 3);
imagesc(C21(:, :, 1), [0 1]); 
axis image;
axis off;
title('Right Coil 2 - Slice 1');

subplot(2, 2, 4);
imagesc(C22(:, :, 1), [0 1]); 
axis image;
axis off;
title('Right Coil 2 - Slice 2');
sgtitle('Coil sensitivities for the different slices');

%% Applying sensitivities to relative slices images
slices_with_Scoils11=slice(:,:,1).*C11(:,:);
slices_with_Scoils12=slice(:,:,2).*C12(:,:);
slices_with_Scoils21=slice(:,:,1).*C21(:,:);
slices_with_Scoils22=slice(:,:,2).*C22(:,:);

% maximum pixel intensity value, used to standardize the intensity range
maxIm = max([max(slices_with_Scoils11(:)) max(slices_with_Scoils12(:)) max(slices_with_Scoils21(:)) max(slices_with_Scoils22(:)) ]);

% Plot slice images * sensitivities maps
figure(4);

subplot(2, 2, 1);
imagesc(slices_with_Scoils11(:, :), [0 maxIm]); 
colormap('gray');
axis image;
axis off;
title('Left Coil 1 - Slice 1');

subplot(2, 2, 2);
imagesc(slices_with_Scoils12(:, :), [0 maxIm]);
colormap('gray');
axis image;
axis off;
title('Left Coil 1 - Slice 2');

subplot(2, 2, 3);
imagesc(slices_with_Scoils21(:, :), [0 maxIm]); 
colormap('gray');
axis image;
axis off;
title('Right Coil 2 - Slice 1');

subplot(2, 2, 4);
imagesc(slices_with_Scoils22(:, :), [0 maxIm]); 
colormap('gray');
axis image;
axis off;
title('Right Coil 2 - Slice 2');
sgtitle('Slices with coil sensitivities applied');

%% mixed images seen by coils
delta_k = 2 * pi / FOVx;
delta_x = FOVx / N_slices; % FOV/2
phase_pattern = exp(-1i * (-ny / 2:ny / 2 - 1) *delta_x * delta_k); % row vector (alternance of 1 and -1)
phase_matrix = repmat(phase_pattern, nx, 1); % repeats the phase_pattern vector for nx times -> creates a matrix with nx rows

if caipishift
    % vertical shift of the second slice
    %mixedImage1 = slices_with_Scoils11 + slices_with_Scoils12([100:199, 1:100],:) + noise_level * randn(size(slices_with_Scoils11));
    %mixedImage2 = slices_with_Scoils21 + slices_with_Scoils22([100:199, 1:100],:) + noise_level * randn(size(slices_with_Scoils21));

    Kspace11 = fftshift(fft2(slices_with_Scoils11));
    Kspace12 = fftshift(fft2(slices_with_Scoils12)).*phase_matrix;
    Kspace21 = fftshift(fft2(slices_with_Scoils21));
    Kspace22 = fftshift(fft2(slices_with_Scoils22)).*phase_matrix;
    Kspace_tot1 = Kspace11 + Kspace12;
    Kspace_tot2 = Kspace21 + Kspace22;
    mixedImage1 = abs(ifft2(ifftshift(Kspace_tot1))) + noise_level * randn(size(Kspace_tot1));
    mixedImage2 = abs(ifft2(ifftshift(Kspace_tot2))) + noise_level * randn(size(Kspace_tot2));


    % horizontal shift of the coil sensitivities for the second slice
    C12 = C12(:,[100:199, 1:100]);
    C22 = C22(:,[100:199, 1:100]);

else
    mixedImage1 = slices_with_Scoils11 + slices_with_Scoils12 + noise_level * randn(size(slices_with_Scoils11)); % tot coil 1
    mixedImage2 = slices_with_Scoils21 + slices_with_Scoils22 + noise_level * randn(size(slices_with_Scoils11)); % tot coil 2
end


if caipishift
% plot of the k-spaces
figure(5); 
subplot(2, 2, 1);
imagesc(log(abs(Kspace11))); 
%colormap('gray');
axis image;
axis off;
title('K space coil 1, slice 1');

subplot(2, 2, 2);
imagesc(log(abs(Kspace12))); 
%colormap('gray');
axis image;
axis off;
title('K space coil 1, slice 2');

subplot(2, 2, 3);
imagesc(log(abs(Kspace21))); 
%colormap('gray');
axis image;
axis off;
title('K space coil 2, slice 1');

subplot(2, 2, 4);
imagesc(log(abs(Kspace12))); 
%colormap('gray');
axis image;
axis off;
title('K space coil 2, slice 2');
end

% plot the images seen by the two coils 
figure(6); 
subplot(1, 2, 1);
imagesc(mixedImage1); 
colormap('gray');
axis image;
axis off;
title('Tot coil 1');

subplot(1, 2, 2);
imagesc(mixedImage2);
colormap('gray');
axis image;
axis off;
title('Tot coil 2');

%% SENSE STANDARD - RECONSTRUCTION ALGORITHM
RHO1 = zeros(size(mixedImage1));
RHO2 = zeros(size(mixedImage2));

% g factor
g1 = zeros(nx, ny);
g2 = zeros(nx, ny);
condition_number = zeros(nx,ny);

for x=1:nx
    for y=1:ny
        C = [C11(x,y),C12(x,y);C21(x,y),C22(x,y)];
        condition_number(x,y) = cond(C);

        m = pinv([C11(x,y),C12(x,y);C21(x,y),C22(x,y)]);
        rho = m * [mixedImage1(x,y);mixedImage2(x,y)];
        RHO1(x,y) = abs(rho(1));
        RHO2(x,y) = abs(rho(2));

        % Calculate pseudoinverse of C' * C
        CHC = C' * C;
        CHC_inv = pinv(CHC); % Stable pseudoinverse

        % Extract diagonal elements of CHC and CHC_inv
        diag_CHC = diag(CHC);         % Diagonal of C' * C
        diag_CHC_inv = diag(CHC_inv); % Diagonal of (C' * C)^{-1}

        % Compute g-factor for each slice
        g_p1 = sqrt(diag_CHC_inv(1) * diag_CHC(1)); % g-factor for slice 1
        g_p2 = sqrt(diag_CHC_inv(2) * diag_CHC(2)); % g-factor for slice 2

        % Assign the g-factors at pixel (x, y) 
        g1(x, y) = g_p1; 
        g2(x, y) = g_p2;
    end 
end

if caipishift
    RHO2=RHO2(:,[100:199, 1:100]); 
    g2=g2(:,[100:199, 1:100]);
else
    RHO2=RHO2(:, :);
    g2=g2(:,:);
end

g1(isnan(g1))=0;
g2(isnan(g2))=0;

g1_mean = mean(g1(g1>=1));
g2_mean = mean(g2(g2>=1));
fprintf('g 1: %.2f\n', g1_mean);
fprintf('g 2: %.2f\n', g2_mean);
fprintf('g mean: %.2f\n', (g1_mean+g2_mean)/2);

% Plot RECONSTRUCTED IMAGES 
figure(7);
subplot(1,2,1),imagesc(abs(RHO1(:, :))); 
colormap('gray');
axis image;
axis off;

subplot(1,2,2),imagesc(abs(RHO2(:, :)));
colormap('gray');
axis image;
axis off;
sgtitle('Reconstructed Images 1 & 2');

% Visualize the g factor as an image
figure(8);
subplot(1,2,1)
imagesc(g1);
colormap('jet');
colorbar;
title('g factor 1');
axis image;
axis off;

subplot(1,2,2)
imagesc(g2);
colormap('jet');
colorbar;
title('g factor 2');
axis image;
axis off;

figure(9);
imagesc(condition_number);
colormap('jet');
colorbar;
title('Condition number');
axis image;
axis off;

%% SNR
% SNR ref
I_original1 = slice(:,:,1);
I_original2 = slice(:,:,2);
I_reconstructed_ref1 = slice(:,:,1) + 10 * randn(size(slice(:,:,1)));
I_reconstructed_ref2 = slice(:,:,2) + 10 * randn(size(slice(:,:,2)));

% pixel by pixel:
P_signal1 = I_original1.^2;
P_signal2 = I_original2.^2;
P_noise_ref1 = (I_original1 - I_reconstructed_ref1).^2;
P_noise_ref2 = (I_original2 - I_reconstructed_ref2).^2;

SNR_ref1 = 10 * log10(P_signal1 ./ P_noise_ref1);
SNR_ref2 = 10 * log10(P_signal2 ./ P_noise_ref2);

SNR_ref1(SNR_ref1 == -inf) = 0;
SNR_ref2(SNR_ref2 == -inf) = 0;
SNR_ref1(SNR_ref1 <0) = 0;
SNR_ref2(SNR_ref2 <0) = 0;

fprintf('SNR ref 1: %.2f\n', mean(SNR_ref1(SNR_ref1>0)));
fprintf('SNR ref 2: %.2f\n', mean(SNR_ref2(SNR_ref2>0)));

% SNR 
I_reconstructed1 = RHO1;
I_reconstructed2 = RHO2;
P_noise1 = (I_original1 - I_reconstructed1).^2;
P_noise2 = (I_original2 - I_reconstructed2).^2;

SNR1 = 10 * log10(P_signal1 ./ P_noise1);
SNR2 = 10 * log10(P_signal2 ./ P_noise2);

SNR1(isnan(SNR1)) = 0;
SNR2(isnan(SNR2)) = 0;
SNR1(SNR1 <0) = 0;
SNR2(SNR2 <0) = 0;

fprintf('SNR 1: %.2f\n', mean(SNR1(SNR1>0)));
fprintf('SNR 2: %.2f\n', mean(SNR2(SNR2>0)));

% SNR calculated with g
if caipishift
SNRg1 = sqrt(N_slices)*SNR_ref1./g1;
SNRg2 = sqrt(N_slices)*SNR_ref2./g2;
else
SNRg1 = SNR_ref1./g1;
SNRg2 = SNR_ref2./g2;
end

fprintf('SNR 1 calculated with g: %.2f\n', mean(SNRg1(SNRg1>0)));
fprintf('SNR 2 calculated with g: %.2f\n', mean(SNRg2(SNRg2>0)));

% Visualize the reference SNR
figure(10);

subplot(3,2,1)
imagesc(SNR_ref1);
colormap('jet');
colorbar;
title('SNR ref 1');
axis image;
axis off;

subplot(3,2,2)
imagesc(SNR_ref2);
colormap('jet');
colorbar;
title('SNR ref 2');
axis image;
axis off;

subplot(3,2,3)
imagesc(SNR1);
colormap('jet');
colorbar;
title('SNR 1');
axis image;
axis off;

subplot(3,2,4)
imagesc(SNR2);
colormap('jet');
colorbar;
title('SNR 2');
axis image;
axis off;

subplot(3,2,5)
imagesc(SNRg1);
colormap('jet');
colorbar;
title('SNR 1 calculated with g');
axis image;
axis off;

subplot(3,2,6)
imagesc(SNRg2);
colormap('jet');
colorbar;
title('SNR 2 calculated with g');
axis image;
axis off;

if caipishift
    sgtitle("SNR comparison for CAIPI");
    else
    sgtitle("SNR comparison for SENSE");
end


