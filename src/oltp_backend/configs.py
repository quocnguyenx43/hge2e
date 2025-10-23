import os
import sys
import time
import psycopg2
from dotenv import load_dotenv

# Load environment variables from .env
load_dotenv()

DB_CONFIG = {
    "host": os.getenv("DB_HOST", "localhost"),
    "port": os.getenv("DB_PORT", "5432"),
    "dbname": os.getenv("DB_NAME", "oltp"),
    "user": os.getenv("DB_USER", "oltp"),
    "password": os.getenv("DB_PASSWORD", "oltp"),
}

ORDERS_SIMULATION_INTERVAL_MIN = float(os.getenv("ORDERS_SIM_INTERVAL_MIN", 5.0))
ORDERS_SIMULATION_INTERVAL_MAX = float(os.getenv("ORDERS_SIM_INTERVAL_MAX", 10.0))

ENTITIES_SIMULATION_INTERVAL_MIN = float(os.getenv("ENTITIES_SIM_INTERVAL_MIN", 10.0))
ENTITIES_SIMULATION_INTERVAL_MAX = float(os.getenv("ENTITIES_SIM_INTERVAL_MAX", 20.0))

def get_connection():
    """Return a new PostgreSQL connection with retry logic.

    Retries:
        - 1st retry after 10 seconds
        - 2nd retry after 15 seconds
        - 3rd retry after 30 seconds
    If all retries fail, exit the program.
    """
    retry_delays = [10, 15, 30]

    for attempt, delay in enumerate(retry_delays, start=1):
        try:
            conn = psycopg2.connect(**DB_CONFIG)
            print("Connected to PostgreSQL successfully\n")
            return conn
        except psycopg2.OperationalError as e:
            print(f"Connection attempt {attempt} failed: {e}\n")
            if attempt < len(retry_delays):
                print(f"Retrying in {delay} seconds...\n")
                time.sleep(delay)
            else:
                print("All connection attempts failed. Exiting program\n")
                sys.exit(1)
