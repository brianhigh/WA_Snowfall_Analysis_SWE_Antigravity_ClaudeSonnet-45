# ==============================================================================
# WA Cascades Snowfall and ENSO Analysis
# ==============================================================================
# This script analyzes the relationship between ENSO patterns and snowfall
# in the Washington Cascades using SNOTEL data and ONI indices.
# ==============================================================================

# ------------------------------------------------------------------------------
# 1. SETUP: Load Required Packages
# ------------------------------------------------------------------------------

# Install and load pacman if not already installed
if (!require("pacman", quietly = TRUE)) {
  install.packages("pacman")
}

# Load required packages
pacman::p_load(
  dplyr, # Data manipulation
  tidyr, # Data tidying
  ggplot2, # Plotting
  lubridate, # Date handling
  readr, # Reading/writing CSV files
  httr, # HTTP requests
  rvest, # Web scraping
  stringr, # String manipulation
  purrr, # Functional programming
  scales # Scale functions for plotting
)

# ------------------------------------------------------------------------------
# 2. CONFIGURATION: Set Parameters and Create Directories
# ------------------------------------------------------------------------------

# Create output directories if they don't exist
dir.create("data", showWarnings = FALSE, recursive = TRUE)
dir.create("plots", showWarnings = FALSE, recursive = TRUE)

# Define SNOTEL sites (site codes for WA Cascades)
snotel_sites <- list(
  list(
    name = "Mount Baker",
    code = "909",
    site_name = "Wells Creek"
  ),
  list(
    name = "Stevens Pass",
    code = "791",
    site_name = "Stevens Pass"
  ),
  list(
    name = "Snoqualmie Pass",
    code = "788",
    site_name = "Stampede Pass"
  ),
  list(
    name = "Mount Rainier",
    code = "679",
    site_name = "Paradise"
  )
)

# Define ENSO phase colors
enso_colors <- c(
  "Strong La Niña" = "#2166AC",
  "Moderate La Niña" = "#4393C3",
  "Weak La Niña" = "#92C5DE",
  "Neutral" = "#B2ABD2",
  "Weak El Niño" = "#F4A582",
  "Moderate El Niño" = "#D6604D",
  "Strong El Niño" = "#B2182B"
)

# Define ENSO phase order for plotting
enso_order <- c(
  "Strong La Niña",
  "Moderate La Niña",
  "Weak La Niña",
  "Neutral",
  "Weak El Niño",
  "Moderate El Niño",
  "Strong El Niño"
)

# Define month order for snow season (Nov-Apr)
month_order <- c("Nov", "Dec", "Jan", "Feb", "Mar", "Apr")

# ------------------------------------------------------------------------------
# 3. DATA ACQUISITION: Download ONI Data
# ------------------------------------------------------------------------------

download_oni_data <- function() {
  cat("Downloading ONI data from NOAA...\n")

  # URL for ONI data
  oni_url <- paste0(
    "https://www.cpc.ncep.noaa.gov/data/indices/oni.ascii.txt"
  )

  # Download and parse ONI data
  tryCatch(
    {
      # Read the data
      oni_raw <- read.table(
        oni_url,
        header = TRUE,
        stringsAsFactors = FALSE
      )

      # The columns are: SEAS, YR, TOTAL, ANOM
      # SEAS is the 3-month season (e.g., "DJF", "JFM")
      # YR is the year
      # ANOM is the ONI value

      # Map season codes to middle month number
      season_to_month <- c(
        "DJF" = 1, # Dec-Jan-Feb -> Jan
        "JFM" = 2, # Jan-Feb-Mar -> Feb
        "FMA" = 3, # Feb-Mar-Apr -> Mar
        "MAM" = 4, # Mar-Apr-May -> Apr
        "AMJ" = 5, # Apr-May-Jun -> May
        "MJJ" = 6, # May-Jun-Jul -> Jun
        "JJA" = 7, # Jun-Jul-Aug -> Jul
        "JAS" = 8, # Jul-Aug-Sep -> Aug
        "ASO" = 9, # Aug-Sep-Oct -> Sep
        "SON" = 10, # Sep-Oct-Nov -> Oct
        "OND" = 11, # Oct-Nov-Dec -> Nov
        "NDJ" = 12 # Nov-Dec-Jan -> Dec
      )

      # Process ONI data
      oni_data <- oni_raw %>%
        rename(
          Season = SEAS,
          Year = YR,
          ONI = ANOM
        ) %>%
        mutate(
          Month = season_to_month[Season],
          Year = as.integer(Year),
          ONI = as.numeric(ONI)
        ) %>%
        select(Year, Month, ONI) %>%
        filter(!is.na(Year), !is.na(Month), !is.na(ONI))

      # Save to CSV
      write_csv(oni_data, "data/oni_data.csv")
      cat("ONI data saved to data/oni_data.csv\n")

      return(oni_data)
    },
    error = function(e) {
      cat("Error downloading ONI data:", e$message, "\n")
      return(NULL)
    }
  )
}

