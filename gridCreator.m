function [hartmann]=gridCreator(hartmann)
%{
This function calculates the grid of a Hartmann Sensor assuming pinholes are equispaced following a rectangular setup, and that there is a space between the edge's pinholes and the edge itself equal to the distance between pinholes.
It is used in the context of the hartmann simulator program, so the inputs is a
struct containing the hartmann configuration.


Created by Sergio Bonaque-Gonzalez, PhD. Optical Engineer
sergiob@wooptix.com
August,2019 - Wooptix S.L.
%}

%Creates the pupil of a pinhole with the previously calculated resolution
hartmann = CreatePupil(hartmann);


% the upper left corner of the square where each pinhole is inscribed is defined .
secuencex = hartmann.space_resolution+1:hartmann.space_resolution+hartmann.phresolution:hartmann.resolution; 
[p,q] = meshgrid(secuencex, secuencex);
pairs = [p(:) q(:)];
Circles = zeros(hartmann.resolution, hartmann.resolution); % Aux Matrix
x11 = zeros(1,length(pairs));
x22 = x11;
y11 = x11;
y22 = x11;


% Creating the pinholes one by one:
hartmann.coor = zeros(length(pairs),4);
for k = 1 : length(pairs)
        % find upper left corner:
        x1 = int16(pairs(k,1));
        x11(k) = x1;
        y1 = int16(pairs(k,2));
        y11(k) = y1;
        x2 = int16(x1 + hartmann.phresolution - 1);
        x22(k)= x2;
        y2 = int16(y1 + hartmann.phresolution - 1);
        y22(k) = y2;
        % Adding the tiny pupil 
        Circles (y1:y2, x1:x2) = Circles(y1:y2,x1:x2)+hartmann.pupils; % Aux Matrix
        hartmann.coor(k,1:4) = [y1,y2,x1,x2];
end
hartmann.grid = Circles;

% axismm=linspace(0,hartmann.surface(1)*1e3,hartmann.resolution);
% figure
% imshow(Circles,[],'XData',axismm,'YData',axismm)
% title('Grid Mask')
% set(gcf,'color','w');
% xlabel('mm')
% ylabel('mm')
% axis on
% drawnow();

end