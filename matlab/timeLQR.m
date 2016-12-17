function timeLQR

    runner = CrazyflieRunner();
    lqr = LQRSimulator();

    totalIterations = 1;
    totalTime = 0;

    for x=1:totalIterations
        tic

        % construct an initial state from the pitch and roll
        initialState = runner.get_initial_state(.2, .2);

        % convert the state into a static vector
        initialStateVector = zeros(initialState.size);
        for idx=1:initialState.size(1)
            initialStateVector(idx) = initialState(idx);
        end

        % simulate our solution on the initial state
        lqr.simulate_initial_state(initialStateVector);
        toc
        totalTime = totalTime + toc;
    end
    avgTime = totalTime / totalIterations;
    display(avgTime, 'avgTime');
end