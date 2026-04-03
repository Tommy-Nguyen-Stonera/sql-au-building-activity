# Australian Building Activity Analysis (T-SQL)

[View Interactive Report](https://htmlpreview.github.io/?https://raw.githubusercontent.com/Tommy-Nguyen-Stonera/sql-au-building-activity/main/report.html)

15 years of quarterly ABS building activity data (2010-2025) tracking what gets started, built, and stuck in the pipeline across every state. 184,971 records covering the post-GFC recovery, apartment boom, COVID disruption, and the current housing supply crisis.

## Key Findings

- National building work grew 87% in current prices, but real growth (adjusted for inflation) was near zero since 2018
- Victoria overtook NSW as the largest construction market by value ($52.7B vs $50.0B in 2024)
- Starts-to-completions ratio spiked to 1.34 in 2021, revealing a post-COVID pipeline jam
- 244,100 dwellings under construction at the Q3 2022 peak
- Apartments outnumber houses in the pipeline 1.6 to 1, despite houses leading by value
- Private sector accounts for 87% of building work commenced
- Non-residential share grew from 36% to 40% of total work

## Tools

SQL Server, T-SQL, ABS Building Activity Survey (Cat. 8752.0)

## Files

- `queries/au_building_activity_analysis.sql` - 8 query blocks
- `report.html` - Interactive report
- `data/building_activity.csv` - 184,971 records
