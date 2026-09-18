# Energy Price Inflation & UK Household Impact

Group project for KEN2110 (Databases) — Maastricht University.
A relational database modeling how rising energy prices, inflation, and
central-bank policy affect UK households across regions and demographic groups.

## Team members

- Alex Todorov Kostadinov
- Leo Fernández Cali
- Angel Lucas Martinez
- Alexander Šajánek

## Repo structure

- `sql/schema.sql` — Table definitions (DDL): 11 tables, PK/FK constraints
- `sql/seed_data.sql` — Mock data (INSERT statements)
- `sql/queries.sql` — Advanced SQL queries (JOINs, aggregations, subqueries)
- `scripts/crud.py` — Python script for basic CRUD operations against the DB

## Entity overview

11 tables: REGION, HOUSEHOLD, DEMOGRAPHIC_PROFILE, ENERGY_BILL, ENERGY_SUPPLIER,
MACROECONOMIC_METRIC, COMMODITY_SHOCK, CENTRAL_BANK_POLICY, and 3 bridge tables
(HOUSEHOLD_DEMOGRAPHIC, SHOCK_IMPACT_LOG, HOUSEHOLD_POLICY_IMPACT) resolving the
many-to-many relationships.

## Setup instructions

1. Clone the repository:

git clone https://github.com/todorovalex/energy-inflation.git
cd energy-inflation

2. Make sure you have MySQL (or compatible) installed and running.

3. Create the schema:

mysql -u root -p -e "CREATE DATABASE IF NOT EXISTS energy_inflation;"
mysql -u root -p energy_inflation < sql/schema.sql

4. Load mock data:

mysql -u root -p energy_inflation < sql/seed_data.sql

5. Run the CRUD script:

python scripts/crud.py

Requires: `mysql-connector-python` (`pip install mysql-connector-python`)

6. Advanced queries are in `sql/queries.sql` — run directly in your MySQL client
or via a GUI tool (MySQL Workbench, DBeaver, etc.).

## Notes
- Schema validated with MySQL syntax via DB Fiddle before merging.
- All foreign keys use default constraint behavior (RESTRICT) unless stated otherwise.
- The advanced queries compare regional energy spending, identify above average bills, and track household borrowing cost changes.
