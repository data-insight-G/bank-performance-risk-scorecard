WHENEVER SQLERROR EXIT SQL.SQLCODE ROLLBACK;

INSERT INTO dim_asset_size_band (
    asset_size_band_key, asset_size_band_name, lower_asset_thousands, upper_asset_thousands, display_order
) VALUES (1, 'Under $1B', 0, 1000000, 1);

INSERT INTO dim_asset_size_band (
    asset_size_band_key, asset_size_band_name, lower_asset_thousands, upper_asset_thousands, display_order
) VALUES (2, '$1B-$10B', 1000000, 10000000, 2);

INSERT INTO dim_asset_size_band (
    asset_size_band_key, asset_size_band_name, lower_asset_thousands, upper_asset_thousands, display_order
) VALUES (3, '$10B-$250B', 10000000, 250000000, 3);

INSERT INTO dim_asset_size_band (
    asset_size_band_key, asset_size_band_name, lower_asset_thousands, upper_asset_thousands, display_order
) VALUES (4, '$250B+', 250000000, NULL, 4);

INSERT INTO dim_reporting_quarter (
    report_date, calendar_year, quarter_number, quarter_label
)
SELECT report_date,
       EXTRACT(YEAR FROM report_date),
       TO_NUMBER(TO_CHAR(report_date, 'Q')),
       TO_CHAR(report_date, 'YYYY') || ' Q' || TO_CHAR(report_date, 'Q')
FROM (
    SELECT ADD_MONTHS(DATE '2020-03-31', (LEVEL - 1) * 3) AS report_date
    FROM dual
    CONNECT BY LEVEL <= 20
);

COMMIT;
