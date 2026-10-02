
SELECT
  (SELECT COUNT(*) FROM REGION WHERE region_name = 'United Kingdom')                       AS uk_regions,
  (SELECT COUNT(*) FROM PAYMENT_METHOD)                                                    AS payment_methods,
  (SELECT COUNT(*) FROM MACROECONOMIC_METRIC m JOIN REGION r USING (region_id)
    WHERE r.region_name = 'United Kingdom')                                                AS cpi_rows,
  (SELECT COUNT(*) FROM ENERGY_BILL WHERE payment_method_id IS NOT NULL)                   AS real_bills;

SELECT COUNT(*) AS regions_with_conflicting_country
FROM (SELECT region_name FROM REGION GROUP BY region_name HAVING COUNT(DISTINCT country) > 1) x;

SELECT COUNT(*) AS overloaded_households
FROM HOUSEHOLD
WHERE dwelling_type LIKE '%customers%' OR postcode LIKE 'UK-CREDIT' OR postcode LIKE 'UK-DD' OR postcode LIKE 'UK-PPM';

SELECT ROUND(MAX(ABS(kwh_consumed * price_cap_rate - total_amount_gbp)), 2) AS max_gap_gbp
FROM ENERGY_BILL WHERE payment_method_id IS NOT NULL;

SELECT COUNT(*) AS rates_that_look_like_pence FROM ENERGY_BILL WHERE price_cap_rate >= 1;
