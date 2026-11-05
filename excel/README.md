# Excel Power Query extraction

`fdic_financials_power_query.pq` is the project's only data-acquisition layer. It uses Excel Power Query to:

1. Call the official FDIC BankFind Financials API.
2. Page through all records in 10,000-row blocks.
3. Select the 29 documented project fields.
4. Apply explicit data types.
5. Reject row-count mismatches, duplicate institution-quarter keys, and unexpected reporting dates.
6. Return a validated 96,902-row table for the fixed 2020 Q1–2024 Q4 snapshot.

## Use in Excel

1. Open Excel and choose **Data → Get Data → From Other Sources → Blank Query**.
2. Open **Advanced Editor** and replace its contents with the query in `fdic_financials_power_query.pq`.
3. Name the query `FDIC Financials` and choose **Close & Load**.
4. Export the loaded table as UTF-8 CSV with the name `fdic_financials_2020q1_2024q4.csv`.
5. Place the CSV in the Oracle server directory represented by `FDIC_DATA_DIR`.
6. Run the Oracle scripts in the order documented in the main README.

Excel supports more than the 96,902 rows returned by this query. Do not manually edit source values after loading.
