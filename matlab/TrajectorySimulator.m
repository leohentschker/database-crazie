classdef TrajectorySimulator

    properties(Constant)
        pitch_index = 5
        roll_index = 4
    end
    
    properties
        r = RigidBodyManipulator('crazyflie.urdf', struct('floating', true))
        runner = CrazyflieRunner()
    end
    
    methods(Static)
        function traj_file = get_traj_file(pitch, roll)
            % run the python script to get the file
            command = ['cd ../api_interface && /usr/local/bin/python manage.py find_closest_trajectory --pitch ', num2str(pitch), ' --roll ', num2str(roll)];
            [~, traj_file] = system(command);
            
            % strip the trailing newline
            traj_file = traj_file(1: length(traj_file) - 1);

        end
    end
    
    methods

        % given a velocity trajectory and an initial position,
        % determine the resulting x trajectory
        function xtraj = simulateTrajectory(obj, utraj, initial_pos)
            
            utraj = utraj.setOutputFrame(obj.runner.cf_model.getInputFrame);

            % construct the dynamical system
            sys = cascade(utraj, obj.runner.cf_model);
            
            % simulate the motion of the quad
            xtraj = simulate(sys, utraj.tspan, initial_pos);
            
            % set the correct output frame of the trajectory
            xtraj = setOutputFrame(xtraj, getStateFrame(obj.r));
        end
        
        % takes in the previous pitch and roll and then uses the solved
        % trajectories to find the closest and best one
        function utraj = get_new_utraj(obj, pitch, roll)

            % get the file name
            utraj_file = obj.get_traj_file(pitch, roll);

            % load the new trajectory as a variable
            load(utraj_file);
            
            % set the correct input on the utraj for the cascade
            utraj = setOutputFrame(utraj, getInputFrame(obj.runner.cf_model));
        end
        
        % construct the expected x-trajectory
        % based on drake/drake/examples/Atlas/runDRCDoorTask.m
        function combined_utraj = constructSimulatedTrajectory(obj, utraj, initial_pos, step_limit)

            % initialize the total trajectory as being empty
            combined_utraj = [];
            
            for idx = 1:step_limit

                % simulate the velocity and initial position
                xtraj = obj.simulateTrajectory(utraj, initial_pos);
                
                % determine the time breaks within the x-trajectory
                xtraj_breaks = xtraj.getBreaks();

                % update the initial position to be the last step in the
                % trajectory
                initial_pos = xtraj.eval(xtraj_breaks(end));
                
                % if we have no trajectory yet, initialize it to be the
                % first value we get
                if isempty(combined_utraj)
                    combined_utraj = utraj;
                
                % otherwise, we add the new trajectory to what we
                % previously had
                else
                    % get the breaks for the total trajectory
                    combined_utraj_breaks = combined_utraj.getBreaks();
                    
                    % get the breaks for the current velocity trajectory
                    utraj_breaks = utraj.getBreaks();
                    
                    % shift the velocity by the required offset
                    utraj = utraj.shiftTime(combined_utraj_breaks(end) - utraj_breaks(1));
                    
                    % append the new velocity trajectory
                    combined_utraj = combined_utraj.append(utraj);
                end
                
                % get the new velocity trajectory
                utraj = obj.get_new_utraj(initial_pos(obj.pitch_index), initial_pos(obj.roll_index));
            end
        end

        function visualizeTrajectory(obj, initial_pos)

            utraj = obj.get_new_utraj(initial_pos(obj.pitch_index), initial_pos(obj.roll_index));

            % determine the x trajectory with the initial position and
            % velocity trajectory
            xtraj = obj.simulateTrajectory(utraj, initial_pos);

            % create a visualizer to look at the trajectory
            vis = obj.r.constructVisualizer();

            % playback the x trajectory, including a slider
            vis.playback(xtraj, struct('slider', true));
            
        end

    end
end