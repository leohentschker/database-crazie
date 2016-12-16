classdef TrajectoryQueryManager

    properties(Constant)
        pitch_index = 5
        roll_index = 4
    end
    
    properties
        r = RigidBodyManipulator('crazyflie.urdf', struct('floating', true))
        runner = CrazyflieRunner()
        initialState
    end
    
    methods(Static)

        function traj_file = get_traj_file(pitch, roll)
            % run the python script to get the file
            command = ['/usr/local/bin/python ../python_interface/manage.py find_closest_trajectory --pitch ', num2str(pitch), ' --roll ', num2str(roll)];
            [~, traj_file] = system(command);
            
            % strip the trailing newline
            traj_file = traj_file(1: length(traj_file) - 1);

        end
    end
    
    methods

        % given a velocity trajectory and an initial position,
        % determine the resulting x trajectory
        function systraj = simulateTrajectory(obj, utraj, initial_state)
            
            utraj = utraj.setOutputFrame(obj.runner.cf_model.getInputFrame);

            % construct the dynamical system
            sys = cascade(utraj, obj.runner.cf_model);

            % simulate the motion of the quad
            systraj = simulate(sys, utraj.tspan, initial_state);

            % set the correct output frame of the trajectory
            systraj = setOutputFrame(systraj, getStateFrame(obj.r));
        end
        
        % takes in the previous pitch and roll and then uses the solved
        % trajectories to find the closest and best one
        function utraj = get_optimal_controls(obj, pitch, roll)

            % get the file name
            ideal_traj_file = obj.get_traj_file(pitch, roll);

            % load the new trajectory as a variable
            load(ideal_traj_file);

            % set the correct input on the utraj for the cascade
            utraj = setOutputFrame(ideal_traj.utraj, getInputFrame(obj.runner.cf_model));
        end

        function xtraj = get_simulated_xtraj(obj, initialState)

            % get the best trajectory we have for the initial state
            utraj = obj.get_optimal_controls(initialState(obj.pitch_index), initialState(obj.roll_index));

            % determine the x trajectory with the initial position and
            % velocity trajectory
            xtraj = obj.simulateTrajectory(utraj, initialState);
            
        end

    end
end