function [maxvalue,r,c]=max2D(x)
%max2D - return maximum value, row, and column number for 2D array
% seems surprising that Matlab doesn't have such a fundamental routine
%
% usage: [maxvalue,row,col]=max2D(x);
%
% see also min2D
% LNT 30 Nov 02
% LNT 26Aug03. Fix a serious problem with algorithm
%
% © 2003 Larry Thibos, Indiana University

% original algorithm follows.  
% it has a fatal flaw discovered 26Aug03: doesn't resolve ties
% cmax = max(x);				% vector of column maxima
% [maxvalue,c] = max(cmax); 	% find column number of maximum 
% cmax = max(x');
% [maxvalue,r] = max(cmax); 

cmax = max(x);				% vector of column maxima
[maxvalue,c] = max(cmax); 	% find column number of the col containing the maximum 
[maxvalue,r] = max(x(:,c));	% find rownumber of first row containing the maximum
