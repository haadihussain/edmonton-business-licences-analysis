-- =====================================================================
-- 02_analysis.sql
-- Data-quality checks and the queries behind the project's findings.
-- Run after 01_load_and_clean.sql, inside the same database:
--   .read sql/02_analysis.sql
--
-- Counts are LICENCE-CATEGORY records, not unique businesses: a licence
-- covering several categories is counted once in each.
-- Results noted in comments are from the data file dated 2026-10-23.
-- =====================================================================

.headers on
.mode column


-- =====================================================================
-- PART A. DATA QUALITY
-- =====================================================================

-- A1. Missing values in the columns used for the main question.
--     Result: 0 missing categories; 4,562 rows with no neighbourhood or ward.
SELECT
  SUM(CASE WHEN category IS NULL OR category = '' THEN 1 ELSE 0 END)           AS missing_category,
  SUM(CASE WHEN neighbourhood IS NULL OR neighbourhood = '' THEN 1 ELSE 0 END) AS missing_neighbourhood,
  SUM(CASE WHEN ward IS NULL OR ward = '' THEN 1 ELSE 0 END)                   AS missing_ward
FROM business_licences;

-- A2. Which licence types have a blank neighbourhood?
--     Result: Non-Resident 2,122; Massage Practitioner 1,569;
--     Adult Services 711; Commercial 140; Home Based 20.
SELECT licence_type, COUNT(*) AS missing_rows
FROM business_licences
WHERE neighbourhood = ''
GROUP BY licence_type
ORDER BY missing_rows DESC;

-- A3. Duplicate licence numbers.
--     Result: 43,678 rows but 40,212 distinct licence numbers. Most of the
--     gap is the single placeholder '<REDACTED FOR PRIVACY>', which appears
--     on 2,902 rows, so COUNT(DISTINCT licence_number) undercounts licences.
SELECT COUNT(*) AS total_rows,
       COUNT(DISTINCT licence_number) AS unique_licences
FROM business_licences;

SELECT licence_number, COUNT(*) AS times_listed
FROM business_licences
GROUP BY licence_number
HAVING COUNT(*) > 1
ORDER BY times_listed DESC
LIMIT 10;

-- A4. Which licence types have redacted licence numbers?
--     Result: Massage Practitioner 1,595; Adult Services 770;
--     Home Based 504; Commercial 26; Non-Resident 7.
SELECT licence_type, COUNT(*) AS redacted_rows
FROM business_licences
WHERE licence_number LIKE '%REDACTED%'
GROUP BY licence_type
ORDER BY redacted_rows DESC;

-- A5. What do the Massage Practitioner and Adult Services licence types contain?
--     Result: Massage Practitioner is almost all "Health Enhancement
--     Practitioner (Accredited)"; Adult Services holds body rub, erotic
--     entertainer and escort categories.
SELECT licence_type, category, COUNT(*) AS rows_count
FROM business_licences
WHERE licence_type IN ('Massage Practitioner', 'Adult Services')
GROUP BY licence_type, category
ORDER BY licence_type, rows_count DESC;

-- A6. Repeated licence numbers that differ only in coordinates.
--     Example: licence 267628186-009 appears 9 times; latitude, longitude,
--     location and geometry_point differ, every other column is identical.
SELECT latitude, longitude
FROM business_licences
WHERE licence_number = '267628186-009';

-- A7. Licences that exist ONLY as a combined (semicolon) row, with no
--     single-category row.
--     Result: 6,838 licences, which is why combined rows are split rather
--     than dropped (see 01_load_and_clean.sql, step 2).
SELECT COUNT(DISTINCT licence_number) AS licences_with_only_combined_rows
FROM business_licences
WHERE category LIKE '%;%'
  AND licence_number NOT LIKE '%REDACTED%'
  AND licence_number NOT IN (
    SELECT licence_number
    FROM business_licences
    WHERE category NOT LIKE '%;%'
  );


-- =====================================================================
-- PART B. WHICH CATEGORIES DOMINATE?
-- =====================================================================

-- B1. Top 10 categories overall, with and without redacted rows.
--     Result: Construction, Contracting, and Labour Service leads (9,449 rows),
--     then Administration Office / Professional Service (5,817) and
--     Retail Sales (Minor) (4,946). Health Enhancement Practitioner
--     (Accredited) has 0 non-redacted rows and 2,127 with redacted rows.
SELECT category_single,
       SUM(CASE WHEN is_redacted = 0 THEN 1 ELSE 0 END) AS without_redacted,
       COUNT(*) AS with_redacted
FROM licences_final
GROUP BY category_single
ORDER BY with_redacted DESC
LIMIT 10;

-- B2. Licence-type mix of the four largest categories.
--     Result: Construction is 54% Home Based, 28% Commercial, 18% Non-Resident;
--     Restaurant or Food Service is essentially all Commercial.
SELECT category_single, licence_type, COUNT(*) AS rows_count
FROM licences_final
WHERE category_single IN (
  'Construction, Contracting, and Labour Service',
  'Administration Office / Professional Service',
  'Retail Sales (Minor)',
  'Restaurant or Food Service'
)
GROUP BY category_single, licence_type
ORDER BY category_single, rows_count DESC;

-- B3. Top 10 categories among COMMERCIAL licences only.
--     Result: Restaurant or Food Service (3,481) and Retail Sales (Minor)
--     (3,465) lead; Construction drops to fourth (2,628).
SELECT category_single, COUNT(*) AS commercial_rows
FROM licences_final
WHERE licence_type = 'Commercial'
GROUP BY category_single
ORDER BY commercial_rows DESC
LIMIT 10;


-- =====================================================================
-- PART C. WHERE ARE THEY CONCENTRATED?
-- =====================================================================

-- C1. Top four commercial categories by ward.
--     Result: six wards (O-day'min, Nakota Isga, Karhiio, Métis, papastew,
--     Anirniq) each hold more than 3,000 commercial rows. One ward value is
--     blank and one is a combined value for two wards; both are excluded
--     from the ward chart.
SELECT ward,
  SUM(CASE WHEN category_single = 'Restaurant or Food Service' THEN 1 ELSE 0 END) AS restaurant,
  SUM(CASE WHEN category_single = 'Retail Sales (Minor)' THEN 1 ELSE 0 END) AS retail,
  SUM(CASE WHEN category_single = 'Administration Office / Professional Service' THEN 1 ELSE 0 END) AS admin_prof,
  SUM(CASE WHEN category_single = 'Construction, Contracting, and Labour Service' THEN 1 ELSE 0 END) AS construction,
  COUNT(*) AS all_commercial
FROM licences_final
WHERE licence_type = 'Commercial'
GROUP BY ward
ORDER BY all_commercial DESC;

-- C2. Top 10 neighbourhoods by commercial licences.
--     Result: Downtown leads (1,483); six of the top ten names contain "Industrial".
SELECT neighbourhood, COUNT(*) AS commercial_rows
FROM licences_final
WHERE licence_type = 'Commercial'
  AND neighbourhood <> ''
GROUP BY neighbourhood
ORDER BY commercial_rows DESC
LIMIT 10;

-- C3. Category mix in a single neighbourhood (change the name to compare).
--     Result for Downtown: Administration / Professional Service is 418 of
--     1,483 commercial rows (about 28%, versus roughly 8% citywide).
SELECT category_single, COUNT(*) AS rows_count
FROM licences_final
WHERE licence_type = 'Commercial'
  AND neighbourhood = 'Downtown'
GROUP BY category_single
ORDER BY rows_count DESC
LIMIT 5;
