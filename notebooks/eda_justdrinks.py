# %% [markdown]
# # JustDrinks Ltd — Exploratory Data Analysis
# **Capstone Analytics Engagement | Embedded Program, Interswitch**
#
# **Author:** Oyinlola Oluwanifesimi Oladeji
# **Dataset:** FY2016 transactional data — sales, inventory, purchases, vendor invoices
#
# ---
#
# ## Notebook Overview
#
# This notebook performs exploratory data analysis (EDA) on the JustDrinks Ltd
# FY2016 dataset prior to SQL aggregation and Tableau dashboard construction.
# It provides visual sanity checks, distribution analysis, and preliminary
# insights to guide the SQL table design and dashboard questions.
#
# **Sections:**
# 1. Environment setup and data loading
# 2. Sales overview and revenue distribution
# 3. Category analysis — wine vs spirits
# 4. Product size analysis
# 5. Store performance
# 6. Vendor analysis
# 7. Inventory aging preview
# 8. Seasonality analysis
# 9. Key findings summary

# %% [markdown]
# ## 1. Environment Setup

# %%
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import matplotlib.ticker as mticker
import seaborn as sns
import warnings
warnings.filterwarnings('ignore')

# ── Plot styling ──────────────────────────────────────────────
BERRY      = '#6D2E46'
ACCENT     = '#C9506A'
ROSE       = '#A26769'
GOLD       = '#C8973A'
CREAM      = '#F9F4EF'
CHARCOAL   = '#2C2C2A'
MUTED      = '#7A6B6E'
PALETTE    = [BERRY, ACCENT, ROSE, GOLD, '#4A1F31', '#E8C4B0']

plt.rcParams.update({
    'figure.facecolor':  CREAM,
    'axes.facecolor':    CREAM,
    'axes.edgecolor':    MUTED,
    'axes.labelcolor':   CHARCOAL,
    'axes.titlesize':    13,
    'axes.titleweight':  'bold',
    'axes.titlecolor':   BERRY,
    'xtick.color':       MUTED,
    'ytick.color':       MUTED,
    'text.color':        CHARCOAL,
    'font.family':       'sans-serif',
    'figure.dpi':        120,
    'grid.color':        '#E8DDE0',
    'grid.linestyle':    '--',
    'grid.linewidth':    0.5,
})

sns.set_palette(PALETTE)
print("✓ Libraries loaded and plot style configured.")

# %% [markdown]
# ## 2. Data Loading
#
# Load the six source CSV files.
# Update file paths below to match your local directory.

# %%
# ── File paths — update these to match your data/raw/ folder ──
DATA_DIR = '../data/raw/'

sales     = pd.read_csv(DATA_DIR + 'SalesFINAL12312016.csv',      low_memory=False)
beg_inv   = pd.read_csv(DATA_DIR + 'BegInvFINAL12312016.csv',     low_memory=False)
end_inv   = pd.read_csv(DATA_DIR + 'EndInvFINAL12312016.csv',     low_memory=False)
purchases = pd.read_csv(DATA_DIR + 'PurchasesFINAL12312016.csv',  low_memory=False)
invoices  = pd.read_csv(DATA_DIR + 'InvoicePurchases12312016.csv',low_memory=False)
prices    = pd.read_csv(DATA_DIR + '2017PurchasePricesDec.csv',   low_memory=False)

# ── Strip whitespace from string columns ──────────────────────
for df in [sales, purchases, invoices]:
    str_cols = df.select_dtypes(include='object').columns
    df[str_cols] = df[str_cols].apply(lambda c: c.str.strip())

print(f"Sales rows:     {len(sales):>10,}")
print(f"BegInv rows:    {len(beg_inv):>10,}")
print(f"EndInv rows:    {len(end_inv):>10,}")
print(f"Purchases rows: {len(purchases):>10,}")
print(f"Invoices rows:  {len(invoices):>10,}")
print(f"Prices rows:    {len(prices):>10,}")

