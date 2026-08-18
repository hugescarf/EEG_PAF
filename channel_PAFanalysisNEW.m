% This file calculates PAF using Center of Gravity(CoG) method by channel.
% Results will be saved in excel file in specified data_directory.
% Specification needed:
data_directory = '';

data_path = [data_directory '/epoched'];
files = cellstr(spm_select('FPList', data_path, '.set$'));
disp(files);

for n = 1:length(files)
    data = files{n};
    disp(data); 
    [filepath, name, ext] = fileparts(data);

    % Load your .set file
    EEG = pop_loadset([name ext], filepath);
    
    % Convert to FieldTrip format
    ft_data = eeglab2fieldtrip(EEG, 'preprocessing', 'none');  % 'none' keeps the data as-is
    
    % freq analysis
    cfg            = [];
    cfg.output     = 'pow';
    cfg.method     = 'mtmfft';       % or 'fft', 'mtmconvol' if time-frequency
    cfg.taper      = 'hanning';
    cfg.foilim     = [2 30];         % frequency range
    cfg.pad        = 'nextpow2';     % Freq bin 0.2Hz
    cfg.keeptrials = 'yes';             % crucial: preserve trial structure
    
    freq = ft_freqanalysis(cfg, ft_data);
    freqs = freq.freq;
    pow = freq.powspctrm;  % dims: [trials x channels x frequencies]
    
    
    % Define CoG function
    compute_CoG = @(f, a) sum(f .* a) / sum(a);
    
    % Get frequency bins and power
    freqs = freq.freq;
    pow   = freq.powspctrm;  % [trials x channels x freqs]
    
    % Define frequency range for CoG
    band_idx    = freqs >= 9 & freqs <= 11;
    band_freqs  = freqs(band_idx);
    band_freqs  = band_freqs(:);  % force column
    
    % Preallocate
    [nTrials, nChannels, ~] = size(pow);
    PAF        = nan(nTrials, nChannels);
    PAF_Power  = nan(nTrials, nChannels);
    
    % Compute PAF
    for tr = 1:nTrials
        for ch = 1:nChannels
            amp = squeeze(pow(tr, ch, band_idx));
            amp = amp(:);  % ensure column shape
            if all(isfinite(amp)) && sum(amp) > 0
                PAF(tr, ch) = compute_CoG(band_freqs, amp);
                [~, idx] = min(abs(freqs - PAF(tr, ch)));
                PAF_Power(tr, ch) = pow(tr, ch, idx);
            end
        end
    end
    
    
    % --- Average across epochs (per channel) ---
    PAF_mean = mean(PAF, 1, 'omitnan');
    PAF_Power_mean = mean(PAF_Power, 1, 'omitnan');
    
    % --- Output ---
    disp('Mean PAF per channel:');
    disp(PAF_mean);
    disp('Mean PAF Power per channel:');
    disp(PAF_Power_mean);
    
    % === Get channel labels from FieldTrip struct ===
    channel_labels = freq.label(:);               % cell array
    
    % === Create table for Excel ===
    T = table(channel_labels, PAF_mean(:), PAF_Power_mean(:), ...
        'VariableNames', {'Channel', 'Mean_PAF_Hz', 'Mean_PAF_Power'});
    
    % === Save to Excel ===
    excel_dir = [data_directory '/PAF_results_New.xlsx'];
    writetable(T, excel_dir, 'Sheet', name);
    fprintf('PAF results saved to PAF_results.xlsx\n');
end