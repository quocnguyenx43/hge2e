import threading

from simulators.simulate_orders import run_order_simulation
from simulators.simulate_entities import run_entity_simulation

if __name__ == "__main__":
    print("Starting OLTP Backend")

    # Start threads for independent continuous simulations
    t1 = threading.Thread(target=run_order_simulation, daemon=True)
    t2 = threading.Thread(target=run_entity_simulation, daemon=True)

    t1.start()
    t2.start()

    try:
        while True:
            pass
    except KeyboardInterrupt:
        print("OLTP Backend shutting down gracefully...\n")