# ------------------------------------------------------------------------------
# 4. DATA ACQUISITION: Download SNOTEL Data
# ------------------------------------------------------------------------------

download_snotel_data <- function(site_code, site_name) {
  cat(sprintf("Downloading SNOTEL data for %s...\n", site_name))

  # SNOTEL data URL (using NRCS web service)
  # Format: CSV download for daily SWE data
  base_url <- paste0(
    "https://wcc.sc.egov.usda.gov/reportGenerator/",
    "view_csv/customSingleStationReport/daily/",
    site_code, ":WA:SNTL%7Cid=%22%22%7Cname/",
    "POR_BEGIN,POR_END/WTEQ::value"
  )

  tryCatch(
    {
      # Download data
      response <- GET(base_url)

      if (status_code(response) != 200) {
        cat(sprintf(
          "Failed to download data for %s (code %s)\n",
          site_name, site_code
        ))
        return(NULL)
      }

      # Parse CSV content
      content_text <- content(response, "text", encoding = "UTF-8")

      # Skip header lines (SNOTEL CSVs have metadata at top)
      lines <- strsplit(content_text, "\n")[[1]]

      # Find the line with column headers - try multiple patterns
      header_patterns <- c("^Date,", "^#Date,", "Date,.*Snow Water")
      header_line <- NA

      for (pattern in header_patterns) {
        matches <- which(grepl(pattern, lines, ignore.case = TRUE))
        if (length(matches) > 0) {
          header_line <- matches[1]
          break
        }
      }

      if (is.na(header_line)) {
        cat(sprintf(
          "Could not find header in SNOTEL data for %s\n",
          site_name
        ))
        # Try to save raw content for debugging
        writeLines(
          lines[1:min(20, length(lines))],
          sprintf("data/debug_%s.txt", gsub(" ", "_", tolower(site_name)))
        )
        return(NULL)
      }

      # Remove comment character if present
      lines[header_line] <- gsub("^#", "", lines[header_line])

      # Read data starting from header line
      data_text <- paste(lines[header_line:length(lines)], collapse = "\n")
      snotel_data <- read_csv(
        data_text,
        show_col_types = FALSE,
        skip_empty_rows = TRUE,
        na = c("", "NA", "-99.9", "-99")
      )

      # Get column names and standardize
      col_names <- colnames(snotel_data)

      # Find the SWE column (might have different names)
      swe_col <- NA
      swe_patterns <- c(
        "Snow Water Equivalent",
        "WTEQ",
        "SWE",
        "value"
      )

      for (pattern in swe_patterns) {
        matches <- grep(pattern, col_names, ignore.case = TRUE)
        if (length(matches) > 0) {
          swe_col <- matches[1]
          break
        }
      }

      if (is.na(swe_col)) {
        cat(sprintf(
          "Could not find SWE column in SNOTEL data for %s\n",
          site_name
        ))
        cat("Available columns:", paste(col_names, collapse = ", "), "\n")
        return(NULL)
      }

      # Rename columns to standard names
      colnames(snotel_data)[1] <- "Date"
      colnames(snotel_data)[swe_col] <- "SWE_inches"

      # Process data
      snotel_data <- snotel_data %>%
        select(Date, SWE_inches) %>%
        mutate(
          Date = as.Date(Date),
          SWE_inches = as.numeric(SWE_inches),
          Site = site_name
        ) %>%
        filter(!is.na(Date), !is.na(SWE_inches))

      # Save to CSV
      filename <- sprintf(
        "data/snotel_raw_%s.csv",
        gsub(" ", "_", tolower(site_name))
      )
      write_csv(snotel_data, filename)
      cat(sprintf("SNOTEL data saved to %s\n", filename))

      return(snotel_data)
    },
    error = function(e) {
      cat(sprintf(
        "Error downloading SNOTEL data for %s: %s\n",
        site_name, e$message
      ))
      return(NULL)
    }
  )
}

