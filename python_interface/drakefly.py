from cflib.crazyflie.log import LogConfig
from crazyflie_logger import CrazyflieLogger
import cflib
from cflib import crazyflie
from cflib import crtp

from threading import Thread
import time

# setup logging as it is a massive hassle
CrazyflieLogger.set_logging()


class DrakeFly(crazyflie.Crazyflie): 

    DEFAULT_TIMEOUT = 10

    def __init__(self, link_uri):
        """
        Override the init method to open the link
        by default
        """
        # instantiate the super class
        crazyflie.Crazyflie.__init__(self)

        # add callback on connect
        self.connected.add_callback(self._connected)
        self.disconnected.add_callback(self._disconnected)
        self.connection_failed.add_callback(self._connection_failed)
        self.connection_lost.add_callback(self._connection_lost)

        # open the connection
        self.open_link(link_uri)

        # solve the trajectory only once
        self.solving_trajectory = False

        print('Connecting to %s' % link_uri)

    def _connected(self, link_uri):
        """ This callback is called form the Crazyflie API when a Crazyflie
        has been connected and the TOCs have been downloaded."""

        # Start a separate thread to do the motor test.
        # Do not hijack the calling thread!
        Thread(target=self._ramp_motors).start()

    def _connection_failed(self, link_uri, msg):
        """Callback when connection initial connection fails (i.e no Crazyflie
        at the specified address)"""
        print('Connection to %s failed: %s' % (link_uri, msg))

    def _connection_lost(self, link_uri, msg):
        """Callback when disconnected after a connection has been made (i.e
        Crazyflie moves out of range)"""
        print('Connection to %s lost: %s' % (link_uri, msg))

    def _disconnected(self, link_uri):
        """Callback when the Crazyflie is disconnected (called in all cases)"""
        print('Disconnected from %s' % link_uri)

    @staticmethod
    def get_fly_uri():
        """
        Initialize the drivers to gain access
        to the crazyflie
        """
        cflib.crtp.init_drivers()
        
        # return the first fly we find
        results = cflib.crtp.scan_interfaces()

        assert results, \
            "Unable to find fly. Check your connection and try again!"
        return results[0][0]

    @classmethod
    def run_fly(cls, *args, **kwargs):
        """
        Helper method to instantiate a fly
        with the correct uri that we find
        """
        fly_uri = cls.get_fly_uri()

        fly = cls(fly_uri, *args, **kwargs)
        time.sleep(cls.DEFAULT_TIMEOUT)
        fly.close_link()

    def _connected(self, link_uri):
        """
        Callback when the fly connects over the radio
        """

        # start logging data
        self.set_data_logging()

        # bring the fly to a hover
        Thread(target=self.hover).start()

    def hover(self):
        """
        Brings the fly to a hover
        """

        roll = 0
        pitch = 0
        yawrate = 0

        # Unlock startup thrust protection
        self.commander.send_setpoint(0, 0, 0, 0)

        start = time.time()

        while time.time() - start < 3:
            self.commander.send_setpoint(roll, pitch, yawrate, 43000)
            # if time.time() - start < 1:
            #     self.commander.send_setpoint(roll, pitch, yawrate, 43000)
            # else:
            #     self.commander.send_setpoint(roll, pitch, yawrate, 30000)

        start = time.time()

        self.commander.send_setpoint(0, 0, 0, 0)
        # Make sure that the last packet leaves before the link is closed
        # since the message queue is not flushed before closing
        time.sleep(0.1)

    def set_data_logging(self):
        """
        Method to setup logging of crazyflie data following
        the example in their docs
        master/examples/basiclog.py
        """

		# The definition of the logconfig can be made before connecting
        self.data_log = LogConfig(name='Stabilizer', period_in_ms=100)
        self.data_log.add_variable('stabilizer.roll', 'float')
        self.data_log.add_variable('stabilizer.pitch', 'float')
        self.data_log.add_variable('stabilizer.yaw', 'float')
        self.data_log.add_variable('stabilizer.thrust', 'float')

        # Adding the configuration cannot be done until a Crazyflie is
        # connected, since we need to check that the variables we
        # would like to log are in the TOC.
        self.log.add_config(self.data_log)

        # This callback will receive the data
        self.data_log.data_received_cb.add_callback(self._receive_data)
        # This callback will be called on errors
        self.data_log.error_cb.add_callback(self._stab_log_error)
        # Start the logging
        self.data_log.start()

    def _receive_data(self, timestamp, data, logconf):
        """
        Takes in the data from the crazyflie
        """

        print data
        if not self.solving_trajectory:
            self.solving_trajectory = True

            commands = self.determine_commands(data)

    def _stab_log_error(self, *args, **kwargs):
        print "ERROR"


if __name__ == "__main__":
    fly = DrakeFly.run_fly()
