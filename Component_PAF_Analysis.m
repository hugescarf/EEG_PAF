
files = cellstr(spm_select('FPList', 'C:\Users\elian2\Desktop\EEG_practice_data\epoched', 'phibopracticefiltered_trimmed.set$'));
disp(files);

for n = 1:length(files)
    data = files{n};
    disp(data); 
    [filepath, name, ext] = fileparts(data);

    % === Load EEG set file with ICA ===
    EEG = pop_loadset([name ext], filepath);

    % === Convert to FieldTrip format, preserving components ===
    ft_data = eeglab2fieldtrip(EEG, 'componentanalysis', 'none');  % components as channels

    % === Frequency analysis on components ===
    cfg            = [];
    cfg.output     = 'pow';
    cfg.method     = 'mtmfft';
    cfg.taper      = 'hanning';
    cfg.foilim     = [2 40];     % frequency range
    cfg.pad        = 'nextpow2';  % for ~0.2 Hz bins
    cfg.keeptrials = 'yes';       % preserve trial info
    freq = ft_freqanalysis(cfg, ft_data);

    % === Plot average power spectra for each component ===
    avg_pow = squeeze(mean(freq.powspctrm, 1, 'omitnan'));  % average over trials
    nComp = size(avg_pow, 1);

    figure;
    for k = 1:nComp
        subplot(ceil(sqrt(nComp)), ceil(sqrt(nComp)), k);
        plot(freq.freq, avg_pow(k, :));
        title(['IC ' num2str(k)]);
        xlabel('Hz'); ylabel('Power');
    end
    sgtitle(['Mean Power Spectrum per Component: ' name]);

    % === Define CoG computation ===
    compute_CoG = @(f, a) sum(f .* a) / sum(a);

    freqs = freq.freq;
    pow   = freq.powspctrm;  % dims: [trials x components x frequencies]

    band_idx    = freqs >= 9 & freqs <= 11;
    band_freqs  = freqs(band_idx);
    band_freqs  = band_freqs(:);  % ensure column vector

    % === Preallocate ===
    [nTrials, nComps, ~] = size(pow);
    PAF        = nan(nTrials, nComps);
    PAF_Power  = nan(nTrials, nComps);

    % === Compute PAF per trial and component ===
    for tr = 1:nTrials
        for comp = 1:nComps
            amp = squeeze(pow(tr, comp, band_idx));
            amp = amp(:);  % column
            if all(isfinite(amp)) && sum(amp) > 0
                PAF(tr, comp) = compute_CoG(band_freqs, amp);
                [~, idx] = min(abs(freqs - PAF(tr, comp)));
                PAF_Power(tr, comp) = pow(tr, comp, idx);
            end
        end
    end

    % === Average across epochs ===
    PAF_mean = mean(PAF, 1, 'omitnan');
    PAF_Power_mean = mean(PAF_Power, 1, 'omitnan');

    % === Component labels ===
    comp_labels = arrayfun(@(x) sprintf('IC%02d', x), 1:nComps, 'UniformOutput', false)';

    % === Create results table ===
    T = table(comp_labels, PAF_mean(:), PAF_Power_mean(:), ...
        'VariableNames', {'Component', 'Mean_PAF_Hz', 'Mean_PAF_Power'});

    % === Export to Excel ===
    output_file = fullfile('C:\Users\elian2\Desktop\EEG_practice_data\', 'Component_PAF_Results.xlsx');
    writetable(T, output_file, 'Sheet', name);
    fprintf('Component-level PAF results saved to %s (Sheet: %s)\n', output_file, name);
end
