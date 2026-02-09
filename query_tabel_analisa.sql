CREATE OR REPLACE TABLE `rakamin-kf-analytics-486815.kimia_farma.tabel_analisa` AS

WITH ft AS (
  SELECT
    transaction_id,
    DATE(date) AS date,
    CAST(branch_id AS STRING) AS branch_id,
    customer_name,
    CAST(product_id AS STRING) AS product_id,
    SAFE_CAST(price AS NUMERIC) AS price,
    SAFE_CAST(discount_percentage AS FLOAT64) AS discount_fraction,
    SAFE_CAST(rating AS FLOAT64) AS rating_trx,
    1 AS item_count
  FROM `rakamin-kf-analytics-486815.kimia_farma.kf_final_transaction`
),

prod AS (
  SELECT
    product_id,
    product_name,
    SAFE_CAST(price AS NUMERIC) AS product_price
  FROM `rakamin-kf-analytics-486815.kimia_farma.kf_product`
),

branch AS (
  SELECT
    CAST(branch_id AS STRING) AS branch_id,
    branch_name,
    kota,
    provinsi,
    SAFE_CAST(rating AS FLOAT64) AS rating_cabang   -- <- catatan: kolom rating di sini
  FROM `rakamin-kf-analytics-486815.kimia_farma.kf_kantor_cabang`
)

SELECT
  ft.transaction_id,
  ft.date,
  ft.branch_id,
  b.branch_name,
  b.kota,
  b.provinsi,
  b.rating_cabang,
  ft.customer_name,
  ft.product_id,
  COALESCE(p.product_name, 'UNKNOWN') AS product_name,
  COALESCE(ft.price, p.product_price, 0) AS actual_price,
  ft.discount_fraction,
  ROUND(ft.discount_fraction * 100, 2) AS discount_percentage,
  CASE
    WHEN COALESCE(ft.price, p.product_price, 0) <= 50000 THEN 10
    WHEN COALESCE(ft.price, p.product_price, 0) <= 100000 THEN 15
    WHEN COALESCE(ft.price, p.product_price, 0) <= 300000 THEN 20
    WHEN COALESCE(ft.price, p.product_price, 0) <= 500000 THEN 25
    ELSE 30
  END AS persentase_gross_laba,
  ROUND(COALESCE(ft.price, p.product_price, 0) * (1 - COALESCE(ft.discount_fraction, 0)), 2) AS nett_sales,
  ROUND(
    COALESCE(ft.price, p.product_price, 0)
    * (1 - COALESCE(ft.discount_fraction, 0))
    * (
      CASE
        WHEN COALESCE(ft.price, p.product_price, 0) <= 50000 THEN 0.10
        WHEN COALESCE(ft.price, p.product_price, 0) <= 100000 THEN 0.15
        WHEN COALESCE(ft.price, p.product_price, 0) <= 300000 THEN 0.20
        WHEN COALESCE(ft.price, p.product_price, 0) <= 500000 THEN 0.25
        ELSE 0.30
      END
    )
  , 2) AS nett_profit,
  ft.rating_trx AS rating_transaksi
FROM ft
LEFT JOIN prod p ON ft.product_id = p.product_id
LEFT JOIN branch b ON ft.branch_id = b.branch_id;
