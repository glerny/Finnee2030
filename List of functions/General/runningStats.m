function [n_new, S1_new, S2_new] = runningStats(x, n, S1, S2)
% addValueVector: update running statistics for vectors x, n, S1, S2 of equal numel.

% Ensure vectors
x  = x(:);
n  = n(:);
S1 = S1(:);
S2 = S2(:);

n_new = n + 1;

% Update sums
S1_new = S1 + x;
S2_new = S2 + x.^2;

end