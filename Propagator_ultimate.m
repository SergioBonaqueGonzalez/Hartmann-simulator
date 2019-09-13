function [x2,Intensity,Uout]=Propagator_ultimate(lambda,z,phase,pupil,L1,L2,N2,calibration)

%{
Methodology for the propagation of a phase in free space, assuming coherent illumination.
Developed by Sergio Bonaque-Gonz�lez, PhD.
sergiob@wooptix.com
July,2019 - Wooptix S.L.

INPUTS:
lambda=wavelength in meters
z=propagation distance in meters
phase=incoming phase defined at the exit pupil 
pupil=Exit pupil where the phase is defined
L1=Length of the object space in meters (i.e. length of the surface containing the pupil)
L2=Length of the image space in meters (i.e. length of the CCD)
N2=pixels in the detector

OUTPUTS:
x2 = axis values of the Intensity and complex phase results
Intensity = Intensity pattern at the requested z distance
Uout = Complex phase at the requested z distance

Its an adaptation of the methods described in: 
- Joseph W Goodman - Introduction to Fourier Optics-McGraw-Hill (1996)
- Jason D. Schmidt - Numerical Simulation of Optical Wave Propagation With Examples in MATLAB (2010)
- David Voelz - Computational Fourier Optics (2011)

ISSUES:
- The first advise "method = xxx" indicates the function used for calculations.
- Next advise indicates the performed interpolation of the incoming phase (bicubic by defect). By definition, twice the resolution is needed as the maximum frequency to be represented. As normally it is not taken into account, it does it automatically. If it has been taken into account when the phase is described, the software should be changed. 
- The last advise indicates the specific method he has used to perform the calculation. This beside the first advise identify the part of the software used for calculations.
- When the direct fourier transform propagation method is used, a gemoetrical propagation could also be used. 
- The boundary conditions to have a good sampling when using the angular
method are very complex to implement. So what I have done is to make sure that the sampling is good enough in the object plane and a warning is displaying saying that if the result is made of several copies or has artifacts, the resolution of the detector must to be increased (normally to the following power of 2).
- Fraunhoffer propagation is not often required. So, the result is placed
in an arbitrary detector with a minimim size and pixel size to adequately perform the simulations 
%}
warning('off', 'Images:initSize:adjustingMag');

config.lambda=lambda;
config.z=z;
config.k=2*pi/config.lambda;
config.resolution_limit=2^13; %limit for array size in the object space. It is used to decide if consecutive propagations in fresnel mode are needed.

%OBJECT SPACE
object.phase=phase;
object.pupil=pupil;
object.pupil=pupil;
object.N=length(phase); %number of grid points in object space
object.L=L1;
object.delta=object.L/object.N;%Grid spacing in object plane

%IMAGE SPACE
image.L=L2;
image.N=N2;
image.delta=image.L/image.N;%Grid spacing in image plane


%%%%%% CHOOSING METHOD FOR PROPAGATION%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%{
When light propagates very far from its source aperture, the optical field in the observation plane is very closely approximated by the Fraunhofer diffraction integral
According to Goodman, �very far� is defined by the inequality:
%}
if config.z>2*(object.L^2)/config.lambda
    method='fraunhofer';
elseif config.z>=object.L*object.delta/config.lambda
    if object.delta==image.delta
        method='fresnel_1';
    else
        method='fresnel_2';
    end
elseif config.z<object.L*object.delta/config.lambda
    method='angular';
end


if strcmp(method,'fraunhofer')==1
    if calibration==1
        fprintf('FraunhoferPropagation.m\n')
    end
    [x2,Uout]=FraunhoferPropagation(config,object,calibration);
    % elseif strcmp(method,'direct_transform')==1
    %     [x2,Uout]=direct(config,object,image);
elseif strcmp(method,'fresnel_1')==1
    if calibration==1
        fprintf('Fresnel_1step_Propagation.m\n')
    end
    [x2,Uout]=Fresnel_1step_Propagation(config,object,image,calibration);
elseif strcmp(method,'fresnel_2')==1
    if calibration==1
        fprintf('Fresnel_2step_Propagation.m\n')
    end
    [x2,Uout]=Fresnel_2step_Propagation(config,object,image,calibration);
elseif strcmp(method,'angular')==1
    if calibration==1
        fprintf('ang_prop.m\n')
    end
    [x2, Uout] = ang_prop(config,object,image,calibration);
end

Intensity = (abs(Uout).^2);
