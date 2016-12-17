function testDircolDeviation
    files = dir('solved_trajectories/*.mat');
    
    numFiles = 10;
    deviations = zeros(numFiles, 1);

    for i=1:numFiles
        file = files(i);
        fileName = strcat('solved_trajectories/', file.name);
        display(fileName);
        load(fileName);
        finalPosition = ideal_traj.xtraj.eval(ideal_traj.xtraj.tspan(2));
        
        deviations(i) = sqrt(finalPosition(4) * finalPosition(4) + finalPosition(5) * finalPosition(5));
    end
    
    display(mean(deviations));
end