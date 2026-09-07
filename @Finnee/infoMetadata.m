function infoMetadata(obj)
%% DESCRIPTION
%
% Print a readable summary of the mzML metadata structure stored in a
% Finnee dataset folder.
%
% This function loads the saved acquisition metadata and walks through the
% nested structure, printing headers and nested element fields in a
% human-readable form.
%
% BSD 3-Clause License
% Copyright (c) 2026, G. Erny
% All rights reserved.
%
% Author: G. Erny
% Email: guillaume.erny@gmail.com

metadata = load(fullfile(obj.Path2Fin, 'AquisitionData.mat')); metadata = metadata.metadata;
mzML = metadata.mzML;

% HEADERS
Head = mzML.Attributes;
fHead = fieldnames(Head);
for ii = 1:height(fHead)
    fprintf('%s: %s\n',  fHead{ii}, Head.(fHead{ii}));

end


% BODY
Body = mzML.subElements;
if iscell(Body)
    for jj = 1:length(Body)
        fprintf('\n');
        sub1 = Body{jj};

        if iscell(sub1), error('')
        elseif isstruct(sub1)
            fsub1 = fields(sub1);

            for kk = 1:height(fsub1)
                if strcmpi(fsub1{kk}, 'offset'), continue, end
                fprintf('\n  %s', fsub1{kk});
                sub2 = sub1.(fsub1{kk});

                if iscell(sub2), error('')
                elseif isstruct(sub2)
                    fsub2 = fields(sub2);

                    for ll = 1:height(fsub2)
                        if strcmpi(fsub2{ll}, 'offset'), continue, end
                        fprintf('\n    %s', fsub2{ll});
                        sub3 = sub2.(fsub2{ll});

                        if iscell(sub3)
                            for mm = 1:length(sub3)
                                sub4 = sub3{mm};

                                if iscell(sub4), error('')
                                elseif isstruct(sub4)
                                    fsub4 = fields(sub4);

                                    for nn = 1:height(fsub4)
                                        fprintf('\n      %s', fsub4{nn});
                                        sub5 = sub4.(fsub4{nn});

                                        if iscell(sub5), error('')
                                        elseif isstruct(sub5)
                                            fsub5 = fields(sub5);

                                            for oo = 1:height(fsub5)
                                                if strcmpi(fsub5{oo}, 'offset'), continue, end
                                                fprintf('\n      %s', fsub5{oo});
                                                sub6 = sub5.(fsub5{oo});

                                                if iscell(sub6)
                                                    for pp = 1:length(sub6)
                                                        sub7 = sub6{pp};

                                                        if iscell(sub7), error('')
                                                        elseif isstruct(sub7)
                                                            fsub7 = fields(sub7);

                                                            for qq = 1:height(fsub7)
                                                                if strcmpi(fsub7{qq}, 'offset'), continue, end
                                                                fprintf('\n        %s', fsub7{qq});
                                                                sub8 = sub7.(fsub7{qq});

                                                                if iscell(sub8), error('')
                                                                elseif isstruct(sub8)
                                                                    fsub8 = fields(sub8);

                                                                    for rr = 1:height(fsub8)
                                                                        if strcmpi(fsub8{rr}, 'offset'), continue, end
                                                                        fprintf('\n          %s', fsub8{rr});
                                                                        sub9 = sub8.(fsub8{rr});

                                                                        if iscell(sub9)
                                                                            for ss = 1:length(sub9)
                                                                                sub10 = sub9{ss};

                                                                                if iscell(sub10), error('')
                                                                                elseif isstruct(sub10)
                                                                                    fsub10 = fields(sub10);

                                                                                    for tt = 1:height(fsub10)
                                                                                        if strcmpi(fsub10{tt}, 'offset'), continue, end
                                                                                        fprintf('\n            %s', fsub10{tt});
                                                                                        sub11 = sub10.(fsub10{tt});

                                                                                        if iscell(sub11), error('')
                                                                                        elseif isstruct(sub11)
                                                                                            fsub11 = fields(sub11);

                                                                                            for uu = 1:height(fsub11)
                                                                                                if strcmpi(fsub11{uu}, 'offset'), continue, end
                                                                                                fprintf('\n              %s', fsub11{uu});
                                                                                                sub12 = sub11.(fsub11{uu});

                                                                                                if iscell(sub12)
                                                                                                    for vv = 1:length(sub12)
                                                                                                        sub13 = sub12{vv};

                                                                                                        if iscell(sub13), error('')
                                                                                                        elseif isstruct(sub13)
                                                                                                            fsub13 = fields(sub13);

                                                                                                            for ww = 1:height(fsub13)
                                                                                                                if strcmpi(fsub13{ww}, 'offset'), continue, end
                                                                                                                fprintf('\n                %s', fsub13{ww});
                                                                                                                sub14 = sub13.(fsub13{ww});

                                                                                                                if iscell(sub14), error('')
                                                                                                                elseif isstruct(sub14)
                                                                                                                    fsub14 = fields(sub14);

                                                                                                                    for xx = 1:height(fsub14)
                                                                                                                        if strcmpi(fsub14{xx}, 'offset'), continue, end
                                                                                                                        fprintf('\n                  %s', fsub14{xx});
                                                                                                                        sub15 = sub14.(fsub14{xx});

                                                                                                                        if iscell(sub15), error('')
                                                                                                                        elseif isstruct(sub15)
                                                                                                                            fsub15 = fields(sub15);

                                                                                                                            for yy = 1:height(fsub15)
                                                                                                                                if strcmpi(fsub15{yy}, 'offset'), continue, end
                                                                                                                                fprintf('\n                    %s', fsub15{yy});
                                                                                                                                sub16 = sub15.(fsub15{yy});

                                                                                                                                if iscell(sub16), error('')
                                                                                                                                elseif isstruct(sub16), error('')
                                                                                                                                elseif isnumeric(sub16), fprintf(': %s', num2str(sub16));
                                                                                                                                else, fprintf(': %s', sub16);
                                                                                                                                end
                                                                                                                            end

                                                                                                                        elseif isnumeric(sub15), fprintf(': %s', num2str(sub15));
                                                                                                                        else, fprintf(': %s', sub15);
                                                                                                                        end
                                                                                                                    end

                                                                                                                    elseif isnumeric(sub14), fprintf(': %s', num2str(sub14));
                                                                                                                    else, fprintf(': %s', sub14);
                                                                                                                end
                                                                                                            end

                                                                                                        else, error('')
                                                                                                        end
                                                                                                    end

                                                                                                elseif isstruct(sub12)
                                                                                                    fsub12 = fields(sub12);

                                                                                                    for vv = 1:height(fsub12)
                                                                                                        if strcmpi(fsub12{vv}, 'offset'), continue, end
                                                                                                        fprintf('\n                %s', fsub12{vv});
                                                                                                        sub13 = sub12.(fsub12{vv});

                                                                                                        if iscell(sub13), error('')
                                                                                                        elseif isstruct(sub13), error('')
                                                                                                        elseif isnumeric(sub13), fprintf(': %s', num2str(sub13));
                                                                                                        else, fprintf(': %s', sub13);
                                                                                                        end
                                                                                                    end
                                                                                                elseif isnumeric(sub12), fprintf(': %s', num2str(sub12));
                                                                                                else, fprintf(': %s', sub12);
                                                                                                end
                                                                                            end

                                                                                        elseif isnumeric(sub11), fprintf(': %s', num2str(sub11));
                                                                                        else fprintf(': %s', sub11);
                                                                                        end
                                                                                    end

                                                                                else, error('')
                                                                                end
                                                                            end

                                                                        elseif isstruct(sub9)
                                                                            fsub9 = fields(sub9);

                                                                            for ss = 1:height(fsub9)
                                                                                if strcmpi(fsub9{ss}, 'offset'), continue, end
                                                                                fprintf('\n          %s', fsub9{ss});
                                                                                sub10 = sub9.(fsub9{ss});

                                                                                if iscell(sub10), error('')
                                                                                elseif isstruct(sub10), error('')
                                                                                elseif isnumeric(sub10), fprintf(': %s', num2str(sub10));
                                                                                else fprintf(': %s', sub10);
                                                                                end
                                                                            end

                                                                        else, error('')
                                                                        end
                                                                    end

                                                                elseif isnumeric(sub8), fprintf(': %s', num2str(sub8));
                                                                else fprintf(': %s', sub8);
                                                                end
                                                            end

                                                        else, error('')
                                                        end
                                                    end

                                                elseif isstruct(sub6)
                                                    fsub6 = fields(sub6);

                                                    for pp = 1:height(fsub6)
                                                        if strcmpi(fsub6{pp}, 'offset'), continue, end
                                                        fprintf('\n        %s', fsub6{pp});
                                                        sub7 = sub6.(fsub6{pp});

                                                        if iscell(sub7), error('')
                                                        elseif isstruct(sub7), error('')
                                                        elseif isnumeric(sub7), fprintf(': %s', num2str(sub7));
                                                        else, fprintf(': %s', sub7);
                                                        end
                                                    end

                                                else, error('')
                                                end
                                            end

                                        elseif isnumeric(sub5), fprintf(': %s', num2str(sub5));
                                        else, fprintf(': %s', sub5);
                                        end
                                    end

                                else, error('')
                                end
                            end

                        elseif isstruct(sub3)
                            fsub3 = fields(sub3);

                            for mm = 1:height(fsub3)
                                if strcmpi(fsub3{mm}, 'offset'), continue, end
                                fprintf('\n      %s', fsub3{mm});
                                sub4 = sub3.(fsub3{mm});

                                if iscell(sub4), error('')
                                elseif isstruct(sub4), error('')
                                elseif isnumeric(sub4), fprintf(': %s', num2str(sub4));
                                else, fprintf(': %s', sub4);
                                end
                            end

                        elseif isnumeric(sub3), fprintf(': %s', num2str(sub3));
                        else, fprintf(': %s', sub3);
                        end
                    end

                else, error('')
                end
            end
        end
    end
end
fprintf('\n')

end