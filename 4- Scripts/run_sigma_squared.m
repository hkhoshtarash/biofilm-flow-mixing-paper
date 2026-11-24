function run_sigma_squared(data_root, output_csv, mask_policy)
%RUN_SIGMA_SQUARED Six-stage batch. Choose mask_policy explicitly; see README.
% Example: run_sigma_squared(root,fullfile(tempdir,'sigma_squared.csv'),'positive-speed')
if nargin<3, error('Specify a fluid mask policy explicitly.'); end
if isfile(output_csv), error('Output already exists.'); end
stages={'T0','T6','T9','T10','T12','T13'}; rows=struct([]);
for i=1:numel(stages)
    st=stages{i}; speed=read_one(fullfile(data_root,'3- Velocity_Conc_fields','VelocityField',[st '.mat']));
    switch mask_policy
        case 'positive-speed', mask=isfinite(speed)&speed>0;
        case 'all-finite', mask=isfinite(speed);
        case 'concentration-finite'
            C=read_one(fullfile(data_root,'3- Velocity_Conc_fields','ConcentrationField',st,'C_cut_T2.mat'));
            if ~isequal(size(C),size(speed)), error('Mask/speed shape mismatch.'); end
            mask=isfinite(C);
        otherwise, error('Unknown mask policy.');
    end
    stats=sigma_squared(speed,'FluidMask',mask);
    for k=1:numel(stats)
        row.stage=st; row.mask_policy=mask_policy;
        fields=fieldnames(stats(k));
        for j=1:numel(fields), row.(fields{j})=stats(k).(fields{j}); end
        rows(end+1)=row; %#ok<AGROW>
    end
end
writetable(struct2table(rows),output_csv);
end

function a=read_one(path)
data=load(path); fields=fieldnames(data); keys={};
for i=1:numel(fields)
    v=data.(fields{i});
    if isnumeric(v)&&ismatrix(v), keys{end+1}=fields{i}; end %#ok<AGROW>
end
if numel(keys)~=1, error('Expected exactly one numeric matrix in %s.',path); end
a=data.(keys{1});
end
