function [x2, Uout]= one_step_prop(Uin, wvl, d1, Dz)
%{
function developed by:
- Jason D. Schmidt - Numerical Simulation of Optical Wave Propagation With Examples in MATLAB (2010)

function [x2, Uout] = one_step_prop(Uin, wvl, d1, Dz)
%}

N = size(Uin, 1); % assume square grid
k = 2*pi/wvl; % optical wavevector
% source-plane coordinates
[x1, y1] = meshgrid((-N/2 : 1 : N/2 - 1) * d1);
% observation-plane coordinates
[x2, y2] = meshgrid((-N/2 : N/2-1) / (N*d1)*wvl*Dz);
% evaluate the Fresnel-Kirchhoff integral
Uout = 1 / (1i*wvl*Dz) .* exp(1i * k/(2*Dz) * (x2.^2 + y2.^2)).* ft2(Uin .* exp(1i * k/(2*Dz) * (x1.^2 + y1.^2)), d1);
end