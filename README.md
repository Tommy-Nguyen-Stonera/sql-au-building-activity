# Australian Building Activity Analysis (T-SQL)

[View Interactive Report](https://htmlpreview.github.io/?https://raw.githubusercontent.com/Tommy-Nguyen-Stonera/sql-au-building-activity/main/report.html)

## Overview

This project analyses 15 years of ABS quarterly building activity data to track what is getting started, what is being completed, and what is piling up in the pipeline. It covers the post-GFC recovery, the apartment boom, COVID disruption, and the current housing supply crunch across all Australian states.

## Dataset

- Source: ABS Building Activity Survey (Cat. 8752.0), decoded from SDMX
- Record count: 184,971 records
- Time period: Q1 2010 to Q3 2025
- Key columns: Quarter, State, BuildingType, Sector, WorkCommenced, WorkCompleted, WorkUnderConstruction, ValueOfWork_M
- Single flat table, no joins required

## Research Questions

1. How has total building activity grown in nominal vs real terms since 2010?
2. Which states dominate construction activity by value and volume?
3. Are projects piling up in the pipeline, or are they completing on a normal schedule?
4. How has the mix between houses, apartments, and non-residential work shifted over 15 years?
5. Where is the highest-value construction concentrated by state and building type?
6. Which states are currently accelerating vs decelerating in activity?
7. How large is the current national pipeline, and how does it break down by state?

## Data Model

Single flat table: BuildingActivity. Each row represents one quarter/state/building type/sector combination with work commenced, completed, and under construction values in millions of dollars. No joins required.

## What Was Analysed

- Nominal vs real growth in total building work value (2010 to 2025)
- State-level ranking by value of work commenced and completed
- Starts-to-completions ratio tracked over time to measure pipeline jam or clearance
- Building type mix shift: houses vs apartments vs non-residential by year
- Concentration of high-value construction by state and building type cross-tab
- Year-over-year growth rate by state to identify accelerating vs decelerating markets
- Current pipeline (work under construction) by state and nationally

## Key Insights

1. National building work grew 87% in current prices, but real growth (adjusted for inflation) has been near zero since 2018, meaning nominal growth is masking a flat to declining real volume.
2. Victoria overtook NSW as the largest construction market by value ($52.7B vs $50.0B in 2024).
3. The starts-to-completions ratio spiked to 1.34 in 2021, revealing a post-COVID pipeline jam where projects were starting faster than they could be finished.
4. The pipeline peaked at 244,100 dwellings under construction in Q3 2022 and has been slowly unwinding since.
5. Apartments now outnumber houses in the pipeline 1.6 to 1, even though houses still lead by total dollar value.
6. The private sector accounts for 87% of building work commenced, which means private sector confidence is the dominant driver of the pipeline.

## Recommendations

1. Prioritise Victoria and Queensland for sales and supply chain investment. Both markets show stronger recent volume trends than NSW, which has been decelerating.
2. Use the starts-to-completions ratio as a demand signal. When it rises above 1.2, pipeline pressure is building and material shortages follow. That is the time to lock in supply agreements early.
3. Factor the apartment-heavy pipeline into product mix planning. High-rise and medium-density projects have different material needs than detached housing, and the market has been skewing that way since 2015.
4. Do not conflate nominal growth with real demand. Inflation has been driving reported value growth since 2018. Volume-based metrics like dwelling counts and square metres are more reliable for actual demand forecasting.

## Tools

SQL Server, T-SQL, ABS Building Activity Survey (Cat. 8752.0)

## Files

- `queries/au_building_activity_analysis.sql` - 8 query blocks
- `report.html` - Interactive report
- `data/building_activity.csv` - 184,971 records
