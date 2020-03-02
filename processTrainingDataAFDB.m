clear all; close all;
addpath('utils/');

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

% Import Data and get RR Intervals according to ann_type
qrs = cell(nrecords, 1);
ann = cell(nrecords, 2);
rr_sets = cell(nrecords, 1);
for n = 1:nrecords
	%% Load atr & qrs annotations
	qrs{n} = rdann([dataset_path rec{n}], qrs_ann{n});
	[ann{n,1}, ~, ~, ~, ~, ann{n,2}] = rdann([dataset_path rec{n}], 'atr');
	%% Get RR sets (per annotation) for each recording
	[rr_sets{n}] = ann2RR(qrs{n}, ann{n,1});
end

% Split RR training data
rr_set_size = 60; % group RR intervals in sets of 60 samples each
% afdb_train_data:
% 1st col: record associated with RR interval
% 2nd col: annotation for RR interval
% 3rd col: array of RR interval
[afdb_train_data] = rrLabel(rr_sets, ann(:,2), rec, rr_set_size);

% ...
% According to the paper:
% The MITBIH-AF database yielded 7,744 consecutive 60 beat sequences of AF, and 10,467 non-AF
af_sequences = length(find(strcmp(afdb_train_data(:,2), '(AFIB')));
non_af_sequences = length(afdb_train_data) - af_sequences;
disp(['Got ' int2str(af_sequences) ' AF sequences.']);
disp(['Got ' int2str(non_af_sequences) ' non-AF sequences.']);
% My results:
% Got 8546 AF sequences.
% Got 11531 non-AF sequences.

% Export annotations for training data
% PS: RR intervals are in samples!!!!!
tb_var_names = {'Filename', 'Record', 'AnnType'};
file_id = arrayfun(@(x) int2str(x), 1:1:length(afdb_train_data), 'UniformOutput', false);
ann_train_data = table(file_id(:), afdb_train_data(:,1), afdb_train_data(:,2), 'VariableNames', tb_var_names);
writetable(ann_train_data, 'training_dat/annotations.csv');
% Write RR intervals as .dat files in training data folder
for f = 1:length(afdb_train_data)
	% This for loop is time consuming...
	%FIXME: Improve storage of training data
	writematrix(afdb_train_data{f,3}, ['training_dat/' file_id{f} '.dat']);
end

%% --------------- FUNCTIONS --------------- %%

%% rrLabel: function description
function [rr_split_sets] = rrLabel(rr_sets, ann_type, rec, rr_set_size)
	rr_split_sets = {};

	% Iterate over all records
	nrecords = length(rr_sets);
	for n = 1:nrecords
		% Get RR intervals for each record
		rr_data = rr_sets{n};

		% Iterate over all rhythm annotations
		nsets = length(rr_sets{n});
		for s = 1:nsets
			% Length of RR intervals per annotation
			rr_length = length(rr_data{s});
			% Check if the RR Set length if larger than rr_set_size
			ndat = floor(rr_length/rr_set_size);
			if ndat > 0
				% Reshape RR data
				rr_data{s} = reshape(rr_data{s}(1:ndat*rr_set_size), [rr_set_size ndat]);

				% Iterate for each piece RR Split Set
				for d = 1:ndat
					% Append to rr_split_sets
					rr_split_sets{end+1, 1} = rec{n};
					rr_split_sets{end, 2} = ann_type{n}{s};
					rr_split_sets{end, 3} = rr_data{s}(:,d);
				end
			end
		end
	end	
end

%% ann2RR: function description
function [rr_sets] = ann2RR(qrs, ann)
	% For each ann_type split qrs points based on ann values into sets
	rr_sets = cell(1, length(ann));
	for n = 1:length(ann)
		if ~isequal(n,length(ann))
			rr_sets{n} = qrs(find(qrs >= ann(n) & qrs <= ann(n+1)));
		else % The last annotation ends with the last QRS of the record
			rr_sets{n} = qrs(find(qrs >= ann(n))); 
		end
	end
	% Get RR Intervals for each QRS set
	rr_sets = cellfun(@(d) diff(d(:)), rr_sets, 'UniformOutput', false);
end
