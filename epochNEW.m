% Specification needed:
data_directory = '';

files = cellstr(spm_select('FPList', 'C:\Users\elian2\Desktop\EEG_practice_data\ica_pruned', '.set$'));

disp(files);
for n = 1:length(files)
    data = files{n};
    disp(data); 
    [filepath, name, ext] = fileparts(data);
    % === Load original data ===
    EEG_orig = pop_loadset([name ext], filepath);
    srate = EEG_orig.srate;
    
    % naming
    eyesopen = 'eos';
    eyesclosed = 'ecs';

    
    % === Epoch after 'eos' and 'ecs' ===
    save_epoch_set(EEG_orig, eyesopen, 'eos_segment', [name '_eos.set'], ...
        'C:\Users\elian2\Desktop\EEG_practice_data\epoched\');
    
    save_epoch_set(EEG_orig, eyesclosed, 'ecs_segment',  [name '_ecs.set'], ...
        'C:\Users\elian2\Desktop\EEG_practice_data\epoched\');
end
    
    % === Define a reusable epoching function ===
    function save_epoch_set(EEG_in, marker, newtype, outfile, outpath)
        idx = find(strcmpi({EEG_in.event.type}, marker), 1);
        if isempty(idx)
            error('No "%s" event found.', marker);
        end
        base_lat = EEG_in.event(idx).latency;
        for i = 0:35
            lat = base_lat + i * 5 * EEG_in.srate;
            if lat + 5 * EEG_in.srate - 1 <= EEG_in.pnts
                EEG_in.event(end+1).type = newtype;
                EEG_in.event(end).latency = lat;
            else
                warning('%s: not enough data at segment %d', marker, i+1);
                break;
            end
        end
        EEG_in = eeg_checkset(EEG_in);
        EEG_ep = pop_epoch(EEG_in, {newtype}, [0 5]);
        EEG_ep = pop_rmbase(EEG_ep, []);
        if ischar(EEG_ep.data) || isa(EEG_ep.data, 'memmapfile')
            EEG_ep.data = eeg_getdatact(EEG_ep);
        end
        pop_saveset(EEG_ep, 'filename', outfile, 'filepath', outpath, 'savemode', 'onefile');
    end