# %%
# ── Parse date columns ────────────────────────────────────────
sales['SalesDate']          = pd.to_datetime(sales['SalesDate'],       infer_datetime_format=True)
purchases['PODate']         = pd.to_datetime(purchases['PODate'],       infer_datetime_format=True)
purchases['ReceivingDate']  = pd.to_datetime(purchases['ReceivingDate'],infer_datetime_format=True)
purchases['InvoiceDate']    = pd.to_datetime(purchases['InvoiceDate'],  infer_datetime_format=True)
purchases['PayDate']        = pd.to_datetime(purchases['PayDate'],       infer_datetime_format=True)

sales['Month']    = sales['SalesDate'].dt.month
sales['MonthName']= sales['SalesDate'].dt.strftime('%b')
sales['Quarter']  = sales['SalesDate'].dt.quarter

print("✓ Date columns parsed.")

# %% [markdown]
# ## 3. Sales Overview

# %%
# ── KPI summary ───────────────────────────────────────────────
total_revenue   = sales['SalesDollars'].sum()
total_qty       = sales['SalesQuantity'].sum()
avg_price       = sales['SalesPrice'].mean()
unique_stores   = sales['Store'].nunique()
unique_products = sales['InventoryId'].nunique()
date_range      = f"{sales['SalesDate'].min().date()} → {sales['SalesDate'].max().date()}"

print("=" * 48)
print("  JustDrinks FY2016 — Sales KPIs")
print("=" * 48)
print(f"  Total Revenue       : ${total_revenue:>15,.2f}")
print(f"  Total Units Sold    : {total_qty:>16,}")
print(f"  Avg Selling Price   : ${avg_price:>15.2f}")
print(f"  Unique Stores       : {unique_stores:>16,}")
print(f"  Unique SKUs Sold    : {unique_products:>16,}")
print(f"  Date Range          : {date_range}")
print("=" * 48)

# %%
# ── Monthly revenue trend ─────────────────────────────────────
monthly = (sales.groupby(['Month', 'MonthName'])['SalesDollars']
               .sum()
               .reset_index()
               .sort_values('Month'))

fig, ax = plt.subplots(figsize=(12, 4.5))
bars = ax.bar(monthly['MonthName'], monthly['SalesDollars'],
              color=BERRY, width=0.65, zorder=2)
ax.set_title('Monthly Sales Revenue — FY2016')
ax.set_xlabel('Month')
ax.set_ylabel('Revenue ($)')
ax.yaxis.set_major_formatter(mticker.FuncFormatter(lambda x, _: f'${x/1e6:.1f}M'))
ax.grid(axis='y', zorder=1)
ax.set_facecolor(CREAM)

# Annotate peak month
peak_idx = monthly['SalesDollars'].idxmax()
peak_bar = bars[monthly.index.get_loc(peak_idx)]
ax.annotate(
    f"Peak: ${monthly.loc[peak_idx,'SalesDollars']/1e6:.1f}M",
    xy=(peak_bar.get_x() + peak_bar.get_width()/2,
        peak_bar.get_height()),
    xytext=(0, 8), textcoords='offset points',
    ha='center', fontsize=9, color=ACCENT, fontweight='bold'
)
plt.tight_layout()
plt.savefig('../assets/monthly_revenue.png', bbox_inches='tight')
plt.show()
print("✓ Chart saved: assets/monthly_revenue.png")

# %% [markdown]
# ## 4. Category Analysis — Wine vs Spirits

# %%
# Map classification codes to readable labels
cat_map = {1: 'Spirits', 2: 'Wine'}
sales['Category'] = sales['Classification'].map(cat_map).fillna('Other')

cat_summary = (sales.groupby('Category')
               .agg(
                   Revenue      = ('SalesDollars',  'sum'),
                   Quantity     = ('SalesQuantity', 'sum'),
                   Transactions = ('SalesDate',     'count'),
                   AvgPrice     = ('SalesPrice',    'mean')
               )
               .round(2)
               .reset_index())

cat_summary['RevenuePct'] = (cat_summary['Revenue'] /
                              cat_summary['Revenue'].sum() * 100).round(1)

