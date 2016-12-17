classdef LQRSimulator

    properties(Constant)
        % initialize Q and Qf to the same values determined by Landry
        %Q = diag([300 300 300 2.5 2.5 300 .001 .001 .001 .001 .001 5])
        %Qf = diag([300 300 300 2.5 2.5 300 .001 .001 .001 .001 .001 5])
        Q = diag([100 100 1000000 2.5 2.5 .001 .001 .001 .001 .001 .001 .001])
        Qf = diag([100 100 1000000 10000 10000 .001 .001 .001 .001 .001 .001 .001])
        R = eye(7)

    end
    
    properties
        model = CrazyflieModel()
        r = RigidBodyManipulator('crazyflie.urdf', struct('floating', true))
    end
    
    methods
        % get the ideal trajectory and velocity for the object
        function [ideal_xtraj, ideal_utraj] = get_ideal_traj(obj, initial_state)
            % extract the pitch and the roll from the initial position
            pitch = initial_state(TrajectoryQueryManager.pitch_index);
            roll = initial_state(TrajectoryQueryManager.roll_index);

            % determine the file that most closely matches the pitch and
            % roll
            traj_file = TrajectoryQueryManager.get_traj_file(pitch, roll);
            
            % load the ideal_trajectory variable from the traj_file
            load(traj_file);
            
            ideal_xtraj = ideal_traj.xtraj;
            ideal_utraj = ideal_traj.utraj;
        end
        
        function system = get_system(obj, ideal_xtraj, ideal_utraj)
            % set the correct output frames
            ideal_xtraj = ideal_xtraj.setOutputFrame(obj.model.getStateFrame);
            ideal_utraj = ideal_utraj.setOutputFrame(obj.model.getInputFrame);

            % run tvlqr to get the controller
            options.angle_flag = [0 0 0 1 1 1 0 0 0 0 0 0]';
            [controller,~] = tvlqr(obj.model,ideal_xtraj,ideal_utraj,obj.Q,obj.R,obj.Qf,options);

            % set the output frame as the input frame of the model
            controller = controller.setOutputFrame(obj.model.getInputFrame);
            controller = controller.setInputFrame(obj.model.getOutputFrame);

            % construct the system based on the controller
            system = feedback(obj.model, controller);
        end

        function systraj = simulate_system(obj, system, initial_state, total_time)

            % construct the system trajectory
            systraj = system.simulate([0 total_time], initial_state);

            % set the output frame
            systraj = systraj.setOutputFrame(getStateFrame(obj.model.manip));
        end
        
        function visualize_system(obj, systraj)
            % make the visualizer and play back the trajectory
            v = obj.model.manip.constructVisualizer();
            v.playback(systraj, struct('slider', true));
        end

        function systraj = simulate_initial_state(obj, initial_state)

            % determine the ideal trajectory
            [ideal_xtraj, ideal_utraj] = obj.get_ideal_traj(initial_state);

            % get the system for the trajectory
            system = obj.get_system(ideal_xtraj, ideal_utraj);

            % simulate the system for the specified amount of time
            total_time = ideal_utraj.tspan(2);

            systraj = obj.simulate_system(system, initial_state, total_time);
            
        end
    end
end