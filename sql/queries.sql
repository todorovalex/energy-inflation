-- Advanced analysis queries for MySQL 8.0+.
-- Run after schema.sql and seed_data.sql, with energy_inflation selected.
-- All source columns already exist in schema.sql; no new schema fields are needed.
-- Table aliases: r = REGION, h = HOUSEHOLD, b/other = ENERGY_BILL,
-- i = HOUSEHOLD_POLICY_IMPACT, p = CENTRAL_BANK_POLICY.
-- Calculated names: households = number of represented households;
-- avg_household_cost = quarterly spending per represented household (GBP);
-- changes = temporary CTE result, previous_cost = previous recorded borrowing cost;
-- cost_increase_gbp = current minus previous borrowing cost (GBP).

-- 1. Compare regional household energy spending in Q1 2022.
-- JOINs combine bills with regions; HAVING requires at least three households.
-- Only households with bills fully within the quarter enter the average.
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

-- 2. Identify individual bills above the average for the exact same period.
-- The correlated subquery uses the outer bill's dates for a fairer comparison.
-- Results are bills, not unique households; high spending need not mean hardship.
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

-- 3. Compare each household's borrowing costs across recorded policy dates.
-- LAG retrieves the preceding recorded observation for that household.
-- Unknown current/previous costs are excluded, not treated as zero.
-- Negative changes indicate decreases; these observations do not prove causation.
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