# ------------------------------------------------------------------------------
# 5. DATA PROCESSING: Calculate Daily New SWE
# ------------------------------------------------------------------------------

calculate_new_swe <- function(snotel_data) {
  cat("Calculating daily new SWE...\n")

  # Calculate daily change in SWE
  snotel_processed <- snotel_data %>%
    arrange(Site, Date) %>%
    group_by(Site) %>%
    mutate(
      # Calculate daily change (new snow)
      New_SWE = SWE_inches - lag(SWE_inches, default = 0),
      # Only count positive changes (new snow, not melt)
      New_SWE = ifelse(New_SWE > 0, New_SWE, 0),
      # Extract date components
      Year = year(Date),
      Month = month(Date),
      Day = day(Date)
    ) %>%
    ungroup()

  return(snotel_processed)
}

# ------------------------------------------------------------------------------
# 6. DATA PROCESSING: Assign Snow Seasons
# ------------------------------------------------------------------------------

assign_snow_season <- function(snotel_data) {
  cat("Assigning snow seasons...\n")

  # Define snow season (Nov-Apr)
  # Season year is the year of the ending April
  snotel_data <- snotel_data %>%
    mutate(
      # Snow season year (year of the ending April)
      Season_Year = ifelse(
        Month >= 11,
        Year + 1,
        Year
      ),
      # Month name
      Month_Name = month.abb[Month]
    ) %>%
    # Filter to only snow season months (Nov-Apr)
    filter(Month %in% c(11, 12, 1, 2, 3, 4))

  # Exclude current incomplete season
  current_date <- Sys.Date()
  current_year <- year(current_date)
  current_month <- month(current_date)

  # If we're before May, exclude current season
  # If we're after April, include up to last completed season
  if (current_month < 5) {
    max_season <- current_year - 1
  } else {
    max_season <- current_year
  }

  snotel_data <- snotel_data %>%
    filter(Season_Year <= max_season)

  return(snotel_data)
}

# ------------------------------------------------------------------------------
# 7. DATA PROCESSING: Classify ENSO Phases
# ------------------------------------------------------------------------------

classify_enso_phase <- function(oni_data) {
  cat("Classifying ENSO phases...\n")

  # Calculate seasonal ONI for snow season (Nov-Apr)
  # Use DJF (Dec-Jan-Feb) as the primary ENSO indicator for the season
  oni_seasonal <- oni_data %>%
    mutate(
      # For DJF, the season year is the year of Jan-Feb
      Season_Year = ifelse(
        Month == 12,
        Year + 1,
        Year
      )
    ) %>%
    # Filter to DJF months
    filter(Month %in% c(12, 1, 2)) %>%
    # Calculate average ONI for each season
    group_by(Season_Year) %>%
    summarize(
      ONI_DJF = mean(ONI, na.rm = TRUE),
      .groups = "drop"
    ) %>%
    # Classify ENSO phase
    mutate(
      ENSO_Phase = case_when(
        ONI_DJF <= -1.5 ~ "Strong La Niña",
        ONI_DJF > -1.5 & ONI_DJF <= -1.0 ~ "Moderate La Niña",
        ONI_DJF > -1.0 & ONI_DJF <= -0.5 ~ "Weak La Niña",
        ONI_DJF > -0.5 & ONI_DJF < 0.5 ~ "Neutral",
        ONI_DJF >= 0.5 & ONI_DJF < 1.0 ~ "Weak El Niño",
        ONI_DJF >= 1.0 & ONI_DJF < 1.5 ~ "Moderate El Niño",
        ONI_DJF >= 1.5 ~ "Strong El Niño",
        TRUE ~ NA_character_
      ),
      # Convert to factor with specified order
      ENSO_Phase = factor(ENSO_Phase, levels = enso_order)
    )

  return(oni_seasonal)
}

