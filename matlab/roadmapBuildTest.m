roadmapBuilder = RoadmapBuilder();
runner = CrazyflieRunner();

% ensure we are generating random inputs correctly
for i = 1:10
    [pitch, roll, ~] = roadmapBuilder.generate_random_inputs();
    assert (pitch < RoadmapBuilder.max_pitch);
    assert (pitch > RoadmapBuilder.min_pitch);
    assert (roll > RoadmapBuilder.min_roll);
    assert (roll < RoadmapBuilder.max_roll);
end

% move on to testing the Crazyflie Runner
initial_state = runner.get_initial_state(pitch, roll);
assert(initial_state(CrazyflieRunner.state_pitch_index) == pitch);
assert(initial_state(CrazyflieRunner.state_roll_index) == roll);

runner.initial_state = initial_state;

final_state = runner.get_final_state();
assert(final_state(CrazyflieRunner.state_roll_index) == 0);
assert(final_state(CrazyflieRunner.state_pitch_index) == 0);

% run through a simulation and then do sanity checks
test_u0 = [0 0 0 0 0 0 runner.cf_model.nominal_thrust]';
test_pitch = .2;
test_roll = .2;
[test_xt_result, test_ut_result] = runner.simulate(test_pitch, test_roll, test_u0);

assert(test_xt_result.tspan(2) == test_ut_result.tspan(2));
final_xt_position = test_xt_result.eval(test_xt_result.tspan(2));
assert(final_xt_position(CrazyflieRunner.state_pitch_index) < 0.001);
assert(final_xt_position(CrazyflieRunner.state_roll_index) < 0.001);