% NOTE: This file is based on the work of Benoit Landry
% https://github.com/blandry/crazyflie-tools/blob/master/matlab/runDircol.m

classdef CrazyflieRunner

    properties(Constant)
        % optimization variables
        min_trajectory_duration = .1
        max_trajectory_duration = 4
        duration_guess = 2
        total_timesteps = 11

        state_z_index = 3
        state_x_index = 1
        state_pitch_index = 5
        state_roll_index = 4
        
        max_vel = 50

        % allow the quadcopter to drift by two coordinates
        final_x_offset = 1

        initial_z_offset = .4
        final_z_offset = 1.5
    end
    
    properties
        cf_model = CrazyflieModel()
        initial_state
        u0
        optimizer
        final_state
    end
    
    methods
        % get the initial position of the crazyflie
        function initial_state = get_initial_state(obj, pitch, roll, ~)
            % initialize with the frame of the crazyflie
            initial_state = Point(getStateFrame(obj.cf_model.manip));

            % set the initial positions that we specified
            initial_state.base_pitch = pitch;
            initial_state.base_roll = roll;
            initial_state.base_z = obj.initial_z_offset;           

        end

        % set the desired final position for the crazyflie
        function final_state = get_final_state(obj)
            final_state = obj.initial_state;

            % we want the final position to be completely level
            % and raised by a unit if "1"
            final_state(obj.state_z_index) = obj.final_z_offset;
            final_state(obj.state_x_index) = obj.final_x_offset;
            final_state(obj.state_pitch_index) = 0;
            final_state(obj.state_roll_index) = 0;

        end
        
        % gets the trajectory optimizer for the crazyflie
        function obj = set_trajectory_optimizer(obj)

            % set limits on the input for the crazyflie
            obj.cf_model = obj.cf_model.setInputLimits(-obj.max_vel*ones(7,1),obj.max_vel*ones(7,1));

            obj.optimizer = DircolTrajectoryOptimization(obj.cf_model, CrazyflieRunner.total_timesteps, [CrazyflieRunner.min_trajectory_duration CrazyflieRunner.max_trajectory_duration]);  
        end

        % set the initial position and initial control constraints
        function obj = set_constraints(obj)
            % construct the constraints
            initial_state_constraint = ConstantConstraint(double(obj.initial_state));
            control_constraint = ConstantConstraint(obj.u0);
            final_state_constraint = ConstantConstraint(double(obj.final_state));

            % add the initial constraints
            obj.optimizer = obj.optimizer.addStateConstraint(initial_state_constraint, 1);
            obj.optimizer = obj.optimizer.addInputConstraint(control_constraint, 1);

            % add the final constraints
            obj.optimizer = obj.optimizer.addStateConstraint(final_state_constraint, obj.total_timesteps);
            
            % add in running costs
            obj.optimizer = obj.optimizer.addRunningCost(@CrazyflieRunner.cost);
            obj.optimizer = obj.optimizer.addFinalCost(@CrazyflieRunner.finalCost);

        end

        % initialize the trajectory optimizer
        function obj = initialize_runner(obj, pitch, roll, u0)
            % set the trajectory optimizer
            obj = obj.set_trajectory_optimizer();
            
            % set the initial variables
            obj.initial_state = obj.get_initial_state(pitch, roll, u0);
            obj.u0 = u0;
            obj.final_state = obj.get_final_state();

            % set the constraints from the variables
            obj = obj.set_constraints();
        end
        
        % return an initial trajectory for the crazyflie to start out with
        function initial_trajectory = get_initial_trajectory(obj)
            initial_trajectory.x = PPTrajectory(foh([0,obj.duration_guess],[double(obj.initial_state), double(obj.final_state)]));
            initial_trajectory.u = ConstantTrajectory(obj.u0);
        end

        % run the simulation for the crazyflie
        function [xtraj, utraj] = run_simulation(obj)

            % get our initial guess at the trajectory
            initial_trajectory = obj.get_initial_trajectory();

            % solve for the actual optimized trajectory
            [xtraj, utraj, ~, ~, ~] = obj.optimizer.solveTraj(obj.duration_guess, initial_trajectory);

        end
        
        % fully simulates the process of running the quadcopter
        function [xtraj, utraj] = simulate(obj, initial_pitch, initial_roll, u0)
            % initialize the values associated with the quadcopter
            obj = obj.initialize_runner(initial_pitch, initial_roll, u0);
            
            % simulate and return the xtrajectory as well as the velocity
            % trajectory
            [xtraj, utraj] = obj.run_simulation();
        end
    end
    
    methods(Static)
        
        % cost functions for the optimizer
        function [g,dg] = cost(~,x,u)
          R = eye(7);
          g = u'*R*u;
          dg = [0,zeros(1,size(x,1)),2*u'*R];
        end

        function [h,dh] = finalCost(t,x)
          h = t;
          dh = [1,zeros(1,size(x,1))];
        end
    end
    
end
