from drakefly import DrakeFly
import matlab.engine
import random
import os


class StateControlStep:

    yaw_index = 5
    pitch_index = 4
    roll_index = 3

    thrust_index = -1

    def __init__(self, state_at_time, controls_at_time):
        """
        Stores the information concerning the controls being
        received at the time
        """

        # read in the state
        self.yaw = state_at_time[self.yaw_index][0]
        self.pitch = state_at_time[self.pitch_index][0]
        self.roll = state_at_time[self.roll_index][0]

        # read in the thrust
        self.thrust = controls_at_time[self.thrust_index][0]


class MatlabTrajectory:

    MATLAB_ENGINE = matlab.engine.start_matlab()
    
    def __init__(self, traj_path):
        """
        Reads in a trajectory from matlab and converts
        it into a usable python object
        """
        assert os.path.exists(traj_path), \
            "Unable to find path: %s" % traj_path

        # load in the trajectory object
        traj_object = self.MATLAB_ENGINE.load(traj_path, nargout=1)

        # extract the trajectories from the object we loaded
        self.trajectory = self.extract_trajectory_info(traj_object)

    def __iter__(self):
        """
        Define the iter over the class to be over
        the trajectory stored
        """
        for element in self.trajectory:
            yield element

    def extract_trajectory_info(self, traj_object):
        """
        Extract the information about a particular
        trajectory
        """

        assert "python_readable_traj" in traj_object, \
            "Invalid trajectory: %s" % traj_path

        # error handling
        if "python_readable_traj" not in traj_object or \
            "xtraj" not in traj_object["python_readable_traj"] or \
            "utraj" not in traj_object["python_readable_traj"]:
            raise KeyError("Invalid Trajectory object: %s" % traj_path)

        # get the elements from the dictionary
        uncleaned_xtraj = traj_object["python_readable_traj"]["xtraj"]
        uncleaned_utraj = traj_object["python_readable_traj"]["utraj"]

        # extract the elements from the uncleaned trajectories, converting to
        # floats so they are easier to use
        trajectory = []
        for state_at_time, controls_at_time in zip(uncleaned_xtraj, uncleaned_utraj):

            trajectory.append(StateControlStep(state_at_time, controls_at_time))

        return trajectory


class SimulatorFly(DrakeFly):
    
    TRAJECTORY_DIR = "../matlab/python_readable_trajectories/"

    def __init__(self, link_uri, trajectory_to_run):
        """
        Override the init to set the trajectory
        as a property. Also why does no one inherit from objects?
        Means I can't do super.
        """
        self.trajectory = trajectory_to_run
        DrakeFly.__init__(self, link_uri)

    def _connected(self, link_uri):
        """
        Run the drake through a simulated trajectory
        to stabilize it
        """
        for timestep in self.trajectory:
            print timestep.roll, "THATS THE ROLL"

    @classmethod
    def find_trajectory_to_run(cls):
        """
        Searches in the list of allowable trajectories and
        finds a good one to run
        """

        # choose a file
        traj_file_to_run = random.choice(os.listdir(cls.TRAJECTORY_DIR))
        traj_path = os.path.join(cls.TRAJECTORY_DIR, traj_file_to_run)

        # load the object
        return MatlabTrajectory(traj_path)


if __name__ == "__main__":
    trajectory_to_run = SimulatorFly.find_trajectory_to_run()
    
    SimulatorFly.run_fly(trajectory_to_run)
