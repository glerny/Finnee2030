function full_int = completeSpectra(spec_mz, spec_int, master_mz)
% completeSpectra:
%   spec_mz   : nSpec x 1 vector of m/z in the spectrum
%   spec_int  : nSpec x 1 vector of intensities
%   master_mz : nMaster x 1 vector of all m/z (master axis)
%
% Returns full_int: nMaster x 1 vector over master_mz, with 0 for missing mz.

    % Ensure sorted master axis
    master_mz = sort(master_mz);

    % Map spec_mz to indices in master_mz.
    % Use ismember or interp1 with tolerance.
    % If master_mz is exactly matching spec_mz, ismember is fine:
    [isInSpec, idxInMaster] = ismember(spec_mz, master_mz);

    % Create full intensity vector, default 0
    full_int = zeros(size(master_mz));

    % Assign intensities where mz exists in master
    full_int(idxInMaster(isInSpec)) = spec_int(isInSpec);
end