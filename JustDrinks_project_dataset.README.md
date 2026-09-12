# JustDrinks_project_dataset/Raw_dataset/Export_data/
This folder contains the Excel files exported from SQLite DB Browser
and used as data sources for Tableau Public dashboards.

## How these files were created

In SQLite DB Browser:
1. Import all relvant `.csv` files 
2. Create necessary tables that is needed to answer the Executive Questions (e.g.  `CREATE TABLE DataPrep1_VendorBillings AS`)
2. Open the **Execute SQL** tab
2. Run the relevant query (e.g. `SELECT * FROM DataPrep1_VendorBillings`)
3. In the results panel, right-click → **Copy All**
4. Paste into a new Excel sheet
5. Add column headers in row 1 (copy from the query's SELECT list)
6. Save as `.xlsx`

> **Note:** Per the case study instructions, the SQLite "Export to SQL" feature was NOT used. Results were copy-pasted manually into Excel.

## Files in this folder

| File | Source Table | Used By |
|---|---|---|
| `DataPrep1_VendorBillings.xlsx` | `DataPrep1_VendorBillings` | Tableau — Vendor Activity Dashboard |
| `DataPrep1_Top10Vendors.xlsx` | `DataPrep1_Top10VendorsByDollars` + `DataPrep1_Top10VendorsByQty` | Tableau — Vendor Activity Dashboard |
| `DataPrep2_InventoryAging.xlsx` | `DataPrep2_InventoryAging` | Tableau — optional inventory deep-dive |
| `Sales_ForTableau.xlsx` | `Sales` (full table or summary) | Tableau — Sales Performance Dashboard |

## Column headers to include

Copy these exactly into row 1 of each Excel file:

**DataPrep1_VendorBillings.xlsx**
`VendorNumber, VendorName, TotalPOs, TotalLineItems, TotalQuantityPurchased, TotalPurchaseDollars, AvgPurchasePrice, MinPurchasePrice, MaxPurchasePrice, UniqueBrands, UniqueProducts, StoresSupplied, FirstPODate, LastPODate, FirstReceivingDate, LastReceivingDate, AvgLeadTimeDays, AvgDaysPOToPayment, TotalFreight, NumClassifications`
 

**DataPrep2_InventoryAging.xlsx**
`InventoryId, Store, VendorName, VendorNumber, Brand, Description, Size, Classification, PODate, ReceivingDate, InvoiceDate, PayDate, PurchasePrice, TotalQtyPurchased, TotalPurchaseDollars, NumPOs, FirstSaleDate, LastSaleDate, TotalSalesQty, TotalSalesDollars, AvgSalesPrice, NumSaleDays, DaysToFirstSale, VendorLeadTimeDays, DaysToPayment, UnitMargin, MarginPct, SellThroughPct, ReceivingMonth, ReceivingMonthName, ReceivingSeason, SaleStatus`
