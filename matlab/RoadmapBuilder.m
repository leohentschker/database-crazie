classdef RoadmapBuilder
    
    properties(Constant)

        min_pitch = -1
        max_pitch = 1
        
        min_roll = -1
        max_roll = 1
        
        min_traj = 0
        
        num_u_dimensions = 7
    end
    
    properties
        runner = CrazyflieRunner()
        max_traj = CrazyflieModel().nominal_thrust
    end

    methods
        % generate a random initial configuration for the quad
        function [pitch, roll, u0] = generate_random_inputs(obj)
            pitch = obj.min_pitch + rand(1) * (obj.max_pitch - obj.min_pitch);
            roll = obj.min_roll + rand(1) * (obj.max_roll - obj.min_roll);
            
            % initialize utraj in each dimension
            u0 = zeros(obj.num_u_dimensions, 1);
            for dim=1:obj.num_u_dimensions
                random_traj = obj.min_traj + rand(1) * obj.max_traj;
                u0(dim) = random_traj;
            end

            u0 = [0 0 0 0 0 0 obj.runner.cf_model.nominal_thrust]';
            
        end
        
        function export_results(obj, xtraj, utraj, pitch, roll, u0)
            
            % construct a string representation for the initial velocity
            u0_str = '';
            for idx=1:numel(u0)
                u0_str = [u0_str strcat(num2str(u0(idx)), ',')];
            end

            % remove the final comma
            u0_str = u0_str(1:length(u0_str) - 1);
            
            ideal_traj.xtraj = xtraj;
            ideal_traj.utraj = utraj;

            % construct the file path to save the trajectory
            file_path = strcat('solved_trajectories/', num2str(pitch), '%', num2str(roll), '%', u0_str, '.mat');

            save(file_path, 'ideal_traj');
        end

        % helper method to get the optimal trajectory for configuration
        function [xtraj, utraj] = run_simulations(obj)
            
            % store how many trajectories we have solved for so I can be
            % happy
            num_trajectories_found = 0;
            
            totalTime = 0;

            while true
                tic
                % generate the random initial configuration
                [pitch, roll, u0] = obj.generate_random_inputs();

                % solve the optimization problem
                [xtraj, utraj] = obj.runner.simulate(pitch, roll, u0);

                % export the results
                obj.export_results(xtraj, utraj, pitch, roll, u0);
                toc
                
                % update the total time taken
                totalTime = totalTime + toc;
                
                % increment the number of trajectories
                num_trajectories_found = num_trajectories_found + 1;

                % display the average time
                display(totalTime/ num_trajectories_found, 'averageTime');
                
                % display how many have been found
                display(num_trajectories_found);

            end
        end

    end
end