# ------------------------------------------------------------------------------
# 8. DATA MERGING: Combine SNOTEL and ENSO Data
# ------------------------------------------------------------------------------

merge_snotel_enso <- function(snotel_data, enso_data) {
  cat("Merging SNOTEL and ENSO data...\n")

  # Merge by season year
  merged_data <- snotel_data %>%
    left_join(enso_data, by = "Season_Year") %>%
    filter(!is.na(ENSO_Phase))

  # Save processed data
  write_csv(merged_data, "data/snotel_processed.csv")
  cat("Processed data saved to data/snotel_processed.csv\n")

  return(merged_data)
}

# ------------------------------------------------------------------------------
# 9. ANALYSIS: Calculate Monthly Summary Statistics
# ------------------------------------------------------------------------------

calculate_monthly_summary <- function(merged_data) {
  cat("Calculating monthly summary statistics...\n")

  # Sum new SWE by month for each site, season, and ENSO phase
  monthly_totals <- merged_data %>%
    group_by(Site, Season_Year, ENSO_Phase, Month_Name) %>%
    summarize(
      Monthly_New_SWE = sum(New_SWE, na.rm = TRUE),
      .groups = "drop"
    )

  # Calculate average monthly new SWE by ENSO phase and site
  monthly_summary <- monthly_totals %>%
    group_by(Site, ENSO_Phase, Month_Name) %>%
    summarize(
      Avg_Monthly_New_SWE = mean(Monthly_New_SWE, na.rm = TRUE),
      SD_Monthly_New_SWE = sd(Monthly_New_SWE, na.rm = TRUE),
      N_Years = n(),
      .groups = "drop"
    ) %>%
    # Convert month to factor with correct order
    mutate(
      Month_Name = factor(Month_Name, levels = month_order)
    )

  # Save summary data
  write_csv(monthly_summary, "data/monthly_summary.csv")
  cat("Monthly summary saved to data/monthly_summary.csv\n")

  return(monthly_summary)
}

# ------------------------------------------------------------------------------
# 10. ANALYSIS: Calculate Percentage Difference from Neutral
# ------------------------------------------------------------------------------

calculate_percentage_difference <- function(merged_data) {
  cat("Calculating percentage difference from neutral...\n")

  # Calculate total seasonal new SWE for each site, season, and ENSO phase
  seasonal_totals <- merged_data %>%
    group_by(Site, Season_Year, ENSO_Phase) %>%
    summarize(
      Seasonal_New_SWE = sum(New_SWE, na.rm = TRUE),
      .groups = "drop"
    )

  # Calculate average seasonal new SWE by ENSO phase and site
  seasonal_avg <- seasonal_totals %>%
    group_by(Site, ENSO_Phase) %>%
    summarize(
      Avg_Seasonal_New_SWE = mean(Seasonal_New_SWE, na.rm = TRUE),
      .groups = "drop"
    )

  # Get neutral baseline for each site
  neutral_baseline <- seasonal_avg %>%
    filter(ENSO_Phase == "Neutral") %>%
    select(Site, Neutral_SWE = Avg_Seasonal_New_SWE)

  # Calculate percentage difference from neutral
  pct_diff <- seasonal_avg %>%
    left_join(neutral_baseline, by = "Site") %>%
    mutate(
      Pct_Diff_From_Neutral =
        ((Avg_Seasonal_New_SWE - Neutral_SWE) / Neutral_SWE) * 100
    ) %>%
    # Filter to only strong/weak La Niña and El Niño
    filter(ENSO_Phase != "Neutral")

  # Save percentage difference data
  write_csv(pct_diff, "data/percentage_difference.csv")
  cat("Percentage difference saved to data/percentage_difference.csv\n")

  return(pct_diff)
}

