-- Advanced analysis queries for MySQL 8.0+.
-- Run after schema.sql and seed_data.sql, with energy_inflation selected.
--
-- Aliases: r = REGION, h = HOUSEHOLD, b / other = ENERGY_BILL,
--          i = HOUSEHOLD_POLICY_IMPACT, p = CENTRAL_BANK_POLICY.
-- Calculated columns:
--   households         = distinct households with bills in the period
--   avg_household_cost = spending per household (GBP)
--   previous_cost      = previous recorded borrowing cost (GBP)
--   cost_increase_gbp  = current minus previous borrowing cost (GBP)

-- 1. Compare regional household energy spending in Q1 2022.
-- JOINs link bills to regions; HAVING requires at least three households.
-- Only bills fully inside the quarter are counted.
-- This compares sample spending, not regional tariffs or population estimates.
SELECT
    r.region_name,
    COUNT(DISTINCT h.household_id) AS households,
    ROUND(
        SUM(b.total_amount_gbp) / COUNT(DISTINCT h.household_id), 2
    ) AS avg_household_cost
FROM REGION r
JOIN HOUSEHOLD h ON h.region_id = r.region_id
JOIN ENERGY_BILL b ON b.household_id = h.household_id
WHERE b.billing_period_start >= '2022-01-01'
  AND b.billing_period_end <= '2022-03-31'
GROUP BY r.region_id, r.region_name
HAVING COUNT(DISTINCT h.household_id) >= 3
ORDER BY avg_household_cost DESC, r.region_name;

-- 2. Find bills above the average for the exact same billing period.
-- The correlated subquery matches the outer bill's start and end dates.
-- Results are individual bills, not unique households; a high bill does not
-- by itself indicate hardship.
SELECT
    b.bill_id,
    b.household_id,
    b.billing_period_start,
    b.billing_period_end,
    b.total_amount_gbp
FROM ENERGY_BILL b
WHERE b.total_amount_gbp > (
    SELECT AVG(other.total_amount_gbp)
    FROM ENERGY_BILL other
    WHERE other.billing_period_start = b.billing_period_start
      AND other.billing_period_end = b.billing_period_end
)
ORDER BY b.total_amount_gbp DESC, b.bill_id;

-- 3. Compare each household's borrowing cost across policy dates.
-- LAG (in the CTE "changes") gets the previous recorded cost per household.
-- Rows with an unknown current or previous cost are excluded, not set to zero.
-- Negative values are decreases; the results do not prove causation.
WITH changes AS (
    SELECT
        i.household_id,
        p.effective_date,
        i.borrowing_cost_gbp,
        LAG(i.borrowing_cost_gbp) OVER (
            PARTITION BY i.household_id
            ORDER BY p.effective_date, p.policy_id
        ) AS previous_cost
    FROM HOUSEHOLD_POLICY_IMPACT i
    JOIN CENTRAL_BANK_POLICY p ON p.policy_id = i.policy_id
)
SELECT
    household_id,
    effective_date,
    borrowing_cost_gbp - previous_cost AS cost_increase_gbp
FROM changes
WHERE previous_cost IS NOT NULL
  AND borrowing_cost_gbp IS NOT NULL
ORDER BY cost_increase_gbp DESC, household_id, effective_date;

-- GitHub user: altay-frzc
-- Question: Do vulnerable households use less energy but pay more per kWh
--           than non-vulnerable households?
-- Why it matters: shows whether rising energy prices hit vulnerable households
--           harder, the central social question of the project.
-- Note: a household with several demographic profiles appears in each group.
SELECT
    d.vulnerability_flag,
    COUNT(DISTINCT hd.household_id) AS households,
    ROUND(AVG(b.kwh_consumed), 2) AS avg_kwh_per_bill,
    ROUND(AVG(b.total_amount_gbp), 2) AS avg_bill_gbp,
    ROUND(SUM(b.total_amount_gbp) / NULLIF(SUM(b.kwh_consumed), 0), 4) AS gbp_per_kwh
FROM DEMOGRAPHIC_PROFILE d
JOIN HOUSEHOLD_DEMOGRAPHIC hd ON hd.demographic_id = d.demographic_id
JOIN ENERGY_BILL b ON b.household_id = hd.household_id
GROUP BY d.vulnerability_flag
ORDER BY d.vulnerability_flag DESC;

