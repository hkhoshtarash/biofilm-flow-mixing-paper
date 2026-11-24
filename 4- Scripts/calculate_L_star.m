function results = calculate_L_star(data_root, output_csv)
%CALCULATE_L_STAR Calculate interface length L and L*=L/L0 for all six stages.
%
% USAGE, after downloading/restoring the data:
%   addpath('4- Scripts');
%   calculate_L_star(pwd, fullfile(tempdir,'L_star.csv'));
%
% data_root contains the four numbered research folders. If omitted, the
% repository root is inferred from this file's location in '4- Scripts'.
% output_csv defaults to a temporary-directory CSV; existing files are never
% overwritten. This is the ONLY L* calculation file; helpers are included below.
%
% METHOD (same definitions as the supplied original MATLAB script):
%  1) Extract ALL C=0.5 contour lines, retaining NaN solid/missing-data masks.
%  2) Sum physical Euclidean distances between successive vertices of each
%     individual contour. Do not connect separate components or smooth C.
%  3) L*=L/L0, with L0=0.44*N_columns*8.3978e-6 m for these supplied grids.
%  4) Normalized time t*=t/ta. Preserve ta from the supplied stage's saved
%     L_star table (columns: L*, normalized time, seconds). Do not substitute
%     a mean speed: the velocity definition behind the saved ta is unresolved.
%
% Grid rows follow y, columns follow x. Change dx/dy/reference_fraction below
% only when using a different documented grid/reference interface length.
% 'contour' is used as in the legacy MATLAB calculation, with a hidden figure.
% No additional toolbox or separate helper/configuration file is required.
if nargin<1 || isempty(data_root), data_root=fileparts(fileparts(mfilename('fullpath'))); end
if nargin<2 || isempty(output_csv), output_csv=fullfile(tempdir,'paper2_L_star.csv'); end
if isfile(output_csv), error('Output exists; choose a new output_csv: %s',output_csv); end
stages={'T0','T6','T9','T10','T12','T13'};
dx=8.3978e-6; dy=8.3978e-6; reference_fraction=0.44; level=0.5;
rows=struct([]);
for s=1:numel(stages)
    stage=stages{s};
    reference=load_one(fullfile(data_root,'3- Velocity_Conc_fields','L_star',[stage '.mat']));
    if size(reference,2)<3, error('Expected three-column saved L* table for %s.',stage); end
    valid=isfinite(reference(:,2)) & isfinite(reference(:,3)) & reference(:,2)>0 & reference(:,3)>0;
    ratios=reference(valid,3)./reference(valid,2);
    if isempty(ratios), error('Cannot recover saved characteristic time for %s.',stage); end
    ta=ratios(1);
    if any(abs(ratios-ta)>1e-10*abs(ta)), error('Inconsistent saved time scale for %s.',stage); end
    folder=fullfile(data_root,'3- Velocity_Conc_fields','ConcentrationField',stage);
    files=dir(fullfile(folder,'C_cut_T*.mat'));
    if isempty(files), error('No C_cut_T*.mat snapshots for %s.',stage); end
    times=zeros(numel(files),1);
    for i=1:numel(files)
        token=regexp(files(i).name,'^C_cut_T([0-9]+(?:\.[0-9]+)?)\.mat$','tokens','once');
        if isempty(token), error('Unexpected concentration filename: %s',files(i).name); end
        times(i)=str2double(token{1});
    end
    [times,order]=sort(times); files=files(order);
    for i=1:numel(files)
        [~,variable]=fileparts(files(i).name);
        loaded=load(fullfile(folder,files(i).name),variable);
        if ~isfield(loaded,variable), error('Missing concentration variable %s.',variable); end
        C=loaded.(variable); validateattributes(C,{'numeric'},{'real','2d'});
        if any(size(C)<2) || ~any(isfinite(C(:))), error('Invalid concentration grid.'); end
        C=double(C); C(~isfinite(C))=NaN;
        L0=reference_fraction*size(C,2)*dx; % Original pixel-count convention.
        L=contour_length(C,dx,dy,level);
        row.stage=stage; row.time_seconds=times(i); row.time_normalized=times(i)/ta;
        row.interface_length_m=L; row.reference_length_m=L0; row.L_star=L/L0;
        rows(end+1)=row; %#ok<AGROW>
    end
    fprintf('%s: processed %d concentration fields.\n',stage,numel(files));
end
results=struct2table(rows); writetable(results,output_csv);
fprintf('Saved %s\n',output_csv);
end

function A=load_one(path)
% Read the single numerical array in each supplied saved L* MAT file.
S=load(path); names=fieldnames(S); keys={};
for k=1:numel(names)
    if isnumeric(S.(names{k})) && ismatrix(S.(names{k})), keys{end+1}=names{k}; end %#ok<AGROW>
end
if numel(keys)~=1, error('Expected one numerical array in %s.',path); end
A=S.(keys{1});
end

function L=contour_length(C,dx,dy,level)
% Parse MATLAB's contour matrix; header columns are not contour vertices.
f=figure('Visible','off'); cleanup=onCleanup(@() close(f)); %#ok<NASGU>
ax=axes('Parent',f); x=(1:size(C,2))*dx; y=(1:size(C,1))*dy;
contours=contour(ax,x,y,C,[level level]); L=0; k=1;
while k<=size(contours,2)
    n=contours(2,k);
    if n<1 || n~=floor(n) || k+n>size(contours,2), error('Invalid contour matrix.'); end
    delta=diff(contours(:,k+(1:n)),1,2);
    L=L+sum(sqrt(sum(delta.^2,1))); k=k+n+1;
end
% Empty contour matrix gives L=0, meaning no C=0.5 interface was found.
end
