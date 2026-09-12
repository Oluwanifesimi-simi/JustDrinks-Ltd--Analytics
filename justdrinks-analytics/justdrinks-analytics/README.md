# JustDrinks Ltd — Retail Analytics Project

**End-to-end data analytics engagement covering vendor intelligence, inventory aging, and executive sales dashboards for a major alcoholic beverages retailer.**

---

## Project Overview

This project was completed as a capstone analytics engagement during an **Embedded Program (job-shadowing)** with the data team at **Interswitch**, working on behalf of a retail client stakeholder.

**JustDrinks Ltd** is a major retailer of alcoholic beverages operating approximately **80 store locations** with total annual sales in excess of **$450 million**. Leadership engaged the analytics team to perform due diligence on a full fiscal year (FY2016) of transactional data — covering starting and ending inventory, vendor purchases, and retail sales — and to surface actionable insights for executive decision-making.

---

## Business Questions Answered

| # | Stakeholder | Question |
|---|---|---|
| 1 | Executive Leadership | Which vendors are most critical to our supply chain, and how active are they? |
| 2 | Procurement | Which products sit on shelves the longest before selling — and why? |
| 3a | CFO | What is total revenue, and how does it split between wine and spirits? |
| 3b | CFO | Which bottle sizes drive the most volume and value by category? |
| 3c | CFO | Which stores have the highest and lowest average selling prices? |
| 4 | CFO | What additional data should we be collecting to improve forecasting? |

---

## Tech Stack

| Tool | Purpose |
|---|---|
| **SQLite / DB Browser** | Database creation, CSV ingestion, SQL aggregation |
| **SQL** | Data preparation, aggregate table construction, exploration |
| **Tableau Public** | Interactive dashboards and visual analytics |
| **Python (pandas, matplotlib, seaborn)** | Exploratory data analysis and sanity checks |
| **PowerPoint** | Executive data strategy presentation |

---

## Repository Structure

```
justdrinks-analytics/
│
├── README.md                        ← You are here
├── .gitignore
│
├── data/
│   ├── raw/                         ← Original CSV source files (gitignored — see note)
│   └── exports/                     ← Excel exports used as Tableau data sources
│       ├── DataPrep1_VendorBillings.xlsx
│       ├── DataPrep1_Top10Vendors.xlsx
│       └── DataPrep2_InventoryAging.xlsx
│
├── sql/
│   ├── 01_setup_notes.sql           ← Import instructions and table verification
│   ├── 02_exploration.sql           ← Exploratory queries run before building tables
│   ├── 03_dataprep1_vendor.sql      ← Q1: Vendor billings + top 10 tables
│   └── 04_dataprep2_aging.sql       ← Q2: Inventory aging aggregate table
│
├── notebooks/
│   └── eda_justdrinks.ipynb         ← Python EDA: distributions, aging buckets, seasonality
│
├── dashboards/
│   ├── dashboard_vendor_activity.png
│   ├── dashboard_sales_performance.png
│   └── TABLEAU_LINK.md              ← Tableau Public URL
│
├── presentation/
│   └── JustDrinks_Q4_DataStrategy.pptx
│
└── assets/
    └── schema_diagram.png           ← Table relationship overview
```

> **Note on raw data:** Source CSV files are excluded from this repository via `.gitignore` as they contain full transactional records. The SQL scripts, exports, and notebook are fully self-documenting of the transformations applied.

---

## Data Sources

Six CSV files ingested into SQLite as the following tables:

| Table Name | Source File | Description |
|---|---|---|
| `Sales` | `SalesFINAL12312016.csv` | Full-year retail sales transactions |
| `BegInv` | `BegInvFINAL12312016.csv` | Beginning inventory (Jan 1 2016) |
| `EndInv` | `EndInvFINAL12312016.csv` | Ending inventory (Dec 31 2016) |
| `Purchases` | `PurchasesFINAL12312016.csv` | Vendor purchase orders and receipts |
| `InvoicePurchases` | `InvoicePurchases12312016.csv` | Invoice-level billing with freight |
| `PurchasePrices2017` | `2017PurchasePricesDec.csv` | Reference pricing for Dec 2017 |

---

## Aggregate Tables Built

### DataPrep1 — Vendor Intelligence

