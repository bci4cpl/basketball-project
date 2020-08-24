



% init repo paths
repo.dir = "basketball-project";
repo.path = strcat(extractBetween(mfilename('fullpath'),"",repo.dir), repo.dir);
repo.src = strcat(repo.path, "\src\");
repo.data = strcat(repo.path, "\data\");
addpath(repo.src)

% init
CURRENT_VERSION = 'v99';
del = Utils.OS.get_delimiter();

% load current version's pipeline input configs
pipeline_input_dir = strcat(repo.data,CURRENT_VERSION);
pipeline_input_cfg = Utils.OS.load_files(pipeline_input_dir, "ini");
cfg = Utils.OS.ini2struct(pipeline_input_cfg);

% check previous pipeline output
prev = Utils.OS.load_files(pipeline_input_dir, 'mat');

if isempty(prev) % there is no previous pipeline output, generate one
    % get all .set input files
    google_drive_input_dir = strcat(Utils.OS.get_current_user_dir(), "Google Drive",...
        del, "M&M Team", del, "all data basketball", del, "raw_data_sets");...
        % its a bit ugly, but it works. we set the input dir for our teams
        % google drive 'raw_data_set' folder.
    input_set_files = Utils.OS.load_files(google_drive_input_dir, "set");

    eeglab
    %eeg_array = cellfun(@(x) preprocess_pipeline(cfg, x, 0, ALLEEG, EEG),input_set_files,'un',0);
    load(strcat(pipeline_input_dir,"\eeg_array.mat"))
    test_idx_path = strcat(repo.src, "+data_split\test_idx.mat");
    [train_set, test_set] = data_split.split_train_test(eeg_array, test_idx_path);
else
    prev = load(prev);
    
end

