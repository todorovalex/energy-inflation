# Energy Price Inflation & UK Household Impact

Group project for KEN2110 (Databases) — Maastricht University.
A relational database modeling how rising energy prices, inflation, and
central-bank policy affect UK households across regions and demographic groups.

## Team members

- todorovalex
- altay-frzc
- angeellucaas
- mystermy

## Repo structure

- `sql/schema.sql` — Table definitions (DDL): 12 tables, PK/FK constraints
- `sql/seed_data.sql` — Mock data (INSERT statements)
- `sql/seed_data_real.sql` — Real UK inflation and electricity data (INSERT statements)
- `sql/UK_ONS_inflation_2000_2025.csv` — Monthly UK CPI and inflation data
- `sql/UK_energy_prices_2000_2025.csv` — Annual UK electricity prices by payment method
- `sql/queries.sql` — Queries on regional spending, bills, borrowing costs, vulnerability, shocks, price-per-kWh versus consumption changes, and average inflation by region
- `sql/payment_and_inflation_queries.sql` — Queries on payment methods and annual bills alongside inflation
- `sql/scheme_and_stress_queries.sql` — Queries on support schemes and mortgage stress
- `sql/verify_normalization.sql` — Checks of the integrated data
- `sql/prepare_release.sql` — Shortens mock postcodes before preparing a release
- `scripts/crud.py` — Python script for basic CRUD operations against the DB

## Entity overview

12 tables: REGION, HOUSEHOLD, DEMOGRAPHIC_PROFILE, ENERGY_BILL, ENERGY_SUPPLIER,
PAYMENT_METHOD, MACROECONOMIC_METRIC, COMMODITY_SHOCK, CENTRAL_BANK_POLICY, and
3 bridge tables (HOUSEHOLD_DEMOGRAPHIC, SHOCK_IMPACT_LOG, HOUSEHOLD_POLICY_IMPACT)
resolving the many-to-many relationships.

## Setup instructions

1. Clone the repository:

git clone https://github.com/todorovalex/energy-inflation.git
cd energy-inflation

2. Make sure you have MySQL 8.0+ (or compatible) installed and running.

3. Create the schema:

mysql -u root -p -e "CREATE DATABASE IF NOT EXISTS energy_inflation;"
mysql -u root -p energy_inflation < sql/schema.sql

4. Load mock data, then real data:

```bash
mysql -u root -p energy_inflation < sql/seed_data.sql
mysql -u root -p energy_inflation < sql/seed_data_real.sql
```

Run each seed file once on a fresh database. The real-data SQL file already
contains the transformed CSV data, so the CSV files do not need importing again.

5. Install the Python dependency:

python -m pip install mysql-connector-python

Set DB_CONFIG in scripts/crud.py to your local MySQL username and password.
Keep the database name as energy_inflation. Do not commit your password.

Run the CRUD script:

python scripts/crud.py

Requires: `mysql-connector-python` (`pip install mysql-connector-python`)

6. Run the analytical query files:

```bash
mysql -u root -p energy_inflation < sql/queries.sql
mysql -u root -p energy_inflation < sql/payment_and_inflation_queries.sql
mysql -u root -p energy_inflation < sql/scheme_and_stress_queries.sql
```

## Notes
- Schema validated with MySQL syntax via DB Fiddle before merging.
- All foreign keys use default constraint behavior (RESTRICT) unless stated otherwise.
- The advanced queries compare regional energy spending, identify above average bills, and track household borrowing cost changes.
- Both real datasets contain UK national averages. Regional inflation comparisons
  therefore rely on mock data, not real regional inflation measurements.
- For real electricity rows, `kwh_consumed` represents standard consumption used
  to calculate annual bills, not measured household consumption. `price_cap_rate`
  stores the electricity unit cost in GBP/kWh, not a historical Ofgem price cap.

## Normalization fix: PAYMENT_METHOD (3NF)

The real electricity price data is differentiated by payment type, so the
payment method is stored in its own lookup table instead of as text on each bill.

- `PAYMENT_METHOD(payment_method_id PK, payment_method_name UNIQUE NOT NULL)`
  holds each payment method once.
- `ENERGY_BILL.payment_method_id` is a foreign key to `PAYMENT_METHOD`. The name
  is no longer repeated on every bill, so it is stored in one place and cannot
  drift between rows (e.g. inconsistent spellings).
- `payment_method_id` is part of the unique key
  `(household_id, supplier_id, payment_method_id, billing_period_start)`, so a
  household can have one bill per payment method for the same supplier and
  period. The real data needs this, as it gives a separate price for each payment
  type.
- The column is nullable for bills where the payment method is unknown.

## Documentation of Real Datasets
UK Consumer Price Inflation
- Source: Office for National Statistics (ONS), Consumer price inflation time series
- Publication date: 21 January 2026 for the December 2025 time-series release.
- Licence: Open Government Licence (OGL) v3.0. ONS states that most of its published content is available under the Open Government Licence.
- Access: Publicly available.
- Selected data: Monthly UK CPI and inflation data from 2000–2025.

UK Domestic Electricity Prices
- Source: Department for Energy Security and Net Zero (DESNZ), Annual domestic energy bills, QEP Table 2.2.3 — Average annual domestic electricity bills for UK regions.
- Publication date: The statistical dataset was originally published 28 March 2013. The version containing the 2025 data was updated on 18 December 2025; QEP Table 2.2.3 was updated again on 30 June 2026.
- Licence: Open Government Licence (OGL) v3.0. DESNZ publications are published under the OGL v3.0.
- Access: Publicly available.
- Selected data: Annual UK domestic electricity prices and bills from 2000–2025, differentiated by payment type.

## Real data query validation (point 3 and 5)

Re-ran the 3 queries from week 3 against the schema with real data integrated:

- Query 1 (regional Q1 2022 spending): the real "United Kingdom" row never appears.
Real bills are annual (Jan-Dec), but the query requires billing_period_end <=
2022-03-31 (quarterly), so no real bill ever matches. Not adapted for this
deliverable since it's expected: the real data is a single national average,
not a 3+ household sample like the query assumes.
- Query 2 (bills above same-period average): still meaningful with real data -
compares the 3 payment methods of the UK household within the same year and
surfaces which one cost above that year's average.
- Query 3 (borrowing cost change via policy impact): unaffected by the real
data integration. Neither real dataset covers interest rates or mortgage
costs, so the UK household has 0 rows in HOUSEHOLD_POLICY_IMPACT and the
query still only reflects mock data.

## Archived release and licence

- Zenodo DOI: [10.5281/zenodo.23218208](https://doi.org/10.5281/zenodo.23218208)
- Licence: CC BY 4.0. Original source data remains under the Open Government Licence (OGL) v3.0.

## Stakeholder Video
[![Video Title](https://img.youtube.com/vi/v=_5tFXJQIzi4.jpg)](https://www.youtube.com/watch?v=https://youtu.be/vXeuZTqllQ0)

