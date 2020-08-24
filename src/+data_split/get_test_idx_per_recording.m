function [idx] = get_test_idx_per_recording(m, subsess, totN9, testN9, totN8, testN8)
    trials_9 = m(m(:,2)==9,:);
    trials_8 = m(m(:,2)==8,:);
    idx.i9 = get_idx(trials_9, round(testN9*(size(trials_9,1)/totN9)));
    idx.n9 = size(trials_9,1);
    idx.i8 = get_idx(trials_8, round(testN8*(size(trials_8,1)/totN8)));
    idx.n8 = size(trials_8,1);
    idx.details = subsess;
end

function [idx] = get_idx(m, num_of_trials)
    positions = randperm(size(m,1),num_of_trials);
    idx = m(positions,1);
end