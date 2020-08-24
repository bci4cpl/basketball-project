function [d] = get_data(S, f)
    d = extractfield(S, f);
    d = d(d~=0);
end