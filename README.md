# Amazon Products: Data Cleaning and Analysis with SQL

A beginner-friendly data analyst project. I took a messy Amazon product dataset, cleaned it in MySQL, and answered business questions about discounts, prices and ratings.

## Objective

Turn a raw CSV (1,465 rows, 16 columns, everything stored as text) into a clean, analysis-ready table, then use it to answer questions such as *Which categories give the biggest discounts?* and *Do heavily discounted products get worse ratings?*

## Tools

- MySQL 8.0 and MySQL Workbench
- SQL: `REGEXP_REPLACE`, `REPLACE`, `CAST`, `NULLIF`, `SUBSTRING_INDEX`, `GROUP BY`, `CASE`
- Excel (for charts and a dashboard)

## Dataset

Amazon Sales dataset from Kaggle: https://www.kaggle.com/datasets/karkavelrajaj/amazon-sales-dataset
The raw file is not included in this repository. Download it from the link above.

## Problems Found in the Raw Data

| Problem | Example | Fix |
|---|---|---|
| Prices stored as text with symbols | `₹1,099` | Remove non-numeric characters, convert to `DECIMAL` |
| Discount stored as text | `64%` | Remove `%`, convert to `DECIMAL` |
| One invalid rating | `\|` | Converted to `NULL` using `NULLIF` |
| Blank rating counts (2 rows) | *(empty)* | Converted to `NULL` using `NULLIF` |
| Rating counts with commas | `24,269` | Remove commas, convert to a whole number |
| Whole category path in one cell | `Computers&Accessories\|Accessories&Peripherals\|...` | Split into `main_category` and `subcategory` |
| Duplicate products | 1,465 rows but only 1,351 unique `product_id` values | `GROUP BY product_id` to keep one row per product |

## Cleaning Steps

1. Created a raw table with every column as text and loaded the CSV using `LOAD DATA LOCAL INFILE`.
2. Backed up the raw data (`amazon_raw`).
3. Profiled the data to find bad values (regex checks, blank checks, duplicate checks).
4. Built `amazon_clean`: converted prices, discount, rating and rating count to numbers, and split the category.
5. Built `amazon_final`: removed duplicate products.
6. Ran a final quality check (1,351 unique products, 1 missing rating, 2 missing rating counts).

### Columns removed

`about_product`, `img_link`, `product_link`, `user_id`, `user_name`, `review_id`, `review_title` and `review_content` were left out. They are long text or links, and the review columns hold several comma-separated reviews in one cell, so they don't support this analysis.

## Key Findings

These numbers come from the cleaned table (1,351 products).

- **Electronics (490), Home&Kitchen (448) and Computers&Accessories (375)** make up almost all products.
- **Computers&Accessories has the highest average discount (53.2%)**, followed by Electronics (49.9%) and Home&Kitchen (40.1%). OfficeProducts is far lower at 12.4%.
- **About 49% of all products are discounted by 50% or more.**
- **Higher discounts go with slightly lower ratings.** Average rating falls from 4.17 (0-20% discount) to 4.05 (61-100% discount). The gap is small, so it shows a mild pattern, not a strong effect.
- **Prices are skewed towards the low end:** 501 products cost up to ₹500, while only 203 cost more than ₹5,000.
- The overall average rating is 4.09.

## Project Structure

```
amazon-sales-sql-project/
├── README.md
├── sql/
│   ├── 01_data_cleaning.sql    # load, profile, clean, deduplicate
│   └── 02_analysis.sql         # 10 analysis queries
├── data/
│   └── amazon_cleaned.csv      # final cleaned table (1,351 rows)
└── screenshots/                # query results and dashboard
```

## How to Run

1. Download the raw `amazon.csv` from the Kaggle link above.
2. Open `sql/01_data_cleaning.sql` in MySQL Workbench.
3. Change the file path in the `LOAD DATA LOCAL INFILE` step to where you saved the CSV.
4. If you get Error 2068, run `SET GLOBAL local_infile = 1;` and add `OPT_LOCAL_INFILE=1` under *Manage Connections > Advanced > Others*, then reconnect.
5. Run the script from top to bottom.
6. Run `sql/02_analysis.sql` to reproduce the analysis.

## What I Learned

- Loading messy data as text first, then converting it, avoids load errors.
- `NULLIF` turns bad values into `NULL` instead of breaking a `CAST`.
- Profiling every column for values that don't fit the expected pattern is a core part of cleaning.
- Duplicate rows are not always identical, so the right deduplication method depends on the data.

## Next Steps

- Build an Excel dashboard (pivot tables and charts) from `data/amazon_cleaned.csv`.
- Split the review columns into one row per review and analyse review text.
- Add a Power BI or Tableau dashboard.