-- GitHub user: altay-frzc
-- Question: Which type of commodity shock has the largest average impact on
--           regional inflation?
-- Why it matters: links wholesale energy shocks to inflation, which is the
--           link between energy prices and inflation that the project studies.
-- Note: observations with an unknown impact_value are excluded.
SELECT
    c.commodity_type,
    s.impact_type,
    COUNT(*) AS observations,
    ROUND(AVG(s.impact_value), 4) AS avg_impact_value,
    ROUND(AVG(m.inflation_rate), 3) AS avg_inflation_rate
FROM SHOCK_IMPACT_LOG s
JOIN COMMODITY_SHOCK c ON c.shock_id = s.shock_id
JOIN MACROECONOMIC_METRIC m ON m.metric_id = s.metric_id
WHERE s.impact_value IS NOT NULL
GROUP BY c.commodity_type, s.impact_type
ORDER BY avg_impact_value DESC, c.commodity_type, s.impact_type;

-- GitHub user: mystermy
-- higher price per kWh vs consumption increase?
-- limitation: the consumption is the dataset's assumption,
-- household usage is not measured.

WITH annual_data AS (
    SELECT
        pm.payment_method_id,
        pm.payment_method_name,
        YEAR(b.billing_period_start) AS recording_year,
        AVG(b.price_cap_rate) AS price_per_kwh,
        AVG(b.kwh_consumed) AS consumption_kwh
    FROM ENERGY_BILL b
    JOIN HOUSEHOLD h ON h.household_id = b.household_id
    JOIN ENERGY_SUPPLIER s ON s.supplier_id = b.supplier_id
    JOIN PAYMENT_METHOD pm
        ON pm.payment_method_id = b.payment_method_id
    WHERE h.postcode = 'UK-AVG'
      AND s.ofgem_license_code = 'NATIONAL-AVG'
    GROUP BY
        pm.payment_method_id,
        pm.payment_method_name,
        YEAR(b.billing_period_start)
),
previous_values AS (
    SELECT
        *,
        LAG(recording_year) OVER (
            PARTITION BY payment_method_id ORDER BY recording_year
        ) AS previous_year,
        LAG(price_per_kwh) OVER (
            PARTITION BY payment_method_id ORDER BY recording_year
        ) AS previous_price,
        LAG(consumption_kwh) OVER (
            PARTITION BY payment_method_id ORDER BY recording_year
        ) AS previous_consumption
    FROM annual_data
),
growth AS (
    SELECT
        *,
        100.0 * (price_per_kwh - previous_price)
            / NULLIF(previous_price, 0) AS price_change_pct,
        100.0 * (consumption_kwh - previous_consumption)
            / NULLIF(previous_consumption, 0) AS consumption_change_pct
    FROM previous_values
    WHERE recording_year = previous_year + 1
)
SELECT
    recording_year,
    payment_method_name,
    ROUND(price_per_kwh, 4) AS price_per_kwh_gbp,
    ROUND(consumption_kwh, 2) AS standard_consumption_kwh,
    ROUND(price_change_pct, 2) AS price_change_pct,
    ROUND(consumption_change_pct, 2) AS consumption_change_pct,
    CASE
        WHEN price_change_pct IS NULL
          OR consumption_change_pct IS NULL THEN 'unk'
        WHEN price_change_pct > 0
         AND price_change_pct > consumption_change_pct THEN 'yes'
        ELSE 'no'
    END AS price_rose_faster
FROM growth
ORDER BY recording_year, payment_method_name;
-- mystermy
-- highest average inflation by region
-- all regions tied for highest.
-- regional inflation records are just mock data.

WITH regional_averages AS (
    SELECT
        r.region_id,
        r.region_name,
        COUNT(*) AS observations,
        MIN(m.recording_date) AS first_date,
        MAX(m.recording_date) AS last_date,
        AVG(m.inflation_rate) AS avg_inflation_rate
    FROM REGION r
    JOIN MACROECONOMIC_METRIC m ON m.region_id = r.region_id
    WHERE r.region_name <> 'United Kingdom'
    GROUP BY r.region_id, r.region_name
),
ranked_regions AS (
    SELECT
        *,
        DENSE_RANK() OVER (
            ORDER BY avg_inflation_rate DESC
        ) AS inflation_rank
    FROM regional_averages
)
SELECT
    region_name,
    ROUND(avg_inflation_rate, 3) AS avg_inflation_rate_pct,
    observations,
    first_date,
    last_date
FROM ranked_regions
WHERE inflation_rank = 1
ORDER BY region_name;
