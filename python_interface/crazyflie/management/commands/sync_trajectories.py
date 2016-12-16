from django.core.management.base import BaseCommand, CommandError
from crazyflie.models import SolvedTrajectory
import time
import os


class Command(BaseCommand):
    help = 'Starts a process to sync the solved trajectories to the database'

    trajectory_dir = "../matlab/solved_trajectories"

    seen_trajectories = set()

    def extract_pitch_roll_velocity(self, trajectory_file):

        # strip out the file extension
        trajectory_file = trajectory_file.strip(".mat")

        # extract the three values
        pitch_str, roll_str, u0 = trajectory_file.split("%")

        # convert the valeus to the correct types
        pitch = float(pitch_str)
        roll = float(roll_str)

        return pitch, roll, u0

    def upload_trajectory(self, trajectory_file):
        """ Takes in a trajectory file and uploads it to the database
        """
        # extract the attributes from the file name
        pitch, roll, u0 = self.extract_pitch_roll_velocity(
            trajectory_file)

        # get or create a database object with those attributes
        trajectory, created =  SolvedTrajectory.objects.get_or_create(
            file_name = trajectory_file)

        # set the attributes
        trajectory.pitch = pitch
        trajectory.roll = roll
        trajectory.u0_string = u0

        # save the object
        trajectory.save()
        return created

    def sync_dir(self):
        """
        Iterates through every trajectory that
        has been solved for and then uploads the
        trajectory that has been solved for
        """

        # mark the trajectories that we have seen
        trajectories = os.listdir(self.trajectory_dir)
        
        for trajectory_file in trajectories:

            if trajectory_file not in self.seen_trajectories:

                created = self.upload_trajectory(trajectory_file)
                self.seen_trajectories.add(trajectory_file)

                if created is True:
                    print "Total of %s solved trajectories" % \
                        SolvedTrajectory.objects.count(), created



    def handle(self, *args, **options):

        while True:
            self.sync_dir()
            time.sleep(2)
