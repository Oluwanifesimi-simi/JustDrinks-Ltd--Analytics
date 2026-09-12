-- ============================================================
-- JustDrinks Ltd — Retail Analytics Capstone
-- Author : Oyinlola Oluwanifesimi Oladeji
-- Program: Embedded Analytics Program, Interswitch
-- Script : 04_dataprep2_aging.sql
-- Purpose: Build DataPrep2_InventoryAging — the core table
--          for identifying slow-moving stock, seasonality
--          patterns, and purchase-to-sale timing gaps.
--
-- Design notes:
--   • Grain: one row per InventoryId (Store + Brand combo).
--   • The Purchases → Sales relationship is one-to-many:
--     one PO line delivers N units that sell across many dates.
--     Sales are pre-aggregated per InventoryId before joining
--     to prevent row multiplication (fan-out).
--   • DaysToFirstSale = NULL means the item has never sold.
--     These are the highest-priority items for the procurement
--     team to investigate.
--   • Seasonality is derived from ReceivingDate (when the
--     item arrived), not SalesDate, to measure how purchase
--     timing relates to sell-through speed.
-- ============================================================


-- ── Pre-aggregation check: sales per InventoryId ─────────────
-- Run this first to confirm the subquery logic before building
-- the full table. Each InventoryId should return one summary row.

SELECT
    InventoryId,
    COUNT(*)                            AS NumSaleDays,
    SUM(SalesQuantity)                  AS TotalSalesQty,
    ROUND(SUM(SalesDollars), 2)         AS TotalSalesDollars,
    ROUND(AVG(SalesPrice), 2)           AS AvgSalesPrice,
    MIN(SalesDate)                      AS FirstSaleDate,
    MAX(SalesDate)                      AS LastSaleDate
FROM Sales
GROUP BY InventoryId
LIMIT 20;


-- ── TABLE: DataPrep2_InventoryAging ──────────────────────────

CREATE TABLE DataPrep2_InventoryAging AS

SELECT
    -- ── Item identifiers ─────────────────────────────────
    p.InventoryId,
    p.Store,
    TRIM(p.VendorName)                                      AS VendorName,
    p.VendorNumber,
    p.Brand,
    TRIM(p.Description)                                     AS Description,
    p.Size,
    p.Classification,

    -- ── Purchase details ──────────────────────────────────
    p.PODate,
    p.ReceivingDate,
    p.InvoiceDate,
    p.PayDate,
    p.PurchasePrice,
    SUM(p.Quantity)                                         AS TotalQtyPurchased,
    ROUND(SUM(p.Dollars), 2)                                AS TotalPurchaseDollars,
    COUNT(DISTINCT p.PONumber)                              AS NumPOs,

    -- ── Sales details (NULL if item never sold) ───────────
    agg_sales.FirstSaleDate,
    agg_sales.LastSaleDate,
    agg_sales.TotalSalesQty,
    agg_sales.TotalSalesDollars,
    agg_sales.AvgSalesPrice,
    agg_sales.NumSaleDays,

    -- ── Core aging metric ─────────────────────────────────
    -- Days from goods receipt to the very first recorded sale.
    -- Large values = slow-moving inventory.
    -- NULL = item has not sold at all during FY2016.
    ROUND(
        JULIANDAY(agg_sales.FirstSaleDate) - JULIANDAY(p.ReceivingDate)
    , 0)                                                    AS DaysToFirstSale,

    -- ── Vendor lead time ──────────────────────────────────
    -- Days from PO creation to goods being received in store.
    -- Longer lead times reduce procurement agility.
    ROUND(
        JULIANDAY(p.ReceivingDate) - JULIANDAY(p.PODate)
    , 0)                                                    AS VendorLeadTimeDays,

    -- ── Payment cycle ─────────────────────────────────────
    -- Days from invoice date to payment. Useful for AP
    -- team and cash flow forecasting.
    ROUND(
        JULIANDAY(p.PayDate) - JULIANDAY(p.InvoiceDate)
    , 0)                                                    AS DaysToPayment,

    -- ── Unit margin ───────────────────────────────────────
    -- Average selling price minus purchase price.
    -- Negative margin = selling below cost (worth investigating).
    ROUND(agg_sales.AvgSalesPrice - p.PurchasePrice, 2)    AS UnitMargin,

    -- ── Margin percentage ─────────────────────────────────
    ROUND(
        CASE
            WHEN p.PurchasePrice > 0
            THEN ((agg_sales.AvgSalesPrice - p.PurchasePrice)
                  / p.PurchasePrice) * 100
        END
    , 1)                                                    AS MarginPct,

    -- ── Sell-through rate ─────────────────────────────────
    -- % of purchased quantity that was sold during FY2016.
    -- 100% = fully sold through.
    -- < 100% = residual stock still on shelf at year end.
    -- > 100% = possible data anomaly (sold more than received
    --   in this period — check beginning inventory).
    ROUND(
        CASE
            WHEN SUM(p.Quantity) > 0
            THEN (CAST(agg_sales.TotalSalesQty AS REAL)
                  / SUM(p.Quantity)) * 100
        END
    , 1)                                                    AS SellThroughPct,

    -- ── Seasonality: receiving month ─────────────────────
    -- Derived from ReceivingDate to analyse whether certain
    -- purchase seasons correlate with slower inventory turns.
    CAST(strftime('%m', p.ReceivingDate) AS INTEGER)        AS ReceivingMonth,

    CASE CAST(strftime('%m', p.ReceivingDate) AS INTEGER)
        WHEN 1  THEN 'January'
        WHEN 2  THEN 'February'
        WHEN 3  THEN 'March'
        WHEN 4  THEN 'April'
        WHEN 5  THEN 'May'
        WHEN 6  THEN 'June'
        WHEN 7  THEN 'July'
        WHEN 8  THEN 'August'
        WHEN 9  THEN 'September'
        WHEN 10 THEN 'October'
        WHEN 11 THEN 'November'
        WHEN 12 THEN 'December'
    END                                                     AS ReceivingMonthName,

    CASE
        WHEN CAST(strftime('%m', p.ReceivingDate) AS INTEGER) IN (12,1,2)
            THEN 'Winter'
        WHEN CAST(strftime('%m', p.ReceivingDate) AS INTEGER) IN (3,4,5)
            THEN 'Spring'
        WHEN CAST(strftime('%m', p.ReceivingDate) AS INTEGER) IN (6,7,8)
            THEN 'Summer'
        ELSE 'Fall'
    END                                                     AS ReceivingSeason,

    -- ── Sale status flag ──────────────────────────────────
    -- Simple filter dimension for Tableau: Sold vs Unsold.
    -- Unsold items represent idle working capital.
    CASE
        WHEN agg_sales.FirstSaleDate IS NULL THEN 'Unsold'
        ELSE 'Sold'
    END                                                     AS SaleStatus

