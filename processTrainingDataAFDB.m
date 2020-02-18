clear all; close all;

%% --- AFDB DATASET --- %%
%% Easily download the required dataset into afdb folder using:
% Total uncompressed size: 605.9 MB
% wget -r -N -c -np -nH --cut-dirs=3 -P afdb https://physionet.org/files/afdb/1.0.0/
% or get a zip file:
% Compressed size: 439.7 MB
% https://physionet.org/static/published-projects/afdb/mit-bih-atrial-fibrillation-database-1.0.0.zip
dataset_path = 'afdb/';

%% Get unique record names and qrs annotator
[rec, qrs_ann, dat_rec] = getDatasetFiles(dataset_path);
nrecords = length(rec);

%% Load atr & qrs annotations
qrs = cell(nrecords, 1);
ann = cell(nrecords, 2);
for n = 1:nrecords
	qrs{n} = rdann([dataset_path rec{n}], qrs_ann{n});
	[ann{n,1}, ~, ~, ~, ~, ann{n,2}] = rdann([dataset_path rec{n}], 'atr');
end

%% --------------- FUNCTIONS --------------- %%

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
