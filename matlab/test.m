function [xtraj, utraj] = test()
    builder = RoadmapBuilder();
    u0 = [0 0 0 0 0 0 builder.runner.cf_model.nominal_thrust]';

    [xtraj, utraj] = builder.runner.simulate(.2, -.2, u0);

    r = RigidBodyManipulator('crazyflie.urdf', struct('floating', true));
    xtraj = setOutputFrame(xtraj, getStateFrame(r));
    vis = r.constructVisualizer();
    vis.playback(xtraj, struct('slider', true));
end