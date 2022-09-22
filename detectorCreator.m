function [detectorImage,detector]=detectorCreator(hartmann,detector,n,Intensity,IdealSizeCeil)
%{
This function built the detector configuration and places each sub-image in
its right coordinates

Created by Sergio Bonaque-Gonzalez, PhD. Optical Engineer
sergio.bonaque.gonzalez@gmail.com
August,2019
%}
detectorImage=zeros(IdealSizeCeil);

%First pinhole
detectorImage(1:n,1:n) = Intensity{1};
CoorY = zeros(1,hartmann.PH);
dif = zeros(1,hartmann.PH);

%Calculations of the center of each pinhole
centroids2=zeros(1,hartmann.PH);
centroids2(1)=detector.PHspacing+(detector.PH/2);
if rem(n,2)==0
    centroids2(1)=centroids2(1)+0.5;
end

for i = 2:hartmann.PH
    centroids2(i) = centroids2(1) + ((detector.PHspacing+detector.PH)*(i-1));
end
a=meshgrid(centroids2,centroids2);
b=a';
centroids=zeros(length(a)*length(a),2);
centroids(:,1)=a(:);
centroids(:,2)=b(:);

% Coordinates of the initial point
CoorY(1)=1;
for i = 2:hartmann.PH
    CoorY_ = CoorY(1)+((detector.PHspacing+detector.PH)*(i-1));
    dif(i) = CoorY_-ceil(CoorY_);
    CoorY(i) = ceil(CoorY_);
end
[p,q] = meshgrid(CoorY(:), CoorY(:));
[p2,q2] = meshgrid(dif(:), dif(:));
pairs = [p(:) q(:)]; %Row/column
difs=[p2(:) q2(:)]; %difx/dify

for k = 2 : length(pairs)
    DetectorImage_copy = zeros(length(detectorImage));
    Intensity{k}=imtranslate(Intensity{k},[difs(k,1) difs(k,2)]);
    DetectorImage_copy(pairs(k,2):pairs(k,2)+n-1,pairs(k,1):pairs(k,1)+n-1)=Intensity{k};
    [a,b] = size(DetectorImage_copy);
    difa = a-length(detectorImage);
    difb = b-length(detectorImage);
    if difa>0
        DetectorImage_copy(end-difa+1:end,:)=[];
    end
    if difb>0
        DetectorImage_copy(:,end-difb+1:end)=[];
    end
    detectorImage=detectorImage+DetectorImage_copy;
end

detector.centers = centroids;

%Testing althe pinholes are equispaced
% a=vec2mat(detector.centers(:,1),sqrt(length(detector.centers)));
% for i=2:length(a)
%     a(i)-a(i-1)
% end
% 
% figure
% imshow(DetectorImage,[])
% hold on
% for i=1:length(centroids)
%     plot(centroids(i,1), centroids(i,2), 'rp', 'MarkerFaceColor','g')
% end

end
