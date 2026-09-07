function [allAttributes, tgtElements] = unpackAttributes(myStruct, allAttributes, elements2extract)
% UNPACKATTRIBUTES  Recursively collect attributes from a parsed mzML structure.
%
% This function traverses a nested structure produced by GETNODES, collects
% attribute name/value pairs into a cell array, and can optionally extract
% selected subelements matching a requested element name.
%
% Input:
%   myStruct          Parsed structure to inspect.
%   allAttributes     Existing attribute list to extend, optional.
%   elements2extract  Element name to collect during traversal, optional.
%
% Output:
%   allAttributes     Cell array containing attribute paths and values.
%   tgtElements       Cell array containing extracted target elements.
%
% BSD 3-Clause License
%
% Copyright (c) 2026, G. Erny
% All rights reserved.
%
% Author: G. Erny
% Email: guillaume.erny@gmail.com

narginchk(1, 3)

if nargin == 1
    allAttributes = {};
    elements2extract = '';
    
elseif nargin == 2
    elements2extract = '';
    
end

fn = fieldnames(myStruct);
tgtElements = {};

for ii = 1:numel(fn)
    
    if isfield(myStruct.(fn{ii}), 'Attributes')
        
        att = fieldnames(myStruct.(fn{ii}).Attributes);
        for jj = 1:numel(att)
            
            allAttributes{end+1, 1} = [fn{ii} '/' att{jj}];
            allAttributes{end, 2} = myStruct.(fn{ii}).Attributes.(att{jj});
            
        end
    end
    
    if isfield(myStruct.(fn{ii}), 'subElements')
        
        for jj = 1:numel(myStruct.(fn{ii}).subElements)
            
            if isfield(myStruct.(fn{ii}).subElements{jj}, elements2extract)
                tgtElements{end+1} = myStruct.(fn{ii}).subElements{jj}.(elements2extract);
            end
            [allAttributes, newElements] = unpackAttributes(myStruct.(fn{ii}).subElements{jj}, allAttributes, elements2extract);
            if ~isempty(newElements)
               tgtElements = [tgtElements; newElements];
            
            end
        end
    end
end

