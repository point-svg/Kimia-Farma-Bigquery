# Kimia-Farma-Bigquery
Query BigQuery Dashboard Kimia Farma
# Tabel Analisa Transaksi Kimia Farma (2020-2023)

## Deskripsi
Tabel `tabel_analisa` dibuat untuk **menganalisis kinerja Kimia Farma** pada periode 2020–2023.  
Tabel ini menggabungkan data dari tiga sumber utama:

1. **Transaksi (`kf_final_transaction`)** – berisi informasi transaksi customer, harga, diskon, dan rating transaksi.  
2. **Produk (`kf_product`)** – berisi kode produk, nama produk, dan harga dasar produk.  
3. **Cabang (`kf_kantor_cabang`)** – berisi kode cabang, nama cabang, kota, provinsi, dan rating cabang.

Tabel ini siap digunakan untuk visualisasi **Looker Studio / Google Data Studio** untuk dashboard performance analytics Kimia Farma.

---

## Struktur Tabel `tabel_analisa`

| Kolom | Tipe | Deskripsi |
|-------|------|-----------|
| `transaction_id` | STRING | Kode unik tiap transaksi |
| `date` | DATE | Tanggal transaksi |
| `branch_id` | STRING | Kode cabang Kimia Farma |
| `branch_name` | STRING | Nama cabang |
| `kota` | STRING | Kota cabang |
| `provinsi` | STRING | Provinsi cabang |
| `rating_cabang` | FLOAT64 | Penilaian konsumen terhadap cabang |
| `customer_name` | STRING | Nama customer yang melakukan transaksi |
| `product_id` | STRING | Kode produk |
| `product_name` | STRING | Nama produk (fallback 'UNKNOWN') |
| `actual_price` | NUMERIC | Harga produk yang digunakan dalam transaksi |
| `discount_fraction` | FLOAT64 | Diskon dalam bentuk desimal (0.1 = 10%) |
| `discount_percentage` | FLOAT64 | Diskon dalam persen (0–100%) |
| `persentase_gross_laba` | INT64 | Persentase laba kotor sesuai harga:<br>≤50k → 10%, 50k–100k → 15%, 100k–300k → 20%, 300k–500k → 25%, >500k → 30% |
| `nett_sales` | NUMERIC | Harga setelah diskon |
| `nett_profit` | NUMERIC | Keuntungan bersih dari transaksi |
| `rating_transaksi` | FLOAT64 | Rating transaksi dari customer |

---

## SQL Pembuatan Tabel

```sql
-- Membuat tabel analisa transaksi Kimia Farma (2020-2023)
-- Tabel ini menggabungkan data transaksi, produk, dan cabang
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

