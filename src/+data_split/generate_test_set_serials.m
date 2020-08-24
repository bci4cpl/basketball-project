function [] = generate_test_set_serials()
% generate_test_set_serials - this function generate test set from all
%   recorded set. we check the overall amount of correct trials, and select
%   randomly a 25% portion for test. we maintain the good shots  vs misses
%   ratio in the test size.

    % load needed paths
    addpath(pwd);
    addpath("c:\ws\gitt\pipeline");
    
    % load files from sets foleder
    files = Utils.OS.load_input_files([".set"], 'dir');
    [ALLEEG, EEG, CURRENTSET, ALLCOM] = eeglab;

    % 
    for i=1:length(files)
       [ALLEEG, EEG, CURRENTSET] = data_split.check_data(files(i).file, ALLEEG, EEG);
       eeg_array{:,i} = EEG;
    end
    
    fields = {"SR", "Class"}; fields2 = {"subject", "session"};
    all_trials = cellfun(@(x) cell2mat(cellfun(@(a) data_split.get_data(x.event,a),fields,'un',0)')',eeg_array,'un',0);
    all_details = cellfun(@(x) cell2mat(cellfun(@(a) data_split.get_data(x,a),fields2,'un',0)')',eeg_array,'un',0);
    all_data = cellfun(@(x,y) [x, repmat(y,size(x,1),1)], all_trials,all_details,'un',0);
    all_data = cell2mat(all_data');
    all_metadata = [all_data, (1:size(all_data,1))'];
    all_8 = size(all_metadata(all_metadata(:,2)==8,:),1);
    all_9 = size(all_metadata(all_metadata(:,2)==9,:),1);
    
    total = all_8 + all_9;
    prop_9 = all_9/total;
    prop_8 = all_8/total;
    test_set_size = total/4;

    tests = cellfun(@(x,y) data_split.get_test_idx_per_recording(x, y, all_9, prop_9*test_set_size, all_8, prop_8*test_set_size),all_trials,all_details,'un',0);
    save('test_idx','tests');
end