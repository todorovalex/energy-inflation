-- Queries on support schemes and mortgage stress (MySQL 8.0+).
-- Run after schema.sql, seed_data.sql and seed_data_real.sql, with energy_inflation selected.
-- Aliases: b = ENERGY_BILL, s = ENERGY_SUPPLIER, p = CENTRAL_BANK_POLICY, i = HOUSEHOLD_POLICY_IMPACT.

-- 4. Support schemes and bills
-- Author: @angeellucaas
-- Question: Do households whose supplier is enrolled in a support scheme pay a lower
--   average bill and a lower price per kWh than households whose supplier is not enrolled?
-- Why it matters: support schemes are meant to protect households from rising energy
--   prices. If enrolled suppliers' customers do not pay less, the schemes may not be
--   cushioning energy inflation, or our data does not capture their effect.
-- Approach: bills are compared within the same billing period only, so quarterly bills
--   are not mixed with the annual national averages (NATIONAL-AVG is excluded). Price per
--   kWh is shown next to the bill total, because a lower total can simply mean lower
--   consumption. CASE inside AVG/SUM places both groups side by side in one row.
SELECT
    b.billing_period_start,
    b.billing_period_end,
    SUM(CASE WHEN s.support_scheme_enrolled THEN 1 ELSE 0 END)     AS bills_enrolled,
    SUM(CASE WHEN NOT s.support_scheme_enrolled THEN 1 ELSE 0 END) AS bills_not_enrolled,
    ROUND(AVG(CASE WHEN s.support_scheme_enrolled THEN b.total_amount_gbp END), 2)     AS avg_bill_enrolled_gbp,
    ROUND(AVG(CASE WHEN NOT s.support_scheme_enrolled THEN b.total_amount_gbp END), 2) AS avg_bill_not_enrolled_gbp,
    ROUND(SUM(CASE WHEN s.support_scheme_enrolled THEN b.total_amount_gbp END)
        / SUM(CASE WHEN s.support_scheme_enrolled THEN b.kwh_consumed END), 4)         AS gbp_per_kwh_enrolled,
    ROUND(SUM(CASE WHEN NOT s.support_scheme_enrolled THEN b.total_amount_gbp END)
        / SUM(CASE WHEN NOT s.support_scheme_enrolled THEN b.kwh_consumed END), 4)     AS gbp_per_kwh_not_enrolled
FROM ENERGY_BILL b
JOIN ENERGY_SUPPLIER s ON s.supplier_id = b.supplier_id
WHERE s.ofgem_license_code <> 'NATIONAL-AVG'
GROUP BY b.billing_period_start, b.billing_period_end
HAVING SUM(CASE WHEN s.support_scheme_enrolled THEN 1 ELSE 0 END) > 0
   AND SUM(CASE WHEN NOT s.support_scheme_enrolled THEN 1 ELSE 0 END) > 0
ORDER BY b.billing_period_start;

-- 5. Mortgage stress and borrowing costs
-- Author: @angeellucaas
-- Question: Does household borrowing cost rise alongside the central bank's mortgage
--   stress index?
-- Why it matters: energy-driven inflation led the central bank to raise interest rates,
--   so households are hit twice: higher energy bills and higher borrowing costs. This
--   links the policy side of the database to the cost burden on households.
-- Approach: the CTE averages borrowing costs per policy date that has observations; LAG
--   then gives the change in both the stress index and the average cost since the previous
--   observed date. Both changes positive means they rose together.
-- Limitation: this shows co-movement, not causation (the base rate changed on the same
--   dates). The households column shows whether each date covers the same sample.
WITH per_policy AS (
    SELECT
        p.policy_id,
        p.effective_date,
        p.mortgage_stress_index,
        COUNT(*)                  AS households,
        AVG(i.borrowing_cost_gbp) AS avg_borrowing_cost_gbp
    FROM CENTRAL_BANK_POLICY p
    JOIN HOUSEHOLD_POLICY_IMPACT i ON i.policy_id = p.policy_id
    WHERE i.borrowing_cost_gbp IS NOT NULL
      AND p.mortgage_stress_index IS NOT NULL
    GROUP BY p.policy_id, p.effective_date, p.mortgage_stress_index
)
SELECT
    effective_date,
    mortgage_stress_index,
    mortgage_stress_index
        - LAG(mortgage_stress_index) OVER (ORDER BY effective_date, policy_id)  AS stress_index_change,
    households,
    ROUND(avg_borrowing_cost_gbp, 2)                                            AS avg_borrowing_cost_gbp,
    ROUND(avg_borrowing_cost_gbp
        - LAG(avg_borrowing_cost_gbp) OVER (ORDER BY effective_date, policy_id), 2) AS avg_cost_change_gbp
FROM per_policy
ORDER BY effective_date, policy_id;