from django.core.management.base import BaseCommand, CommandError
from crazyflie.models import SolvedTrajectory
import decimal
import random
import math
import time


class Command(BaseCommand):
    help = 'Starts a process to sync the solved trajectories to the database'

    MIN_BENCHMARK_PITCH = 0
    MAX_BENCHMARK_PITCH = 1

    MIN_BENCHMARK_ROLL = 0
    MAX_BENCHMARK_ROLL = 1

    def add_arguments(self, parser):
        """
        Accept the pitch and roll from the command line
        """
        parser.add_argument(
            '--pitch',
            type=decimal.Decimal)

        parser.add_argument(
            '--roll',
            type=decimal.Decimal)

        parser.add_argument(
            '--min_roll_differential',
            default=decimal.Decimal(.1),
            type=decimal.Decimal)

        parser.add_argument(
            '--ideal_min_roll_differential',
            default=decimal.Decimal(.05),
            type=decimal.Decimal)

        parser.add_argument(
            '--min_pitch_differential',
            default=decimal.Decimal(.1),
            type=decimal.Decimal)

        parser.add_argument(
            '--ideal_min_pitch_differential',
            default=decimal.Decimal(.01),
            type=decimal.Decimal)

        parser.add_argument(
            '--benchmark',
            action="store_true",
            default=False)

        parser.add_argument(
            '--benchmark_iterations',
            default=1000,
            type=int)

    def get_match_score(self, trajectory, pitch, roll):
        """
        Takes in a trajectory and returns how close it
        is to the inputted pitch and roll
        """
        pitch_differential = abs(trajectory.pitch - pitch)
        roll_differential = abs(trajectory.roll - roll)

        return pow(pitch_differential, 2) + pow(roll_differential, 2)

    def find_closest_trajectory(self, **kwargs):
        """
        Finds the file name associated with the
        closest trajectory
        """
        # if we can find an approximation that works to two
        # decimal places, just return that
        ideal_min_pitch = kwargs["pitch"] - kwargs["ideal_min_pitch_differential"]
        ideal_max_pitch = kwargs["pitch"] + kwargs["ideal_min_pitch_differential"]

        ideal_min_roll = kwargs["roll"] - kwargs["ideal_min_roll_differential"]
        ideal_max_roll = kwargs["roll"] + kwargs["ideal_min_roll_differential"]

        # find trajectories that we are good with even if they aren't the absolute
        # best
        ideal_trajectory = SolvedTrajectory.objects.filter(
            pitch__gt=ideal_min_pitch,
            roll__gt=ideal_min_roll
        ).filter(
            pitch__lt=ideal_max_pitch,
            roll__lt=ideal_max_roll)
        ideal_trajectory = ideal_trajectory.first()

        # if we found something in the ideal trajectory, just return that!
        if ideal_trajectory:
            best_trajectory = ideal_trajectory
            best_match_score = self.get_match_score(
                best_trajectory, kwargs["pitch"], kwargs["roll"])

        # otherwise, we expand our filter and include more results
        else:

            # determine bounds on the pitch and the roll
            # of the trajectory we will return
            min_pitch = kwargs["pitch"] - kwargs["min_pitch_differential"]
            max_pitch = kwargs["pitch"] + kwargs["min_pitch_differential"]

            min_roll = kwargs["roll"] - kwargs["min_roll_differential"]
            max_roll = kwargs["roll"] + kwargs["min_roll_differential"]

            # determine the candidate trajectories
            candidate_trajectories = SolvedTrajectory.objects.filter(
                pitch__gt=min_pitch,
                roll__gt=min_roll
            ).filter(
                pitch__lt=max_pitch,
                roll__lt=max_roll
            )

            # determine the best match from what we have available
            best_trajectory = None
            best_match_score = float("inf")

            for trajectory in candidate_trajectories:
                match_score = self.get_match_score(
                    trajectory, kwargs["pitch"], kwargs["roll"])

                if match_score < best_match_score:
                    best_trajectory = trajectory
                    best_match_score = match_score

        # calculate the norm of the deviation
        deviation = math.sqrt(best_match_score)
        return best_trajectory.file_name, deviation

    def benchmark(self, **kwargs):
        """
        Benchmarks the speed of the result
        """
        num_iterations = kwargs.get("benchmark_iterations")

        start_time = time.time()

        # store how far off we are
        deviations = []

        for _ in xrange(num_iterations):
            kwargs["roll"] = decimal.Decimal(random.uniform(
                self.MIN_BENCHMARK_ROLL, self.MAX_BENCHMARK_ROLL))
            kwargs["pitch"] = decimal.Decimal(random.uniform(
                self.MIN_BENCHMARK_PITCH, self.MAX_BENCHMARK_PITCH))

            _, deviation = self.find_closest_trajectory(**kwargs)
            deviations.append(deviation)

        # calculate results from the benchmarking
        total_time = time.time() - start_time
        average_time = total_time / num_iterations
        average_deviation = sum(deviations) / len(deviations)

        print "AVERAGE TIME: %s AVERAGE DEVIATION: %s" \
            % (average_time, average_deviation)

    def handle(self, *args, **options):
        """
        Exposes a script to find the closest trajectory
        """
        # used to test the speed of determining the closest
        # trajectory
        if options["benchmark"]:
            self.benchmark(**options)

        # finds the closest trajectory
        else:
            file_name, deviation = "solved_trajectories/" + \
                self.find_closest_trajectory(**options)
            return file_name
