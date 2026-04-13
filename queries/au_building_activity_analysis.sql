-- ============================================================================
-- AUSTRALIAN BUILDING ACTIVITY ANALYSIS
-- ============================================================================
-- Dataset:   Australian Bureau of Statistics (ABS), Building Activity Survey
--            Catalogue No. 8752.0
-- Period:    Q1 2010 through Q3 2025 (63 quarters)
-- Source:    ABS SDMX data feed, 184,971 records
-- Author:    Tommy Nguyen
--
-- CONTEXT:
-- The ABS Building Activity Survey measures what is physically happening on
-- construction sites across Australia each quarter. Unlike building approvals
-- (which measure intent), this dataset captures actual commencements, work in
-- progress, and completions, in dollar value and dwelling unit counts.
--
-- DATA STRUCTURE:
-- The source CSV uses ABS SDMX coded columns:
--   MEASURE:       M1 (Value Commenced), M2 (Value Completed),
--                  M3 (Value Work Commenced), M4 (Value Work Done),
--                  M5 (Value Work Completed), M6 (Dwellings Yet To Do),
--                  M7 (Value Under Construction), M8 (Dwellings Under Construction)
--   REGION:        1 (NSW), 2 (VIC), 3 (QLD), 4 (SA), 5 (WA),
--                  6 (TAS), 7 (NT), 8 (ACT), AUS (Australia)
--   PRICE_ADJ:     CUR (Current Prices), CVM (Chain Volume Measures)
--   BLD_WORK_TYPE: 1 (New), 8 (Alterations & Additions), TOT (Total)
--   SECTOR_OWN:    1 (Private), 5 (Public), 9 (Total)
--   TYPE_BLDG:     110 (Houses), 150 (Other Residential/Apartments),
--                  100 (Total Residential), 700 (Non-Residential),
--                  800 (Total Building), TOT (Total)
--   TSEST:         10 (Original), 20 (Seasonally Adjusted), 30 (Trend)
--   OBS_VALUE:     Dollar value ($'000 when UNIT_MULT=3) or count (UNIT_MULT=0)
--
-- ANALYSIS APPROACH:
-- The queries progress from macro to micro: national totals → state rankings →
-- bottleneck identification → dwelling type mix → value concentration →
-- momentum tracking → pipeline measurement → year-over-year comparison.
-- Each query builds context for the one that follows.
-- ============================================================================


-- ============================================================================
-- SETUP: Create and populate the analysis table
-- ============================================================================
-- The raw SDMX data needs to be imported first. This setup assumes you have
-- loaded building_activity.csv into a staging table and decoded the dimension
-- columns into human-readable values for the main analysis table.
--
-- Expected schema for BuildingActivity:
--   Quarter            DATE        -- First day of each quarter (e.g., 2024-01-01)
--   State              VARCHAR(50) -- Full state name (e.g., 'New South Wales')
--   BuildingType       VARCHAR(50) -- 'Houses', 'Apartments', 'Non-Residential', etc.
--   Sector             VARCHAR(20) -- 'Private', 'Public', 'Total'
--   WorkCommenced      DECIMAL     -- Value of work commenced ($M)
--   WorkUnderConstruction DECIMAL  -- Value of work under construction ($M)
--   WorkCompleted      DECIMAL     -- Value of work completed ($M)
--   ValueOfWork_M      DECIMAL     -- Value of work done in period ($M)
-- ============================================================================


-- ============================================================================
-- QUERY 1: Annual Building Activity Overview
-- ============================================================================
-- PURPOSE:
-- Establish the national trajectory of building activity over the full period.
-- This is the "big picture" query - how much work is being started and finished
-- each year, and is the gap between them growing or shrinking?
--
-- TECHNIQUE:
-- Two-level CTE: first aggregates quarterly data into annual totals, then uses
-- LAG() window function to calculate year-over-year growth rates. The NetPipeline
-- column (Commenced minus Completed) shows whether the industry is building
-- backlog or clearing it.
--
-- KEY FINDING:
-- National building work commenced grew from $89.4B in 2010 to $167.4B in 2024
-- (87% growth in current prices). However, chain volume measures show real growth
-- from 2018-2024 was effectively zero, as cost inflation consumed all nominal gains.
-- ============================================================================

WITH AnnualActivity AS (
    SELECT
        YEAR(Quarter) AS ActivityYear,
        SUM(WorkCommenced) AS TotalCommenced,
        SUM(WorkCompleted) AS TotalCompleted,
        ROUND(SUM(ValueOfWork_M), 1) AS TotalValue_M
    FROM BuildingActivity
    GROUP BY YEAR(Quarter)
),
WithGrowth AS (
    SELECT
        ActivityYear,
        TotalCommenced,
        TotalCompleted,
        TotalValue_M,
        LAG(TotalCommenced) OVER (ORDER BY ActivityYear) AS PrevCommenced,
        LAG(TotalCompleted) OVER (ORDER BY ActivityYear) AS PrevCompleted,
        TotalCommenced - TotalCompleted AS NetPipeline
    FROM AnnualActivity
)
SELECT
    ActivityYear,
    TotalCommenced,
    TotalCompleted,
    NetPipeline,
    TotalValue_M,
    ROUND(
        (TotalCommenced - PrevCommenced) * 100.0
        / NULLIF(PrevCommenced, 0), 1
    ) AS Commenced_Growth_Pct,
    ROUND(
        (TotalCompleted - PrevCompleted) * 100.0
        / NULLIF(PrevCompleted, 0), 1
    ) AS Completed_Growth_Pct
FROM WithGrowth
ORDER BY ActivityYear;


-- ============================================================================
-- QUERY 2: State Comparison - Building Activity Rankings (2020-2025)
-- ============================================================================
-- PURPOSE:
-- Identify which states dominate national building activity and quantify their
-- share. This answers a fundamental question for any building materials supplier:
-- where should you concentrate resources?
--
-- TECHNIQUE:
-- Two CTEs: StateActivity aggregates each state's totals for the recent period,
-- NationalTotal provides the denominator for share calculations. CROSS JOIN
-- brings the national total into each state row. RANK() window function
-- provides ordinal rankings by both volume and value.
--
-- KEY FINDING:
-- Victoria ($52.7B) narrowly leads NSW ($50.0B) in 2024 work commenced, with
-- Queensland ($32.2B) third. The top three states account for >80% of national
-- activity. The concentration is even more extreme than it appears because
-- TAS, ACT, and NT combined represent less than 5% of national volume.
-- ============================================================================

WITH StateActivity AS (
    SELECT
        State,
        SUM(WorkCommenced) AS TotalCommenced,
        SUM(WorkCompleted) AS TotalCompleted,
        ROUND(SUM(ValueOfWork_M), 1) AS TotalValue_M,
        SUM(WorkCommenced) - SUM(WorkCompleted) AS PipelineBacklog
    FROM BuildingActivity
    WHERE YEAR(Quarter) >= 2020
    GROUP BY State
),
NationalTotal AS (
    SELECT
        SUM(TotalCommenced) AS NatCommenced,
        SUM(TotalValue_M) AS NatValue
    FROM StateActivity
)
SELECT
    s.State,
    s.TotalCommenced,
    RANK() OVER (ORDER BY s.TotalCommenced DESC) AS CommencedRank,
    ROUND(
        s.TotalCommenced * 100.0 / n.NatCommenced, 1
    ) AS CommencedShare_Pct,
    s.TotalCompleted,
    s.PipelineBacklog,
    s.TotalValue_M,
    RANK() OVER (ORDER BY s.TotalValue_M DESC) AS ValueRank,
    ROUND(
        s.TotalValue_M * 100.0 / n.NatValue, 1
    ) AS ValueShare_Pct
FROM StateActivity s
CROSS JOIN NationalTotal n
ORDER BY s.TotalCommenced DESC;


-- ============================================================================
-- QUERY 3: Starts vs Completions Ratio by State
-- ============================================================================
-- PURPOSE:
-- Diagnose whether projects are piling up (backlog building) or getting finished
-- on schedule. A ratio above 1.0 means more work is starting than finishing;
-- the pipeline is growing. Below 1.0 means the pipeline is clearing.
--
-- TECHNIQUE:
-- Simple aggregation with CAST to FLOAT for precise ratio calculation. NULLIF
-- prevents divide-by-zero errors for states with zero completions in a period.
-- HAVING clause filters to the four largest states for readability.
--
-- KEY FINDING:
-- The starts-to-completions ratio nationally spiked to 1.34 in 2021, indicating
-- a severe pipeline jam post-COVID. Projects were starting at a normal pace but
-- finishing much more slowly due to trade shortages and material delays. By 2024,
-- the ratio had normalised back to 1.09, still slightly elevated, meaning the
-- backlog accumulated in 2021-22 has not fully cleared.
-- ============================================================================

SELECT
    YEAR(Quarter) AS ActivityYear,
    State,
    SUM(WorkCommenced) AS Commenced,
    SUM(WorkCompleted) AS Completed,
    ROUND(
        CAST(SUM(WorkCommenced) AS FLOAT)
        / NULLIF(SUM(WorkCompleted), 0), 2
    ) AS StartsToCompletionRatio
    -- Interpretation guide:
    --   Ratio > 1.0 = more starting than finishing (backlog building)
    --   Ratio < 1.0 = more completing than starting (backlog clearing)
    --   Ratio = 1.0 = balanced flow
FROM BuildingActivity
GROUP BY YEAR(Quarter), State
HAVING State IN ('New South Wales', 'Victoria', 'Queensland', 'Western Australia')
ORDER BY State, ActivityYear;


-- ============================================================================
-- QUERY 4: Dwelling Type Trends - Houses vs Apartments vs Non-Residential
-- ============================================================================
-- PURPOSE:
-- Track how the mix of building types has shifted over time. The product mix
-- matters enormously for building materials: houses use different materials in
-- different quantities than apartment towers, and non-residential projects have
-- entirely different specification requirements.
--
-- TECHNIQUE:
-- Two CTEs: TypeTrend calculates annual commencements and value by building type,
-- YearTotal provides the annual denominator for share calculations. The JOIN
-- brings them together to show both absolute values and percentage shares.
--
-- KEY FINDING:
-- Houses dominate commencements by value (61% in 2024, $53.0B vs $33.6B for
-- apartments). But the pipeline tells the opposite story: 141,852 apartments
-- under construction vs 87,323 houses as of Q3 2025. Apartments take longer
-- to build, so they accumulate in the pipeline and represent a disproportionate
-- share of ongoing material demand.
-- ============================================================================

WITH TypeTrend AS (
    SELECT
        YEAR(Quarter) AS ActivityYear,
        BuildingType,
        SUM(WorkCommenced) AS Commenced,
        ROUND(SUM(ValueOfWork_M), 1) AS Value_M
    FROM BuildingActivity
    GROUP BY YEAR(Quarter), BuildingType
),
YearTotal AS (
    SELECT
        ActivityYear,
        SUM(Commenced) AS TotalCommenced
    FROM TypeTrend
    GROUP BY ActivityYear
)
SELECT
    t.ActivityYear,
    t.BuildingType,
    t.Commenced,
    ROUND(
        t.Commenced * 100.0 / y.TotalCommenced, 1
    ) AS Share_Pct,
    t.Value_M
FROM TypeTrend t
JOIN YearTotal y ON t.ActivityYear = y.ActivityYear
ORDER BY t.ActivityYear, t.Commenced DESC;


-- ============================================================================
-- QUERY 5: Value of Work - Highest Value States and Building Types
-- ============================================================================
-- PURPOSE:
-- Identify the highest-value construction segments by combining state and
-- building type. This pinpoints exactly where the construction dollars are
-- most concentrated, which matters for a materials supplier deciding where to
-- focus sales effort and inventory.
--
-- TECHNIQUE:
-- Grouped aggregation on two dimensions (State x BuildingType) with both
-- SUM and AVG to show total value and typical quarterly run-rate. RANK()
-- window function orders the combinations by total value.
--
-- KEY FINDING:
-- The highest-value combinations are predictable but the magnitude is not.
-- NSW and VIC residential dominate, but the gap between the top 5 and the
-- rest is enormous. Knowing the average quarterly value helps with pipeline
-- planning, it tells you the expected run-rate, not just the cumulative total.
-- ============================================================================

SELECT
    State,
    BuildingType,
    ROUND(SUM(ValueOfWork_M), 1) AS TotalValue_M,
    ROUND(AVG(ValueOfWork_M), 1) AS AvgQuarterlyValue_M,
    RANK() OVER (ORDER BY SUM(ValueOfWork_M) DESC) AS ValueRank
FROM BuildingActivity
WHERE YEAR(Quarter) >= 2020
GROUP BY State, BuildingType
ORDER BY TotalValue_M DESC;


-- ============================================================================
-- QUERY 6: Quarter-over-Quarter Momentum by State
-- ============================================================================
-- PURPOSE:
-- Detect turning points in state-level building activity. Momentum analysis
-- shows whether activity is accelerating or decelerating, a more actionable
-- signal than absolute levels for timing inventory and staffing decisions.
--
-- TECHNIQUE:
-- CTE aggregates quarterly data by state. The main query uses LAG() to
-- calculate quarter-over-quarter percentage change, and AVG() OVER with
-- ROWS BETWEEN 3 PRECEDING AND CURRENT ROW to compute a rolling 4-quarter
-- average that smooths out seasonal volatility.
--
-- KEY FINDING:
-- Seasonally adjusted national commencements grew steadily from $30.1B/quarter
-- in Q2 2020 to $46.0B in Q3 2025, but the growth rate decelerated from
-- ~3% per quarter in 2022-2023 to ~1.3% in early 2025. The rolling average
-- helps distinguish genuine turning points from normal quarterly noise.
-- ============================================================================

WITH QuarterlyState AS (
    SELECT
        Quarter,
        State,
        SUM(WorkCommenced) AS QtrCommenced,
        ROUND(SUM(ValueOfWork_M), 1) AS QtrValue_M
    FROM BuildingActivity
    GROUP BY Quarter, State
)
SELECT
    Quarter,
    State,
    QtrCommenced,
    LAG(QtrCommenced) OVER (
        PARTITION BY State ORDER BY Quarter
    ) AS PrevQtr,
    ROUND(
        (QtrCommenced - LAG(QtrCommenced) OVER (
            PARTITION BY State ORDER BY Quarter
        )) * 100.0
        / NULLIF(LAG(QtrCommenced) OVER (
            PARTITION BY State ORDER BY Quarter
        ), 0)
    , 1) AS QoQ_Change_Pct,
    ROUND(
        AVG(CAST(QtrCommenced AS FLOAT)) OVER (
            PARTITION BY State ORDER BY Quarter
            ROWS BETWEEN 3 PRECEDING AND CURRENT ROW
        ), 0
    ) AS Rolling4Qtr_Avg
FROM QuarterlyState
WHERE State IN ('New South Wales', 'Victoria', 'Queensland', 'Western Australia')
ORDER BY State, Quarter;


-- ============================================================================
-- QUERY 7: Pipeline Under Construction - National and State Breakdown
-- ============================================================================
-- PURPOSE:
-- Measure how much work is physically under construction at any point in time.
-- The pipeline is the most direct metric for materials demand
-- because it represents work that is actively consuming materials right now,
-- not work that might start in the future or work that has already finished.
--
-- TECHNIQUE:
-- Conditional aggregation using SUM(CASE WHEN ...) to break out state-level
-- pipelines within a single query. This creates a wide-format result showing
-- national and key state pipelines side by side for each quarter.
--
-- KEY FINDING:
-- The national pipeline peaked at 244,100 dwellings in Q3 2022, contracted to
-- 212,475 by Q4 2024 (-13%), then rebounded to 229,750 by Q3 2025. NSW holds
-- the largest state pipeline at 75,612 dwellings (33% of national). The
-- pipeline's recent rebound suggests a new cycle of commencements is filling
-- the construction funnel.
-- ============================================================================

SELECT
    Quarter,
    SUM(WorkUnderConstruction) AS NationalPipeline,
    SUM(CASE WHEN State = 'New South Wales'
        THEN WorkUnderConstruction ELSE 0
    END) AS NSW_Pipeline,
    SUM(CASE WHEN State = 'Victoria'
        THEN WorkUnderConstruction ELSE 0
    END) AS VIC_Pipeline,
    SUM(CASE WHEN State = 'Queensland'
        THEN WorkUnderConstruction ELSE 0
    END) AS QLD_Pipeline,
    SUM(CASE WHEN State = 'Western Australia'
        THEN WorkUnderConstruction ELSE 0
    END) AS WA_Pipeline
FROM BuildingActivity
GROUP BY Quarter
ORDER BY Quarter;


-- ============================================================================
-- QUERY 8: Yearly PIVOT - State Activity Side by Side (2020-2024)
-- ============================================================================
-- PURPOSE:
-- Create a compact year-over-year comparison of each state's building
-- commencements. The PIVOT format makes it easy to scan across years and
-- immediately see which states are growing, which are flat, and which are
-- declining. This is the "dashboard view" of state-level trajectory.
--
-- TECHNIQUE:
-- Subquery aggregates annual commencements by state and year. The PIVOT
-- operator transforms year values from rows into columns, creating one row
-- per state with five year columns. ISNULL handles any missing combinations.
-- ORDER BY sorts states by their most recent year (2024) to show the current
-- leaders first.
--
-- KEY FINDING:
-- Victoria and NSW have traded the top position over the 2020-2024 period.
-- Queensland has grown steadily. WA has been volatile. The PIVOT view makes
-- these trajectory differences immediately visible in a way that a long
-- time-series table does not.
-- ============================================================================

SELECT
    State,
    ISNULL([2020], 0) AS [2020],
    ISNULL([2021], 0) AS [2021],
    ISNULL([2022], 0) AS [2022],
    ISNULL([2023], 0) AS [2023],
    ISNULL([2024], 0) AS [2024]
FROM (
    SELECT
        State,
        YEAR(Quarter) AS ActivityYear,
        SUM(WorkCommenced) AS Commenced
    FROM BuildingActivity
    WHERE YEAR(Quarter) BETWEEN 2020 AND 2024
    GROUP BY State, YEAR(Quarter)
) AS SourceData
PIVOT (
    SUM(Commenced)
    FOR ActivityYear IN ([2020], [2021], [2022], [2023], [2024])
) AS PivotTable
ORDER BY ISNULL([2024], 0) DESC;
