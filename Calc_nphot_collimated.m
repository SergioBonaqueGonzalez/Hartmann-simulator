function [nphot]=Calc_nphot_collimated(exposuretime,power,lambda)
%{
This function calculates the number of photons reaching a detector supposing a collimated monochromatic light source

According to the equation E=n*h*v (energy = number of photons times Planck's constant times the frequency), 
if you divide the energy by Planck's constant, you should get photons per second.
In this case, it is supposed to be a collimated monochromatic light source, where all the emitted photons are reaching the detector.

INPUTS:
- exposuretime = exposure time in seconds
- power = Source power in W
- lambda = %wavelength in meters

Created by Sergio Bonaque-Gonzalez, PhD. Optical Engineer
sergiob@wooptix.com
July,2019 - Wooptix S.L.
%}

nphot=round(exposuretime*power/(6.62607004e-34*physconst('LightSpeed')/lambda));

end