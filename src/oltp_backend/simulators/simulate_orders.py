import random
import time
from datetime import date
from decimal import Decimal

from configs import get_connection, \
    ORDERS_SIMULATION_INTERVAL_MIN, ORDERS_SIMULATION_INTERVAL_MAX


def get_random_customer(cursor):
    cursor.execute("SELECT customer_id FROM customers ORDER BY RANDOM() LIMIT 1;")
    res = cursor.fetchone()
    return res[0] if res else None


def get_random_product(cursor):
    cursor.execute("SELECT product_id, price FROM products ORDER BY RANDOM() LIMIT 1;")
    res = cursor.fetchone()
    return res if res else (None, None)


def create_order(cursor, customer_id, order_items):
    total = sum(Decimal(i['price']) * i['quantity'] for i in order_items)
    cursor.execute("""
        INSERT INTO orders (customer_id, order_date, total_amount)
        VALUES (%s, %s, %s) RETURNING order_id;
    """, (customer_id, date.today(), total))
    order_id = cursor.fetchone()[0]

    for item in order_items:
        cursor.execute("""
            INSERT INTO order_items (order_id, product_id, quantity, price)
            VALUES (%s, %s, %s, %s);
        """, (order_id, item['product_id'], item['quantity'], item['price']))
    print(f"New order '{order_id}' created")
    return order_id


def simulate_order_cycle(conn):
    try:
        with conn.cursor() as cur:
            customer_id = get_random_customer(cur)
            if not customer_id:
                print("No customers found")
                return

            order_items = []
            for _ in range(random.randint(1, 3)):
                product_id, price = get_random_product(cur)
                if not product_id:
                    return
                order_items.append({
                    "product_id": product_id,
                    "quantity": random.randint(1, 5),
                    "price": price
                })

            create_order(cur, customer_id, order_items)
        conn.commit()
    except Exception as e:
        conn.rollback()
        print(f"Transaction failed: {e}")


def run_order_simulation():
    conn = get_connection()
    print("Order simulation started...")
    try:
        while True:
            simulate_order_cycle(conn)
            time.sleep(random.uniform(ORDERS_SIMULATION_INTERVAL_MIN, ORDERS_SIMULATION_INTERVAL_MAX))
    except KeyboardInterrupt:
        print("Order simulation stopped")
    finally:
        conn.close()
