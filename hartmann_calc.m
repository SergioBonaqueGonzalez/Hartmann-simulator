function [result,detectorImage]=hartmann_calc(config,hartmann,detector,phase,source)
%{
Created by:
 Sergio Bonaque-Gonzalez. Optical Engineer.
 sergio.bonaque.gonzalez@gmail.com
 August,2019 

This program simulates the response of a Hartmann sensor with respect a user-defined incoming phase.
It first defines the geometry of the Hartmann sensor and the detector
behaviour, and then it simulates the answer for a given phase and intensity wavefront.

INPUTS are 4 structs and an incoming phase as defined in HartmannSimulatorMaster.m
OUTPUTS are the image at the detector and the recovered phase.
%}
hartmann.PHdiameter=hartmann.PHradius*2;
hartmann.surface=(hartmann.PH*hartmann.PHdiameter)+hartmann.PHspacing*(hartmann.PH+1);
detector.surface=detector.pixelsize*detector.resolution;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%     READING THE INCOMING PHASE
iphase.phase = phase;
iphase.size = length(phase); %only phases defined over a square surface are considered
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
[hartmann,iphase] = adjust_resolutions(hartmann,config,detector,iphase,errorsXY);
[hartmann] = gridCreator(hartmann); %creates the grid of the hartmann sensor and obtains the coord for each pinhole

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% DEFINITION OF PINHOLES
%Assigns to each pinhole its corresponding portion of the phase and add the
%space between pinholes
Pinholes = cell(1,length(hartmann.coor));
for i = 1:length(hartmann.coor)
    Pinhole = hartmann.pupils.*iphase.phase(hartmann.coor(i,1):hartmann.coor(i,2), hartmann.coor(i,3):hartmann.coor(i,4));
    Pinholes{i} = padarray(Pinhole,[hartmann.space_resolution hartmann.space_resolution],0,'both');
end
hartmann.pupils = padarray(hartmann.pupils,[hartmann.space_resolution hartmann.space_resolution],0,'both');%This is the pinhole shape used for propagation. its a big size compared with the pinhole, so, crosstalking is taking into account only to this size
hartmann.delta = hartmann.surface/length(hartmann.grid);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%     CALCULATION OF NUMBER OF DETECTOR's PIXELS BEHIND MICROLENSES
n = 1;
while n*detector.pixelsize<length(hartmann.pupils)*hartmann.delta
       n = n+1; %number of minimum detector pixels behind each microlens. It must be a natural number.
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%     PROPAGATION BETWEEN GRID AND SENSOR
L1 = hartmann.PHdiameter+(2*hartmann.PHspacing); %Length of the pupil in the grid plane
lambda = config.lambda;
distance = hartmann.distance;
pupil = hartmann.pupils;
N2 = n; %Length of the detector area for a particular pinhole
L2 = N2*detector.pixelsize; %number of pixels in the detector for that area
Intensity = cell(1,length(Pinholes));

fprintf('-----Propagations start------\n')
parfor i=1:length(Pinholes)
    [~,Intensity{i},~] = Propagator_ultimate(lambda,distance,Pinholes{i},pupil,L1,L2,N2,0);
end
fprintf('Propagations done.\n')
clear Pinholes
hartmann.grid = [];

