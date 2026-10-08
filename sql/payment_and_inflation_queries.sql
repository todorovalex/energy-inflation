-- Author: @todorovalex

-- 6. Average bill per payment method
-- Question: do prepayment customers pay more than direct debit or credit customers?
-- Why it matters: prepayment households are often the poorest ones, so if they pay
-- more, inflation hits them harder.
-- In our data Credit is the most expensive, so prepayment is not the worst one here.
SELECT pm.payment_method_name, ROUND(AVG(b.total_amount_gbp), 2) AS avg_bill
FROM ENERGY_BILL b
JOIN PAYMENT_METHOD pm ON b.payment_method_id = pm.payment_method_id
GROUP BY pm.payment_method_name
ORDER BY avg_bill DESC;

-- 7. Yearly bill and inflation
-- Question: did the electricity bill go up in the same years as inflation?
-- Why it matters: it joins the two real datasets (bills and inflation) and checks
-- if energy prices and inflation move together, which is the main idea of the project.
-- Only the UK average household has real data, so it is filtered by its postcode.
SELECT YEAR(b.billing_period_start) AS year,
       ROUND(AVG(b.total_amount_gbp), 2) AS avg_bill,
       ROUND(AVG(m.inflation_rate), 2) AS avg_inflation
FROM ENERGY_BILL b
JOIN HOUSEHOLD h ON b.household_id = h.household_id
JOIN MACROECONOMIC_METRIC m ON m.region_id = h.region_id
    AND YEAR(m.recording_date) = YEAR(b.billing_period_start)
WHERE h.postcode = 'UK-AVG'
GROUP BY YEAR(b.billing_period_start)
ORDER BY year;