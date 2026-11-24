function results = calculate_sigma_squared(data_root, output_csv, mask_policy)
%CALCULATE_SIGMA_SQUARED Var[ln(max(speed/whole_fluid_mean,1e-4))], divisor N.
%
% USAGE, after downloading/restoring the data:
%   addpath('4- Scripts');
%   calculate_sigma_squared(pwd,fullfile(tempdir,'sigma_squared.csv'),'positive-speed');
%
% This is the ONLY sigma^2 calculation file; all helpers are included below.
% It follows the supplied poster code exactly in the order of operations:
%  1) Select the original whole-fluid sample and calculate its arithmetic mean.
%  2) Normalize each speed by THAT ORIGINAL MEAN (not a floored or regional mean).
%  3) Set every normalized speed <=1e-4 to 1e-4, INCLUDING valid fluid zeros.
%  4) Take the NATURAL log and compute population variance, dividing by N.
% Thus 1e-4 is DIMENSIONLESS. The equivalent dimensional floor is
% 1e-4*original_whole_fluid_mean, NOT a fixed speed of 1e-4 m/s.
%
% The supplied MAT files hold SCALAR SPEED matrices (already |velocity|), not
% vector components. If adapting to vectors, first use the pointwise Euclidean
% magnitude sqrt(Ux.^2+Uy.^2+Uz.^2), not MATLAB norm on an entire matrix.
%
% mask_policy is REQUIRED because zero speed may represent solids or stagnant
% fluid. Pick the scientifically appropriate policy explicitly:
%  'positive-speed'       : zero encodes solid; excludes all zeros BEFORE mean.
%  'all-finite'           : every finite pixel belongs to fluid, including zero.
%  'concentration-finite' : fluid mask = finite C_cut_T2 nodes, if appropriate.
%  'provided-mask'        : independently verified logical fluid mask stored as
%       3- Velocity_Conc_fields/FluidMasks/T0.mat (and T6,T9,T10,T12,T13).
% The last option is recommended when a registered fluid mask is available.
% Neither thresholding speed nor finite C alone proves the physical fluid mask.
%
% Optional INSIDE/OUTSIDE BIOFILM statistics: if a registered logical mask is
% present in 3- Velocity_Conc_fields/BiofilmMasks/<stage>.mat, both regions use
% the SAME original whole-fluid mean. Without it, only whole-fluid sigma^2 is
% reported. Do NOT resize/align segmented images automatically to create masks.
% Equal point weights are used, not flux or cell-volume weights.
%
% Outputs include floor probability and its equivalent dimensional value.
% Existing output files are not overwritten. No toolbox/helper file is needed.
if nargin<1 || isempty(data_root), data_root=fileparts(fileparts(mfilename('fullpath'))); end
if nargin<2 || isempty(output_csv), output_csv=fullfile(tempdir,'paper2_sigma_squared.csv'); end
if nargin<3 || isempty(mask_policy), error('Specify mask_policy explicitly; see comments above.'); end
if isfile(output_csv), error('Output exists; choose a new output_csv: %s',output_csv); end
stages={'T0','T6','T9','T10','T12','T13'}; a=1e-4; rows=struct([]);
for s=1:numel(stages)
    stage=stages{s}; base=fullfile(data_root,'3- Velocity_Conc_fields');
    speed=load_one(fullfile(base,'VelocityField',[stage '.mat']));
    validateattributes(speed,{'numeric'},{'real','2d'}); speed=double(speed);
    switch mask_policy
        case 'positive-speed', fluid=isfinite(speed)&speed>0;
        case 'all-finite', fluid=isfinite(speed);
        case 'concentration-finite'
            C=load_one(fullfile(base,'ConcentrationField',stage,'C_cut_T2.mat'));
            if ~isequal(size(C),size(speed)), error('Concentration/speed shape mismatch.'); end
            fluid=isfinite(C)&isfinite(speed);
        case 'provided-mask'
            fluid=load_mask(fullfile(base,'FluidMasks',[stage '.mat']),size(speed))&isfinite(speed);
        otherwise, error('Unknown mask_policy: %s',mask_policy);
    end
    v=speed(fluid);
    if isempty(v)||any(v<0), error('Need finite nonnegative fluid speeds for %s.',stage); end
    reference_mean=mean(v); % Shared ORIGINAL mean, before flooring or splitting.
    if reference_mean<=0, error('Mean speed must be positive for %s.',stage); end
    original_u=v/reference_mean; u=max(original_u,a);
    names={'Whole fluid sample'}; masks={true(size(v))};
    bio_path=fullfile(base,'BiofilmMasks',[stage '.mat']);
    if isfile(bio_path)
        bio=load_mask(bio_path,size(speed)); bio=bio(fluid);
        names=[names {'Inside biofilm','Outside biofilm'}]; masks=[masks {bio,~bio}];
    end
    for j=1:numel(names)
        selected=masks{j}; selected_u=u(selected); n=numel(selected_u);
        if n==0, error('No fluid samples in %s, %s.',stage,names{j}); end
        logs=log(selected_u); mu=mean(logs); floor_count=sum(original_u(selected)<=a);
        r.stage=stage; r.region=names{j}; r.mask_policy=mask_policy;
        r.reference_mean_m_s=reference_mean; r.normalized_floor=a;
        r.equivalent_dimensional_floor_m_s=a*reference_mean;
        r.n_total=n; r.point_mass_count=floor_count;
        r.point_mass_probability=floor_count/n;
        r.sigma_squared=sum((logs-mu).^2)/n; % Population variance, divisor N.
        rows(end+1)=r; %#ok<AGROW>
    end
    fprintf('%s: processed %d valid fluid points.\n',stage,numel(v));
end
results=struct2table(rows); writetable(results,output_csv); fprintf('Saved %s\n',output_csv);
end

function A=load_one(path)
S=load(path); names=fieldnames(S); keys={};
for k=1:numel(names)
    value=S.(names{k});
    if (isnumeric(value)||islogical(value))&&ismatrix(value), keys{end+1}=names{k}; end %#ok<AGROW>
end
if numel(keys)~=1, error('Expected one numerical/logical array in %s.',path); end
A=S.(keys{1});
end

function mask=load_mask(path,expected_size)
mask=load_one(path);
if ~islogical(mask)||~isequal(size(mask),expected_size)
    error('Mask must be logical, co-registered, and match speed shape: %s',path);
end
end
