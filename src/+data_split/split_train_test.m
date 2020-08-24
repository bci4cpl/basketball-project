function [train_set, test_set] = split_train_test(eeg_array, test_idx_path)
    idx = load(test_idx_path);
    [train_set, test_set] = cellfun(@(x,y) split_struct_train_test(x,y),eeg_array, idx.tests,'un',0);
    validate_trian_test(idx.tests, test_set);
end

function [train, test] = split_struct_train_test(EEG, tests_idx)
    t_idx = {tests_idx.i8, tests_idx.i9};
    events_sr = extractfield(EEG.event, "SR"); events_sr(events_sr==0) = [];
    [trials_to_test, trials_exist] = cellfun(@(x) extract_test_trials(events_sr, EEG.nbchan, x),t_idx,'un',0);
    bool_test_trials = trials_to_test{1,1}+trials_to_test{end,end};
    
    train = pop_TBT(EEG,bool_test_trials,2,0.9,0);
    train_sr = extractfield(train.event, "SR"); train_sr(train_sr==0) = [];
    train.serials = train_sr;
    train_labels = extractfield(train.event, "Class"); train_labels(train_labels==0) = [];
    train.labels = train_labels;
    train.etc.origin_all_trials = EEG.trials;
    
    test = pop_TBT(EEG,~bool_test_trials,2,0.9,0);
    test_sr = extractfield(test.event, "SR"); test_sr(test_sr==0) = [];
    test.serials = test_sr;
    test_labels = extractfield(test.event, "Class"); test_labels(test_labels==0) = [];
    test.labels = test_labels;
    test.n8 = trials_exist{1,1}; test.n9 = trials_exist{end,end}; 
end

function [trials_to_test, trials_exist] = extract_test_trials(events_sr, nchan, test_trials_sr)
    trials_to_test = ismember(events_sr, test_trials_sr);
    trials_exist = sum(trials_to_test);
    trials_to_test = repmat(trials_to_test,nchan,1);
end

function [EEG] = stamp_eeg(EEG)
    sr = extractfield(EEG.event, "SR"); sr(sr==0) = [];
    EEG.serials = sr;
    labels = extractfield(EEG.event, "Class"); labels(labels==0) = [];
    EEG.labels = labels;
    EEG.etc.origin_all_trials = EEG.trials;
end

function [] = validate_trian_test(idx, test_set)
    test_set_trials = cell2mat(cellfun(@(x) [length(x.i8); length(x.i9)],idx,'un',0));
    num_test_trials = sum(test_set_trials,2);
    test_num_8 = num_test_trials(1,1); test_num_9 = num_test_trials(end,end);
    overall_tests_trials = cell2mat(cellfun(@(x) [x.n8; x.n9], test_set,'un',0));
    num_current_test_trials = sum(overall_tests_trials,2); 
    test_trails_8 = num_current_test_trials(1,1); test_trails_9 = num_current_test_trials(end,end);
    
    rat_curr_from_origin = sum(num_current_test_trials)/sum(num_test_trials);
    rat_curr8_from_origin_8 = test_trails_8/test_num_8;
    rat_curr9_from_origin_9 = test_trails_9/test_num_9;
    
    disp("Current Test set: " + num2str(test_trails_8 + test_trails_9) + " trials, " + num2str(rat_curr_from_origin)...
        + " form desinated test's trials, "+ sum(num_test_trials) + "." + newline... 
        + "Good shots: " + num2str(test_trails_8) + ", " + num2str(rat_curr8_from_origin_8)...
        + " from all test's good shots (" + num2str(test_num_8) + ")," + newline...
        + "Bad shots: " + num2str(test_trails_9) + ", " + num2str(rat_curr9_from_origin_9)...
        + " from all test's bad shots (" + num2str(test_num_9) + ").")

    if rat_curr_from_origin < 0.6
        warning("Current test set is lower than 60% from designated test set.")
    elseif rat_curr8_from_origin_8 < 0.5
        warning("Current test set good shots is lower than 50% from designated amount of good shots.")
    elseif rat_curr9_from_origin_9 < 0.5
        warning("Current test set bad shots is lower than 50% from designated amount of good shots.")
    end            
end
