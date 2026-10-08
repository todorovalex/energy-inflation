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