print(cat_summary.to_string(index=False))

# %%
# ── Side-by-side: revenue pie + quantity bar ──────────────────
fig, axes = plt.subplots(1, 2, figsize=(12, 5))

# Pie — revenue share
axes[0].pie(
    cat_summary['Revenue'],
    labels=cat_summary['Category'],
    autopct='%1.1f%%',
    colors=[BERRY, ACCENT],
    startangle=90,
    wedgeprops={'edgecolor': CREAM, 'linewidth': 2},
    textprops={'fontsize': 12}
)
axes[0].set_title('Revenue Share\nWine vs Spirits')
axes[0].set_facecolor(CREAM)

# Bar — quantity sold
axes[1].bar(cat_summary['Category'], cat_summary['Quantity'],
            color=[BERRY, ACCENT], width=0.5, zorder=2)
axes[1].set_title('Total Units Sold\nWine vs Spirits')
axes[1].set_ylabel('Units Sold')
axes[1].yaxis.set_major_formatter(mticker.FuncFormatter(lambda x, _: f'{x/1e6:.1f}M'))
axes[1].grid(axis='y', zorder=1)
axes[1].set_facecolor(CREAM)

plt.tight_layout()
plt.savefig('../assets/category_split.png', bbox_inches='tight')
plt.show()
print("✓ Chart saved: assets/category_split.png")

# %% [markdown]
# ## 5. Product Size Analysis

# %%
# Revenue and quantity by bottle size — spirits
def size_chart(category_label, color, filename):
    subset = sales[sales['Category'] == category_label]
    size_df = (subset.groupby('Size')
               .agg(Revenue=('SalesDollars','sum'),
                    Qty=('SalesQuantity','sum'))
               .sort_values('Revenue', ascending=False)
               .head(10)
               .reset_index())

    fig, ax1 = plt.subplots(figsize=(10, 4.5))
    ax2 = ax1.twinx()

    bars = ax1.bar(size_df['Size'], size_df['Revenue'],
                   color=color, alpha=0.85, width=0.5, zorder=2, label='Revenue')
    ax2.plot(size_df['Size'], size_df['Qty'],
             color=GOLD, marker='o', linewidth=2, label='Qty Sold', zorder=3)

    ax1.set_title(f'{category_label} — Sales by Bottle Size (Top 10)')
    ax1.set_xlabel('Bottle Size')
    ax1.set_ylabel('Revenue ($)', color=color)
    ax2.set_ylabel('Units Sold', color=GOLD)
    ax1.yaxis.set_major_formatter(mticker.FuncFormatter(lambda x, _: f'${x/1e6:.1f}M'))
    ax1.grid(axis='y', zorder=1)
    ax1.set_facecolor(CREAM)

    lines1, labels1 = ax1.get_legend_handles_labels()
    lines2, labels2 = ax2.get_legend_handles_labels()
    ax1.legend(lines1 + lines2, labels1 + labels2, loc='upper right', fontsize=9)

    plt.xticks(rotation=30, ha='right')
    plt.tight_layout()
    plt.savefig(f'../assets/{filename}', bbox_inches='tight')
    plt.show()
    print(f"✓ Chart saved: assets/{filename}")
    return size_df

spirits_sizes = size_chart('Spirits', BERRY,  'spirits_by_size.png')
wine_sizes    = size_chart('Wine',    ACCENT, 'wine_by_size.png')

# %% [markdown]
# ## 6. Store Performance

# %%
store_summary = (sales.groupby('Store')
                 .agg(
                     Revenue  = ('SalesDollars', 'sum'),
                     AvgPrice = ('SalesPrice',   'mean'),
                     Qty      = ('SalesQuantity','sum')
                 )
                 .round(2)
                 .reset_index()
                 .sort_values('AvgPrice', ascending=False))

print(f"Total stores: {len(store_summary)}")
print("\nTop 10 by Average Sales Price:")
print(store_summary.head(10).to_string(index=False))
print("\nBottom 10 by Average Sales Price:")
print(store_summary.tail(10).to_string(index=False))

