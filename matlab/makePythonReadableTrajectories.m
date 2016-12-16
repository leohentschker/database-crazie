function python_readable_traj = makePythonReadableTrajectories()

unreadable_files = dir('solved_trajectories/*.mat');

for file_ind=1:length(unreadable_files)
    
    % extract the name of the file
    file_name = unreadable_files(file_ind).name; 

    % construct where to find the file and where to save it
    unreadable_traj_path = strcat('solved_trajectories/', file_name);
    readable_traj_path = strcat('python_readable_trajectories/', file_name);

    % load in the trajectory
    load(unreadable_traj_path);

    % construct the cell arrays to store the trajectories
    python_readable_traj = struct('xtraj', [], 'utraj', []);
    for idx=1:ideal_traj.xtraj.length
        python_readable_traj.xtraj{idx} = ideal_traj.xtraj.eval(idx);
        python_readable_traj.utraj{idx} = ideal_traj.utraj.eval(idx);
    end
    
    % save the readable trajectory
    save(readable_traj_path, 'python_readable_traj');

end