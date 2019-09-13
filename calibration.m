function calibration(config,hartmann,detector,phase)
%{
This function makes the calibration file for the hartmann simulator

Created by Sergio Bonaque-Gonzalez, PhD. Optical Engineer
sergiob@wooptix.com
August,2019 - Wooptix S.L.

INPUTS:
    3 structs (config, hartmann & detector) defined in the same way that
    for HartmannSimulatorMaster.m, and an incoming phase
OUTPUTS:
    None. The new structs are saved in .mat files.
%}
iphase.size = length(phase);
iphase.phase = zeros(iphase.size);
% clear phase


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%     DEFINITION OF THE HARTMANN SENSOR SURFACE
%We need to adjust how much resolution is needed as minimum to avoid pixelation effects from the pinholes.
%Also, I set a variety of conditions that make easier the calculations:
%- I set the condition that both, sample of pinholes and space between
%them, have to be a natural number of pixels in the simulation.
%- Sampling of the grid in the simulation has to be at least the resolution of the detector.
%- Incoming wave front is resized to this resolution by mean of bicubic
%interpolation.
% Errors in size/pixel below errorsXY will be ignored. This is very usefull for simplify calculations
errorsXY = config.lambda/100;
[hartmann,~] = adjust_resolutions(hartmann,config,detector,iphase,errorsXY);
[hartmann] = gridCreator(hartmann); %creates the grid of the hartmann sensor and obtains the coord for each pinhole


% DEFINITION OF PINHOLES
%Assigns to each pinhole its corresponding portion of the phase (in this case is zero) and add the
%space between pinholes
Pinhole = hartmann.pupils.*0;
Pinholes = padarray(Pinhole,[hartmann.space_resolution hartmann.space_resolution],0,'both');
hartmann.pupils = padarray(hartmann.pupils,[hartmann.space_resolution hartmann.space_resolution],0,'both');%This is the pinhole shape used for propagation. its a big size compared with the pinhole, so, crosstalking is taking into account only to this size
hartmann.delta = hartmann.surface/length(hartmann.grid);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%     CALCULATION OF NUMBER OF DETECTOR's PIXELS BEHIND MICROLENSES
n=1;
while n*detector.pixelsize<length(hartmann.pupils)*hartmann.delta
    n=n+1; %number of minimum detector pixels behind each microlens. It must be a natural number.
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%     PROPAGATION BETWEEN GRID AND SENSOR
L1 = hartmann.PHdiameter+(2*hartmann.PHspacing); %Length of the pupil in the grid plane
N2 = n; %Length of the detector area for a particular pinhole
L2 = N2*detector.pixelsize; %number of pixels in the detector for that area
[~,Intensity_,~] = Propagator_ultimate(config.lambda,hartmann.distance,Pinholes,hartmann.pupils,L1,L2,N2,1);

Intensity = cell(1,length(hartmann.coor));
for i = 1:length(hartmann.coor)
    Intensity{i} = Intensity_;
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%      PLACING SUB-IMAGES IN THE DETECTOR
fprintf('Building detector image...\n');
[detector,detectorImage]=placing_subimages(hartmann,detector,n,Intensity);
fprintf('done.\n');
% figure
% imshow(detectorImage,[])
% hold on
% for i=1:length(detector.centers)
%     plot(detector.centers(i,1), detector.centers(i,2), 'rp', 'MarkerFaceColor','g')
% end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%      CENTROID CALCULATION
UL_corners = round(detector.centers-(detector.PH/2)-(detector.PHspacing/2));
DR_corners = round(detector.centers+(detector.PH/2)+(detector.PHspacing/2));

for i=1:length(UL_corners)
    if UL_corners(i,1)<1
        UL_corners(i,1) = 1;
    end
    if UL_corners(i,2)<1
        UL_corners(i,2) = 1;
    end
    if DR_corners(i,1)>detector.resolution
        DR_corners(i,1) = detector.resolution;
    end
    if DR_corners(i,2)>detector.resolution
        DR_corners(i,2) = detector.resolution;
    end
end

for i=1:length(UL_corners)
    area=detectorImage(UL_corners(i,2):DR_corners(i,2),UL_corners(i,1):DR_corners(i,1));
    [cx, cy] = CentroidCalculation(area,config.centroidmethod, 0);
    cx = UL_corners(i,1)+cx-1;
    cy = UL_corners(i,2)+cy-1;
    detector.referenceCentroids(i,:) = ([cx cy]);
end

% figure
% imshow(detectorImage,[])
% hold on
% plot(detector.centers(:,1),detector.centers(:,2),'o','MarkerSize',2,'MarkerEdgeColor','r')
% hold off

a=iphase.size; %#ok<NASGU>
save('phaseLength_cal.mat','a');
save('detector_cal.mat', 'detector');
save('hartmann_cal.mat', 'hartmann');
save('config_cal.mat', 'config');

fprintf('Done!\n');
end
