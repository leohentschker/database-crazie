function findAverageApproximateDeviation
    b = RoadmapBuilder();
    runner = CrazyflieRunner();
    numIters = 100;
    totalDeviation = 0;
    queryManager = TrajectoryQueryManager();
    
    for idx=1:numIters
        [pitch, roll, ~] = b.generate_random_inputs();
        initialState = runner.get_initial_state(pitch, roll);

        % convert the state into a static vector
        initialStateVector = zeros(initialState.size);
        for idx2=1:initialState.size(1)
            initialStateVector(idx2) = initialState(idx2);
        end

        % simulate our solution on the initial state
        simulated_xtraj = queryManager.get_simulated_xtraj(initialStateVector);
        
        xf = simulated_xtraj.eval(simulated_xtraj.tspan(2));

        end_pitch = xf(CrazyflieRunner.state_pitch_index);
        end_roll = xf(CrazyflieRunner.state_roll_index);

        totalDeviation = totalDeviation + sqrt(end_pitch * end_pitch + end_roll * end_roll);
        
        avg_dev = totalDeviation / idx;
        display(avg_dev, 'MEAN DEVIATION');
    end
end