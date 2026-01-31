# ============================================================================
# DATA PREPARATION
# Load and prepare CAS Schedule P data for analysis
# ============================================================================

source("src/utils.R")

prepare_data <- function() {
  print_header("DATA LOADING AND PREPARATION")
  
  # Load CAS Schedule P data
  cat("Loading CAS Schedule P data...\n")
  url <- "https://www.casact.org/sites/default/files/2021-04/ppauto_pos.csv"
  
  suppressMessages({
    ppauto_data <- readr::read_csv(url, show_col_types = FALSE)
  })
  
  cat("✅ Data loaded successfully\n")
  cat("   Records:", nrow(ppauto_data), "\n")
  cat("   Companies:", length(unique(ppauto_data$GRNAME)), "\n")
  cat("   Accident Years:", paste(range(ppauto_data$AccidentYear), collapse = "-"), "\n\n")
  
  # Extract ultimate losses (fully developed - DevelopmentLag = 10)
  base_data <- ppauto_data %>%
    dplyr::filter(DevelopmentLag == 10) %>%
    dplyr::mutate(
      Loss = IncurLoss_B,
      Premium = EarnedPremDIR_B
    ) %>%
    dplyr::filter(Loss > 0, Premium > 0) %>%
    dplyr::select(GRCODE, GRNAME, AccidentYear, Loss, Premium)
  
  cat("✅ Base data prepared\n")
  cat("   Company-year observations:", nrow(base_data), "\n\n")
  
  # Save prepared data
  dir.create("data", showWarnings = FALSE)
  saveRDS(base_data, "data/base_data.rds")
  cat("✅ Data saved to data/base_data.rds\n\n")
  
  return(base_data)
}

# Run if executed directly
if (!interactive()) {
  library(tidyverse)
  prepare_data()
}
