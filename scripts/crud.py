import mysql.connector

DB_CONFIG = {
    "host": "localhost",
    "user": "root",
    "password": "",
    "database": "energy_inflation"
}

def get_connection():
    return mysql.connector.connect(**DB_CONFIG)

def create_household(region_id, postcode, dwelling_type, occupant_count, housing_tenure):
    conn = get_connection()
    cursor = conn.cursor()
    query = """
        INSERT INTO HOUSEHOLD (region_id, postcode, dwelling_type, occupant_count, housing_tenure)
        VALUES (%s, %s, %s, %s, %s)
    """
    cursor.execute(query, (region_id, postcode, dwelling_type, occupant_count, housing_tenure))
    conn.commit()
    household_id = cursor.lastrowid
    print(f"[CREATE] Household created with ID: {household_id}")
    cursor.close()
    conn.close()
    return household_id

def create_energy_bill(household_id, supplier_id, billing_period_start, billing_period_end, kwh_consumed, price_cap_rate, total_amount_gbp):
    conn = get_connection()
    cursor = conn.cursor()
    query = """
        INSERT INTO ENERGY_BILL (household_id, supplier_id, billing_period_start, billing_period_end, kwh_consumed, price_cap_rate, total_amount_gbp)
        VALUES (%s, %s, %s, %s, %s, %s, %s)
    """
    cursor.execute(query, (household_id, supplier_id, billing_period_start, billing_period_end, kwh_consumed, price_cap_rate, total_amount_gbp))
    conn.commit()
    bill_id = cursor.lastrowid
    print(f"[CREATE] Energy bill created with ID: {bill_id}")
    cursor.close()
    conn.close()
    return bill_id

def read_household(household_id):
    conn = get_connection()
    cursor = conn.cursor(dictionary=True)
    query = "SELECT * FROM HOUSEHOLD WHERE household_id = %s"
    cursor.execute(query, (household_id,))
    row = cursor.fetchone()
    print(f"[READ] Household data {household_id}: {row}")
    cursor.close()
    conn.close()
    return row

def update_energy_bill_cost(bill_id, new_total):
    conn = get_connection()
    cursor = conn.cursor()
    query = "UPDATE ENERGY_BILL SET total_amount_gbp = %s WHERE bill_id = %s"
    cursor.execute(query, (new_total, bill_id))
    conn.commit()
    print(f"[UPDATE] Bill {bill_id} updated total amount to: {new_total} GBP")
    cursor.close()
    conn.close()

def delete_energy_bill(bill_id):
    conn = get_connection()
    cursor = conn.cursor()
    query = "DELETE FROM ENERGY_BILL WHERE bill_id = %s"
    cursor.execute(query, (bill_id,))
    conn.commit()
    print(f"[DELETE] Bill {bill_id} deleted successfully.")
    cursor.close()
    conn.close()

def delete_household(household_id):
    conn = get_connection()
    cursor = conn.cursor()
    query = "DELETE FROM HOUSEHOLD WHERE household_id = %s"
    cursor.execute(query, (household_id,))
    conn.commit()
    print(f"[DELETE] Household {household_id} deleted successfully.")
    cursor.close()
    conn.close()

if __name__ == "__main__":
    print("--- STARTING CRUD TESTS ---")
    
    h_id = create_household(1, "SW1A 1AA", "Apartment", 2, "Rent")
    b_id = create_energy_bill(h_id, 1, "2026-01-01", "2026-01-31", 320.5, 0.28, 95.00)
    
    read_household(h_id)
    update_energy_bill_cost(b_id, 110.50)
    
    delete_energy_bill(b_id)
    delete_household(h_id)
    
    print("--- CRUD TESTS FINISHED SUCCESSFULLY ---")
