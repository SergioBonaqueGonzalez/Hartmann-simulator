%{
Example file for the Hartmann Simulator. See 'HartmannSimulatorMaster.m' for
complete documentation.

Developed by Sergio Bonaque-González, PhD.
sergiob@wooptix.com
September,2019 - Wooptix S.L.
%}

clear all
close all
clc
%% Definition of the incoming phase
phase = turbulence_gen(2^8).*1e-9; %in this example, it is an atmospheric phase

%%Definition of the general configuration
config.lambda = 0.1e-9; %wavelength in meters
config.exposuretime = 0.5e-8; %exposure time in seconds
config.centroidmethod = 4; %See CentroidCalculation.m script to check the different implemented methods or add a new one

%%HARTMANN CONFIGURATION: variables related with the amplitude mask
hartmann.PH = 30; %Number of pinholes in each column/row in the sensor. Only square configurations are considered
hartmann.PHradius = 5e-6; %radius of pinholes in meters.
hartmann.PHspacing = 30e-6; %spacing between pinholes in meters.
hartmann.distance = 100e-3; %Distance (m) between the grid and the detector
hartmann.sourcedistance = 1; %. Only used when the light source is considered to radiate uniformly across all directions: distance in meters from the light source to the hartmann sensor (or the entrance pupil of the system)
        
%%DETECTOR: Configuration of the detector
detector.resolution = 2^10; %number of pixels in the detector. Only square detectors are considered
detector.pixelsize = 0.55e-6; %Pixel size of the detector
detector.bits = 16; %number of bits of the CCD. 
detector.QE = 0.9;%quantum efficiency of the CCD at the used wavelength
detector.wellcapacity = 18000; %Photons well capacity of detector
detector.darkcurrent = 0.01; %Dark current of the CCD in e-/pixel/s.
detector.readoutnoise = 8; %Read Noise of the detector in RMS
detector.allowedSaturatedPixels = 1; %percentage of allowed saturated pixels used for calculations of the proper exposure time

%%SOURCE.
source.power = 100; %Source power in W
source.shape = 1; %Two cases are considered: 
%               1=collimated monochromatic light source, where all the emitted photons are reaching the detector.
%               2=light source with a uniform radiation across all directions. In this case, the distance between the source and the hartmann sensor (or the entrance pupil of the system) should be considered.
   

[result,detectorImage]=HartmannSimulatorMaster(config,hartmann,detector,phase,source);


