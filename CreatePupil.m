function hartmann=CreatePupil(hartmann)
%{
This function creates a circular pupil in a matrix of certain size. It is
used in the context of the hartmann simulator program, so the inputs is a
struct containing the hartmann configuration.

Created by Sergio Bonaque-Gonzalez. Optical Engineer.
sergiob@wooptix.com
%}
xp = linspace(-1,1,hartmann.phresolution);
hartmann.pupils = ones(hartmann.phresolution, hartmann.phresolution);
[X,Y] = meshgrid (xp,xp);
[rho] = sqrt(X.^2+Y.^2);
[a,b] = size(rho);
for i = (1:a);
    for j = (1:b);
        if rho(i,j) > 1 ;
            hartmann.pupils(i,j) = 0;
        end;
    end;
end;

end