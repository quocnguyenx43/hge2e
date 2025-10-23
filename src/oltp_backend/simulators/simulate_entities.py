import random
import time

from faker import Faker

from configs import get_connection, \
    ENTITIES_SIMULATION_INTERVAL_MIN, ENTITIES_SIMULATION_INTERVAL_MAX


fake = Faker()


def create_customer(cursor):
    name = fake.name()
    email = fake.email()
    cursor.execute("""
        INSERT INTO customers (name, email)
        VALUES (%s, %s)
        RETURNING customer_id;
    """, (name, email))
    cid = cursor.fetchone()[0]
    print(f"New customer '{cid}' created")


def update_random_product(cursor):
    cursor.execute("SELECT product_id FROM products ORDER BY RANDOM() LIMIT 1;")
    res = cursor.fetchone()
    if not res:
        print("No products found")
        return
    pid = res[0]
    new_price = round(random.uniform(20, 1200), 2)
    cursor.execute("UPDATE products SET price = %s WHERE product_id = %s;", (new_price, pid))
    print(f"Product {pid} updated")


def simulate_entity_cycle(conn):
    try:
        with conn.cursor() as cur:
            # Randomly create or update entities
            if random.random() < 0.6:
                create_customer(cur)
            else:
                update_random_product(cur)
        conn.commit()
    except Exception as e:
        conn.rollback()
        print(f"Entity transaction failed: {e}")


def run_entity_simulation():
    conn = get_connection()
    print("Entity simulation started...")
    try:
        while True:
            simulate_entity_cycle(conn)
            time.sleep(random.uniform(ENTITIES_SIMULATION_INTERVAL_MIN, ENTITIES_SIMULATION_INTERVAL_MAX))
    except KeyboardInterrupt:
        print("Entity simulation stopped")
    finally:
        conn.close()
