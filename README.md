# Edmonton Business Licences: Which Categories Dominate, and Where?

**Author:** Haadi Hussain

**Interactive dashboard:** [View on Tableau Public](https://public.tableau.com/app/profile/haadi.hussain/viz/EdmontonBusinessLicences/EdmontonCommercialBusinessLicences)

**Tools:** SQLite (data cleaning and analysis), Tableau Public (visualization)

## The question

Which types of business hold the most licences in Edmonton, and where in the city are they concentrated?

## Data

- **Source:** City of Edmonton Open Data Portal, "Business Licences" dataset (data.edmonton.ca)
- **File used:** CSV export dated 2026-10-23, 43,678 rows and 18 columns
- **Attribution:** Contains data from the City of Edmonton Open Data Portal.

The raw data is not stored in this repository. To reproduce the analysis, download the dataset from the portal and save it as `business_licences.csv` in the project folder.

## Key findings

1. **Construction is the largest category overall, but not by commercial premises.** Construction, Contracting, and Labour Service has the most licence-category records (9,449, about 18% of the 53,629 cleaned records). However, only about 28% of its licences are commercial; about 54% are home-based and about 18% are non-resident.
2. **Among commercial licences, restaurants and retail lead.** Restaurant or Food Service (3,481) and Retail Sales (Minor) (3,465) are nearly tied at the top, followed by Administration Office / Professional Service (2,654) and Construction (2,628).
3. **Commercial licences cluster in six wards.** O-day'min, Nakota Isga, Karhiio, Métis, papastew, and Anirniq each hold more than 3,000 commercial records, together about 79% of the 32,139 commercial records with a usable ward.
4. **Downtown and industrial areas lead by neighbourhood.** Downtown has the most commercial records (1,483), and six of the top ten neighbourhoods have "Industrial" in their name. Professional services make up about 28% of Downtown's commercial records, compared with roughly 8% citywide.

## Method

1. Loaded the CSV into SQLite with all columns as text.
2. Split rows where the category field held several categories separated by semicolons, giving one row per licence-category pair (54,139 rows, 66 distinct categories).
3. Removed duplicate rows for licences with a real licence number. Many repeats differed only in map coordinates.
4. Kept redacted rows (licence number shown as a privacy placeholder) as-is and flagged them, because identical-looking redacted rows cannot be told apart from different practitioners.
5. Built three summary tables and charted them in Tableau Public.

## Data quality notes and limitations

- **Counts are licence-category records, not unique businesses.** A licence covering several categories is counted once in each.
- **Redacted licence numbers.** 2,902 raw rows (3,555 after splitting categories) have the licence number hidden, mostly for Massage Practitioner, Adult Services, and Home Based licences. Counting distinct licence numbers would undercount them, and some identical-looking redacted rows may be true repeats.
- **Missing locations.** 4,562 rows (about 10% of the raw data) have no neighbourhood or ward, mostly Non-Resident, Massage Practitioner, and Adult Services licences. The ward chart also leaves out 229 commercial records with a blank ward or a combined two-ward value.
- **Coordinates vary within a licence.** Repeated records of the same licence can have map points a few hundred metres apart, so point-level maps would show duplicates. Counts by ward and neighbourhood are not affected by this.
- **Raw counts, not rates.** Larger or busier wards and neighbourhoods will naturally hold more licences, so the charts show where licences are, not where a category is unusually strong.
- **Snapshot.** Results reflect the data file dated 2026-10-23 and include licences of different ages.

## Repository contents

```
├── README.md
└── sql/
    ├── 01_load_and_clean.sql   load the CSV and build the cleaned tables
    ├── 02_analysis.sql         data-quality checks and the queries behind the findings
    └── 03_exports.sql          export the summary tables used by Tableau
```

## How to reproduce

1. Download the Business Licences CSV from the City of Edmonton Open Data Portal and save it as `business_licences.csv` in the project folder.
2. From that folder, start SQLite: `sqlite3 edmonton_business.db`
3. Run the scripts in order:
   ```
   .read sql/01_load_and_clean.sql
   .read sql/02_analysis.sql
   .read sql/03_exports.sql
   ```
4. Open the exported CSV files in Tableau Public to rebuild the dashboard.
