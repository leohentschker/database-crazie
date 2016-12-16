from django.db import models


class SolvedTrajectory(models.Model):
    """
    Store the attributes of the solved trajectory
    in the database
    """

    # store the file name as an identifier
    file_name = models.CharField(
        max_length=100,
        db_index=True)

    # store the pitch and the roll of the trajectory
    pitch = models.DecimalField(
        max_digits=15,
        decimal_places=6,
        null=True,
        db_index=True)

    roll = models.DecimalField(
        max_digits=15,
        decimal_places=6,
        null=True,
        db_index=True)

    # store the string representing the initial velocity
    u0_string = models.TextField(
        null=True)
