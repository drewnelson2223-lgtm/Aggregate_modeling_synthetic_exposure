# ============================================================================
# COMPOUND POISSON-GAMMA WITH SYNTHETIC EXPOSURE
# Methodological demonstration using synthetic assumptions
# WARNING: For educational purposes only - do not use for actual estimates
# ============================================================================

source("src/utils.R")

fit_cp_gamma <- function(base_data, 
                         avg_premium_per_car_year = 1000,
                         avg_severity_per_claim = 5000) {
  
  print_header("PART 1: COMPOUND POISSON-GAMMA WITH SYNTHETIC EXPOSURE")
  
  cat("⚠️  IMPORTANT NOTE ⚠️\n")
  cat("This section demonstrates traditional frequency/severity methodology.\n")
  cat("However, exposure data is NOT available in the dataset.\n")
  cat("We synthesize exposure from premium using explicit assumptions.\n")
  cat("This should be viewed as a METHODOLOGICAL DEMONSTRATION.\n")
  cat("Part 2 provides more reliable results using appropriate methods.\n\n")
  
  # -------------------------------------------------------------------------
  # Create Synthetic Variables
  # -------------------------------------------------------------------------
  
  print_subheader("Step 1: Creating Synthetic Exposure")
  
  cat("📋 ASSUMPTIONS:\n")
  cat("   - Average premium per car-year: $", avg_premium_per_car_year, "\n", sep = "")
  cat("   - Average severity per claim: $", avg_severity_per_claim, "\n\n", sep = "")
  
  cp_data <- base_data %>%
    dplyr::mutate(
      # Synthetic exposure (car-years)
      Synthetic_Exposure = Premium / avg_premium_per_car_year,
      
      # Synthetic claim count (back-calculated)
      Synthetic_Claims = Loss / avg_severity_per_claim,
      Synthetic_Claims_Rounded = round(Synthetic_Claims),
      
      # Implied metrics
      Implied_Frequency = Synthetic_Claims / Synthetic_Exposure,
      Implied_Severity = Loss / Synthetic_Claims,
      Implied_PurePremium = Loss / Synthetic_Exposure
    )
  
  cat("✅ Synthetic variables created\n")
  cat("   Sample statistics:\n")
  cat("   - Mean synthetic exposure:", round(mean(cp_data$Synthetic_Exposure), 0), "car-years\n")
  cat("   - Mean synthetic claims:", round(mean(cp_data$Synthetic_Claims), 1), "\n")
  cat("   - Mean implied frequency:", round(mean(cp_data$Implied_Frequency), 4), "claims/car-year\n")
  cat("   - Mean implied severity: $", round(mean(cp_data$Implied_Severity), 0), "\n\n", sep = "")
  
  # -------------------------------------------------------------------------
  # Frequency Model (Poisson)
  # -------------------------------------------------------------------------
  
  print_subheader("Step 2: Frequency Modeling (Poisson)")
  
  freq_model <- glm(
    Synthetic_Claims_Rounded ~ AccidentYear,
    family = poisson,
    offset = log(Synthetic_Exposure),
    data = cp_data
  )
  
  cat("Frequency Model Summary:\n")
  print(summary(freq_model))
  cat("\n")
  
  freq_change <- interpret_annual_change(coef(freq_model)["AccidentYear"])
  cat("Temporal Trend:\n")
  cat("   - Year coefficient:", round(freq_change$coefficient, 6), "\n")
  cat("   - Annual change:", round(freq_change$pct_change, 2), "%\n")
  cat("   - Interpretation:", freq_change$direction, "frequency over time\n\n")
  
  cp_data$freq_fitted <- predict(freq_model, type = "response")
  
  # -------------------------------------------------------------------------
  # Severity Model (Gamma)
  # -------------------------------------------------------------------------
  
  print_subheader("Step 3: Severity Modeling (Gamma)")
  
  sev_model <- glm(
    Implied_Severity ~ AccidentYear,
    family = Gamma(link = "log"),
    data = cp_data
  )
  
  cat("Severity Model Summary:\n")
  print(summary(sev_model))
  cat("\n")
  
  sev_change <- interpret_annual_change(coef(sev_model)["AccidentYear"])
  cat("Temporal Trend:\n")
  cat("   - Year coefficient:", round(sev_change$coefficient, 6), "\n")
  cat("   - Annual change:", round(sev_change$pct_change, 2), "%\n")
  cat("   - Interpretation:", sev_change$direction, "severity over time\n\n")
  
  cp_data$sev_fitted <- predict(sev_model, type = "response")
  
  # -------------------------------------------------------------------------
  # Combine and Aggregate
  # -------------------------------------------------------------------------
  
  print_subheader("Step 4: Compound Poisson-Gamma Results")
  
  cp_data$pure_premium_fitted <- cp_data$freq_fitted * cp_data$sev_fitted
  cp_data$loss_fitted_cp <- cp_data$pure_premium_fitted * cp_data$Synthetic_Exposure
  
  annual_cp <- cp_data %>%
    dplyr::group_by(AccidentYear) %>%
    dplyr::summarise(
      n_companies = n(),
      actual_total_loss = sum(Loss),
      fitted_total_loss = sum(loss_fitted_cp),
      avg_frequency = mean(Implied_Frequency),
      avg_severity = mean(Implied_Severity),
      avg_pure_premium = mean(Implied_PurePremium),
      total_exposure = sum(Synthetic_Exposure),
      .groups = "drop"
    ) %>%
    dplyr::mutate(
      pct_error = pct_error(fitted_total_loss, actual_total_loss)
    )
  
  cat("Annual Aggregate Results (Compound Poisson-Gamma):\n")
  print(annual_cp)
  cat("\n")
  
  cat("⚠️  REMINDER: These results are based on SYNTHETIC exposure!\n\n")
  
  # -------------------------------------------------------------------------
  # Diagnostics and Limitations
  # -------------------------------------------------------------------------
  
  print_subheader("Step 5: Model Diagnostics")
  
  print_model_diagnostics(freq_model, "Frequency Model (Poisson)")
  print_model_diagnostics(sev_model, "Severity Model (Gamma)")
  
  cat("⚠️  CRITICAL LIMITATIONS OF PART 1:\n")
  cat("   1. Exposure is SYNTHETIC, not observed\n")
  cat("   2. Claim counts are BACK-CALCULATED, not actual\n")
  cat("   3. Assumes constant $", avg_premium_per_car_year, " premium per car-year (may not hold)\n", sep = "")
  cat("   4. Assumes constant $", avg_severity_per_claim, " average severity (may not hold)\n", sep = "")
  cat("   5. Results depend heavily on these unverified assumptions\n")
  cat("   6. Use Part 2 (Tweedie) for reliable estimates\n\n")
  
  # Save results
  dir.create("results", showWarnings = FALSE)
  results <- list(
    data = cp_data,
    models = list(freq = freq_model, sev = sev_model),
    annual = annual_cp,
    assumptions = list(
      premium_per_car_year = avg_premium_per_car_year,
      severity_per_claim = avg_severity_per_claim
    )
  )
  saveRDS(results, "results/cp_gamma_results.rds")
  cat("✅ Results saved to results/cp_gamma_results.rds\n\n")
  
  return(results)
}

# Run if executed directly
if (!interactive()) {
  library(tidyverse)
  base_data <- readRDS("data/base_data.rds")
  fit_cp_gamma(base_data)
}
