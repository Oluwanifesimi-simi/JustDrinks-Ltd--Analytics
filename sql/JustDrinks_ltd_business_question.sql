<?xml version="1.0" encoding="UTF-8"?><sqlb_project><db path="JustDrinks_Ltd.db" readonly="0" foreign_keys="1" case_sensitive_like="0" temp_store="0" wal_autocheckpoint="1000" synchronous="2"/><attached/><window><main_tabs open="structure browser pragmas query" current="3"/></window><tab_structure><column_width id="0" width="300"/><column_width id="1" width="0"/><column_width id="2" width="100"/><column_width id="3" width="3290"/><column_width id="4" width="0"/><expanded_item id="0" parent="1"/><expanded_item id="1" parent="1"/><expanded_item id="2" parent="1"/><expanded_item id="3" parent="1"/></tab_structure><tab_browse><table title="BegInv" custom_title="0" dock_id="1" table="4,6:mainBegInv"/><dock_state state="000000ff00000000fd00000001000000020000000000000000fc0100000001fb000000160064006f0063006b00420072006f00770073006500310100000000ffffffff0000011800ffffff000000000000000000000004000000040000000800000008fc00000000"/><default_encoding codec=""/><browse_table_settings/></tab_browse><tab_sql><sql name="SQL 1*">-- ============================================================

-- JustDrinks Ltd — Data Analytics Case Study

-- Author: OLADEJI OYINLOLA OLUWANIFESIMI

-- Date: 1 June, 2026

-- Database: JustDrinks.db

-- ============================================================



-- TABLE IMPORTS (done via DB Browser CSV import UI)

-- SalesFINAL → Sales

-- BegInvFINAL → BegInv

-- EndInvFINAL → EndInv

-- PurchasesFINAL → Purchases

-- InvoicePurchases → InvoicePurchases

-- 2017PurchasePricesDec → PurchasePrices2017



-- ============================================================

-- PHASE 1 - DATA PREPARATION

-- ============================================================







-- Aggregate vendor billings: total quantity, dollars, invoices, and freight per vendor.

-- Joins Purchases with InvoicePurchases to combine line-item and invoice-level data.

-- A &quot;critical vendor&quot; is defined here as one with total purchased dollars &gt; $1,000.

CREATE TABLE DataPrep1_VendorBillings AS

SELECT

    p.VendorNumber,

    p.VendorName,

    COUNT(DISTINCT p.PONumber)         AS TotalPOs,

    SUM(p.Quantity)                    AS TotalQuantity,

    ROUND(SUM(p.Dollars), 2)           AS TotalPurchaseDollars,

    ROUND(AVG(p.PurchasePrice), 2)     AS AvgPurchasePrice,

    COUNT(DISTINCT p.Classification)   AS NumCategories,

    MIN(p.PODate)                      AS FirstPODate,

    MAX(p.PODate)                      AS LastPODate,

    ROUND(SUM(i.Freight), 2)           AS TotalFreight,

    COUNT(DISTINCT i.PONumber)         AS NumInvoices

FROM Purchases p

LEFT JOIN InvoicePurchases i

    ON p.VendorNumber = i.VendorNumber

    AND p.PONumber    = i.PONumber

GROUP BY p.VendorNumber, p.VendorName

HAVING SUM(p.Dollars) &gt; 1000          -- &quot;Critical vendor&quot; threshold

ORDER BY TotalPurchaseDollars DESC;





-- Top 10 vendors ranked by total quantity of items purchased.

-- Useful for identifying high-volume suppliers even if unit prices are low.

CREATE TABLE DataPrep1_Top10VendorsByQty AS

SELECT

    VendorNumber,

    VendorName,

    TotalQuantity,

    TotalPurchaseDollars,

    TotalPOs

FROM DataPrep1_VendorBillings

ORDER BY TotalQuantity DESC

LIMIT 10;



-- Top 10 vendors by total dollar spend — these are the highest-value supplier relationships.

CREATE TABLE DataPrep1_Top10VendorsByDollars AS

SELECT

    VendorNumber,

    VendorName,

    TotalPurchaseDollars,

    TotalQuantity,

    AvgPurchasePrice,

    TotalFreight

FROM DataPrep1_VendorBillings

ORDER BY TotalPurchaseDollars DESC

LIMIT 10;



-- Inventory aging analysis: measures the gap between when items were purchased

-- (ReceivingDate) and when they were sold (SalesDate).

-- Includes purchase price, seasonality info, and vendor context.

-- Items with a NULL SaleDate have not yet been sold (still on shelf).

CREATE TABLE DataPrep2_InventoryAging AS

