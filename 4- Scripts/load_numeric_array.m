function array = load_numeric_array(path, variable)
%LOAD_NUMERIC_ARRAY Load an explicit MAT variable or headerless CSV matrix.
if nargin < 2, variable = ''; end
[~,~,ext] = fileparts(path);
if strcmpi(ext,'.csv')
    array = readmatrix(path);
elseif strcmpi(ext,'.mat')
    data = load(path);
    if isempty(variable)
        keys = fieldnames(data); candidates = {};
        for i = 1:numel(keys)
            value = data.(keys{i});
            if isnumeric(value) && ismatrix(value)
                candidates{end+1} = keys{i}; %#ok<AGROW>
            end
        end
        if numel(candidates) ~= 1, error('Specify a MAT variable for %s.',path); end
        variable = candidates{1};
    end
    if ~isfield(data,variable), error('Missing variable %s in %s.',variable,path); end
    array = data.(variable);
else
    error('Use a MAT file or headerless numeric CSV matrix.');
end
validateattributes(array, {'numeric'}, {'real','2d'});
array = double(array);
end
