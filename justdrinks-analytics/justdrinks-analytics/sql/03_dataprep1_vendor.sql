-- ============================================================
-- JustDrinks Ltd — Retail Analytics Capstone
-- Author : Oyinlola Oluwanifesimi Oladeji
-- Program: Embedded Analytics Program, Interswitch
-- Script : 03_dataprep1_vendor.sql
-- Purpose: Build the three DataPrep1 vendor intelligence tables
--          for executive dashboard reporting.
--
-- Tables created:
--   DataPrep1_VendorBillings         (all critical vendors)
--   DataPrep1_Top10VendorsByDollars  (highest spend)
--   DataPrep1_Top10VendorsByQty      (highest volume)
--
-- Design notes:
--   • "Critical vendor" = total purchased dollars > $1,000.
--     Adjust the HAVING clause threshold if the business
--     redefines this threshold in future cycles.
--   • Freight is pre-aggregated per (VendorNumber, PONumber)
--     before joining. Without this, freight is multiplied
--     once per product line on the same invoice — causing
--     significant double-counting in total freight figures.
--   • TRIM() applied to VendorName to remove trailing spaces
--     present in the source CSV export.
-- ============================================================


-- ── TABLE 1: DataPrep1_VendorBillings ────────────────────────
-- One row per critical vendor. Aggregates all purchasing
-- activity across POs, product lines, stores, and invoices.
-- Includes volume metrics, pricing range, vendor lead times,
-- payment behaviour, and freight costs.

CREATE TABLE DataPrep1_VendorBillings AS

SELECT
    p.VendorNumber,
    TRIM(p.VendorName)                          AS VendorName,

    -- ── Purchase volume metrics ───────────────────────────
    COUNT(DISTINCT p.PONumber)                  AS TotalPOs,
    COUNT(*)                                    AS TotalLineItems,
    SUM(p.Quantity)                             AS TotalQuantityPurchased,
    ROUND(SUM(p.Dollars), 2)                    AS TotalPurchaseDollars,

    -- ── Unit pricing range ────────────────────────────────
    ROUND(AVG(p.PurchasePrice), 2)              AS AvgPurchasePrice,
    ROUND(MIN(p.PurchasePrice), 2)              AS MinPurchasePrice,
    ROUND(MAX(p.PurchasePrice), 2)              AS MaxPurchasePrice,

    -- ── Product and store footprint ───────────────────────
    COUNT(DISTINCT p.Brand)                     AS UniqueBrands,
    COUNT(DISTINCT p.Description)               AS UniqueProducts,
    COUNT(DISTINCT p.Store)                     AS StoresSupplied,

    -- ── Order timeline ────────────────────────────────────
    MIN(p.PODate)                               AS FirstPODate,
    MAX(p.PODate)                               AS LastPODate,
    MIN(p.ReceivingDate)                        AS FirstReceivingDate,
    MAX(p.ReceivingDate)                        AS LastReceivingDate,

    -- ── Vendor lead time: avg days from PO to receiving ──
    -- A long lead time signals supply chain risk for this vendor
    ROUND(
        AVG(JULIANDAY(p.ReceivingDate) - JULIANDAY(p.PODate))
    , 1)                                        AS AvgLeadTimeDays,

    -- ── Payment cycle: avg days from PO to payment ───────
    ROUND(
        AVG(JULIANDAY(p.PayDate) - JULIANDAY(p.PODate))
    , 1)                                        AS AvgDaysPOToPayment,

    -- ── Freight costs (pre-aggregated to avoid fan-out) ──
    -- Joined from InvoicePurchases which stores freight at
    -- the invoice level, not the product line level.
    ROUND(SUM(inv_freight.TotalFreight), 2)     AS TotalFreight,

    -- ── Category flag ────────────────────────────────────
    -- If NumClassifications = 2, this vendor supplies both
    -- wine and spirits — useful context for buyer meetings
    COUNT(DISTINCT p.Classification)            AS NumClassifications

FROM Purchases p

-- Pre-aggregate freight per PO to prevent multiplication
-- across multiple product lines on the same invoice
LEFT JOIN (
    SELECT
        VendorNumber,
        PONumber,
        SUM(Freight)                            AS TotalFreight
    FROM InvoicePurchases
    GROUP BY VendorNumber, PONumber
) AS inv_freight
    ON  p.VendorNumber = inv_freight.VendorNumber
    AND p.PONumber     = inv_freight.PONumber

GROUP BY p.VendorNumber, p.VendorName

-- Critical vendor filter: exclude vendors with < $1,000 spend
HAVING SUM(p.Dollars) > 1000

ORDER BY TotalPurchaseDollars DESC;


-- ── Verification: row count and top 10 preview ────────────────
SELECT COUNT(*) AS CriticalVendorCount FROM DataPrep1_VendorBillings;

SELECT
    VendorName,
    TotalPurchaseDollars,
    TotalQuantityPurchased,
    TotalPOs,
    UniqueProducts,
    StoresSupplied,
    TotalFreight,
    AvgLeadTimeDays
FROM DataPrep1_VendorBillings
LIMIT 10;

-- Sanity check: aggregate dollars in this table should be
-- slightly less than raw Purchases total (vendors < $1k excluded)
SELECT ROUND(SUM(Dollars), 2)              AS RawPurchasesTotal FROM Purchases;
SELECT ROUND(SUM(TotalPurchaseDollars), 2) AS VendorBillingsTotal FROM DataPrep1_VendorBillings;


-- ── TABLE 2: DataPrep1_Top10VendorsByDollars ──────────────────
-- Top 10 vendors by total dollar spend.
-- These are JustDrinks' highest-value supplier relationships —
-- the ones procurement leadership should prioritise for
-- contract negotiations, rebate agreements, and risk reviews.

CREATE TABLE DataPrep1_Top10VendorsByDollars AS
SELECT
    VendorNumber,
    VendorName,
    TotalPurchaseDollars,
    TotalQuantityPurchased,
    TotalPOs,
    UniqueProducts,
    StoresSupplied,
    TotalFreight,
    AvgPurchasePrice,
    AvgLeadTimeDays,
    AvgDaysPOToPayment,
    NumClassifications
FROM DataPrep1_VendorBillings
ORDER BY TotalPurchaseDollars DESC
LIMIT 10;

-- Verification
SELECT * FROM DataPrep1_Top10VendorsByDollars;


-- ── TABLE 3: DataPrep1_Top10VendorsByQty ─────────────────────
-- Top 10 vendors by total units purchased.
-- Volume rank differs from spend rank when unit prices are low.
-- A high-volume, low-spend vendor may be operationally critical
-- (e.g. supplying high-turnover entry-price products) even if
-- it doesn't appear in the top spend tier.

CREATE TABLE DataPrep1_Top10VendorsByQty AS
SELECT
    VendorNumber,
    VendorName,
    TotalQuantityPurchased,
    TotalPurchaseDollars,
    TotalPOs,
    UniqueProducts,
    StoresSupplied,
    AvgPurchasePrice,
    AvgLeadTimeDays
FROM DataPrep1_VendorBillings
ORDER BY TotalQuantityPurchased DESC
LIMIT 10;

-- Verification
SELECT * FROM DataPrep1_Top10VendorsByQty;
