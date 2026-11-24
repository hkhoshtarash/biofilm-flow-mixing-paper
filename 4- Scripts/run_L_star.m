function run_L_star(data_root, output_csv, config_file)
%RUN_L_STAR Calculate all supplied concentration snapshots with legacy scales.
if nargin<3, config_file=fullfile(fileparts(mfilename('fullpath')),'legacy_six_stages.json'); end
if isfile(output_csv), error('Output already exists.'); end
cfg=jsondecode(fileread(config_file)); rows=struct([]);
for s=1:numel(cfg.stages)
    st=cfg.stages(s); files=dir(fullfile(data_root,st.concentration_directory,'C_cut_T*.mat'));
    if isempty(files), error('Missing snapshots for %s.',st.stage); end
    times=zeros(numel(files),1);
    for i=1:numel(files)
        t=regexp(files(i).name,'^C_cut_T([0-9]+(?:\.[0-9]+)?)\.mat$','tokens','once');
        if isempty(t), error('Unexpected snapshot filename.'); end
        times(i)=str2double(t{1});
    end
    [times,order]=sort(times); files=files(order);
    for i=1:numel(files)
        [~,key]=fileparts(files(i).name);
        C=load_numeric_array(fullfile(files(i).folder,files(i).name),key);
        L0=cfg.legacy_width_fraction*size(C,2)*cfg.dx;
        if isfield(st,'reference_length'), L0=st.reference_length; end
        r=interface_length(C,cfg.dx,cfg.dy,L0,cfg.concentration_level);
        row.stage=st.stage; row.time_seconds=times(i);
        row.time_normalized=times(i)/st.ta_seconds;
        row.length_m=r.length; row.L_star=r.L_star;
        row.reference_length_m=L0; row.n_contours=r.n_contours;
        rows(end+1)=row; %#ok<AGROW>
    end
    fprintf('%s: %d snapshots\n',st.stage,numel(files));
end
writetable(struct2table(rows),output_csv);
end
