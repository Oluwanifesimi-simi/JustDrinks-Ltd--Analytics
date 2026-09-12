-- ============================================================
-- JustDrinks Ltd — Retail Analytics Capstone
-- Author : Oyinlola Oluwanifesimi Oladeji
-- Program: Embedded Analytics Program, Interswitch
-- Script : 02_exploration.sql
-- Purpose: Exploratory queries run before building aggregate
--          tables. These answer basic structural questions about
--          the data: what does it contain, how complete is it,
--          and how do tables relate to one another?
-- ============================================================


-- ── SALES TABLE ───────────────────────────────────────────────

-- Total revenue and transaction count across the full year
SELECT
    COUNT(*)                            AS TotalTransactions,
    COUNT(DISTINCT InventoryId)         AS UniqueProducts,
    COUNT(DISTINCT Store)               AS UniqueStores,
    ROUND(SUM(SalesDollars), 2)         AS TotalRevenue,
    ROUND(AVG(SalesPrice), 2)           AS AvgSalesPrice,
    MIN(SalesDate)                      AS EarliestSale,
    MAX(SalesDate)                      AS LatestSale
FROM Sales;

-- Revenue split by Classification (1 = Spirits, 2 = Wine)
-- Verify the classification codes before building Tableau charts
SELECT
    Classification,
    COUNT(*)                            AS Transactions,
    SUM(SalesQuantity)                  AS TotalQty,
    ROUND(SUM(SalesDollars), 2)         AS TotalRevenue,
    ROUND(SUM(SalesDollars) * 100.0
        / SUM(SUM(SalesDollars)) OVER(), 1) AS RevenuePct
FROM Sales
GROUP BY Classification
ORDER BY Classification;

-- Top 10 best-selling products by revenue
SELECT
    Description,
    Size,
    Classification,
    SUM(SalesQuantity)                  AS TotalQty,
    ROUND(SUM(SalesDollars), 2)         AS TotalRevenue
FROM Sales
GROUP BY Description, Size, Classification
ORDER BY TotalRevenue DESC
LIMIT 10;

-- Sales distribution by bottle size
SELECT
    Size,
    COUNT(*)                            AS Transactions,
    SUM(SalesQuantity)                  AS TotalQty,
    ROUND(SUM(SalesDollars), 2)         AS TotalRevenue
FROM Sales
GROUP BY Size
ORDER BY TotalRevenue DESC;

-- Store-level revenue summary (top 15 by revenue)
SELECT
    Store,
    COUNT(*)                            AS Transactions,
    ROUND(AVG(SalesPrice), 2)           AS AvgSalesPrice,
    ROUND(SUM(SalesDollars), 2)         AS TotalRevenue
FROM Sales
GROUP BY Store
ORDER BY TotalRevenue DESC
LIMIT 15;


-- ── PURCHASES TABLE ───────────────────────────────────────────

-- High-level purchase summary
SELECT
    COUNT(*)                            AS TotalPurchaseLines,
    COUNT(DISTINCT VendorNumber)        AS UniqueVendors,
    COUNT(DISTINCT PONumber)            AS UniquePOs,
    COUNT(DISTINCT Store)               AS StoresOrdering,
    ROUND(SUM(Dollars), 2)             AS TotalPurchaseDollars,
    MIN(PODate)                         AS EarliestPO,
    MAX(PODate)                         AS LatestPO
FROM Purchases;

-- How many vendors cross the $1,000 "critical vendor" threshold?
SELECT
    COUNT(*)                            AS CriticalVendorCount
FROM (
    SELECT VendorNumber, SUM(Dollars) AS TotalSpend
    FROM Purchases
    GROUP BY VendorNumber
    HAVING SUM(Dollars) > 1000
);

-- Confirm InvoicePurchases join cardinality:
-- Does one PONumber ever appear multiple times in InvoicePurchases?
-- (If max > 1, freight must be pre-aggregated to avoid double-counting)
SELECT
    PONumber,
    COUNT(*)                            AS InvoiceRows
FROM InvoicePurchases
GROUP BY PONumber
ORDER BY InvoiceRows DESC
LIMIT 10;


-- ── INVENTORY TABLES ─────────────────────────────────────────

-- How many SKUs appear in both BegInv and EndInv?
-- Measures full-year inventory continuity
SELECT
    COUNT(DISTINCT b.InventoryId)       AS InBegInv,
    COUNT(DISTINCT e.InventoryId)       AS InEndInv,
    COUNT(DISTINCT
        CASE WHEN e.InventoryId IS NOT NULL
             THEN b.InventoryId END)    AS InBoth
FROM BegInv b
LEFT JOIN EndInv e ON b.InventoryId = e.InventoryId;

-- Inventory value comparison: beginning vs ending
SELECT
    'Beginning Inventory'               AS Period,
    COUNT(*)                            AS SKUs,
    ROUND(SUM(onHand * Price), 2)       AS InventoryValue
FROM BegInv
UNION ALL
SELECT
    'Ending Inventory',
    COUNT(*),
    ROUND(SUM(onHand * Price), 2)
FROM EndInv;


-- ── JOIN VALIDATION ───────────────────────────────────────────

-- What % of purchased InventoryIds have a matching Sales record?
-- Unsold items = purchased but never appeared in Sales
SELECT
    COUNT(DISTINCT p.InventoryId)       AS InPurchases,
    COUNT(DISTINCT s.InventoryId)       AS InSales,
    COUNT(DISTINCT
        CASE WHEN s.InventoryId IS NOT NULL
             THEN p.InventoryId END)    AS InBoth,
    ROUND(
        COUNT(DISTINCT
            CASE WHEN s.InventoryId IS NOT NULL
                 THEN p.InventoryId END) * 100.0
        / COUNT(DISTINCT p.InventoryId)
    , 1)                                AS PctWithSales
FROM Purchases p
LEFT JOIN Sales s ON p.InventoryId = s.InventoryId;

-- Preview a single InventoryId across both Purchases and Sales
-- to understand the one-to-many relationship before aggregating
SELECT
    'Purchases' AS Source,
    InventoryId, ReceivingDate AS EventDate,
    Quantity AS Qty, Dollars AS Amount
FROM Purchases
WHERE InventoryId = '1_HARDERSFIELD_5255'
UNION ALL
SELECT
    'Sales', InventoryId, SalesDate,
    SalesQuantity, SalesDollars
FROM Sales
WHERE InventoryId = '1_HARDERSFIELD_5255'
ORDER BY Source, EventDate;
