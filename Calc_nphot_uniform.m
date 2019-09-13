function [nphot]=Calc_nphot_uniform(sourcedistance,power,exposuretime,area,lambda)
%{
This function calculates the number of photons reaching a detector supposing a collimated monochromatic light source

According to the equation E=n*h*v (energy = number of photons times Planck's constant times the frequency),
if you divide the energy by Planck's constant, you should get photons per second.
In this case, it is supposed a light source with a uniform radiation across all
directions. So, the distance between the source and the entrance pupil of the system should be considered.

INPUTS:
- sourcedistance = distance in meters from the light source to the image
plane.
- power = Source power in W.
- exposuretime = exposure time in seconds.
- area = area of the image plane in meters. (i.e. area of a detector or the
entrance pupil of the optical system.
- lambda = %wavelength in meters.

Created by Sergio Bonaque-Gonzalez, PhD. Optical Engineer
sergiob@wooptix.com
July,2019 - Wooptix S.L.
%}

spherearea=4*pi*(sourcedistance^2);
I=power/spherearea; %This is the energy per unit area per second.Divide the energy by the energy of a single photon to get the number of photons per unit area multiply by the area of the sensor or entrance pupil
nphot=round(exposuretime*area*I/(6.62607004e-34*physconst('LightSpeed')/lambda));

end