function image = readNoise(detector)
%funcion que calcula un ruido de lectura sobre una imagen problema.
% image: La imagen original
% bits: el numero de bits considerado
% exposureTime: tiempo de exposición en segundos
% capacidad de Electrones de la CCD (viene especificada (p.ej 18000)
% darkCurrent: en electrones/pixel/segundo p.ej 0.01e/pixel/s
% readOutNoise: en electrones RMS 8e RMS
%Ejemplo de llamada:
%im1 = readNoise(im1, bits, 18000, 10, 0.01, 8);

image = round(detector.readoutnoise*randn(detector.resolution)*((2^(detector.bits)-1)/detector.wellcapacity));
image(image<0)=0;

end