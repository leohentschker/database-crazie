function [xtraj,utraj] = test()
    b = RoadmapBuilder();
    runner = CrazyflieRunner();
    numIters = 10;
    deviations = zeros(numIters, 1);
    
    for idx=1:numIters
        [pitch, roll, u0] = b.generate_random_inputs();
        [xt, ~] = runner.simulate(pitch, roll, u0);
        xf = xt.eval(xt.tspan(2));

        end_pitch = xf(CrazyflieRunner.state_pitch_index);
        end_roll = xf(CrazyflieRunner.state_roll_index);
        display(end_pitch)
        deviations(idx) = sqrt(end_pitch * end_pitch + end_roll * end_roll);
        
        display(mean(deviations));
    end
end