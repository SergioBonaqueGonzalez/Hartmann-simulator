function [config,hartmann,detector]=checkCalibration(config,hartmann,detector,phase)
%{
Created by:
 Sergio Bonaque-Gonzalez. Optical Engineer.
 sergio.bonaque.gonzalez@gmail.com
 August,2019 

Check if the calibration file is right for this configuration. If not, the
calibration procedure is launched
%}

if exist('hartmann_cal.mat', 'file') == 2
    a1 = load('config_cal.mat');
    a_1 = isequaln(a1.config,config);
    a2 = load('hartmann_cal.mat');
    a_2_1 = isequaln(a2.hartmann.PH,hartmann.PH);
    a_2_2 = isequaln(a2.hartmann.PHradius,hartmann.PHradius);
    a_2_3 = isequaln(a2.hartmann.PHspacing,hartmann.PHspacing);
    a_2_4 = isequaln(a2.hartmann.distance,hartmann.distance);
    a3 = load('detector_cal.mat');
    a_3_1 = isequaln(a3.detector.resolution,detector.resolution);
    a_3_2 = isequaln(a3.detector.pixelsize,detector.pixelsize);
    a4 = load('phaseLength_cal.mat');
    a_4 = isequaln(a4.a(1),length(phase));
    
    
    if a_1==1 && a_2_1==1 && a_2_2==1 && a_2_3==1 && a_2_4==1 && a_3_1==1 && a_3_2==1 && a_4==1
        fprintf('Loading calibration file...\n');
        clear config hartmann detector
        config = a1.config;
        hartmann = a2.hartmann;
        detector = a3.detector;
    else
        fprintf('------------------------------------------------------------------\n');
        fprintf('The configuration has changed. Calculating the calibration file...\n');
        fprintf('------------------------------------------------------------------\n');
        calibration(config,hartmann,detector,phase);
        clear config hartmann detector
        a1 = load('config_cal.mat');
        a2 = load('hartmann_cal.mat');
        a3 = load('detector_cal.mat');
        config = a1.config;
        hartmann = a2.hartmann;
        detector = a3.detector;
    end
else
    fprintf('------------------------------------------------------------------\n');
    fprintf('Calculating the calibration file...\n');
    fprintf('------------------------------------------------------------------\n');
    calibration(config,hartmann,detector,phase);
    clear config hartmann detector
    a1 = load('config_cal.mat');
    a2 = load('hartmann_cal.mat');
    a3 = load('detector_cal.mat');
    config = a1.config;
    hartmann = a2.hartmann;
    detector = a3.detector;
end
end
