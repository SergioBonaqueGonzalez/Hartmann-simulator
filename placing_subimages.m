function [detector,detectorImage]=placing_subimages(hartmann,detector,n,Intensity)
%{
This function places each image produced by each pinhole in the proper
coordinates in the sensor

Created by Sergio Bonaque-Gonzalez, PhD. Optical Engineer
sergiob@wooptix.com
August,2019 - Wooptix S.L.
%}

%Usable pixels in detector
relation_grid=hartmann.space_resolution/hartmann.phresolution; %relation between the size of the pinhole and the separation area.
relations_detector=n/((2*relation_grid+1));
detector.PH=relations_detector;
detector.PHspacing=relations_detector*relation_grid;


%Initially, we will built an ideal detector covering at least all the pinholes, and at
%the end, we will adjust the real size
IdealSize_=(hartmann.PH+1)*detector.PHspacing+hartmann.PH*detector.PH;
IdealSizeCeil=ceil(IdealSize_);
dif=(IdealSizeCeil-IdealSize_)/2;


%place each sub-image in the detector
[detectorImage,detector] = detectorCreator(hartmann,detector,n,Intensity,IdealSizeCeil);
detectorImage = imtranslate(detectorImage,[dif dif]);
detector.centers = detector.centers+dif;


%Adjust the size of the detector to the real size
if detector.resolution<IdealSizeCeil
    dif = IdealSizeCeil-detector.resolution;
    if rem(dif,2)==0
        detectorImage(:,end-dif/2+1:end)=[];
        detectorImage(end-dif/2+1:end,:)=[];
        detectorImage(:,1:dif/2)=[];
        detectorImage(1:dif/2,:)=[];
        detector.centers = detector.centers-(dif/2);
        for i=length(detector.centers):-1:1
            if detector.centers(i,1)>detector.resolution || detector.centers(i,2)>detector.resolution || detector.centers(i,1)<detector.PH || detector.centers(i,2)<detector.PH
                detector.centers(i,:) = [];
            end
        end
    else
        detectorImage(:,end-floor(dif/2)+1:end)=[];
        detectorImage(end-floor(dif/2)+1:end,:)=[];
        detectorImage(:,1:ceil(dif/2))=[];
        detectorImage(1:ceil(dif/2),:)=[];
        detectorImage = imtranslate(detectorImage,[0.5 0.5]);
        detector.centers = detector.centers-(dif/2);
        for i=length(detector.centers):-1:1
            if detector.centers(i,1)>detector.resolution || detector.centers(i,2)>detector.resolution || detector.centers(i,1)<detector.PH || detector.centers(i,2)<detector.PH
                detector.centers(i,:)=[];
            end
        end
    end
    fprintf('Detector is not big enough to cover all the calculated sub-images. Edges has been cut to fit the real size.\n')
elseif detector.resolution>IdealSizeCeil 
    dif = detector.resolution-IdealSizeCeil;
    if rem(dif,2)==0
        detectorImage = padarray(detectorImage,[dif/2 dif/2],0,'both');
        detector.centers = detector.centers+(dif/2);
    else
        detectorImage = padarray(detectorImage,[floor(dif/2) floor(dif/2)],0,'post');
        detectorImage = padarray(detectorImage,[ceil(dif/2) ceil(dif/2)],0,'post');
        detectorImage = imtranslate(detectorImage,[0.5 0.5]);
        detector.centers = detector.centers+(dif/2);
    end
end

end