FROM Purchases p

-- Pre-aggregated sales: one summary row per InventoryId.
-- Using LEFT JOIN so unsold items (no Sales match) are retained
-- with NULL sales fields rather than being dropped.
LEFT JOIN (
    SELECT
        InventoryId,
        MIN(SalesDate)                  AS FirstSaleDate,
        MAX(SalesDate)                  AS LastSaleDate,
        SUM(SalesQuantity)              AS TotalSalesQty,
        ROUND(SUM(SalesDollars), 2)     AS TotalSalesDollars,
        ROUND(AVG(SalesPrice), 2)       AS AvgSalesPrice,
        COUNT(*)                        AS NumSaleDays
    FROM Sales
    GROUP BY InventoryId
) AS agg_sales
    ON p.InventoryId = agg_sales.InventoryId

GROUP BY
    p.InventoryId,
    p.Store,
    p.VendorName,
    p.VendorNumber,
    p.Brand,
    p.Description,
    p.Size,
    p.Classification,
    p.PODate,
    p.ReceivingDate,
    p.InvoiceDate,
    p.PayDate,
    p.PurchasePrice

ORDER BY DaysToFirstSale DESC;


-- ── Verification queries ──────────────────────────────────────

-- Total rows in the aging table
SELECT COUNT(*) AS TotalRows FROM DataPrep2_InventoryAging;

-- Sold vs unsold breakdown
SELECT
    SaleStatus,
    COUNT(*)                            AS Items,
    ROUND(SUM(TotalPurchaseDollars), 2) AS TotalPurchaseValue
FROM DataPrep2_InventoryAging
GROUP BY SaleStatus;

-- Aging distribution buckets
-- Shows how inventory is spread across fast, medium, and slow movers
SELECT
    CASE
        WHEN DaysToFirstSale IS NULL    THEN '5. Never sold'
        WHEN DaysToFirstSale <= 7       THEN '1. 0–7 days (fast mover)'
        WHEN DaysToFirstSale <= 30      THEN '2. 8–30 days'
        WHEN DaysToFirstSale <= 90      THEN '3. 31–90 days'
        ELSE                                 '4. 90+ days (slow mover)'
    END                                 AS AgingBucket,
    COUNT(*)                            AS Items,
    ROUND(AVG(TotalPurchaseDollars), 2) AS AvgPurchaseValue,
    ROUND(AVG(SellThroughPct), 1)       AS AvgSellThrough
FROM DataPrep2_InventoryAging
GROUP BY AgingBucket
ORDER BY AgingBucket;

-- Seasonality: average aging by receiving month
-- Identifies which purchase months correlate with slow sell-through
SELECT
    ReceivingMonth,
    ReceivingMonthName,
    ReceivingSeason,
    COUNT(*)                            AS Items,
    ROUND(AVG(DaysToFirstSale), 1)      AS AvgDaysToFirstSale,
    ROUND(AVG(SellThroughPct), 1)       AS AvgSellThroughPct,
    ROUND(AVG(UnitMargin), 2)           AS AvgUnitMargin
FROM DataPrep2_InventoryAging
WHERE SaleStatus = 'Sold'
GROUP BY ReceivingMonth, ReceivingMonthName, ReceivingSeason
ORDER BY ReceivingMonth;

-- Top 15 slowest-moving items (sold but took the longest)
-- Priority list for procurement review
SELECT
    Description,
    VendorName,
    Size,
    Classification,
    DaysToFirstSale,
    TotalQtyPurchased,
    COALESCE(TotalSalesQty, 0)          AS TotalSold,
    SellThroughPct,
    ROUND(TotalPurchaseDollars, 2)      AS PurchaseValue,
    UnitMargin
FROM DataPrep2_InventoryAging
WHERE SaleStatus = 'Sold'
ORDER BY DaysToFirstSale DESC
LIMIT 15;

-- Top 15 items by purchase value that never sold
-- These represent the highest idle capital risk
SELECT
    Description,
    VendorName,
    Size,
    Classification,
    TotalQtyPurchased,
    ROUND(TotalPurchaseDollars, 2)      AS PurchaseValue,
    ReceivingDate,
    ReceivingSeason
FROM DataPrep2_InventoryAging
WHERE SaleStatus = 'Unsold'
ORDER BY TotalPurchaseDollars DESC
LIMIT 15;
