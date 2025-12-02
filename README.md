# WA Cascades Snowfall and ENSO Analysis

## Overview

This project analyzes the relationship between El Niño-Southern Oscillation (ENSO) climate patterns and snowfall in the Washington Cascades. The analysis focuses on four SNOTEL sites and examines how different ENSO phases (Strong/Moderate/Weak La Niña, Neutral, Strong/Moderate/Weak El Niño) correlate with monthly snowfall patterns.

## Research Question

**How do El Niño & La Niña climate patterns relate to snowfall in WA Cascades?**

## Data Sources

1. **ENSO Data**: Oceanic Niño Index (ONI) from NOAA Climate Prediction Center
   - Source: https://www.cpc.ncep.noaa.gov/data/indices/oni.ascii.txt
   
2. **Snowfall Data**: SNOTEL Snow Water Equivalent (SWE) measurements
   - Source: USDA NRCS SNOTEL network via web scraping
   - Four WA Cascade sites:
     - Near Mount Baker
     - Stevens Pass
     - Snoqualmie Pass
     - Mount Rainier

## Methodology

### Snow Season Definition
- **Season Period**: November through April of the following year
- **Exclusion**: Current incomplete season (if applicable)

### ENSO Phase Classification
Based on DJF (December-January-February) ONI values:
- **Strong La Niña**: ONI ≤ -1.5
- **Moderate La Niña**: -1.5 < ONI ≤ -1.0
- **Weak La Niña**: -1.0 < ONI ≤ -0.5
- **Neutral**: -0.5 < ONI < 0.5
- **Weak El Niño**: 0.5 ≤ ONI < 1.0
- **Moderate El Niño**: 1.0 ≤ ONI < 1.5
- **Strong El Niño**: ONI ≥ 1.5

### Snowfall Metric
- **Measure**: Snow Water Equivalent (SWE)
- **Calculation**: Daily new snow (delta from previous day), summed by month
- **Monthly Average**: Average of monthly new snowfall across years for each ENSO phase

### Analysis Steps

1. **Data Acquisition**
   - Web scrape ONI data from NOAA
   - Download SNOTEL SWE data for four sites
   - Save raw data to `data/` folder as CSV files

2. **Data Processing**
   - Calculate daily new SWE (delta from previous day)
   - Sum daily new SWE by month for each site
   - Classify each snow season by ENSO phase
   - Merge ENSO and snowfall datasets

3. **Statistical Analysis**
   - Calculate monthly average new SWE by ENSO phase and site
   - Compute percentage difference from neutral years

4. **Visualization**
   - **Plot 1**: Line plot of monthly average new SWE by ENSO phase and site
     - X-axis: Months (Nov, Dec, Jan, Feb, Mar, Apr)
     - Y-axis: Average new SWE
     - Lines: One per ENSO phase (5 lines)
     - Facets: One panel per site (4 panels)
     - Colors: Consistent ENSO phase colors
   
   - **Plot 2**: Bar plot of percentage snowfall difference from neutral
     - X-axis: Sites
     - Y-axis: Percentage difference from neutral
     - Bars: Grouped by ENSO intensity (Strong/Moderate/Weak La Niña, Strong/Moderate/Weak El Niño)
     - Colors: Consistent ENSO phase colors

5. **Output**
   - Save processed data as CSV files in `data/` folder
   - Save plots as PNG files in `plots/` folder

## Code Structure

The R script (`analysis.R`) is organized into the following sections:

1. **Setup**: Load required packages using `pacman::p_load()`
2. **Data Acquisition**: Web scraping and downloading functions
3. **Data Processing**: Calculate new SWE and classify ENSO phases
4. **Data Merging**: Combine ENSO and snowfall data
5. **Analysis**: Calculate statistics and prepare data for plotting
6. **Visualization**: Generate and save plots
7. **Execution**: Run the complete analysis pipeline

## Running the Analysis

### Prerequisites
- R (version 4.0 or higher recommended)
- Internet connection for data download
- Required R packages (automatically installed via pacman)

### Execution
```bash
/path/to/Rscript analysis.R
```

### Output Files

**Data Files** (saved to [data/](data/) folder):
- [oni_data.csv](data/oni_data.csv): Raw ONI data from NOAA
- [snotel_raw_[site].csv](data/snotel_raw_[site].csv): Raw SNOTEL data for each site
- [snotel_processed.csv](data/snotel_processed.csv): Processed snowfall data with ENSO classifications
- [monthly_summary.csv](data/monthly_summary.csv): Monthly average new SWE by ENSO phase and site
- [percentage_difference.csv](data/percentage_difference.csv): Percentage difference from neutral years

**Plot Files** (saved to [plots/](plots/) folder):
- [monthly_swe_by_enso_phase.png](plots/monthly_swe_by_enso_phase.png): Line plot of monthly patterns
- [percentage_difference_from_neutral.png](plots/percentage_difference_from_neutral.png): Bar plot of differences

**Results Summary** (saved to top-level folder):
- [RESULTS_SUMMARY.md](RESULTS_SUMMARY.md): Summary of results

## Code Style

- **Line Length**: Maximum 80 characters
- **Package Loading**: `pacman::p_load()` for all dependencies
- **Indentation**: 2 spaces
- **Naming**: snake_case for variables and functions
- **Comments**: Descriptive comments for major sections

## Plot Specifications

### Common Elements
- **Title**: Includes data year range
- **Caption**: Includes data source
- **Colors**: Consistent ENSO phase colors across all plots
- **Theme**: Clean, professional appearance

### Color Palette
```r
enso_colors <- c(
  "Strong La Niña" = "#2166AC",      # dark blue
  "Moderate La Niña" = "#4393C3",    # medium blue
  "Weak La Niña" = "#92C5DE",        # light blue
  "Neutral" = "#B2ABD2",             # purple-gray
  "Weak El Niño" = "#F4A582",        # light coral
  "Moderate El Niño" = "#D6604D",    # medium red
  "Strong El Niño" = "#B2182B"       # dark red
)
```

## Expected Results

The analysis will reveal:
1. Monthly snowfall patterns across different ENSO phases
2. Site-specific responses to ENSO variability
3. Quantitative differences in snowfall between strong and weak ENSO events
4. Overall impact of El Niño and La Niña on WA Cascade snowfall

## References

- NOAA Climate Prediction Center: https://www.cpc.ncep.noaa.gov/
- USDA NRCS SNOTEL Network: https://www.nrcs.usda.gov/wps/portal/wcc/home/
- Oceanic Niño Index (ONI): Standard metric for identifying El Niño and La Niña events

## Notes

- The analysis excludes the current snow season if incomplete
- SNOTEL sites are selected to represent different regions of the WA Cascades
- Monthly calculations use new snowfall (daily deltas) rather than cumulative values
- Statistical comparisons use percentage differences to account for site-to-site variability

---

This project was completed using the Antigravity prompt settings: ^Fast ^Claude Sonnet 4.5. See [prompt.md](prompt.md) for details.