# ------------------------------------------------------------------------------
# 11. VISUALIZATION: Create Monthly Line Plot
# ------------------------------------------------------------------------------

create_monthly_line_plot <- function(monthly_summary, year_range) {
  cat("Creating monthly line plot...\n")

  # Create plot
  p <- ggplot(
    monthly_summary,
    aes(
      x = Month_Name,
      y = Avg_Monthly_New_SWE,
      color = ENSO_Phase,
      group = ENSO_Phase
    )
  ) +
    geom_line(linewidth = 1.0) +
    geom_point(size = 2.5) +
    facet_wrap(~Site, scales = "free_y", ncol = 2) +
    scale_color_manual(
      values = enso_colors,
      name = "ENSO Phase"
    ) +
    labs(
      title = sprintf(
        "Monthly Average New Snowfall (SWE) by ENSO Phase (%s)",
        year_range
      ),
      x = "Month",
      y = "Average Monthly New SWE (inches)",
      caption = paste(
        "Data source: USDA NRCS SNOTEL Network and",
        "NOAA Climate Prediction Center (ONI)"
      )
    ) +
    theme_minimal(base_size = 12) +
    theme(
      plot.title = element_text(hjust = 0.5, face = "bold", size = 14),
      plot.caption = element_text(hjust = 0.5, size = 9),
      legend.position = "bottom",
      legend.title = element_text(face = "bold"),
      strip.text = element_text(face = "bold", size = 11),
      axis.text.x = element_text(angle = 45, hjust = 1),
      panel.grid.minor = element_blank()
    )

  # Save plot
  ggsave(
    "plots/monthly_swe_by_enso_phase.png",
    plot = p,
    width = 12,
    height = 8,
    dpi = 300,
    bg = "white"
  )
  cat("Monthly line plot saved to plots/monthly_swe_by_enso_phase.png\n")

  return(p)
}

# ------------------------------------------------------------------------------
# 12. VISUALIZATION: Create Percentage Difference Bar Plot
# ------------------------------------------------------------------------------

create_percentage_bar_plot <- function(pct_diff, year_range) {
  cat("Creating percentage difference bar plot...\n")

  # Create plot
  p <- ggplot(
    pct_diff,
    aes(
      x = Site,
      y = Pct_Diff_From_Neutral,
      fill = ENSO_Phase
    )
  ) +
    geom_bar(
      stat = "identity",
      position = position_dodge(width = 0.8),
      width = 0.7
    ) +
    geom_hline(yintercept = 0, linetype = "dashed", color = "gray40") +
    scale_fill_manual(
      values = enso_colors,
      name = "ENSO Phase"
    ) +
    labs(
      title = sprintf(
        "Snowfall Difference from Neutral Years by ENSO Intensity (%s)",
        year_range
      ),
      x = "Site",
      y = "Percentage Difference from Neutral (%)",
      caption = paste(
        "Data source: USDA NRCS SNOTEL Network and",
        "NOAA Climate Prediction Center (ONI)"
      )
    ) +
    theme_minimal(base_size = 12) +
    theme(
      plot.title = element_text(hjust = 0.5, face = "bold", size = 14),
      plot.caption = element_text(hjust = 0.5, size = 9),
      legend.position = "bottom",
      legend.title = element_text(face = "bold"),
      axis.text.x = element_text(angle = 45, hjust = 1),
      panel.grid.minor = element_blank()
    )

  # Save plot
  ggsave(
    "plots/percentage_difference_from_neutral.png",
    plot = p,
    width = 10,
    height = 7,
    dpi = 300,
    bg = "white"
  )
  cat(paste(
    "Percentage difference bar plot saved to",
    "plots/percentage_difference_from_neutral.png\n"
  ))

  return(p)
}

