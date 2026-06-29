import time
import psycopg2
import psycopg2.extras
from app.models import Item, Cart
from app.service import CartService
from app.config import settings

_MAX_RETRIES = 30
_RETRY_DELAY = 2


class PostgresCartService(CartService):
    def __init__(self):
        for attempt in range(1, _MAX_RETRIES + 1):
            conn = None
            try:
                conn = psycopg2.connect(
                    host=settings.postgres_host,
                    port=settings.postgres_port,
                    dbname=settings.postgres_db,
                    user=settings.postgres_user,
                    password=settings.postgres_password,
                )
                conn.autocommit = True
                with conn.cursor() as cur:
                    cur.execute("SELECT 1 FROM cart_items LIMIT 1")
                self._conn = conn
                return
            except Exception as e:
                if conn is not None:
                    try:
                        conn.close()
                    except Exception:
                        pass
                if attempt == _MAX_RETRIES:
                    raise
                print(f"Waiting for PostgreSQL... ({attempt}/{_MAX_RETRIES}): {e}")
                time.sleep(_RETRY_DELAY)

    def get(self, customer_id: str) -> Cart:
        return Cart(customerId=customer_id, items=self.get_items(customer_id))

    def delete(self, customer_id: str) -> None:
        with self._conn.cursor() as cur:
            cur.execute("DELETE FROM cart_items WHERE customer_id = %s", (customer_id,))

    def merge(self, customer_id: str, session_id: str) -> None:
        for item in self.get_items(session_id):
            self.add_item(customer_id, item)
        self.delete(session_id)

    def get_items(self, customer_id: str) -> list[Item]:
        with self._conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor) as cur:
            cur.execute(
                "SELECT item_id, quantity, unit_price FROM cart_items WHERE customer_id = %s",
                (customer_id,),
            )
            return [
                Item(itemId=r["item_id"], quantity=r["quantity"], unitPrice=r["unit_price"])
                for r in cur.fetchall()
            ]

    def add_item(self, customer_id: str, item: Item) -> Item:
        with self._conn.cursor() as cur:
            cur.execute(
                """
                INSERT INTO cart_items (customer_id, item_id, quantity, unit_price)
                VALUES (%s, %s, %s, %s)
                ON CONFLICT (customer_id, item_id)
                DO UPDATE SET quantity = EXCLUDED.quantity, unit_price = EXCLUDED.unit_price
                """,
                (customer_id, item.itemId, item.quantity, item.unitPrice),
            )
        return item

    def update_item(self, customer_id: str, item: Item) -> Item | None:
        with self._conn.cursor() as cur:
            cur.execute(
                """
                UPDATE cart_items SET quantity = %s, unit_price = %s
                WHERE customer_id = %s AND item_id = %s
                """,
                (item.quantity, item.unitPrice, customer_id, item.itemId),
            )
            return item if cur.rowcount > 0 else None

    def get_item(self, customer_id: str, item_id: str) -> Item | None:
        with self._conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor) as cur:
            cur.execute(
                "SELECT item_id, quantity, unit_price FROM cart_items WHERE customer_id = %s AND item_id = %s",
                (customer_id, item_id),
            )
            r = cur.fetchone()
            return Item(itemId=r["item_id"], quantity=r["quantity"], unitPrice=r["unit_price"]) if r else None

    def delete_item(self, customer_id: str, item_id: str) -> None:
        with self._conn.cursor() as cur:
            cur.execute(
                "DELETE FROM cart_items WHERE customer_id = %s AND item_id = %s",
                (customer_id, item_id),
            )