# %%
# ── Average price per store — horizontal bar (top + bottom 10) ─
top5    = store_summary.head(5).copy()
bot5    = store_summary.tail(5).copy()
subset  = pd.concat([top5, bot5]).reset_index(drop=True)
subset['Color'] = ([BERRY]*5) + ([ACCENT]*5)
subset['Label'] = ['Top 5']*5 + ['Bottom 5']*5

fig, ax = plt.subplots(figsize=(10, 6))
bars = ax.barh(subset['Store'].astype(str),
               subset['AvgPrice'],
               color=subset['Color'], zorder=2)

avg_all = store_summary['AvgPrice'].mean()
ax.axvline(avg_all, color=GOLD, linewidth=1.5,
           linestyle='--', label=f'Network Avg: ${avg_all:.2f}')

ax.set_title('Top 5 & Bottom 5 Stores — Average Sales Price')
ax.set_xlabel('Average Selling Price ($)')
ax.set_ylabel('Store Number')
ax.grid(axis='x', zorder=1)
ax.set_facecolor(CREAM)
ax.legend(fontsize=9)
plt.tight_layout()
plt.savefig('../assets/store_avg_price.png', bbox_inches='tight')
plt.show()
print("✓ Chart saved: assets/store_avg_price.png")

# %% [markdown]
# ## 7. Vendor Analysis

# %%
vendor_summary = (purchases.groupby(['VendorNumber','VendorName'])
                  .agg(
                      TotalDollars = ('Dollars',  'sum'),
                      TotalQty     = ('Quantity', 'sum'),
                      TotalPOs     = ('PONumber', 'nunique'),
                      UniqueItems  = ('Description','nunique')
                  )
                  .round(2)
                  .reset_index()
                  .sort_values('TotalDollars', ascending=False))

critical = vendor_summary[vendor_summary['TotalDollars'] > 1000]
print(f"Total vendors     : {len(vendor_summary)}")
print(f"Critical vendors  : {len(critical)}  (> $1,000 spend)")
print(f"\nTop 10 by Spend:")
print(critical.head(10)[['VendorName','TotalDollars','TotalQty','TotalPOs']].to_string(index=False))

# %%
# ── Top 15 vendors by spend ───────────────────────────────────
top15 = critical.head(15).copy()

fig, ax = plt.subplots(figsize=(11, 6))
ax.barh(top15['VendorName'].str[:30],
        top15['TotalDollars'],
        color=BERRY, zorder=2)
ax.set_title('Top 15 Vendors by Total Purchase Spend')
ax.set_xlabel('Total Purchase Dollars ($)')
ax.xaxis.set_major_formatter(mticker.FuncFormatter(lambda x,_: f'${x/1e6:.1f}M'))
ax.invert_yaxis()
ax.grid(axis='x', zorder=1)
ax.set_facecolor(CREAM)
plt.tight_layout()
plt.savefig('../assets/top15_vendors.png', bbox_inches='tight')
plt.show()
print("✓ Chart saved: assets/top15_vendors.png")

# %% [markdown]
# ## 8. Inventory Aging Preview
#
# Approximate the SQL `DataPrep2_InventoryAging` logic in pandas
# to visualise aging distributions before the full SQLite build.

# %%
# Aggregate sales per InventoryId
sales_agg = (sales.groupby('InventoryId')
             .agg(
                 FirstSaleDate  = ('SalesDate',     'min'),
                 TotalSalesQty  = ('SalesQuantity', 'sum'),
                 TotalSalesDollars = ('SalesDollars','sum'),
                 AvgSalesPrice  = ('SalesPrice',    'mean')
             )
             .reset_index())

# Aggregate purchases per InventoryId
purch_agg = (purchases.groupby(['InventoryId','ReceivingDate','PurchasePrice','VendorName','Classification'])
             .agg(
                 TotalQtyPurchased    = ('Quantity','sum'),
                 TotalPurchaseDollars = ('Dollars', 'sum')
             )
             .reset_index())

# Join
aging = purch_agg.merge(sales_agg, on='InventoryId', how='left')

