function [user_dir] = get_current_user_dir()
    current_user = getenv('username');
    if isunix
        user_dir = strcat('/usr/', current_user, '/');
    else
        user_dir = strcat('C:\Users\', current_user, '\');
    end
end