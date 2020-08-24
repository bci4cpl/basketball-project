function [files] = load_files(dir_path, file_type)
    dir_content = dir(dir_path);
    files = {dir_content(cellfun(@(x) endsWith(x,strcat('.', file_type)),{dir_content(:).name})).name};
    files = cellfun(@(x) strcat(dir_path, '\', x),files);
end