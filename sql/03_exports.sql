-- =====================================================================
-- 03_exports.sql
-- Export the three small summary tables used by the Tableau dashboard.
-- Run after 01_load_and_clean.sql, inside the same database:
--   .read sql/03_exports.sql
-- The CSV files are written to the folder where sqlite3 was started.
-- =====================================================================

.headers on
.mode csv

-- Chart 1: top 10 commercial licence categories
.output commercial_top10.csv
SELECT category_single, COUNT(*) AS commercial_rows
FROM licences_final
WHERE licence_type = 'Commercial'
GROUP BY category_single
ORDER BY commercial_rows DESC
LIMIT 10;

-- Chart 2: commercial licences by ward
-- (excludes the blank ward and the combined two-ward value)
.output wards.csv
SELECT ward, COUNT(*) AS commercial_rows
FROM licences_final
WHERE licence_type = 'Commercial'
  AND ward <> ''
  AND ward NOT LIKE '%,%'
GROUP BY ward
ORDER BY commercial_rows DESC;

-- Chart 3: licence-type mix of the four largest categories
-- (limited to the three main licence types; 2 stray records are excluded)
.output category_by_type.csv
SELECT category_single, licence_type, COUNT(*) AS rows_count
FROM licences_final
WHERE category_single IN (
  'Construction, Contracting, and Labour Service',
  'Administration Office / Professional Service',
  'Retail Sales (Minor)',
  'Restaurant or Food Service'
)
  AND licence_type IN ('Commercial', 'Home Based', 'Non-Resident')
GROUP BY category_single, licence_type;

-- Send output back to the screen
.output stdout
.mode column
