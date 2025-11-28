# WA Cascades Snowfall and ENSO Analysis - Summary of Results

## Analysis Overview

This analysis examined the relationship between ENSO (El Niño-Southern Oscillation) climate patterns and snowfall in the Washington Cascades from 1981-2025. Data from four SNOTEL sites were analyzed across five ENSO phases.

## Key Findings

### Percentage Difference from Neutral Years

The analysis reveals distinct patterns in how different ENSO phases affect snowfall across the four sites:

#### Paradise (Mount Rainier Region)
- **Strong La Niña**: +12.7% more snowfall than neutral years
- **Weak La Niña**: -5.8% less snowfall than neutral years
- **Weak El Niño**: -18.2% less snowfall than neutral years
- **Strong El Niño**: -17.4% less snowfall than neutral years

#### Stampede Pass (Snoqualmie Pass Region)
- **Strong La Niña**: +13.1% more snowfall than neutral years
- **Weak La Niña**: -11.8% less snowfall than neutral years
- **Weak El Niño**: -24.8% less snowfall than neutral years
- **Strong El Niño**: -21.3% less snowfall than neutral years

#### Stevens Pass
- **Strong La Niña**: +19.5% more snowfall than neutral years
- **Weak La Niña**: +2.7% more snowfall than neutral years
- **Weak El Niño**: -11.6% less snowfall than neutral years
- **Strong El Niño**: -18.0% less snowfall than neutral years

#### Wells Creek (Mount Baker Region)
- **Strong La Niña**: +38.4% more snowfall than neutral years
- **Weak La Niña**: +46.8% more snowfall than neutral years
- **Weak El Niño**: -31.1% less snowfall than neutral years
- **Strong El Niño**: -15.4% less snowfall than neutral years

## Major Insights

1. **Strong La Niña consistently brings more snow**: All sites show increased snowfall during Strong La Niña years, with the Mount Baker region (Wells Creek) showing the most dramatic increase (+38-47%).

2. **El Niño years generally bring less snow**: Both Weak and Strong El Niño phases result in below-normal snowfall across all sites, with reductions ranging from 11% to 31%.

3. **Regional variation is significant**: The Mount Baker region (Wells Creek) shows the strongest response to ENSO patterns, with both La Niña phases bringing substantially more snow than neutral years.

4. **Weak La Niña shows mixed results**: While Wells Creek and Stevens Pass see increased snowfall during Weak La Niña, Paradise and Stampede Pass actually see decreased snowfall compared to neutral years.

5. **Stampede Pass most affected by El Niño**: The Snoqualmie Pass region shows the largest snowfall deficit during Weak El Niño years (-24.8%).

## Monthly Patterns

The monthly analysis (see `plots/monthly_swe_by_enso_phase.png`) shows:
- Peak snowfall typically occurs in December-January across all ENSO phases
- Strong La Niña years show consistently higher monthly snowfall throughout the season
- El Niño years show reduced snowfall in all months, particularly mid-winter

## Data Quality

- **Time Period**: 1981-2025 (44 complete snow seasons)
- **Sites**: 4 SNOTEL stations across WA Cascades
- **Data Source**: USDA NRCS SNOTEL Network and NOAA Climate Prediction Center
- **Metric**: Snow Water Equivalent (SWE) in inches

## Implications

These findings have important implications for:
- **Water resource management**: La Niña years may provide more snowpack for summer water supply
- **Winter recreation**: El Niño years may present challenges for ski areas
- **Climate adaptation**: Understanding ENSO patterns can help predict seasonal snowfall
- **Regional planning**: Different regions of the Cascades respond differently to ENSO

## Files Generated

### Data Files (in `data/` folder)
- `oni_data.csv`: Raw ONI data from NOAA
- `snotel_raw_*.csv`: Raw SNOTEL data for each site
- `snotel_processed.csv`: Processed snowfall data with ENSO classifications
- `monthly_summary.csv`: Monthly average new SWE by ENSO phase and site
- `percentage_difference.csv`: Percentage difference from neutral years

### Plot Files (in `plots/` folder)
- `monthly_swe_by_enso_phase.png`: Line plot of monthly patterns
- `percentage_difference_from_neutral.png`: Bar plot of differences

## Running the Analysis

To reproduce this analysis:

```bash
/usr/local/bin/Rscript analysis.R
```

The script will:
1. Download current ONI data from NOAA
2. Download SNOTEL data for all four sites
3. Process and merge the datasets
4. Generate summary statistics
5. Create visualizations
6. Save all outputs to `data/` and `plots/` folders

## References

- NOAA Climate Prediction Center: https://www.cpc.ncep.noaa.gov/
- USDA NRCS SNOTEL Network: https://www.nrcs.usda.gov/wps/portal/wcc/home/
- Oceanic Niño Index (ONI): Standard metric for identifying El Niño and La Niña events
