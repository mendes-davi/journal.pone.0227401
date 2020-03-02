%% getDatasetFiles: function description
function [rec_names, qrs_annotator, dat] = getDatasetFiles(dataset_path)
	% Ann Extensions
	ann_ext = {'.atr', '.qrs', '.qrsc', '.dat'};
	% Get Folder Information
	dir_info = dir(dataset_path);
	records = {dir_info.name};
	records = records(find([dir_info.isdir] == 0));
	
	% Filter Names and Extensions
	[~, rec_names, rec_ext] = cellfun(@(rec) fileparts(rec), records, 'UniformOutput', false);	
	rec_names = rec_names(find(contains(rec_ext,ann_ext) == 1));
	rec_names = unique(rec_names); % List of unique names for the dataset
	assert(isequal(length(rec_names), 25), 'Records are missing in the local afdb folder!');
	records = records(find(contains(rec_ext,ann_ext) == 1));
	
	% Get qrs_annotator
	qrs_annotator = cell(1, length(rec_names));
	dat = zeros(1, length(rec_names));
	for r = 1:length(rec_names)
		% Check if .dat file exists for the recording
		dat(r) = any(strcmp([rec_names{r} '.dat'], records));
		% Assert for .atr file
		atr_file = any(strcmp([rec_names{r} ann_ext{1}], records));
		assert(atr_file, ['atr annotation file is missing for: ' rec_names{r}]);
		% Assert for .qrs file
		qrs_file = find(strcmp([rec_names{r} ann_ext{2}], records));
		assert(~isempty(qrs_file), ['qrs annotation file is missing for: ' rec_names{r}]);
		qrsc_file = find(strcmp([rec_names{r} ann_ext{3}], records));
		% For some records, manually corrected beat annotation files are available
		% (with the suffix .qrsc)
		if ~isempty(qrsc_file)
			qrs_annotator{r} = 'qrsc';
		else
			qrs_annotator{r} = 'qrs';
		end
	end	
end
