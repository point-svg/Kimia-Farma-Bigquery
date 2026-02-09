# Kimia-Farma-Bigquery
Query BigQuery Dashboard Kimia Farma
# Tabel Analisa Transaksi Kimia Farma (2020-2023)

## Deskripsi
Tabel `tabel_analisa` dibuat untuk menganalisis kinerja Kimia Farma selama periode 2020–2023.  
Tabel ini menggabungkan data dari tiga sumber utama:  
1. **Transaksi akhir (`kf_final_transaction`)**  
2. **Informasi produk (`kf_product`)**  
3. **Informasi cabang (`kf_kantor_cabang`)**

---

## Struktur Tabel

| Kolom | Tipe | Deskripsi |
|-------|------|-----------|
| `transaction_id` | STRING | Kode unik transaksi |
| `date` | DATE | Tanggal transaksi |
| `branch_id` | STRING | Kode cabang |
| `branch_name` | STRING | Nama cabang |
| `kota` | STRING | Kota cabang |
| `provinsi` | STRING | Provinsi cabang |
| `rating_cabang` | FLOAT64 | Penilaian konsumen terhadap cabang |
| `customer_name` | STRING | Nama customer |
| `product_id` | STRING | Kode produk |
| `product_name` | STRING | Nama produk |
| `actual_price` | NUMERIC | Harga produk |
| `discount_fraction` | FLOAT64 | Diskon desimal (0–1) |
| `discount_percentage` | FLOAT64 | Diskon persen |
| `persentase_gross_laba` | INT64 | Persentase laba kotor |
| `nett_sales` | NUMERIC | Harga setelah diskon |
| `nett_profit` | NUMERIC | Keuntungan bersih |
| `rating_transaksi` | FLOAT64 | Rating transaksi customer |

---

## SQL Pembuatan Tabel

```sql
-- SQL lengkap seperti yang sudah dibuat sebelumnya
CREATE TABLE `rakamin-kf-analytics-486815.kimia_farma.tabel_analisa` AS
WITH ft AS (
  ...
)
SELECT
  ...
FROM ft
LEFT JOIN prod p ON ft.product_id = p.product_id
LEFT JOIN branch b ON ft.branch_id = b.branch_id;
