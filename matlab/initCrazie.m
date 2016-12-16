% function that I use to setup my environment
function initCrazie()
    % store the current directory
    cwd = pwd;
    cd ~/drake-distro/drake;
    
    % add drake to the path
    addpath_drake;
    
    % go back to the current directory
    cd(cwd);
end