figure
imshow(Intensity{hartmann.PH*(hartmann.PH/2)-(hartmann.PH/2)},[])
title('Example of propagation (check quality)')
drawnow()

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%      PLACING SUB-IMAGES IN THE DETECTOR
fprintf('Building detector image...\n');
[detector,detectorImage] = placing_subimages(hartmann,detector,n,Intensity);
% fprintf('done.\n');
% figure
% imshow(detectorImage,[])
% hold on
% for i=1:length(detector.centers)
%     plot(detector.centers(i,1), detector.centers(i,2), 'rp', 'MarkerFaceColor','g')
%    
% end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%     CALCULATE NUMBER OF PHOTONS REACHING THE DETECTOR. 
%{ 
According to the equation E=n*h*v (energy = number of photons times Planck's constant times the frequency), 
if you divide the energy by Planck's constant, you should get photons per second.
In the first case, it is supposed to be a collimated monochromatic light source, where all the emitted photons are reaching the detector.
In the second case, it is supposed a light source with a uniform radiation across all
directions. In this case, the distance between the source and the hartmann
sensor (or the entrance pupil of the system) should be considered.
%}
if source.shape==1 %first case
    nphot=Calc_nphot_collimated(config.exposuretime,source.power,config.lambda);
elseif source.shape==2 %second case
    hartmannarea=hartmann.surface(1)*hartmann.surface(2);
    nphot=Calc_nphot_uniform(hartmann.sourcedistance,source.power,config.exposuretime,hartmannarea,config.lambda);
end


%{
***************************************************************************
****** Quantization of the signal, introduction of photonic noise**********
****************** & introduction of read noise****************************
***************************************************************************
Photon noise, also known as Poisson noise, is a basic form of uncertainty 
associated with the measurement of light, inherent to the quantized nature 
of light and the independence of photon detections. Its expected magnitude 
constitutes the dominant source of image noise except in low-light conditions.
Individual photon detections can be treated as independent events that 
follow a random temporal distribution. As a result, photon counting is a 
classic Poisson process.Photon noise is signal dependent, and its standard 
deviation grows with the square root of the signal. Contrary to popular 
belief, shot noise experienced by the detector IS related to the QE of the 
detector! Back-illuminated sensors with higher QE yields a better 
Signal/Shot Noise ratio. There is a simple intuitive explanation for this –
 shot noise must be calculated from the signal represented by the number 
of photoelectrons in the sensor (electrons generated from photons falling 
on the sensor), NOT JUST from the number of incoming photons. Therefore, 
if an average of 100 photons hit a pixel, but the sensor has a QE of 50% at
the wavelength of these photons, then an average of 50 photoelectrons will 
be created – the shot noise and Signal/Shot Noise must be calculated from 
this value.
%}
%Introduction of Photon Noise
nphot=nphot*detector.QE; %Only a portion of the photons will be detected by the sensor
detectorImage=poissrnd(nphot*detectorImage/sum(detectorImage(:)));

% Well Capacity
number=detectorImage>detector.wellcapacity;
number=sum(number(:));
perc=number*100/(detector.resolution^2);
fprintf(' %f per cent of pixels in detector are saturated\n',perc);
if perc>detector.allowedSaturatedPixels
    if source.shape==1 %first case
        while perc>detector.allowedSaturatedPixels
            config.exposuretime=config.exposuretime/10;
            nphot=Calc_nphot_collimated(config.exposuretime,source.power,config.lambda);
            nphot=nphot*detector.QE; %Only a portion of the photons will be detected by the sensor
            detectorImage_junk=poissrnd(nphot*detectorImage/sum(detectorImage(:)));
            number=detectorImage_junk>detector.wellcapacity;
            number=sum(number(:));
            perc=number*100/(detector.resolution^2);
        end
    elseif source.shape==2
        while perc>detector.allowedSaturatedPixels
            nphot=Calc_nphot_uniform(hartmann.sourcedistance,source.power,config.exposuretime,hartmannarea,config.lambda);
            nphot=nphot*detector.QE; %Only a portion of the photons will be detected by the sensor
            detectorImage_junk=poissrnd(nphot*detectorImage/sum(detectorImage(:)));
            number=detectorImage_junk>detector.wellcapacity;
            number=sum(number(:));
            perc=number*100/(detector.resolution^2);
        end
    end
    fprintf('the proper exposure time to fit with the detector.allowedSaturatedPixels condition is:i% \n',config.exposuretime);
    return
end
detectorImage(detectorImage>detector.wellcapacity)=detector.wellcapacity; %Adjust to the real well-capacity

%Quantization of the signal
detectorImage=round((detectorImage/max(detectorImage(:)))*((2^detector.bits)-1));

%Calculation of shot and read noise
shotnoise = poissrnd(detector.darkcurrent*config.exposuretime, size(detectorImage));
readnoise = readNoise(detector);
detectorImage=detectorImage+shotnoise+readnoise;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%      Calculation of shot and read noise
%Asignation of each area in the detector to each PH
UL_corners=round(detector.centers-(detector.PH/2)-(detector.PHspacing/2));
DR_corners=round(detector.centers+(detector.PH/2)+(detector.PHspacing/2));

for i=1:length(UL_corners)
    if UL_corners(i,1)<1
        UL_corners(i,1)=1;
    end
    if UL_corners(i,2)<1
        UL_corners(i,2)=1;
    end
    if DR_corners(i,1)>detector.resolution
        DR_corners(i,1)=detector.resolution;
    end
    if DR_corners(i,2)>detector.resolution
        DR_corners(i,2)=detector.resolution;
    end
end

for i=1:length(UL_corners)
    area=detectorImage(UL_corners(i,2):DR_corners(i,2),UL_corners(i,1):DR_corners(i,1));
    [cx, cy] = CentroidCalculation(area,config.centroidmethod, 0);
    cx=UL_corners(i,1)+cx-1;
    cy=UL_corners(i,2)+cy-1;
    detector.PhaseCentroids(i,:)=([cx cy]);
end

CentroidLength=zeros(length(UL_corners),2);
for i=1:length(UL_corners)
    CentroidLength(i,1)=(detector.PhaseCentroids(i,1)-detector.referenceCentroids(i,1));
    CentroidLength(i,2)=(detector.PhaseCentroids(i,2)-detector.referenceCentroids(i,2));
end


figure
suptitle('Reference centroid vs calculated centroid')
subplot(1,2,1)
set(gcf,'color','w');
imshow(detectorImage,[])
hold on
plot(detector.referenceCentroids(:,1),detector.referenceCentroids(:,2),'o','MarkerSize',2,'MarkerEdgeColor','r')
hold on
plot(detector.PhaseCentroids(:,1)',detector.PhaseCentroids(:,2)','x','MarkerSize',5,'MarkerEdgeColor','b')
legend('Reference centroid','calculated centroid')
title('Centroids position in the detector')
xlabel('pixels')
ylabel('pixels')
xlim([0 detector.resolution])
ylim([0 detector.resolution])

subplot(1,2,2)
quiver(detector.referenceCentroids(:,1),detector.referenceCentroids(:,2),CentroidLength(:,1)*10,CentroidLength(:,2)*10,0);
title('Displacement of centroid (x10)')
xlabel('pixels')
ylabel('pixels')
set(gca,'ydir','reverse')
xlim([0 detector.resolution])
ylim([0 detector.resolution])
drawnow();

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%      SLOPE CALCULATION

delta=double(CentroidLength*detector.pixelsize);
alfax= double(atan(delta(:,1)/hartmann.distance));
alfay=double(atan(delta(:,2)/hartmann.distance));

alfax=vec2mat(alfax,sqrt(length(UL_corners)))';
alfay=vec2mat(alfay,sqrt(length(UL_corners)))';


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%      INTEGRATION
%{
L. Huang, J. Xue, B. Gao, C. Zuo, and M. Idir, "Spline based least squares integration for two-dimensional shape or wavefront reconstruction," Optics and Lasers in Engineering 91, 221-226 (2017).

https://doi.org/10.1016/j.optlaseng.2016.12.004
%}
% x=zeros(1,length(alfax));
% for i=1:length(alfax)
% x(1,i)=detector.referenceCentroids(i,2);
% end
x=linspace(1,length(alfax),length(alfax));
deltax=meshgrid(x);
deltay=meshgrid(x)';


result=sli2(alfax,alfay,deltax,deltay);
%Integration procedure is non-sensible to piston:
result=result-mean(result(:));

%scaling
result=result.*hartmann.distance/hartmann.resolution;

%Calculating area of the phase seen by detector
pixels=(detector.surface*hartmann.resolution/hartmann.surface); 
dif=round((hartmann.resolution-pixels)/2);
if dif>0
    seen_phase=iphase.phase(dif:end-dif+1,dif:end-dif+1);
    seen_phase=imresize(seen_phase,[length(result) length(result)]);
    
    %removing piston:
    seen_phase=seen_phase-mean(seen_phase(:));
    
    square=ones(length(iphase.phase));
    square(dif:end-dif+1,dif:end-dif+1)=0;
    figure
    imshowpair(iphase.phase,square)
    title('Incoming phase and area seen by detector')
    
    figure
    imshow([seen_phase,result, seen_phase-result],[])
    title('Input phase seen by detector Vs Recovered (pistons removed). Rigth=difference')
    colormap('parula')
    colorbar
else
    %removing piston:
    seen_phase=iphase.phase-mean(iphase.phase(:));

    seen_phase=imresize(seen_phase,[length(result) length(result)]);
    figure
    imshow([seen_phase,result, seen_phase-result],[])
    title('Input phase seen by detector Vs Recovered (pistons removed). Rigth=difference')
    colormap('parula')
    colorbar
    
end