SELECT

    p.InventoryId,

    p.Store,

    p.Brand,

    p.Description,

    p.Size,

    p.VendorNumber,

    p.VendorName,

    p.Classification,           -- 1 = spirits, 2 = wine (check your data)

    p.PODate,

    p.ReceivingDate,

    p.InvoiceDate,

    p.PurchasePrice,

    p.Quantity                                         AS QuantityPurchased,

    p.Dollars                                          AS PurchaseDollars,

    s.SalesDate,

    s.SalesPrice,

    s.SalesDollars,

    s.SalesQuantity,

    -- Days from receiving to first sale (inventory aging)

    JULIANDAY(s.SalesDate) - JULIANDAY(p.ReceivingDate) AS DaysOnShelf,

    -- Season of purchase (for seasonality analysis)

    CASE

        WHEN CAST(strftime('%m', p.ReceivingDate) AS INTEGER) IN (12,1,2)  THEN 'Winter'

        WHEN CAST(strftime('%m', p.ReceivingDate) AS INTEGER) IN (3,4,5)   THEN 'Spring'

        WHEN CAST(strftime('%m', p.ReceivingDate) AS INTEGER) IN (6,7,8)   THEN 'Summer'

        ELSE 'Fall'

    END AS PurchaseSeason,

    -- Month number for sorting in charts

    CAST(strftime('%m', p.ReceivingDate) AS INTEGER)   AS PurchaseMonth,

    -- Margin per unit

    ROUND(s.SalesPrice - p.PurchasePrice, 2)           AS UnitMargin

FROM Purchases p

LEFT JOIN SalesFINAL s

    ON  p.InventoryId = s.InventoryId

    AND s.SalesDate  &gt;= p.ReceivingDate   -- sale must come after receiving

ORDER BY DaysOnShelf DESC;





SELECT 'Sales'             AS TableName, COUNT(*) AS Rows FROM Sales

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





-- How many unique vendors are in Purchases?

SELECT COUNT(DISTINCT VendorNumber) FROM Purchases;



-- What does a single vendor's data look like?

SELECT *

FROM Purchases

WHERE VendorNumber = 4466

LIMIT 10;



-- Does InvoicePurchases have one row per PO, or can there be multiples?

SELECT PONumber, COUNT(*) AS Rows

FROM InvoicePurchases

GROUP BY PONumber

ORDER BY Rows DESC

LIMIT 10;





-- Preview what a joined row looks like

SELECT

    p.VendorNumber,

    p.VendorName,

    p.PONumber,

    p.Quantity,

    p.Dollars,

    i.Freight

FROM Purchases p

LEFT JOIN InvoicePurchases i

    ON p.VendorNumber = i.VendorNumber

    AND p.PONumber    = i.PONumber

LIMIT 20;





-- Aggregate freight once per PO to avoid double-counting

SELECT

    VendorNumber,

    PONumber,

    SUM(Freight) AS TotalFreight

FROM InvoicePurchases

GROUP BY VendorNumber, PONumber;





-- ============================================================

-- DataPrep1_VendorBillings

-- 

-- Purpose: Aggregate all critical vendor purchasing activity

-- for executive dashboard reporting. One row per vendor.

--

-- &quot;Critical vendor&quot; = total purchased dollars &gt; $1,000.

-- Adjust threshold below if needed.

--

-- Freight is pre-aggregated per PO to avoid double-counting

-- across multiple product lines on the same invoice.

-- ============================================================



CREATE TABLE DataPrep1_VendorBillings AS



SELECT

    p.VendorNumber,

    TRIM(p.VendorName)                          AS VendorName,



    -- Purchase volume metrics

    COUNT(DISTINCT p.PONumber)                  AS TotalPOs,

    COUNT(*)                                    AS TotalLineItems,

    SUM(p.Quantity)                             AS TotalQuantityPurchased,

    ROUND(SUM(p.Dollars), 2)                    AS TotalPurchaseDollars,

    ROUND(AVG(p.PurchasePrice), 2)              AS AvgPurchasePrice,

    ROUND(MIN(p.PurchasePrice), 2)              AS MinPurchasePrice,

    ROUND(MAX(p.PurchasePrice), 2)              AS MaxPurchasePrice,



    -- Product variety

    COUNT(DISTINCT p.Brand)                     AS UniqueBrands,

    COUNT(DISTINCT p.Description)               AS UniqueProducts,

    COUNT(DISTINCT p.Store)                     AS StoresSupplied,



    -- Timeline

    MIN(p.PODate)                               AS FirstPODate,

    MAX(p.PODate)                               AS LastPODate,

    MIN(p.ReceivingDate)                        AS FirstReceivingDate,

    MAX(p.ReceivingDate)                        AS LastReceivingDate,



    -- Payment behavior: avg days from PO to payment

    ROUND(

        AVG(JULIANDAY(p.PayDate) - JULIANDAY(p.PODate))

    , 1)                                        AS AvgDaysPOToPayment,



    -- Freight (pre-aggregated to avoid double-counting)

    ROUND(SUM(inv_freight.TotalFreight), 2)     AS TotalFreight,



    -- Classification (spirits=1, wine=2) — flag if vendor supplies both

    COUNT(DISTINCT p.Classification)            AS NumClassifications