# Compute days to first sale
aging['DaysToFirstSale'] = (
    (aging['FirstSaleDate'] - aging['ReceivingDate'])
    .dt.days
)

# Sell-through rate
aging['SellThroughPct'] = (
    aging['TotalSalesQty'] / aging['TotalQtyPurchased'] * 100
).clip(upper=200)

# Sale status
aging['SaleStatus'] = aging['FirstSaleDate'].apply(
    lambda x: 'Sold' if pd.notnull(x) else 'Unsold'
)

sold = aging[aging['SaleStatus'] == 'Sold']
print(f"Total inventory lines : {len(aging):,}")
print(f"Sold                  : {len(sold):,}")
print(f"Unsold                : {len(aging) - len(sold):,}")
print(f"\nAging stats (sold items):")
print(sold['DaysToFirstSale'].describe().round(1).to_string())

# %%
# ── Aging distribution histogram ──────────────────────────────
fig, ax = plt.subplots(figsize=(11, 4.5))
ax.hist(sold['DaysToFirstSale'].dropna(),
        bins=60, color=BERRY, edgecolor=CREAM, linewidth=0.3, zorder=2)
ax.axvline(sold['DaysToFirstSale'].median(), color=GOLD,
           linewidth=2, linestyle='--',
           label=f"Median: {sold['DaysToFirstSale'].median():.0f} days")
ax.set_title('Distribution of Days to First Sale (Sold Items Only)')
ax.set_xlabel('Days from Receiving to First Sale')
ax.set_ylabel('Number of Items')
ax.grid(axis='y', zorder=1)
ax.set_facecolor(CREAM)
ax.legend()
plt.tight_layout()
plt.savefig('../assets/aging_distribution.png', bbox_inches='tight')
plt.show()
print("✓ Chart saved: assets/aging_distribution.png")

# %%
# ── Sell-through rate by aging bucket ─────────────────────────
bins   = [0, 7, 30, 90, float('inf')]
labels = ['0–7 days', '8–30 days', '31–90 days', '90+ days']
sold['AgingBucket'] = pd.cut(sold['DaysToFirstSale'],
                              bins=bins, labels=labels, right=True)

bucket_summary = (sold.groupby('AgingBucket', observed=True)
                  .agg(
                      Items          = ('InventoryId',      'count'),
                      AvgSellThrough = ('SellThroughPct',   'mean'),
                      AvgPurchaseVal = ('TotalPurchaseDollars','mean')
                  )
                  .round(1)
                  .reset_index())

print(bucket_summary.to_string(index=False))

fig, ax = plt.subplots(figsize=(9, 4))
ax.bar(bucket_summary['AgingBucket'].astype(str),
       bucket_summary['AvgSellThrough'],
       color=[BERRY, ROSE, ACCENT, GOLD], width=0.5, zorder=2)
ax.axhline(100, color=MUTED, linewidth=1, linestyle='--', label='100% sell-through')
ax.set_title('Average Sell-Through Rate by Aging Bucket')
ax.set_xlabel('Days to First Sale')
ax.set_ylabel('Avg Sell-Through (%)')
ax.grid(axis='y', zorder=1)
ax.set_facecolor(CREAM)
ax.legend(fontsize=9)
plt.tight_layout()
plt.savefig('../assets/sellthrough_by_bucket.png', bbox_inches='tight')
plt.show()
print("✓ Chart saved: assets/sellthrough_by_bucket.png")

# %% [markdown]
# ## 9. Seasonality Analysis

# %%
# Average days to first sale by receiving month
aging['ReceivingMonth']    = aging['ReceivingDate'].dt.month
aging['ReceivingMonthName']= aging['ReceivingDate'].dt.strftime('%b')

seasonality = (sold.assign(
    ReceivingMonth    = sold['ReceivingDate'].dt.month,
    ReceivingMonthName= sold['ReceivingDate'].dt.strftime('%b')
).groupby(['ReceivingMonth','ReceivingMonthName'])
 .agg(
     AvgDaysToFirstSale = ('DaysToFirstSale','mean'),
     AvgSellThrough     = ('SellThroughPct', 'mean'),
     Items              = ('InventoryId',    'count')
 )
 .round(1)
 .reset_index()
 .sort_values('ReceivingMonth'))

