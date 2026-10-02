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

2. Make sure you have MySQL 8.0+ (or compatible) installed and running.

3. Create the schema:

mysql -u root -p -e "CREATE DATABASE IF NOT EXISTS energy_inflation;"
mysql -u root -p energy_inflation < sql/schema.sql

4. Load mock data:

mysql -u root -p energy_inflation < sql/seed_data.sql

5. Install the Python dependency:

python -m pip install mysql-connector-python

Set DB_CONFIG in scripts/crud.py to your local MySQL username and password.
Keep the database name as energy_inflation. Do not commit your password.

Run the CRUD script:

python scripts/crud.py

Requires: `mysql-connector-python` (`pip install mysql-connector-python`)

6. Advanced queries are in `sql/queries.sql` — run directly in your MySQL client
or via a GUI tool (MySQL Workbench, DBeaver, etc.).

## Notes
- Schema validated with MySQL syntax via DB Fiddle before merging.
- All foreign keys use default constraint behavior (RESTRICT) unless stated otherwise.
- The advanced queries compare regional energy spending, identify above average bills, and track household borrowing cost changes.

## Documentation of Real Datasets
UK Consumer Price Inflation
- Source: Office for National Statistics (ONS), Consumer price inflation time series
- Publication date: 21 January 2026 for the December 2025 time-series release.
- Licence: Open Government Licence (OGL) v3.0. ONS states that most of its published content is available under the Open Government Licence.
- Access: Publicly available.
- Selected data: Monthly UK CPI and inflation data from 2000–2025.

UK Domestic Electricity Prices
- Source: Department for Energy Security and Net Zero (DESNZ), Annual domestic energy bills, QEP Table 2.2.3 — Average annual domestic electricity bills for UK regions.
- Publication date: The statistical dataset was originally published 28 March 2013. The version containing the 2025 data was updated on 18 December 2025; QEP Table 2.2.3 was  updated again on 30 June 2026.
- Licence: Open Government Licence (OGL) v3.0. DESNZ publications are published under the OGL v3.0.
- Access: Publicly available.
- Selected data: Annual UK domestic electricity prices and bills from 2000–2025, differentiated by payment type.
