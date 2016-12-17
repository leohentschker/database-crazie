function systraj = simulatePitchAndRollLQR(pitch, roll)
    lqr = LQRSimulator();

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
    systraj = lqr.simulate_initial_state(initialStateVector);
    
    lqr.visualize_system(systraj);
    
    display(systraj.eval(systraj.tspan(2)) - initialStateVector, 'diff');
end