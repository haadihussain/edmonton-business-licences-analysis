-- =====================================================================
-- 01_load_and_clean.sql
-- Load the City of Edmonton business licences CSV into SQLite and build
-- a cleaned table with one row per licence-category pair.
--
-- Usage (run from the project folder, which contains business_licences.csv):
--   sqlite3 edmonton_business.db
--   .read sql/01_load_and_clean.sql
-- =====================================================================


-- ---------------------------------------------------------------------
-- 1. Raw table. Every column is TEXT, in the same order as the CSV, so
--    the import never fails on messy values.
-- ---------------------------------------------------------------------
DROP TABLE IF EXISTS business_licences;

CREATE TABLE business_licences (
  category                TEXT,
  business_name           TEXT,
  address                 TEXT,
  licence_number          TEXT,
  most_recent_issue_date  TEXT,
  expiry_date             TEXT,
  improvement_area        TEXT,
  neighbourhood_id        TEXT,
  neighbourhood           TEXT,
  ward                    TEXT,
  latitude                TEXT,
  longitude               TEXT,
  location                TEXT,
  count                   TEXT,
  geometry_point          TEXT,
  original_issue_date     TEXT,
  licence_duration        TEXT,
  licence_type            TEXT
);

.mode csv
.import --skip 1 business_licences.csv business_licences
.headers on
.mode column

-- Check: expect 43678 rows (data file dated 2026-10-23)
SELECT COUNT(*) AS raw_rows FROM business_licences;


-- ---------------------------------------------------------------------
-- 2. Split multi-category rows.
--    The category column sometimes holds several categories joined by
--    semicolons (e.g. "Hotel / Motel;Exhibition Hall"). A recursive query
--    peels off one category at a time so each gets its own row.
-- ---------------------------------------------------------------------
DROP TABLE IF EXISTS category_split;

CREATE TABLE category_split AS
WITH RECURSIVE split(src_id, part, rest) AS (
  SELECT rowid, '', category || ';'
  FROM business_licences
  UNION ALL
  SELECT src_id,
         TRIM(SUBSTR(rest, 1, INSTR(rest, ';') - 1)),
         SUBSTR(rest, INSTR(rest, ';') + 1)
  FROM split
  WHERE rest <> ''
)
SELECT b.rowid AS src_id,
       b.licence_number,
       s.part AS category_single,
       b.business_name,
       b.address,
       b.neighbourhood,
       b.ward,
       b.licence_type
FROM split s
JOIN business_licences b ON b.rowid = s.src_id
WHERE s.part <> '';

-- Check: expect 54139 rows and 66 distinct categories
SELECT COUNT(*) AS split_rows,
       COUNT(DISTINCT category_single) AS distinct_categories
FROM category_split;


-- ---------------------------------------------------------------------
-- 3. Remove duplicates for licences with a real licence number.
--    Rows repeat because (a) coordinates vary slightly between records of
--    the same licence, and (b) some licences appear both as single-category
--    rows and inside a combined row. DISTINCT on the columns that matter
--    collapses both kinds of repeat.
--
--    Redacted licence numbers are handled separately (step 5): every
--    redacted row shares the placeholder '<REDACTED FOR PRIVACY>', so
--    identical-looking rows cannot be told apart from different
--    practitioners and are kept as they are.
-- ---------------------------------------------------------------------
DROP TABLE IF EXISTS licence_categories;

CREATE TABLE licence_categories AS
SELECT DISTINCT licence_number, category_single, business_name,
       address, neighbourhood, ward, licence_type
FROM category_split
WHERE licence_number NOT LIKE '%REDACTED%';

-- Check: expect 50094 rows, but only 50074 unique licence-category pairs
SELECT COUNT(*) AS rows_total,
       COUNT(DISTINCT licence_number || '|' || category_single) AS unique_licence_category_pairs
FROM licence_categories;


-- ---------------------------------------------------------------------
-- 4. One row per licence-category pair.
--    The 20 remaining repeats differ only in neighbourhood (one record
--    has a neighbourhood, the other is blank or on a nearby boundary).
--    MAX(neighbourhood) prefers a filled-in value over a blank one.
--    (SQLite-specific: with a single MAX(), the other columns come from
--    the same row.)
-- ---------------------------------------------------------------------
DROP TABLE IF EXISTS licence_categories_clean;

CREATE TABLE licence_categories_clean AS
SELECT licence_number, category_single, business_name, address,
       MAX(neighbourhood) AS neighbourhood, ward, licence_type
FROM licence_categories
GROUP BY licence_number, category_single;

-- Check: expect 50074
SELECT COUNT(*) AS clean_rows FROM licence_categories_clean;


-- ---------------------------------------------------------------------
-- 5. Final analysis table: real licence numbers plus every redacted row,
--    with a flag so queries can include or exclude the redacted rows.
-- ---------------------------------------------------------------------
DROP TABLE IF EXISTS licences_final;

CREATE TABLE licences_final AS
SELECT licence_number, category_single, business_name, address,
       neighbourhood, ward, licence_type, 0 AS is_redacted
FROM licence_categories_clean
UNION ALL
SELECT licence_number, category_single, business_name, address,
       neighbourhood, ward, licence_type, 1 AS is_redacted
FROM category_split
WHERE licence_number LIKE '%REDACTED%';

-- Check: expect 50074 rows with is_redacted = 0 and 3555 with is_redacted = 1
SELECT is_redacted, COUNT(*) AS rows_count
FROM licences_final
GROUP BY is_redacted;