FROM Purchases p



-- Join to freight subquery instead of raw InvoicePurchases

LEFT JOIN (

    SELECT

        VendorNumber,

        PONumber,

        SUM(Freight) AS TotalFreight

    FROM InvoicePurchases

    GROUP BY VendorNumber, PONumber

) AS inv_freight

    ON  p.VendorNumber = inv_freight.VendorNumber

    AND p.PONumber     = inv_freight.PONumber



GROUP BY p.VendorNumber, p.VendorName



-- Only include critical vendors (&gt; $1,000 total purchased)

HAVING SUM(p.Dollars) &gt; 1000



ORDER BY TotalPurchaseDollars DESC;





-- How many critical vendors made it in?

SELECT COUNT(*) FROM DataPrep1_VendorBillings;



-- Preview the top 10

SELECT

    VendorName,

    TotalPurchaseDollars,

    TotalQuantityPurchased,

    TotalPOs,

    UniqueProducts,

    StoresSupplied,

    TotalFreight

FROM DataPrep1_VendorBillings

LIMIT 10;



-- Sanity check: does total dollars here roughly match raw Purchases?

SELECT ROUND(SUM(Dollars), 2) AS RawTotal FROM Purchases;

SELECT ROUND(SUM(TotalPurchaseDollars), 2) AS AggTotal FROM DataPrep1_VendorBillings;

-- The second number will be slightly lower because vendors &lt; $1,000 are excluded





-- ============================================================

-- DataPrep1_Top10VendorsByDollars

-- Highest-value supplier relationships by spend

-- ============================================================

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

    AvgDaysPOToPayment

FROM DataPrep1_VendorBillings

ORDER BY TotalPurchaseDollars DESC

LIMIT 10;



-- ============================================================

-- DataPrep1_Top10VendorsByQty

-- Highest-volume suppliers (useful if unit prices are low

-- but volume is strategically significant)

-- ============================================================

CREATE TABLE DataPrep1_Top10VendorsByQty AS

SELECT

    VendorNumber,

    VendorName,

    TotalQuantityPurchased,

    TotalPurchaseDollars,

    TotalPOs,

    UniqueProducts,

    StoresSupplied,

    AvgPurchasePrice

FROM DataPrep1_VendorBillings

ORDER BY TotalQuantityPurchased DESC

LIMIT 10;





---========PHASE 2 DATA EXPLORATION=======

-- Pick one InventoryId that appears in both tables and examine it

SELECT InventoryId, ReceivingDate, Quantity, Dollars, PurchasePrice

FROM Purchases

WHERE InventoryId = '1_HARDERSFIELD_5255';



SELECT InventoryId, SalesDate, SalesQuantity, SalesDollars, SalesPrice

FROM Sales

WHERE InventoryId = '1_HARDERSFIELD_5255'

ORDER BY SalesDate;



-- How much overlap exists between the two tables?

-- (What % of purchase InventoryIds appear in Sales?)

SELECT

    COUNT(DISTINCT p.InventoryId)                           AS InPurchases,

    COUNT(DISTINCT s.InventoryId)                           AS InSales,

    COUNT(DISTINCT CASE

        WHEN s.InventoryId IS NOT NULL

        THEN p.InventoryId END)                             AS InBoth

FROM Purchases p

LEFT JOIN Sales s ON p.InventoryId = s.InventoryId;



-- Test this subquery first to make sure it looks right

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







-- ============================================================

-- DataPrep2_InventoryAging

--

-- Purpose: Identify how long purchased inventory sits on the

-- shelf before being sold. Supports analysis of slow-moving

-- stock, seasonal purchasing patterns, and vendor lead times.

--

-- Grain: One row per InventoryId (Store + Brand combination).

--

-- Key metric: DaysToFirstSale — gap between ReceivingDate and

-- the first recorded sale. NULL means item has not yet sold.

--

-- Seasonality is derived from ReceivingDate month so we can

-- analyze whether certain seasons drive slower inventory turns.

-- ============================================================



CREATE TABLE DataPrep2_InventoryAging AS



