-- ============================================================
-- JustDrinks Ltd — Retail Analytics Capstone
-- Author : Oyinlola Oluwanifesimi Oladeji
-- Program: Embedded Analytics Program, Interswitch
-- Script : 01_setup_notes.sql
-- Purpose: Import verification and table row-count checks.
--          Run immediately after loading all 6 CSV files
--          via DB Browser (File → Import → Table from CSV).
-- ============================================================

-- ── IMPORT REFERENCE ─────────────────────────────────────────
-- Each CSV was imported using DB Browser's CSV import wizard:
--   ✓ "Column names in first line" checked
--   ✓ Field separator: comma (,)
--   ✓ Quote character: "
--   ✓ Encoding: UTF-8
--
-- CSV File                    → SQLite Table Name
-- ─────────────────────────────────────────────────────────────
-- SalesFINAL12312016.csv      → Sales
-- BegInvFINAL12312016.csv     → BegInv
-- EndInvFINAL12312016.csv     → EndInv
-- PurchasesFINAL12312016.csv  → Purchases
-- InvoicePurchases12312016.csv→ InvoicePurchases
-- 2017PurchasePricesDec.csv   → PurchasePrices2017
-- ─────────────────────────────────────────────────────────────

-- ── STEP 1: Row count verification ───────────────────────────
-- Run after import. All tables should return non-zero counts.
-- If any row count = 0, the import failed — re-import that file.

SELECT 'Sales'              AS TableName, COUNT(*) AS RowCount FROM Sales
UNION ALL
SELECT 'BegInv',                          COUNT(*) FROM BegInv
UNION ALL
SELECT 'EndInv',                          COUNT(*) FROM EndInv
UNION ALL
SELECT 'Purchases',                       COUNT(*) FROM Purchases
UNION ALL
SELECT 'InvoicePurchases',                COUNT(*) FROM InvoicePurchases
UNION ALL
SELECT 'PurchasePrices2017',              COUNT(*) FROM PurchasePrices2017;


-- ── STEP 2: Column structure checks ──────────────────────────
-- Verify that column names imported cleanly (no trailing spaces
-- or encoding artefacts in header names, which would break JOINs).

PRAGMA table_info(Sales);
PRAGMA table_info(Purchases);
PRAGMA table_info(InvoicePurchases);
PRAGMA table_info(BegInv);
PRAGMA table_info(EndInv);
PRAGMA table_info(PurchasePrices2017);


-- ── STEP 3: Date format spot-check ───────────────────────────
-- SQLite stores all dates as TEXT. Confirm date fields are in
-- a consistent format before running JULIANDAY() arithmetic.
-- Expected: 'M/D/YYYY' (e.g. '1/1/2016') or 'YYYY-MM-DD'.

SELECT SalesDate   FROM Sales        LIMIT 5;
SELECT startDate   FROM BegInv       LIMIT 5;
SELECT endDate     FROM EndInv       LIMIT 5;
SELECT PODate,
       ReceivingDate,
       InvoiceDate,
       PayDate     FROM Purchases    LIMIT 5;


-- ── STEP 4: Rename any columns with trailing whitespace ───────
-- If PRAGMA table_info() revealed columns like 'VendorName   '
-- (with trailing spaces), fix them here before proceeding.
-- Example — uncomment and adjust name as needed:
--
-- ALTER TABLE Purchases RENAME COLUMN "VendorName   " TO VendorName;
-- ALTER TABLE Sales     RENAME COLUMN "VendorName   " TO VendorName;
