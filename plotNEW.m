file_path = spm_select('FPList', 'C:\Users\elian2\Desktop\EEG_practice_data', 'PAF_results_New.xlsx');
disp(file_path);

% Load sheet names
[~, sheet_names] = xlsfinfo(file_path);

% Initialize data
x_binary = [];  % 0 for EoS, 1 for EcS
paf_values = [];

% Extract data
for i = 1:length(sheet_names)
    sheet = sheet_names{i};
    data = readtable(file_path, 'Sheet', sheet);

    if ~ismember('Mean_PAF_Hz', data.Properties.VariableNames)
        warning('Sheet "%s" skipped: no Mean_PAF_Hz column.', sheet);
        continue;
    end

    % Label and collect
    n = length(data.Mean_PAF_Hz);
    if contains(lower(sheet), 'eos')
        x_binary = [x_binary; zeros(n, 1)];
    elseif contains(lower(sheet), 'ecs')
        x_binary = [x_binary; ones(n, 1)];
    else
        warning('Sheet "%s" does not match "eos" or "ecs". Skipped.', sheet);
        continue;
    end
    paf_values = [paf_values; data.Mean_PAF_Hz];
end

% === GROUP-LEVEL COMPARISON  ===

% Initialize per-subject summary
eos_subject_means = [];
ecs_subject_means = [];
subject_ids_eos = {};
subject_ids_ecs = {};

for i = 1:length(sheet_names)
    sheet = sheet_names{i};
    data = readtable(file_path, 'Sheet', sheet);

    disp(['Reading sheet: ' sheet]);
    
    if ismember('Mean_PAF_Hz', data.Properties.VariableNames)
        disp('  → Found Mean_PAF_Hz!');
        disp(['  → Subject mean: ' num2str(mean(data.Mean_PAF_Hz))]);
    else
        disp('  → Mean_PAF_Hz not found.');
    end

    % Get subject-level mean
    subj_mean = mean(data.Mean_PAF_Hz);

    % Store based on condition
    if contains(lower(sheet), 'eos')
        eos_subject_means(end+1,1) = subj_mean;
        subject_ids_eos{end+1,1} = sheet;
    elseif contains(lower(sheet), 'ecs')
        ecs_subject_means(end+1,1) = subj_mean;
        subject_ids_ecs{end+1,1} = sheet;
    end
end
disp(subject_ids_eos);
disp(subject_ids_ecs);

% Extract subject name by removing the '_eos' or '_ecs' part
extract_subject = @(name) regexprep(lower(name), '_eos|_ecs', '');
subject_ids_eos = cellfun(extract_subject, subject_ids_eos, 'UniformOutput', false);
subject_ids_ecs = cellfun(extract_subject, subject_ids_ecs, 'UniformOutput', false);


% Match EoS and EcS subjects
[common_ids, idx_eos, idx_ecs] = intersect(subject_ids_eos, subject_ids_ecs);
eos_vals = eos_subject_means(idx_eos);
ecs_vals = ecs_subject_means(idx_ecs);

% Paired t-test
[~, pval, ~, stats] = ttest(eos_vals, ecs_vals);

% Bar plot with error bars
mean_vals = [mean(eos_vals), mean(ecs_vals)];
sem_vals = [std(eos_vals)/sqrt(length(eos_vals)), std(ecs_vals)/sqrt(length(ecs_vals))];

figure;
bar(1:2, mean_vals, 0.5);
hold on;
errorbar(1:2, mean_vals, sem_vals, '.k', 'LineWidth', 1.5);
xticks([1 2]);
xticklabels({'EoS', 'EcS'});
ylabel('Mean PAF (Hz)');
title(sprintf('Group Mean PAF (paired t-test, p = %.4f)', pval));
grid on;



