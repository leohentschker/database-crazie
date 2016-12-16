import logging
import sys


class CrazyflieLogger:
    
    @staticmethod
    def set_logging():
        root = logging.getLogger()
        root.setLevel(logging.ERROR)

        ch = logging.StreamHandler(sys.stdout)
        ch.setLevel(logging.DEBUG)
        formatter = logging.Formatter('%(asctime)s - %(name)s - %(levelname)s - %(message)s')
        ch.setFormatter(formatter)
        root.addHandler(ch)
