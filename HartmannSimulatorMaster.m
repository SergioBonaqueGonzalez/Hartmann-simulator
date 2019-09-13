function [result,detectorImage]=HartmannSimulatorMaster(config,hartmann,detector,phase,source)
%{
Created by:
 Sergio Bonaque-Gonzalez. Optical Engineer.
 sergiob@wooptix.com
 August,2019 - Wooptix S.L. 

This program simulates the response of a Hartmann sensor with respect a user-defined incoming phase.
It first defines the geometry of the Hartmann sensor and the detector
behaviour, and then it simulates the answer for a given phase and intensity wavefront.

It has been written for a very specific purpose. So, I have not tested all possible configurations and maybe there are still some bugs. Please, if you find one send me the 'example.m' file with the used configuration.

NOTES:
- You have an 'example.m' file. I suggest you to play with that file. 

- That it is a simulation very close to reality means that you have to adjust all the parameters very well so that the phase recovery is possible. 

- - Yes, an interpolation of the incoming phase is neccesary to be sure that the propagation is good. Maybe you can define the phase in such as resolution. 

- The simulator is complex and has a lot of details. I tested it for very specific situations. However, I may have missed some unexpected bugs present with other configurations. If you find one bug, please send me the 'example.m' file with your configuration. Take into account that if you put some crazy parameters, maybe the simulator fails (read following comment).

- IMPORTANT:physical propagation of waves is complex. So DO NOT IGNORE the
example of propagation image provided by the software. If the PSF is not
good or has artifacts, increase the resolution of the detector. It will
imply that the detector image will not fit its real size, but the phase
recovering will do. Additionally, if the example image is not good, it is normal that the following images have no sense. 

- Hartmann grid is built assuming pinholes are equispaced following a rectangular setup and that there is a space between the edge's pinholes and the edge itself equal to the distance between pinholes.

- It is assumed that the incoming phase is defined at the same plane than
the Hartmann grid. Anyway, it could be also defined in an arbitrary plane
and be propagated to the grid's plane using the 'propagator_ultimate.m'
function.

- Also, it is supposed that the incoming phase is defined at the same physical
length than the hartmann grid.

- Due to the sceficic problem this software was created for, the analysis of
the propagation is perfomed pinhole-by-pinhole and taking into account
crosstalking. However, possible interference between pinholes is not taking
into account. If neccesary, software can be changed to account for the
propagation of the whole grid in a "shot".

- Take into account that due to the presence of different noises according
to the detector's struct, if a zero phase is introduced there will be a
sligth fake phase in the result exclusively due to the noise. If you want to
check the script with zero phase (so, the recovered phase is zero), comment
lines from "quantization of the signal, introduction of pho...." to
"Calculation of shot and read noise" in 'hartmann_calc.m'

- The integration procedure is the described in:
L. Huang, J. Xue, B. Gao, C. Zuo, and M. Idir, "Spline based least squares integration for two-dimensional shape or wavefront reconstruction," Optics and Lasers in Engineering 91, 221-226 (2017)
 and downloaded from https://github.com/huanglei0114/Spline-based-least-squares-integration-for-two-dimensional-shape-or-wavefront-reconstruction

- In order to maintain the matrix's length in a reasonable size, with some
configurations the airy disk has a "hole" in the center. It is normal, and
it occurs with slight decentrations of the pupil. IT DOES NOT AFFECT TO
CALCULATIONS 

- Each time the configuration is changed, the calculation of the reference centroids is calculated.

- The methodology used for propagations between the grid and the detector is the one described in https://github.com/SergioBonaqueGonzalez/Wavefront-Propagator

INPUTS:
    INPUTS are 4 structs and an incoming phase as follow:
    -----------------------------------------------------
    phase = ; %The incoming phase
    
    -----------------------------------------------------
    CONFIG's STRUCT
    config.lambda = ; %wavelength in meters (i.e. 0.1e-9)
    config.exposuretime = ; %exposure time in seconds (i.e. 0.5e-8)
    config.centroidmethod = ; %See CentroidCalculation.m script to check the different implemented methods or add a new one. (i.e. 1)

    -----------------------------------------------------
	HARTMANN's STRUCT
    hartmann.PH = ; %Number of pinholes in each column/row in the sensor. Only square configurations are considered (i.e. 30) 
    hartmann.PHradius = ; %radius of pinholes in meters. (i.e. 5e-6)
    hartmann.PHspacing = ; %spacing between pinholes in meters. (i.e. 30e-6)
    hartmann.distance = ; %Distance (m) between the grid and the detector (i.e. 100e-3)
    hartmann.sourcedistance = ; %. Only used when the light source is considered to radiate uniformly across all directions: distance in meters from the light source to the hartmann sensor (or the entrance pupil of the system) (i.e. 1)
        
    -----------------------------------------------------
	DETECTOR's STRUCT
    detector.resolution = ; %number of pixels in the detector. Only square detectors are considered (i.e. 2^10)
    detector.pixelsize = ; %Pixel size of the detector (i.e. 0.55e-6)
    detector.bits = ; %number of bits of the CCD. (i.e. 16)
    detector.QE = ;%quantum efficiency of the CCD at the used wavelength (i.e. 0.9)
    detector.wellcapacity = ; %Photons well capacity of detector (i.e. 18000)
    detector.darkcurrent = ; %Dark current of the CCD in e-/pixel/s. (i.e. 0.01)
    detector.readoutnoise = ; %Read Noise of the detector in RMS (i.e. 8)
    detector.allowedSaturatedPixels = ; %percentage of allowed saturated pixels used for calculations of the proper exposure time. (i.e. 1)

    -----------------------------------------------------
	SOURCE's STRUCT
    source.power = ; %Source power in W (i.e. 100)
    source.shape = ; %Two cases are considered:  (i.e. 1)
                    1=collimated monochromatic light source, where all the emitted photons are reaching the detector.
                    2=light source with a uniform radiation across all directions. In this case, the distance between the source and the hartmann sensor (or the entrance pupil of the system) should be considered.
   
OUTPUTS:
    detectorImage = Image produced at the detector.
    result = recovered phase
%}
hartmann.PHdiameter=hartmann.PHradius*2;
hartmann.surface=(hartmann.PH*hartmann.PHdiameter)+hartmann.PHspacing*(hartmann.PH+1);
detector.surface=detector.pixelsize*detector.resolution;

%Check if the configuration has changed. If yes, a new calibration file is
%calculated
[config,hartmann,detector] = checkCalibration(config,hartmann,detector,phase);

%Starting the simulation with the incoming phase
fprintf('------------------------------------------------------------------\n');
fprintf('Calculating the result...\n');
fprintf('------------------------------------------------------------------\n');
[result,detectorImage]=hartmann_calc(config,hartmann,detector,phase,source);





