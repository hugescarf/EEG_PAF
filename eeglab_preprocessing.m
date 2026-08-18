% === Parameters ===
files = cellstr(spm_select('FPList', 'C:\Users\elian2\Desktop\EEG_practice_data', '.vhdr$'));
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

    badChans = {'A2', 'ExG1', 'ExG2', 'ACCx', 'ACCy', 'ACCz'};  % Replace with your bad channel names
    EEG = pop_select(EEG, 'nochannel', badChans);

    EEG = pop_eegfiltnew(EEG, 59, 61, [], 1);                          % notch flter
    EEG = pop_eegfiltnew(EEG, 1, 30);                           % band pass filter

    newname = [name 'filtered.set'];
    EEG = pop_saveset(EEG, newname, 'C:\Users\elian2\Desktop\EEG_practice_data/filtered/');
end


    % % % % === manual check data quality before proceed === % % % % %
% 
% 
% files = cellstr(spm_select('FPList', 'C:\Users\elian2\Desktop\EEG_practice_data\filtered', 'cpecfiltered.set'));
% disp(files);
% 
% for n = 1:length(files)
%     data = files{n};
%     disp(data); 
%     [filepath, name, ext] = fileparts(data);
%     % === Load raw EEG  ===
%     EEG = pop_loadset([name, ext], filepath);
% 
%     EEG_reref = pop_reref(EEG, []);                                 % Average re-reference
%     EEG_forica =  pop_eegfiltnew(EEG_reref, 5, 16);                  % alpha band filtering
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
%     EEG = pop_saveset(EEG_reref, newname, 'C:\Users\elian2\Desktop\EEG_practice_data');
% end