SELECT

    -- Item identifiers

    p.InventoryId,

    p.Store,

    TRIM(p.VendorName)                                      AS VendorName,

    p.VendorNumber,

    p.Brand,

    TRIM(p.Description)                                     AS Description,

    p.Size,

    p.Classification,



    -- Purchase details

    p.PODate,

    p.ReceivingDate,

    p.InvoiceDate,

    p.PayDate,

    p.PurchasePrice,

    SUM(p.Quantity)                                         AS TotalQtyPurchased,

    ROUND(SUM(p.Dollars), 2)                                AS TotalPurchaseDollars,

    COUNT(DISTINCT p.PONumber)                              AS NumPOs,



    -- Sales details (NULL if item never sold)

    agg_sales.FirstSaleDate,

    agg_sales.LastSaleDate,

    agg_sales.TotalSalesQty,

    agg_sales.TotalSalesDollars,

    agg_sales.AvgSalesPrice,

    agg_sales.NumSaleDays,



    -- --------------------------------------------------------

    -- Core aging metric: days from receiving to first sale

    -- A large number here = slow-moving inventory

    -- NULL = item has not sold at all

    -- --------------------------------------------------------

    ROUND(

        JULIANDAY(agg_sales.FirstSaleDate) - JULIANDAY(p.ReceivingDate)

    , 0)                                                    AS DaysToFirstSale,



    -- Days from PO creation to receiving (vendor lead time)

    ROUND(

        JULIANDAY(p.ReceivingDate) - JULIANDAY(p.PODate)

    , 0)                                                    AS VendorLeadTimeDays,



    -- Days from invoice to payment (payment cycle)

    ROUND(

        JULIANDAY(p.PayDate) - JULIANDAY(p.InvoiceDate)

    , 0)                                                    AS DaysToPayment,



    -- --------------------------------------------------------

    -- Profitability

    -- --------------------------------------------------------

    ROUND(agg_sales.AvgSalesPrice - p.PurchasePrice, 2)     AS UnitMargin,

    ROUND(

        CASE

            WHEN p.PurchasePrice &gt; 0

            THEN ((agg_sales.AvgSalesPrice - p.PurchasePrice)

                  / p.PurchasePrice) * 100

        END

    , 1)                                                    AS MarginPct,



    -- --------------------------------------------------------

    -- Sell-through rate: what % of purchased qty was sold?

    -- 100% = fully sold through, &lt;100% = still on shelf

    -- --------------------------------------------------------

    ROUND(

        CASE

            WHEN SUM(p.Quantity) &gt; 0

            THEN (CAST(agg_sales.TotalSalesQty AS REAL)

                  / SUM(p.Quantity)) * 100

        END

    , 1)                                                    AS SellThroughPct,



    -- --------------------------------------------------------

    -- Seasonality: derived from the month the item was received

    -- --------------------------------------------------------

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



    -- Sold or unsold flag (useful as a Tableau filter)

    CASE

        WHEN agg_sales.FirstSaleDate IS NULL THEN 'Unsold'

        ELSE 'Sold'

    END                                                     AS SaleStatus



FROM Purchases p



-- Pre-aggregated sales: one row per InventoryId

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





-- Row count

SELECT COUNT(*) FROM DataPrep2_InventoryAging;



-- How many items never sold?

SELECT SaleStatus, COUNT(*) AS Items

FROM DataPrep2_InventoryAging

GROUP BY SaleStatus;



-- What does the aging distribution look like?

-- Gives you a sense of fast vs. slow movers

SELECT

    CASE

        WHEN DaysToFirstSale IS NULL    THEN '5. Never sold'

        WHEN DaysToFirstSale &lt;= 7       THEN '1. 0-7 days'

        WHEN DaysToFirstSale &lt;= 30      THEN '2. 8-30 days'

        WHEN DaysToFirstSale &lt;= 90      THEN '3. 31-90 days'

        ELSE                                 '4. 90+ days'

    END                                 AS AgingBucket,

    COUNT(*)                            AS Items,

    ROUND(AVG(TotalPurchaseDollars), 2) AS AvgPurchaseValue

FROM DataPrep2_InventoryAging

GROUP BY AgingBucket

ORDER BY AgingBucket;



-- Slowest-moving items (most interesting for the CFO)

SELECT

    Description,

    VendorName,

    Size,

    DaysToFirstSale,

    TotalQtyPurchased,

    SellThroughPct,

    TotalPurchaseDollars

FROM DataPrep2_InventoryAging

WHERE SaleStatus = 'Sold'

ORDER BY DaysToFirstSale DESC

LIMIT 15;



-- Seasonality: which receiving month has the slowest average aging?

SELECT

    ReceivingMonthName,

    ReceivingMonth,

    COUNT(*)                            AS Items,

    ROUND(AVG(DaysToFirstSale), 1)      AS AvgDaysToFirstSale,

    ROUND(AVG(SellThroughPct), 1)       AS AvgSellThroughPct

FROM DataPrep2_InventoryAging

WHERE SaleStatus = 'Sold'

GROUP BY ReceivingMonth, ReceivingMonthName

ORDER BY ReceivingMonth;





















































































</sql><current_tab id="0"/></tab_sql></sqlb_project>