print(seasonality[['ReceivingMonthName','AvgDaysToFirstSale',
                    'AvgSellThrough','Items']].to_string(index=False))

# %%
fig, ax1 = plt.subplots(figsize=(12, 4.5))
ax2 = ax1.twinx()

bars = ax1.bar(seasonality['ReceivingMonthName'],
               seasonality['AvgDaysToFirstSale'],
               color=BERRY, alpha=0.8, width=0.55, zorder=2,
               label='Avg Days to First Sale')
ax2.plot(seasonality['ReceivingMonthName'],
         seasonality['AvgSellThrough'],
         color=GOLD, marker='o', linewidth=2.5,
         label='Avg Sell-Through %', zorder=3)

ax1.set_title('Seasonality — Purchase Month vs Inventory Aging & Sell-Through')
ax1.set_xlabel('Month Inventory Was Received')
ax1.set_ylabel('Avg Days to First Sale', color=BERRY)
ax2.set_ylabel('Avg Sell-Through (%)', color=GOLD)
ax1.grid(axis='y', zorder=1)
ax1.set_facecolor(CREAM)

lines1, labels1 = ax1.get_legend_handles_labels()
lines2, labels2 = ax2.get_legend_handles_labels()
ax1.legend(lines1 + lines2, labels1 + labels2,
           loc='upper left', fontsize=9)

plt.tight_layout()
plt.savefig('../assets/seasonality.png', bbox_inches='tight')
plt.show()
print("✓ Chart saved: assets/seasonality.png")

# %% [markdown]
# ## 10. Key Findings Summary

# %%
print("=" * 60)
print("  JustDrinks FY2016 — EDA Key Findings")
print("=" * 60)

top_cat = cat_summary.sort_values('Revenue', ascending=False).iloc[0]
top_spirit_size = spirits_sizes.iloc[0]
top_wine_size   = wine_sizes.iloc[0]
top_store_high  = store_summary.iloc[0]
top_store_low   = store_summary.iloc[-1]
top_vendor      = critical.iloc[0]
median_aging    = sold['DaysToFirstSale'].median()
unsold_pct      = (len(aging) - len(sold)) / len(aging) * 100

print(f"""
Revenue
  Total FY2016 revenue       : ${total_revenue:,.0f}
  Dominant category          : {top_cat['Category']} ({top_cat['RevenuePct']:.1f}% of revenue)

Product Size
  Top spirits size (revenue) : {top_spirit_size['Size']} (${top_spirit_size['Revenue']:,.0f})
  Top wine size (revenue)    : {top_wine_size['Size']} (${top_wine_size['Revenue']:,.0f})

Store Pricing
  Highest avg price store    : Store {top_store_high['Store']} (${top_store_high['AvgPrice']:.2f})
  Lowest avg price store     : Store {top_store_low['Store']} (${top_store_low['AvgPrice']:.2f})

Vendor Landscape
  Critical vendors (>$1k)    : {len(critical)}
  Top vendor by spend        : {top_vendor['VendorName']} (${top_vendor['TotalDollars']:,.0f})

Inventory Aging
  Median days to first sale  : {median_aging:.0f} days
  Items never sold (FY2016)  : {unsold_pct:.1f}% of purchased lines
""")
print("=" * 60)

# %% [markdown]
# ---
# ## Notes
#
# - All monetary figures are in USD.
# - `Classification = 1` maps to **Spirits**; `Classification = 2` maps to **Wine**.
#   Verify this against source documentation if the business uses a different encoding.
# - The aging analysis uses `ReceivingDate` as the inventory start point.
#   Items purchased before FY2016 and carried forward from beginning inventory
#   are not captured in this analysis.
# - Charts are saved to `../assets/` for inclusion in the README and presentations.
#
# **Next steps:** Load aggregate tables into Tableau for interactive dashboard build.
