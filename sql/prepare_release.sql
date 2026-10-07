-- Run once on energy_inflation BEFORE making the dump for Zenodo.
-- The mock households use real, full UK postcodes (e.g. 'SW1A 1AA' is Buckingham Palace).
-- A full postcode covers only ~15 addresses, so combined with tenure, occupant count and
-- the linked income/vulnerability profile it could be read as describing a real household.
-- This keeps only the postcode district (the part before the space): 'SW1A 1AA' -> 'SW1A'.
-- Placeholder codes without a space (e.g. 'UK-AVG') are left unchanged.

SET SQL_SAFE_UPDATES = 0;   -- MySQL Workbench blocks UPDATEs on non-key columns otherwise

UPDATE HOUSEHOLD
SET postcode = SUBSTRING_INDEX(postcode, ' ', 1)
WHERE postcode LIKE '% %';

SET SQL_SAFE_UPDATES = 1;

-- Check: should return 0
SELECT COUNT(*) AS full_postcodes_left FROM HOUSEHOLD WHERE postcode LIKE '% %';