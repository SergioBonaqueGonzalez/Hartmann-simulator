function [hartmann,iphase]=adjust_resolutions(hartmann,config,detector,iphase,errorsXY)
%{
This function adjust the resolution of the simulations in order to fit the
following conditions:

%- Both, sample of pinholes and space between
%them, in the grid have to be a natural number of pixels in the simulation.
%- Sampling of the grid in the simulation has to be at least the resolution of the detector.
%- Incoming wave front is resized to this resolution by mean of bicubic
%interpolation.
%Errors size/pixel below errorsXY will be ignored. This is very usefull for
simplify calculations and anyway it will be corrected when centroids are
calculated 

Created by Sergio Bonaque-Gonzalez, PhD. Optical Engineer
sergiob@wooptix.com
August,2019 - Wooptix S.L.
%}


%The following formula states beyond what resolution the pixelation of the
%pinhole is irrelevant.
pinhole_minimum_resolution = ceil((hartmann.PHdiameter+hartmann.PHspacing+hartmann.PHspacing)/sqrt(config.lambda*hartmann.distance));


%search for a natural number for the space between pinholes and pinhole
%itself
spacing_resolution = hartmann.PHspacing*pinhole_minimum_resolution/(hartmann.PHdiameter);
while mod(spacing_resolution,1)>errorsXY
    pinhole_minimum_resolution = pinhole_minimum_resolution+1;
    spacing_resolution = hartmann.PHspacing*pinhole_minimum_resolution/(hartmann.PHdiameter);
end

grid_minimum_resolution = pinhole_minimum_resolution*hartmann.PH +spacing_resolution*(hartmann.PH+1);
grid_minimum_resolution = round(grid_minimum_resolution);


%make sure the resolution is good enough to sample all pixels in the
%detector
while grid_minimum_resolution<detector.resolution
    pinhole_minimum_resolution = pinhole_minimum_resolution+1;
    spacing_resolution = hartmann.PHspacing*pinhole_minimum_resolution/(hartmann.PHdiameter);
    while mod(spacing_resolution,1)>0
        pinhole_minimum_resolution=pinhole_minimum_resolution+1;
        spacing_resolution = hartmann.PHspacing*pinhole_minimum_resolution/(hartmann.PHdiameter);
    end
    grid_minimum_resolution = pinhole_minimum_resolution*hartmann.PH +spacing_resolution*(hartmann.PH+1);
end


%Check if the user-defined incoming phase has enough resolution
if iphase.size(1)<grid_minimum_resolution %if the phase is smaller, its size is increased to the minimum.
    %if below, the wavefront is interpolate to the proper resolution
    fprintf('adjust_resolutions.m:    INTERPOLATION OF THE INCOMING PHASE!. \nIt has been resized to the resolution=%ix%i.\n',grid_minimum_resolution,grid_minimum_resolution)
    iphase.phase = imresize(iphase.phase,[grid_minimum_resolution,grid_minimum_resolution]); %Bicubic interpolation by defect
    iphase.size = size(iphase.phase);
elseif iphase.size(1)>grid_minimum_resolution %if the phase is bigger, its search for the combination of natural numbers for pinhole and spacing resolution that is closest to that resolution. After, the resolution of the incoming phase is also resized
    pinhole_minimum_resolution = ceil(hartmann.PHdiameter*iphase.size(1)/hartmann.surface(1));
    spacing_resolution = hartmann.PHspacing*pinhole_minimum_resolution/(hartmann.PHdiameter);
    while mod(spacing_resolution,1)>0
        pinhole_minimum_resolution = pinhole_minimum_resolution+1;
        spacing_resolution = hartmann.PHspacing*pinhole_minimum_resolution/(hartmann.PHdiameter);
    end
    grid_minimum_resolution = pinhole_minimum_resolution*hartmann.PH +spacing_resolution*(hartmann.PH+1);
    iphase.phase = imresize(iphase.phase,[grid_minimum_resolution,grid_minimum_resolution]); %Bicubic interpolation by defect
    iphase.size = size(iphase.phase);
    fprintf('adjust_resolutions.m:    INTERPOLATION OF THE INCOMING PHASE!. \nIt has been resized to the resolution=%ix%i.\n',grid_minimum_resolution,grid_minimum_resolution)
end


%As said above. Differences below 1nm in size will be ignored.
hartmann.resolution = round(grid_minimum_resolution);
hartmann.space_resolution = round(spacing_resolution);
hartmann.phresolution = round(pinhole_minimum_resolution);


end