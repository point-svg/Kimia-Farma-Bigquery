-- Membuat tabel analisa transaksi Kimia Farma (2020-2023)
CREATE TABLE `rakamin-kf-analytics-486815.kimia_farma.tabel_analisa` AS

-- final transaction
WITH ft AS (
  SELECT
    transaction_id, -- Kode unik transaksi
    DATE(date) AS date, -- Tanggal transaksi
    CAST(branch_id AS STRING) AS branch_id, -- Kode cabang sebagai string
    customer_name, -- Nama customer
    CAST(product_id AS STRING) AS product_id, -- Kode produk sebagai string
    SAFE_CAST(price AS NUMERIC) AS price, -- Harga produk per unit
    SAFE_CAST(discount_percentage AS FLOAT64) AS discount_fraction, -- Diskon dalam bentuk desimal
    SAFE_CAST(rating AS FLOAT64) AS rating_trx, -- Rating transaksi
    1 AS item_count -- Jumlah item default = 1
  FROM `rakamin-kf-analytics-486815.kimia_farma.kf_final_transaction`
),

-- product info
prod AS (
  SELECT
    product_id, -- Kode produk
    product_name, -- Nama produk
    SAFE_CAST(price AS NUMERIC) AS product_price -- Harga produk
  FROM `rakamin-kf-analytics-486815.kimia_farma.kf_product`
),

-- branch info
branch AS (
  SELECT
    CAST(branch_id AS STRING) AS branch_id, -- Kode cabang sebagai string
    branch_name, -- Nama cabang
    kota, -- Kota cabang
    provinsi, -- Provinsi cabang
    SAFE_CAST(rating AS FLOAT64) AS rating_cabang   -- Rating cabang
  FROM `rakamin-kf-analytics-486815.kimia_farma.kf_kantor_cabang`
)

-- Select final data untuk tabel analisa
SELECT
  ft.transaction_id, -- ID transaksi
  ft.date, -- Tanggal transaksi
  ft.branch_id, -- Kode cabang
  b.branch_name, -- Nama cabang
  b.kota, -- Kota cabang
  b.provinsi, -- Provinsi cabang
  b.rating_cabang, -- Rating cabang
  ft.customer_name, -- Nama customer
  ft.product_id, -- Kode produk
  COALESCE(p.product_name, 'UNKNOWN') AS product_name, -- Nama produk
  COALESCE(ft.price, p.product_price, 0) AS actual_price, -- Harga produk yang digunakan
  ft.discount_fraction, -- Diskon (desimal)
  ROUND(ft.discount_fraction * 100, 2) AS discount_percentage, -- Diskon dalam persen
  CASE
    WHEN COALESCE(ft.price, p.product_price, 0) <= 50000 THEN 10
    WHEN COALESCE(ft.price, p.product_price, 0) <= 100000 THEN 15
    WHEN COALESCE(ft.price, p.product_price, 0) <= 300000 THEN 20
    WHEN COALESCE(ft.price, p.product_price, 0) <= 500000 THEN 25
    ELSE 30
  END AS persentase_gross_laba, -- Persentase laba kotor sesuai ketentuan
  ROUND(COALESCE(ft.price, p.product_price, 0) * (1 - COALESCE(ft.discount_fraction, 0)), 2) AS nett_sales, -- Harga setelah diskon
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
  , 2) AS nett_profit, -- Keuntungan bersih
  ft.rating_trx AS rating_transaksi -- Rating transaksi customer
FROM ft
LEFT JOIN prod p ON ft.product_id = p.product_id -- Gabung info produk
LEFT JOIN branch b ON ft.branch_id = b.branch_id; -- Gabung info cabang
