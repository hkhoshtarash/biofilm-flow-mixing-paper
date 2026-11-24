function rows = sigma_squared(velocity, varargin)
%SIGMA_SQUARED Population Var[ln(max(speed / original_whole_mean, 1e-4))].
% Whole-fluid mean is shared between inside/outside biofilm, before flooring.
% ComponentDimension explicitly identifies vector components; otherwise input
% is a scalar speed array. FluidMask excludes solids. Valid fluid zeros remain
% included and are clamped AFTER normalization. Natural logarithm; divisor N.
p = inputParser;
addParameter(p,'ComponentDimension',[]);
addParameter(p,'FluidMask',[]);
addParameter(p,'BiofilmMask',[]);
addParameter(p,'NormalizedFloor',1e-4);
parse(p,varargin{:}); o = p.Results;
validateattributes(velocity,{'numeric'},{'real'});
validateattributes(o.NormalizedFloor,{'numeric'},{'real','scalar','finite','positive'});
speed = double(velocity);
if ~isempty(o.ComponentDimension)
    validateattributes(o.ComponentDimension,{'numeric'},{'scalar','positive','integer'});
    speed = sqrt(sum(speed.^2,o.ComponentDimension));
end
fluid = isfinite(speed);
if ~isempty(o.FluidMask)
    if ~islogical(o.FluidMask) || ~isequal(size(o.FluidMask),size(speed))
        error('FluidMask must be logical and match the speed shape.');
    end
    fluid = fluid & o.FluidMask;
end
v = speed(fluid);
if isempty(v) || any(v<0), error('Need finite nonnegative fluid speeds.'); end
reference_mean = mean(v);
if reference_mean<=0, error('Whole-fluid mean must be positive.'); end
original_u = v/reference_mean;
u = max(original_u,o.NormalizedFloor);
names = {'Whole fluid sample'}; masks = {true(size(v))};
if ~isempty(o.BiofilmMask)
    if ~islogical(o.BiofilmMask) || ~isequal(size(o.BiofilmMask),size(speed))
        error('BiofilmMask must be logical and match the speed shape.');
    end
    bio = o.BiofilmMask(fluid);
    names = [names {'Inside biofilm','Outside biofilm'}];
    masks = [masks {bio,~bio}];
end
rows = struct([]);
for i=1:numel(names)
    selected=masks{i}; values=u(selected); n=numel(values);
    if n==0, error('No valid fluid samples in %s.',names{i}); end
    logs=log(values); mu=mean(logs);
    atom=sum(original_u(selected)<=o.NormalizedFloor);
    r.region=names{i};
    r.reference_mean_m_s=reference_mean;
    r.normalized_floor=o.NormalizedFloor;
    r.equivalent_dimensional_floor_m_s=o.NormalizedFloor*reference_mean;
    r.n_total=n; r.n_continuous=n-atom;
    r.point_mass_count=atom; r.point_mass_probability=atom/n;
    r.mean_floored_normalized_speed=mean(values);
    r.variance_ln_floored_normalized_speed=sum((logs-mu).^2)/n;
    r.mean_ln_floored_normalized_speed=mu;
    rows(end+1)=r; %#ok<AGROW>
end
end
