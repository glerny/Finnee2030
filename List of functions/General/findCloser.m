function indOut = findCloser(valorIn, vectorIn)
%FINDCLOSER Return the index of the element closest to a target value.
%
%   indOut = findCloser(valorIn, vectorIn)
%
%   Inputs
%   ------
%   valorIn  : scalar numeric target value
%   vectorIn : numeric vector
%
%   Output
%   ------
%   indOut   : index of the element in vectorIn whose value is closest
%              to valorIn
%
%   Notes
%   -----
%   - If two values are equally close, the first one is returned.
%   - vectorIn can be a row or column vector.
%
% BSD 3-Clause License
% Copyright (c) 2026, G. Erny
% All rights reserved.
%
% Author: G. Erny
% Email: guillaume.erny@gmail.com
%
% This file was developed with assistance from Perplexity AI and then
% reviewed, adapted, and integrated by G. Erny.

    arguments
        valorIn (1,1) double
        vectorIn {mustBeNumeric, mustBeVector}
    end

    [~, indOut] = min(abs(vectorIn - valorIn));
end