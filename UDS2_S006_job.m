% Specify directory for SPM.mat
spm_dir = '/ifs/loni/faculty/kjann/UDS_Project/UDS2/DO_VOL_NEW/SPM_FILES/UDS2_S006/';

% Initialize batch
spm('defaults', 'FMRI');
spm_jobman('initcfg');
matlabbatch = {};

% Set up directory and timing
matlabbatch{1}.spm.stats.fmri_spec.dir = {spm_dir};
matlabbatch{1}.spm.stats.fmri_spec.timing.units = 'secs';
matlabbatch{1}.spm.stats.fmri_spec.timing.RT = 1;
matlabbatch{1}.spm.stats.fmri_spec.timing.fmri_t = 16;
matlabbatch{1}.spm.stats.fmri_spec.timing.fmri_t0 = 8;

% Set up scans
matlabbatch{1}.spm.stats.fmri_spec.sess.scans = cell(1450,1);
for i = 1:1450
    matlabbatch{1}.spm.stats.fmri_spec.sess.scans{i} = ['/ifs/loni/faculty/kjann/UDS_Project/UDS2/NIFTI/UDS2_S006/rfMRI_UDS_AP_0007/swufUDS2_S006_4D.nii,' num2str(i)];
end

% Define types of contractions
contractionTypes = {'VOL', 'DO'};

% Given onset times for each phase in each contraction
contractions = [137.60 147.60 176.20 240.50 304.50;
585.80 595.80 610.70 717.20 738.30;
921.30 931.30 938.70 971.60 979.70;
983.40 993.40 1017.10 1049.30 1059.60;
1308.50 1318.50 1335.80 1434.10 1451.20];

% Round contraction times to the nearest integer
contractions = round(contractions);

% Define rest times
rest_times = [1, 270, 720, 1050, 1440;
              30, 300, 750, 1080, 1450];

% Create condition names
conditionNames = {'Early', 'Rise', 'Plateau', 'Fall', 'Rest'};

% Voluntary contraction start times
voluntary_times = [150, 600, 930, 1320];

% Initialize matrix to store the type of each contraction (1 = voluntary, 2 = involuntary)
contractionTypeIndexes = ones(1, size(contractions, 1))*2;

% Check each contraction to see if it is voluntary
for i = 1:size(contractions, 1)
    % If the rise of the contraction is within 10 seconds of a voluntary time, mark it as voluntary
    if any(abs(contractions(i, 2) - voluntary_times) <= 10)
        contractionTypeIndexes(i) = 1;
    end
end

% Initialize condition map
conditions = containers.Map('KeyType', 'char', 'ValueType', 'any');

% Iterate over each contraction
for i = 1:size(contractions, 1)
    % Get the type of this contraction
    typeIndex = contractionTypeIndexes(i);
    
    % Iterate over each phase in the contraction
    for j = 1:(length(conditionNames) - 1)
        % Get the condition name
        conditionName = [conditionNames{j}, '_', contractionTypes{typeIndex}];
        
        % Check if this condition already exists
        if conditions.isKey(conditionName)
            % If it exists, add the new onset and duration to the existing condition
            condition = conditions(conditionName);
            condition.onset = [condition.onset, contractions(i, j)];
            condition.duration = [condition.duration, contractions(i, j+1) - contractions(i, j)];
        else
            % If it doesn't exist, create a new condition
            condition = struct('name', conditionName, 'onset', [contractions(i, j)], 'duration', [contractions(i, j+1) - contractions(i, j)], 'tmod', 0, 'pmod', struct('name', {}, 'param', {}, 'poly', {}), 'orth', 1);
        end
        
        % Update the condition in the map
        conditions(conditionName) = condition;
    end
end

% Initialize Rest condition
restCondition = struct('name', 'Rest', 'onset', [], 'duration', [], 'tmod', 0, 'pmod', struct('name', {}, 'param', {}, 'poly', {}), 'orth', 1);

% Iterate over rest periods
for k = 1:size(rest_times, 2)
    % Check if rest period overlaps with any contraction
    isOverlapping = any((rest_times(1, k) >= contractions(:, 1) & rest_times(1, k) <= contractions(:, end)) | ...
                        (rest_times(2, k) >= contractions(:, 1) & rest_times(2, k) <= contractions(:, end)));
    
    % If it does not overlap, add it to the restCondition
    if ~isOverlapping
        restCondition.onset = [restCondition.onset, rest_times(1, k)];
        restCondition.duration = [restCondition.duration, rest_times(2, k) - rest_times(1, k)];
    end
end

% Add the rest condition to the conditions map
conditions('Rest') = restCondition;

% Initialize conditions for matlabbatch
matlabbatch{1}.spm.stats.fmri_spec.sess.cond = struct('name', {}, 'onset', {}, 'duration', {}, 'tmod', 0, 'pmod', struct('name', {}, 'param', {}, 'poly', {}), 'orth', 1);

% Get all conditions from the map
conditionValues = values(conditions);

% Add the conditions to matlabbatch
for i = 1:length(conditionValues)
    matlabbatch{1}.spm.stats.fmri_spec.sess.cond(i) = conditionValues{i};
end

% Rest of your script here
matlabbatch{1}.spm.stats.fmri_spec.sess.multi = {''};
matlabbatch{1}.spm.stats.fmri_spec.sess.regress = struct('name', {}, 'val', {});
matlabbatch{1}.spm.stats.fmri_spec.sess.multi_reg = {'/ifs/loni/faculty/kjann/UDS_Project/UDS2/NIFTI/UDS2_S006/rfMRI_UDS_AP_0007/rp_fUDS2_S006_4D.txt'};
matlabbatch{1}.spm.stats.fmri_spec.sess.hpf = 128;
matlabbatch{1}.spm.stats.fmri_spec.fact = struct('name', {}, 'levels', {});
matlabbatch{1}.spm.stats.fmri_spec.bases.hrf.derivs = [0 0];
matlabbatch{1}.spm.stats.fmri_spec.volt = 1;
matlabbatch{1}.spm.stats.fmri_spec.global = 'None';
matlabbatch{1}.spm.stats.fmri_spec.mthresh = 0.8;
matlabbatch{1}.spm.stats.fmri_spec.mask = {''};
matlabbatch{1}.spm.stats.fmri_spec.cvi = 'AR(1)';

% Run SPM job
spm_jobman('run', matlabbatch)


