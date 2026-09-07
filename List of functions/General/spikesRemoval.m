function dataOut = spikesRemoval(dataIn, spkSz )
% SPIKESREMOVAL  Remove narrow spikes from spectral profile data.
%
% This function suppresses isolated non-zero signal regions composed of
% spkSz points or fewer in a two-column numeric array, where the first
% column contains axis values and the second column contains intensities.
%
% Input:
%   dataIn  n-by-2 numeric array [axis, intensity].
%   spkSz   Maximum spike width to remove.
%
% Output:
%   dataOut Filtered n-by-2 numeric array.
%
% BSD 3-Clause License
%
% Copyright (c) 2026, G. Erny
% All rights reserved.
%
% Author: G. Erny
% Email: guillaume.erny@gmail.com
%
% This file was developed with assistance from Perplexity AI and then
% reviewed, adapted, and integrated by G. Erny.


dataOut = dataIn;

if spkSz >= 10
    findZeros = find(dataOut(:,2) == 0);
    ind2null = findZeros(diff(findZeros) > 10 & diff(findZeros) <= 11);
    dataOut(ind2null+1, 2) = 0;
end

if spkSz >= 9
    findZeros = find(dataOut(:,2) == 0);
    ind2null = findZeros(diff(findZeros) > 9 & diff(findZeros) <= 10);
    dataOut(ind2null+1, 2) = 0;
end

if spkSz >= 8
    findZeros = find(dataOut(:,2) == 0);
    ind2null = findZeros(diff(findZeros) > 8 & diff(findZeros) <= 9);
    dataOut(ind2null+1, 2) = 0;
end

if spkSz >= 7
    findZeros = find(dataOut(:,2) == 0);
    ind2null = findZeros(diff(findZeros) > 7 & diff(findZeros) <= 8);
    dataOut(ind2null+1, 2) = 0;
end

if spkSz >= 6
    findZeros = find(dataOut(:,2) == 0);
    ind2null = findZeros(diff(findZeros) > 6 & diff(findZeros) <= 7);
    dataOut(ind2null+1, 2) = 0;
end

if spkSz >= 5
    findZeros = find(dataOut(:,2) == 0);
    ind2null = findZeros(diff(findZeros) > 5 & diff(findZeros) <= 6);
    dataOut(ind2null+1, 2) = 0;
end

if spkSz >= 4
    findZeros = find(dataOut(:,2) == 0);
    ind2null = findZeros(diff(findZeros) > 4 & diff(findZeros) <= 5);
    dataOut(ind2null+1, 2) = 0;
end

if spkSz >= 3
    findZeros = find(dataOut(:,2) == 0);
    ind2null = findZeros(diff(findZeros) > 3 & diff(findZeros) <= 4);
    dataOut(ind2null+1, 2) = 0;
end

if spkSz >= 2
    findZeros = find(dataOut(:,2) == 0);
    ind2null = findZeros(diff(findZeros) > 2 & diff(findZeros) <= 3);
    dataOut(ind2null+1, 2) = 0;
end

findZeros = find(dataOut(:,2) == 0);
ind2null = findZeros(diff(findZeros) > 1 & diff(findZeros) <=2);
dataOut(ind2null+1, 2) = 0;
end

