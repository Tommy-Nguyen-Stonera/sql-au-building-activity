<p align="center">
  <img src="https://img.shields.io/badge/SQL_Server-T--SQL-CC2927?logo=microsoftsqlserver&logoColor=white" alt="T-SQL">
  <img src="https://img.shields.io/badge/SSMS-19.x-0078D4?logo=microsoft&logoColor=white" alt="SSMS">
  <img src="https://img.shields.io/badge/Data_Source-ABS_(Cat._8752.0)-003366" alt="ABS">
  <img src="https://img.shields.io/badge/Period-2010--2025-2E8B57" alt="Period">
  <img src="https://img.shields.io/badge/Records-184,971-FF6F00" alt="Records">
</p>

# Australian Building Activity Analysis (T-SQL)
> **[View Interactive Report](https://htmlpreview.github.io/?https://raw.githubusercontent.com/Tommy-Nguyen-Stonera/sql-au-building-activity/main/report.html)** — Full analysis with findings, methodology, and insights


A deep-dive into 15 years of quarterly building activity data from the Australian Bureau of Statistics (ABS), tracking what gets started, what gets built, and what gets stuck in the pipeline across every state and territory. The dataset covers Q1 2010 through Q3 2025 — a period that spans the post-GFC recovery, the apartment construction boom, the COVID disruption, and the current housing supply crisis.

## The Story Behind This Analysis

Approvals tell you what's planned, but activity data tells you what's actually happening on the ground. In my years selling building materials, I learned that the gap between what gets approved and what gets built is where the real story is. An approval is a piece of paper. A commencement is a slab being poured. A completion is a certificate of occupancy. The distances between those three events — in time, in dollars, and across states — reveal things about the construction industry that no single headline number can capture.

I have watched projects sit approved but uncommenced for quarters at a time because the builder could not lock in trades or materials. I have seen states where commencements were running hot but completions were lagging further and further behind, creating a pipeline that looked healthy on paper but was actually congested. And I have noticed that the mix of what gets built — houses versus apartments, residential versus non-residential, private versus public — shifts in ways that directly affect which products move and which sit in the warehouse.

This project takes the ABS Building Activity Survey (Cat. 8752.0) and works through it systematically with T-SQL. The goal is not just to report the numbers, but to structure the queries in a way that mirrors how someone in the construction supply chain actually thinks about the market: What is the pipeline doing? Where is the money flowing? Which states are accelerating, and which are stalling? Is the residential-to-commercial mix shifting in a way that changes demand patterns?

The ABS dataset came in SDMX format with coded columns — MEASURE codes like M1 through M8, REGION codes 1 through 8, PRICE_ADJ as CUR or CVM. Before I could start the analysis, I had to map every code to its meaning. In that process, I discovered that the dataset contains both current prices and chain volume measures — and that distinction turned out to be the most important analytical choice in the entire project.

The thinking was progressive. Start with the national overview to understand scale and trajectory. Then compare states to see where the real concentration of activity is. From there, examine the starts-to-completions ratio to identify bottlenecks. Break the dwelling types apart to see whether the industry is building houses or apartments. Look at the value of work to understand where the highest-dollar construction is concentrated. Track the quarter-over-quarter momentum to identify turning points. Measure the pipeline to see how much work is physically under construction. And finally, use a PIVOT to compare states side-by-side across years.

## Business Questions

1. **How much building work is being started, completed, and progressed each year?** What is the trajectory of national construction activity?
2. **Which states dominate building activity?** How concentrated is the industry, and is the balance shifting?
3. **Are projects piling up or getting finished?** What does the starts-to-completions ratio reveal about construction bottlenecks?
4. **What is being built — houses or apartments?** How has the dwelling type mix changed over 15 years?
5. **Where is the highest-value construction?** Which state-and-building-type combinations command the most dollars?
6. **Is momentum accelerating or slowing?** What do the quarter-over-quarter changes show about turning points?
7. **How large is the national pipeline?** How many dwellings are physically under construction at any given time?
8. **How do states compare year-by-year?** Which states are gaining or losing share of national commencements?

## Thinking Flow

The analysis follows a deliberate progression from macro to micro, and from descriptive to diagnostic:

```
National annual totals (scale & direction)
    |
    v
State-level rankings (concentration & share)
    |
    v
Starts-to-completions ratio (bottleneck identification)
    |
    v
Dwelling type breakdown (structural mix shifts)
    |
    v
Value analysis by state x type (dollar concentration)
    |
    v
Quarter-over-quarter momentum (turning point detection)
    |
    v
Pipeline under construction (physical work in progress)
    |
    v
Year-over-year PIVOT comparison (state trajectory mapping)
```

That was the planned sequence. In practice, the chain volume finding in Query 1 changed how I interpreted everything that followed. Every subsequent query, I ran in both current prices and CVM to check whether the pattern held in real terms or was just cost inflation. In most cases, the CVM picture was less dramatic than the current-price picture.

Each query builds on the context established by the previous one. The national overview tells you the industry is growing. The state comparison tells you where that growth is concentrated. The starts-to-completions ratio tells you whether the growth is translating into finished buildings or just accumulating as work-in-progress. And so on. By the final PIVOT query, you have enough context to read the year-by-year state numbers and immediately understand the implications.

## Key Findings

### 1. National building activity grew 87% in current prices over 14 years, but real growth was far more modest

Total building work commenced rose from $89.4B in 2010 to $167.4B in 2024 — an 87% increase in current dollar terms. But when you adjust for construction cost inflation using chain volume measures, the picture is very different. In CVM terms, 2024 ($162.5B) is barely above 2018 ($164.1B). The apparent growth over the last six years is almost entirely explained by higher construction costs, not more physical building work. This is the single most important finding for anyone in building materials: the industry is spending more money to build roughly the same amount of stuff. This made me reconsider every growth headline I had read about the construction industry. If nominal growth is not translating to more physical work, then material volumes should be roughly flat — which is exactly what we have seen in our order books. The data finally explained something I had been observing but could not quantify.

### 2. Victoria overtook NSW as the largest construction market by value of work commenced

In 2024, Victoria led with $52.7B in total building work commenced, ahead of NSW at $50.0B and Queensland at $32.2B. Together, the top three states account for over 80% of national building activity. Western Australia ($15.7B) and South Australia ($9.7B) round out the meaningful markets. Tasmania, ACT, and the Northern Territory are collectively under $8B. For a building materials supplier, the strategic implication is clear: your growth comes from VIC, NSW, and QLD. Everything else is margin.

### 3. The starts-to-completions ratio spiked to 1.34 in 2021, revealing a post-COVID pipeline jam

The ratio of work commenced to work done (the closest proxy for starts-to-completions in value terms) ran at a healthy 1.04-1.09 range between 2015 and 2018. In 2020, it dropped to 0.97 as COVID slowed new starts. Then in 2021, it surged to 1.34 — meaning $1.34 was being started for every $1.00 of work being done. This represents a massive pipeline jam: projects were starting but not progressing at the same rate, likely due to trade shortages, material delays, and supply chain disruptions. By 2024, the ratio had settled back to 1.09, but the backlog accumulated during 2021-2022 is still working through the system.

### 4. Houses dominate commencements by value, but apartments dominate the pipeline by count

In 2024, houses accounted for 61% of new residential work commenced by value ($53.0B vs $33.6B for apartments). But the under-construction pipeline tells a different story: as of Q3 2025, there were 141,852 apartments under construction versus only 87,323 houses. Apartments take longer to build — multi-storey construction involves more complex staging, more trades, and longer approval-to-completion timelines. This means the apartment pipeline represents a disproportionate share of active construction sites, ongoing material demand, and trade labour absorption relative to its share of commencement value.

This raises a question the data cannot directly answer: how long does the average apartment project actually stay under construction? If apartment completion times have been stretching — as trade shortages and material delays would suggest — then the pipeline count overstates how much active work is being done at any given time.

### 5. The national pipeline peaked at 244,100 dwellings in Q3 2022, then contracted before rebounding

The number of dwellings under construction nationally peaked at 244,100 in September 2022. It then contracted steadily to 212,475 by December 2024 — a 13% decline that reflected both completions catching up and new starts slowing. But by Q3 2025, the pipeline had rebounded to 229,750, suggesting a new cycle of commencements is filling the pipeline again. For building materials, the pipeline count is arguably more important than commencement data because it represents the work that is actively consuming materials right now.

### 6. NSW carries the largest state pipeline at 75,612 dwellings under construction

As of Q3 2025, NSW had 75,612 dwellings under construction — 33% of the national pipeline. Victoria followed at 61,768 (27%), then Queensland at 45,142 (20%). Western Australia had 23,618 and South Australia 14,897. The state-level pipeline distribution tells you where material demand is physically concentrated. A dwelling under construction in NSW is consuming concrete, steel, timber, plasterboard, and finishing materials right now. A dwelling that has been approved but not commenced is not.

### 7. COVID barely dented quarterly commencements nationally — the real impact was in the pipeline

Looking at seasonally adjusted quarterly commencements, COVID's direct impact was surprisingly small: spending dipped from $30.6B in Q4 2019 to $29.7B in Q3 2020, a drop of less than 3%. The real disruption was not in the volume of new starts but in the flow-through. Existing projects slowed dramatically due to lockdowns and supply chain issues, causing the under-construction pipeline to swell from 184,199 in Q3 2020 to 244,100 by Q3 2022 — a 33% increase in dwellings stuck in the construction phase. The industry was not starting fewer projects; it was finishing them much more slowly.

### 8. Private sector accounts for 87% of building work commenced

In 2024, private sector building work commenced totalled $145.2B versus $22.2B for the public sector. The 87/13 split has been remarkably stable over the full period. This means the construction cycle is overwhelmingly driven by private investment decisions — developer confidence, interest rates, credit availability, and housing demand. Public spending provides a small stabilising floor but does not meaningfully offset private sector downturns.

### 9. Non-residential construction has grown its share from 36% to 40% of total work commenced

In 2015, residential accounted for 64% of total building work commenced and non-residential for 36%. By 2024, the split had shifted to 60/40. Non-residential work grew from $37.1B to $66.7B — an 80% increase — driven by infrastructure, healthcare, education, and commercial projects. For a building materials supplier, this gradual shift means the product mix is changing: non-residential typically demands different specifications, larger order quantities, and different procurement processes than residential.

### 10. NSW has the most balanced house-to-apartment ratio of any major state

In 2024, NSW commenced $12.7B in new houses and $12.5B in new apartments — a nearly even 50/50 split. Victoria skewed heavily toward houses ($17.5B vs $10.5B apartments), Queensland was 62/38 houses, and Western Australia was 83/17. NSW's balanced mix reflects Sydney's density constraints and strong apartment development pipeline. For suppliers, this means the NSW market demands a broader product range — from detached house finishing materials through to high-rise apartment specifications — compared to states where houses dominate.

## What Surprised Me

The chain volume comparison was the most striking finding. An 87% increase in current dollar terms over 14 years sounds like genuine industry growth. But when you strip out construction cost inflation, the real growth from 2018 to 2024 is effectively zero. The industry is running harder just to stand still in terms of physical output. Construction cost inflation — driven by material prices, trade wages, and compliance costs — has consumed almost all of the nominal growth. For anyone interpreting industry statistics at face value, this is a critical caveat.

The other surprise was the apartment pipeline dominance. By value of work commenced, houses are clearly the larger market. But by physical count of dwellings under construction, apartments outnumber houses by a ratio of 1.6 to 1. This means the "average" construction site in Australia is more likely to be a multi-storey apartment development than a detached house. The implications for material demand, trade allocation, and logistics are significant — and they are not obvious from the commencement data alone.

## What I'd Investigate Next

- **Completion timelines by dwelling type**: The data shows what is under construction but does not directly report how long projects take to complete. Estimating average completion times for houses versus apartments would reveal whether the pipeline is genuinely congested or just reflects normal construction duration.
- **Approved-but-not-commenced backlog**: The M6 "yet to be done" measure (51,359 dwellings as of Q3 2025 and rising) deserves deeper analysis. A growing backlog of approved-but-uncommenced work could signal builder capacity constraints, financing difficulties, or regulatory delays.
- **Sub-state granularity**: National and state-level data is useful for market sizing, but procurement decisions happen at the metro and regional level. Linking this data to LGA-level approval data would create a much more actionable view.
- **Cross-referencing with approvals data**: Comparing this activity dataset with the ABS Building Approvals data (Cat. 8731.0) would quantify the approval-to-commencement conversion rate — a key leading indicator for materials demand.
- **Construction cost deflators**: Building a more detailed view of how cost inflation varies by state and building type would help separate genuine volume growth from price effects.

## Dataset Overview

The ABS Building Activity Survey (Cat. 8752.0) is published quarterly and covers all building work across Australia. The SDMX-format CSV contains 184,971 records with coded columns:

| Column | Description | Values |
|---|---|---|
| `MEASURE` | What is being measured | M1 (Value Commenced), M2 (Value Completed), M3 (Value Work Commenced), M4 (Value Work Done), M5 (Value Work Completed), M6 (Dwellings Yet To Do), M7 (Value Under Construction), M8 (Dwellings Under Construction) |
| `REGION` | State/territory or national | 1 (NSW), 2 (VIC), 3 (QLD), 4 (SA), 5 (WA), 6 (TAS), 7 (NT), 8 (ACT), AUS |
| `PRICE_ADJ` | Price basis | CUR (Current Prices), CVM (Chain Volume Measures) |
| `BLD_WORK_TYPE` | Type of building work | 1 (New), 8 (Alterations & Additions), TOT (Total) |
| `SECTOR_OWN` | Sector | 1 (Private), 5 (Public), 9 (Total) |
| `TYPE_BLDG` | Building type | 110 (Houses), 150 (Other Residential), 100 (Total Residential), 700 (Non-Residential), 800 (Total Building), TOT (Total) |
| `TSEST` | Time series estimate | 10 (Original), 20 (Seasonally Adjusted), 30 (Trend) |
| `TIME_PERIOD` | Quarter | 2010-Q1 through 2025-Q3 |
| `OBS_VALUE` | Observation value | Dollars ($'000 when UNIT_MULT=3) or count (when UNIT_MULT=0) |

## SQL Techniques Used

- **Common Table Expressions (CTEs)** with multiple levels for staged aggregation
- **Window functions**: `LAG()` for period-over-period comparison, `SUM() OVER()` for running totals, `AVG() OVER(ROWS BETWEEN)` for rolling averages, `RANK() OVER()` for state rankings
- **`PIVOT`** for transforming years into columns for side-by-side state comparison
- **`CROSS JOIN`** for calculating shares against national totals
- **Ratio calculations** for starts-to-completions analysis
- **Rolling 4-quarter averages** for trend smoothing
- **`CASE` expressions** for conditional aggregation across states
- **`NULLIF`** for safe division avoiding divide-by-zero errors

## Files

| File | Description |
|---|---|
| `queries/au_building_activity_analysis.sql` | Full T-SQL analysis — 8 query blocks with detailed comments |
| `report.html` | Interactive HTML report — self-contained, all findings and methodology |
| `data/building_activity.csv` | ABS SDMX source data (184,971 records, Q1 2010 - Q3 2025) |
| `building-activity/` | Raw ABS time series workbooks and data cubes (80 Excel files) |
| `engineering-construction/` | Related ABS engineering construction data |
| `DATA_INDEX.txt` | Guide to all downloaded ABS tables and recommended tables for analysis |
| `README.md` | This file — project overview, methodology, and findings |

## How to Run

1. Install [SQL Server Express](https://www.microsoft.com/en-us/sql-server/sql-server-downloads) (free)
2. Import `data/building_activity.csv` into a table called `BuildingActivity`
3. Map the coded columns using the dataset overview above, or work with the codes directly
4. Open `queries/au_building_activity_analysis.sql` in SSMS
5. Run each query block in sequence — comments explain what each one does and why

## A Note on AI Tools

I used AI coding assistants when I hit syntax issues or needed a second opinion on query structure. The analysis approach, business questions, data interpretation, and all findings are my own work. The thinking progression — from national overview through state comparison to pipeline analysis — reflects how I actually evaluate construction markets from a materials supply perspective.

---

**Tommy Nguyen** | [GitHub](https://github.com/Tommy-Nguyen-Stonera) | [Portfolio](https://tommy-nguyen-stonera.vercel.app)
