# Tableau Public Dashboards

## Live Dashboards

> **[→ View on Tableau Public](https://public.tableau.com/)**
> *(Replace this link with your published Tableau Public URL after publishing)*

---

## Dashboard 1 — Vendor Activity

**Data source:** `DataPrep1_VendorBillings.xlsx`, `DataPrep1_Top10Vendors.xlsx`

| Worksheet | Chart Type | Key Metric |
|---|---|---|
| Critical Vendor Billing Summary | Text table | All critical vendors with POs, spend, freight, lead time |
| Top 10 Vendors by Spend | Horizontal bar | TotalPurchaseDollars |
| Top 10 Vendors by Quantity | Horizontal bar | TotalQuantityPurchased |

**Filters available:** Classification (Wine / Spirits), Date range (PODate)

---

## Dashboard 2 — Sales Performance

**Data source:** `Sales_ForTableau.xlsx`

| Worksheet | Chart Type | Key Metric |
|---|---|---|
| Total Revenue KPI | Big number | SUM(SalesDollars) |
| Wine vs Spirits Breakdown | Pie chart | SalesDollars % by Category |
| Most Popular Size — Spirits | Bar chart | SalesDollars + SalesQuantity by Size |
| Most Popular Size — Wine | Bar chart | SalesDollars + SalesQuantity by Size |
| Store Average Price | Sorted bar + reference line | AVG(SalesPrice) by Store, top/bottom 5 highlighted |

**Filters available:** Category (Wine / Spirits) — applies to all worksheets on dashboard

---

## How to Republish

1. Open the `.twbx` workbook in Tableau Public (Desktop)
2. Update the Excel data source connections if file paths have changed
3. Go to **Server → Tableau Public → Save to Tableau Public As...**
4. Update the URL in this file
