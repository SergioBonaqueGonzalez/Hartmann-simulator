function[x2,Uout]=FraunhoferPropagation(config,object,calibration)
%{
Its an adaptation of the methods described in: 
- Joseph W Goodman - Introduction to Fourier Optics-McGraw-Hill (1996)
- Jason D. Schmidt - Numerical Simulation of Optical Wave Propagation With Examples in MATLAB (2010)
- David Voelz - Computational Fourier Optics (2011)

Adapted by Sergio Bonaque-Gonzalez. Optical Engineer.
sergiob@wooptix.com
July,2019 - Wooptix S.L.

This function calculates the propagation in the Fraunhofer region. A uniform sampling is supossed. 

INPUTS:
	config.L - Length of the side of the source 
	config.lambda - wavelength in meters
	config.z - propagation distance in meters. 
	contador= dummy variable which indicates if a message should be showed or not

OUTPUTS:
	x2 - Length of the side of the image plane.  
	Uout - observed field
%}
if calibration==1
    fprintf('--Fraunhofer propagation--\n'); %valid for very long propagations
end

% SAMPLING CONSTRAINS IN OBJECT AND IMAGE PLANES
%the chirp function will be adequately sampled in the observation plane if:
if object.delta<abs(config.lambda*config.z/object.L)
    M_=object.N;
    while M_<4*object.L^2/(object.delta^2)
        M_=M_+1;
    end
end
M = 2^ceil(log2(M_));
% This implies a large M. Fortunately, the Fraunhofer phase is not often required.

if M<=config.resolution_limit
    if length(object.phase)<M
        if calibration==1
            fprintf('Incoming phase has been resized to %ix%i because sampling constrains in object plane.\n',M,M);
        end
        [first, last]= get_fist_last_non_zero_index(object.pupil);
        pupil=mascaraCircular((last-first)/length(object.pupil), M);
        phase=imresize(object.phase, [M M]);
        object.delta=object.L/M;
    else
        pupil=object.pupil;
        phase=object.phase;
    end
else
    M=config.resolution_limit;
    if M_>=config.resolution_limit
        if calibration==1
            fprintf('WARNING. More resolution limit is required for accurate propagation.\n');
        end
    end
    if calibration==1
        fprintf('Incoming phase has been resized to %ix%i because sampling constrains in object plane.\n',M,M);
    end
    [first, last]= get_fist_last_non_zero_index(object.pupil);
    pupil=mascaraCircular((last-first)/length(object.pupil), M);
    phase=imresize(object.phase, [M M]);
    object.delta=object.L/M;
end

Uin = pupil.*exp(config.k.*1i.*phase); %complex phase screen
   
L2=config.lambda*config.z/object.delta;          
dx2=config.lambda*config.z/object.L;          
x2=-L2/2:dx2:L2/2-dx2;    

[X2,Y2]=meshgrid(x2,x2); 
c=1/(1i*config.lambda*config.z)*exp(1i*config.k/(2*config.z)*(X2.^2+Y2.^2)); 
Uout=c.*ifftshift(fft2(fftshift(Uin)))*object.delta^2; 

dx2=L2/object.N;
x2=-L2/2:dx2:L2/2-dx2; %obs coords

end 