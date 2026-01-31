# ============================================================================
# EXTREME VALUE ANALYSIS
# GEV (block maxima) and GPD (peaks over threshold) for tail risk assessment
# ============================================================================

source("src/utils.R")

fit_evt_models <- function(tweedie_data, threshold_percentile = 0.85) {
  
  print_header("PART 4: EXTREME VALUE ANALYSIS")
  
  # -------------------------------------------------------------------------
  # GEV (Block Maxima)
  # -------------------------------------------------------------------------
  
  print_subheader("Generalized Extreme Value (GEV) Distribution")
  
  # Extract annual maxima
  annual_maxima <- tweedie_data %>%
    dplyr::group_by(AccidentYear) %>%
    dplyr::summarise(max_loss = max(Loss), .groups = "drop") %>%
    dplyr::pull(max_loss)
  
  cat("Annual Maximum Losses:\n")
  print(data.frame(
    Year = sort(unique(tweedie_data$AccidentYear)), 
    MaxLoss = annual_maxima
  ))
  cat("\n")
  
  # Fit GEV
  gev_fit <- evd::fgev(annual_maxima)
  
  cat("GEV Model:\n")
  print(gev_fit)
  cat("\n")
  
  gev_params <- gev_fit$estimate
  cat("GEV Parameters:\n")
  cat("   Location (μ):", round(gev_params["loc"], 0), "\n")
  cat("   Scale (σ):", round(gev_params["scale"], 0), "\n")
  cat("   Shape (ξ):", round(gev_params["shape"], 4), "\n\n")
  
  # Interpret shape
  if (abs(gev_params["shape"]) < 0.05) {
    cat("   Interpretation: ξ ≈ 0 → Gumbel (exponential tail)\n")
  } else if (gev_params["shape"] > 0) {
    cat("   Interpretation: ξ > 0 → Fréchet (heavy tail)\n")
  } else {
    cat("   Interpretation: ξ < 0 → Weibull (bounded tail)\n")
  }
  cat("\n")
  
  # Return levels
  return_periods <- c(10, 20, 50, 100)
  gev_return_levels <- sapply(return_periods, function(rp) {
    evd::qgev(1 - 1/rp, 
              loc = gev_params["loc"],
              scale = gev_params["scale"],
              shape = gev_params["shape"])
  })
  
  cat("Return Level Estimates (GEV):\n")
  gev_return_table <- data.frame(
    ReturnPeriod = return_periods,
    ReturnLevel = round(gev_return_levels, 0)
  )
  print(gev_return_table)
  cat("\n")
  
  # -------------------------------------------------------------------------
  # GPD (Peaks Over Threshold)
  # -------------------------------------------------------------------------
  
  print_subheader("Generalized Pareto Distribution (GPD)")
  
  # Choose threshold
  threshold <- quantile(tweedie_data$Loss, threshold_percentile)
  n_exceed <- sum(tweedie_data$Loss > threshold)
  
  cat("Threshold Selection:\n")
  cat("   Percentile:", threshold_percentile * 100, "%\n")
  cat("   Threshold value:", round(threshold, 0), "\n")
  cat("   Exceedances:", n_exceed, "(", round(n_exceed/nrow(tweedie_data)*100, 1), "%)\n\n")
  
  # Fit GPD
  cat("Fitting GPD...\n")
  gpd_fit <- tryCatch({
    evd::fpot(tweedie_data$Loss, threshold, std.err = TRUE)
  }, error = function(e) {
    cat("Note: Using std.err = FALSE due to numerical issues\n")
    evd::fpot(tweedie_data$Loss, threshold, std.err = FALSE)
  })
  
  cat("\nGPD Model:\n")
  print(gpd_fit)
  cat("\n")
  
  gpd_params <- gpd_fit$estimate
  cat("GPD Parameters:\n")
  cat("   Scale (σ):", round(gpd_params["scale"], 0), "\n")
  cat("   Shape (ξ):", round(gpd_params["shape"], 4), "\n\n")
  
  # Interpret shape
  if (abs(gpd_params["shape"]) < 0.05) {
    cat("   Interpretation: ξ ≈ 0 → Exponential tail\n")
  } else if (gpd_params["shape"] > 0) {
    cat("   Interpretation: ξ > 0 → Heavy tail (Pareto-type)\n")
    if (gpd_params["shape"] < 0.5) {
      cat("   → Finite variance exists\n")
    } else {
      cat("   → Infinite variance (very heavy tail)\n")
    }
  } else {
    cat("   Interpretation: ξ < 0 → Light tail (bounded)\n")
  }
  cat("\n")
  
  # Return levels from GPD
  exceedance_prob <- n_exceed / nrow(tweedie_data)
  gpd_return_levels <- sapply(return_periods, function(rp) {
    if (abs(gpd_params["shape"]) < 1e-6) {
      threshold + gpd_params["scale"] * log(rp * exceedance_prob)
    } else {
      threshold + (gpd_params["scale"] / gpd_params["shape"]) * 
        ((rp * exceedance_prob)^gpd_params["shape"] - 1)
    }
  })
  
  cat("Return Level Estimates (GPD):\n")
  evt_return_table <- data.frame(
    ReturnPeriod = return_periods,
    GEV_ReturnLevel = round(gev_return_levels, 0),
    GPD_ReturnLevel = round(gpd_return_levels, 0)
  )
  print(evt_return_table)
  cat("\n")
  
  # Save results
  dir.create("results", showWarnings = FALSE)
  results <- list(
    gev = list(
      fit = gev_fit,
      params = gev_params,
      annual_maxima = annual_maxima,
      return_levels = gev_return_table
    ),
    gpd = list(
      fit = gpd_fit,
      params = gpd_params,
      threshold = threshold,
      return_levels = evt_return_table
    )
  )
  saveRDS(results, "results/evt_results.rds")
  cat("✅ Results saved to results/evt_results.rds\n\n")
  
  return(results)
}

# Run if executed directly
if (!interactive()) {
  library(tidyverse)
  library(evd)
  tweedie_results <- readRDS("results/tweedie_results.rds")
  fit_evt_models(tweedie_results$data)
}
