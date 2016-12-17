function xtraj = simulatePitchAndRoll(pitch, roll)
    queryManager = TrajectoryQueryManager();    

    % initialize the crazyflie runner to get access to its method to
    % construct an initial state
    runner = CrazyflieRunner();
    initialState = runner.get_initial_state(pitch, roll);

    % convert the state into a static vector
    initialStateVector = zeros(initialState.size);
    for idx=1:initialState.size(1)
        initialStateVector(idx) = initialState(idx);
    end

    % simulate our solution on the initial state
    xtraj = queryManager.get_simulated_xtraj(initialStateVector);
    
    % visualize the trajectory the quad will take
    queryManager.visualizeTrajectory(xtraj);
end