| Table | Description |
|---|---|
| `DataPrep1_VendorBillings` | One row per critical vendor (>$1,000 purchased); includes PO count, total spend, freight, lead times, and payment behavior |
| `DataPrep1_Top10VendorsByDollars` | Top 10 vendors ranked by total purchase dollars |
| `DataPrep1_Top10VendorsByQty` | Top 10 vendors ranked by total units purchased |

### DataPrep2 — Inventory Aging

| Table | Description |
|---|---|
| `DataPrep2_InventoryAging` | One row per inventory item; measures days from goods receipt to first sale, sell-through rate, unit margin, and purchase seasonality |

---

## Key SQL Design Decisions

**Freight pre-aggregation:** `InvoicePurchases` stores freight at the invoice level, not the line-item level. A naive join multiplies freight costs across every product line on the same PO. This was resolved by pre-aggregating freight per `(VendorNumber, PONumber)` as a subquery before joining to `Purchases`.

**Sales pre-aggregation:** One purchase row maps to many sales rows (one delivery → multiple sale dates). Sales were pre-aggregated per `InventoryId` before joining to avoid row fan-out in the aging table.

**Date handling:** SQLite stores all dates as TEXT. `JULIANDAY()` was used for all date arithmetic (aging, lead times, payment cycles) and `strftime('%m', ...)` for month/season extraction.

---

## Tableau Dashboards

> 📊 **[View Live Dashboards on Tableau Public →](https://public.tableau.com/app/profile/oyinlola.oladeji/viz/JustDrinks_FY2016_Analysis/Bar_StoreAvgPrice)**


**Dashboard 1 — Vendor Activity**
- Critical vendor billing summary table
- Top 10 vendors by spend (bar chart)
- Top 10 vendors by quantity (bar chart)

**Dashboard 2 — Sales Performance**
- Total revenue KPI with wine vs. spirits percentage breakdown (pie)
- Most popular bottle sizes by sales dollars and quantity — wine and spirits separately (bar)
- Store-level average selling price with top/bottom 5 highlighted (sorted bar with reference line)

---

## Data Strategy Recommendation (Q4)

The PowerPoint in `/presentation/` addresses the CFO's question: *"What additional data should we be collecting?"*

Top recommendations prioritised by business impact and ease of collection:

1. **Customer demographics & loyalty data** — enables targeted promotions and lifetime value analysis
2. **Promotional & discount flags on transactions** — allows true measurement of promotion ROI vs. margin giveaway
3. **Weather data linked to store locations** — the single largest external driver of demand that current data cannot explain
4. **Competitor pricing** — identifies where JustDrinks is over- or under-priced by region
5. **Staff headcount & hours** — correlates labour investment with store-level performance

---

## How to Reproduce

### 1. Set up the database

```bash
# Download SQLite DB Browser from https://sqlitebrowser.org
# Create a new database: JustDrinks.db
# Import all 6 CSV files via File → Import → Table from CSV
# Use table names exactly as listed in the Data Sources table above
```

### 2. Run SQL scripts in order

```
sql/01_setup_notes.sql      → verify imports
sql/02_exploration.sql      → understand data shape
sql/03_dataprep1_vendor.sql → build vendor tables
sql/04_dataprep2_aging.sql  → build aging table
```

### 3. Run Python EDA (optional)

```bash
pip install pandas matplotlib seaborn openpyxl
jupyter notebook notebooks/eda_justdrinks.ipynb
```

### 4. Connect Tableau

Open Tableau Public → Connect → Microsoft Excel → select each file from `JustDrinks Project Dataset`

---

## Author

**Oyinlola Oluwanifesimi Oladeji**
Financial Data Analyst | Accountant | M.Sc. Financial Engineering (WorldQuant University, 2027)
Nigeria

[![LinkedIn](https://img.shields.io/badge/LinkedIn-Connect-blue)](https://www.linkedin.com/in/oyinlola-oladeji-430108294/)
[![Tableau](https://img.shields.io/badge/Tableau-Public-orange)](https://public.tableau.com/app/profile/oyinlola.oladeji/viz/JustDrinks_FY2016_Analysis/Bar_StoreAvgPrice)

---

*Completed as a capstone analytics engagement during my Embedded Program (job-shadowing) at Interswitch.*
