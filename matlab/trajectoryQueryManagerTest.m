tqm = TrajectoryQueryManager();
runner = CrazyflieRunner();

test_pitch = .2;
test_roll = .2;

% check that we can get an associated trajectory from pitch and roll
% this checks the connection to the python script. If this fails, then
% there is something wrong with the link between MATLAB and python
traj_file = tqm.get_traj_file(test_pitch,test_roll);

% test the query manager for some initial state
initialState = runner.get_initial_state(test_pitch, test_roll);

% convert the state into a static vector as required
initialStateVector = zeros(initialState.size);
for idx=1:initialState.size(1)
    initialStateVector(idx) = initialState(idx);
end

% get a trajectory from the query manager
xtraj = tqm.get_simulated_xtraj(initialStateVector);

initialx = xtraj.eval(0);
for idx=1:length(initialStateVector)
    
    assert(abs(initialx(idx) - initialStateVector(idx)) < .01);
end
