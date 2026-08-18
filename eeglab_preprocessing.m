% Two-part preprocessing pipeline which requires manual quality check 
% of the EEG data in-between the sections. Unquote to use second part.
% manual quality check of ICA pruning is recommended.
% Specification needed:
data_directory = '';


% === Parameters ===
files = cellstr(spm_select('FPList', data_directory, '.vhdr$'));
addpath(fullfile(fileparts(which('eeglab')), 'plugins', 'fileio'));
disp(files);
for n = 1:length(files)
    data = files{n};
    disp(data); 
    [filepath, name, ext] = fileparts(data);
    % === Load raw EEG  ===
    EEG = pop_loadbv(filepath,[name, ext]);

    % === Preprocessing ===
    EEG = pop_chanedit(EEG, 'load', ...
        fullfile(fileparts(which('eeglab')), ...
        'plugins', 'dipfit', 'standard_BEM', 'elec', 'standard_1005.elc'), ...
        'filetype', 'autodetect');

    badChans = {'ExG1', 'ExG2', 'ACCx', 'ACCy', 'ACCz'};  % Replace with your bad channel names
    EEG = pop_select(EEG, 'nochannel', badChans);

    EEG = pop_eegfiltnew(EEG, 59, 61, [], 1);           % notch flter
    EEG = pop_eegfiltnew(EEG, 1, 30);                   % band pass filter

    newname = [name 'filtered.set'];
    filtered_path = [data_directory '/filtered/'];
    EEG = pop_saveset(EEG, newname, filtered_path);
end


    % % % % === manual check data quality before proceed === % % % % %
% 
% 
% files = cellstr(spm_select('FPList', filtered_path, 'filtered.set'));
% disp(files);
% 
% for n = 1:length(files)
%     data = files{n};
%     disp(data); 
%     [filepath, name, ext] = fileparts(data);
%     % === Load raw EEG  ===
%     EEG = pop_loadset([name, ext], filepath);
% 
%     EEG_reref = pop_reref(EEG, []);                       % Average re-reference
%     EEG_forica =  pop_eegfiltnew(EEG_reref, 5, 16);       % alpha band filtering
% 
%     % === Run ICA on filtered version ===
%     EEG_ica = pop_runica(EEG_forica, 'extended', 1, 'interupt', 'on');
%     EEG_ica.setname = 'ICA_Filtered';
% 
%     % === Transfer ICA weights to unfiltered rereferenced data ===
%     EEG_reref.icaweights = EEG_ica.icaweights;
%     EEG_reref.icasphere  = EEG_ica.icasphere;
%     EEG_reref.icawinv    = EEG_ica.icawinv;
%     EEG_reref.icaact     = [];
% 
%     % Optional: save or name the dataset
%     newname = [name '_ica.set'];
%     EEG = pop_saveset(EEG_reref, newname, data_directory);
% end
 %  %%%% Proceed to next step after manual ICA pruning.




