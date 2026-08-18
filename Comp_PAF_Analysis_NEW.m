files = cellstr(spm_select('FPList', 'C:\Users\elian2\Desktop\EEG_practice_data\epoched', '.set$'));
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
    cfg.foilim     = [2 40];
    cfg.pad        = 'nextpow2';
    cfg.keeptrials = 'yes';
    freq = ft_freqanalysis(cfg, ft_data);

    % === Plot average power spectra for each component ===
    avg_pow = squeeze(mean(freq.powspctrm, 1, 'omitnan'));  % [components x freqs]
    nComp = size(avg_pow, 1);

    % figure;
    % for k = 1:nComp
    %     subplot(ceil(sqrt(nComp)), ceil(sqrt(nComp)), k);
    %     plot(freq.freq, avg_pow(k, :));
    %     title(['IC ' num2str(k)]);
    %     xlabel('Hz'); ylabel('Power');
    % end
    % sgtitle(['Mean Power Spectrum per Component: ' name]);

    % === Select best component with strongest mean alpha power in 9–11 Hz ===
    alpha_idx = freq.freq >= 8 & freq.freq <= 12;
    alpha_power = mean(avg_pow(:, alpha_idx), 2);  % average alpha power per component
    [~, best_comp] = max(alpha_power);  % index of best alpha component
    disp(['Best alpha component: IC' num2str(best_comp)]);

    % === Define CoG computation ===
    compute_CoG = @(f, a) sum(f .* a) / sum(a);

    freqs = freq.freq;
    pow   = freq.powspctrm;  % [trials x components x frequencies]
    band_idx = freqs >= 8 & freqs <= 12;
    band_freqs = freqs(band_idx);
    band_freqs = band_freqs(:);

    % === Preallocate for best component only ===
    nTrials = size(pow, 1);
    PAF = nan(nTrials, 1);
    PAF_Power = nan(nTrials, 1);

    for tr = 1:nTrials
        amp = squeeze(pow(tr, best_comp, band_idx));
        amp = amp(:);
        if all(isfinite(amp)) && sum(amp) > 0
            PAF(tr) = compute_CoG(band_freqs, amp);
            [~, idx] = min(abs(freqs - PAF(tr)));
            PAF_Power(tr) = pow(tr, best_comp, idx);
        end
    end

    % === Mean across trials ===
    PAF_mean = mean(PAF, 'omitnan');
    PAF_Power_mean = mean(PAF_Power, 'omitnan');

    % === Output ===
    T = table({['IC' num2str(best_comp)]}', PAF_mean, PAF_Power_mean, ...
        'VariableNames', {'Best_Component', 'Mean_PAF_Hz', 'Mean_PAF_Power'});

    output_file = fullfile('C:\Users\elian2\Desktop\EEG_practice_data\', 'Component_PAF_Results_SelectedIC.xlsx');
    writetable(T, output_file, 'Sheet', name);
    fprintf('PAF results (best component) saved to %s (Sheet: %s)\n', output_file, name);
end
