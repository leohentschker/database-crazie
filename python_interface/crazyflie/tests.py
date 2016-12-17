from crazyflie.management.commands.sync_trajectories import Command as SyncCommand
from crazyflie.management.commands.find_closest_trajectory import Command as FindCommand
from crazyflie.models import SolvedTrajectory
from django.test import TestCase
from django.db import connection
import random
import os


class CrazyflieTestcase(TestCase):

    TRAJ_DIR = "../matlab/solved_trajectories/"

    def test_traj_upload(self):
        """
        Test that ensures we can upload objects
        from the databses
        """
        # get a trajectory to upload
        self.assertTrue(os.path.exists(self.TRAJ_DIR))
        random_traj_file = random.choice(os.listdir(self.TRAJ_DIR))
        random_traj_path = os.path.join(self.TRAJ_DIR, random_traj_file)

        self.assertTrue(os.path.exists(random_traj_path))

        # upload the trajectory
        SyncCommand.upload_trajectory(random_traj_path)

        self.assertEqual(SolvedTrajectory.objects.count(), 1)

        # get the trajectory
        traj = SolvedTrajectory.objects.first()

        # check the pitch and the roll
        pitch, roll, u0 = SyncCommand.extract_pitch_roll_velocity(random_traj_path)
        self.assertTrue(float(traj.pitch) - pitch < .001)
        self.assertTrue(float(traj.roll) - roll < .001)

    def test_find_closest_traj(self):
        """
        Test the function meant to find the closest trajectory
        to a given pitch and roll
        """

        # get a trajectory to upload
        random_traj_file = random.choice(os.listdir(self.TRAJ_DIR))
        random_traj_path = os.path.join(self.TRAJ_DIR, random_traj_file)

        # upload the trajectory
        SyncCommand.upload_trajectory(random_traj_path)

        # get the associated trajectory
        solved_traj = SolvedTrajectory.objects.first()

        pitch = solved_traj.pitch
        roll = solved_traj.roll

        file_name, _ = FindCommand.find_closest_trajectory(
            pitch=pitch, roll=roll)

        # make sure the file was in the path
        self.assertTrue(file_name in random_traj_path)