# ------------------------------------------------------------------------------
# 13. MAIN EXECUTION: Run Complete Analysis Pipeline
# ------------------------------------------------------------------------------

main <- function() {
  cat("\n")
  cat("==============================================================\n")
  cat("WA Cascades Snowfall and ENSO Analysis\n")
  cat("==============================================================\n")
  cat("\n")

  # Step 1: Download ONI data
  cat("STEP 1: Downloading ONI data...\n")
  cat("--------------------------------------------------------------\n")
  oni_data <- download_oni_data()
  if (is.null(oni_data)) {
    stop("Failed to download ONI data. Exiting.")
  }
  cat("\n")

  # Step 2: Download SNOTEL data for all sites
  cat("STEP 2: Downloading SNOTEL data...\n")
  cat("--------------------------------------------------------------\n")
  snotel_list <- list()
  for (site in snotel_sites) {
    snotel_data <- download_snotel_data(site$code, site$site_name)
    if (!is.null(snotel_data)) {
      snotel_list[[site$site_name]] <- snotel_data
    }
  }

  if (length(snotel_list) == 0) {
    stop("Failed to download any SNOTEL data. Exiting.")
  }

  # Combine all SNOTEL data
  snotel_combined <- bind_rows(snotel_list)
  cat("\n")

  # Step 3: Calculate daily new SWE
  cat("STEP 3: Processing SNOTEL data...\n")
  cat("--------------------------------------------------------------\n")
  snotel_processed <- calculate_new_swe(snotel_combined)
  cat("\n")

  # Step 4: Assign snow seasons
  cat("STEP 4: Assigning snow seasons...\n")
  cat("--------------------------------------------------------------\n")
  snotel_seasonal <- assign_snow_season(snotel_processed)

  # Get year range for plot titles
  year_range <- sprintf(
    "%d-%d",
    min(snotel_seasonal$Season_Year, na.rm = TRUE),
    max(snotel_seasonal$Season_Year, na.rm = TRUE)
  )
  cat(sprintf("Year range: %s\n", year_range))
  cat("\n")

  # Step 5: Classify ENSO phases
  cat("STEP 5: Classifying ENSO phases...\n")
  cat("--------------------------------------------------------------\n")
  enso_classified <- classify_enso_phase(oni_data)
  cat("\n")

  # Step 6: Merge SNOTEL and ENSO data
  cat("STEP 6: Merging SNOTEL and ENSO data...\n")
  cat("--------------------------------------------------------------\n")
  merged_data <- merge_snotel_enso(snotel_seasonal, enso_classified)
  cat("\n")

  # Step 7: Calculate monthly summary statistics
  cat("STEP 7: Calculating monthly summary statistics...\n")
  cat("--------------------------------------------------------------\n")
  monthly_summary <- calculate_monthly_summary(merged_data)
  cat("\n")

  # Step 8: Calculate percentage difference from neutral
  cat("STEP 8: Calculating percentage difference from neutral...\n")
  cat("--------------------------------------------------------------\n")
  pct_diff <- calculate_percentage_difference(merged_data)
  cat("\n")

  # Step 9: Create monthly line plot
  cat("STEP 9: Creating monthly line plot...\n")
  cat("--------------------------------------------------------------\n")
  monthly_plot <- create_monthly_line_plot(monthly_summary, year_range)
  cat("\n")

  # Step 10: Create percentage difference bar plot
  cat("STEP 10: Creating percentage difference bar plot...\n")
  cat("--------------------------------------------------------------\n")
  pct_plot <- create_percentage_bar_plot(pct_diff, year_range)
  cat("\n")

  # Summary
  cat("==============================================================\n")
  cat("Analysis complete!\n")
  cat("==============================================================\n")
  cat("\n")
  cat("Output files:\n")
  cat("  Data files saved to: data/\n")
  cat("  Plot files saved to: plots/\n")
  cat("\n")
  cat("Plots generated:\n")
  cat("  1. plots/monthly_swe_by_enso_phase.png\n")
  cat("  2. plots/percentage_difference_from_neutral.png\n")
  cat("\n")
}

# Run the analysis
main()
