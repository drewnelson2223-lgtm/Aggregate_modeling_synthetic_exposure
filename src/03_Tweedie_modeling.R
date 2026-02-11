# ============================================================================
# TWEEDIE DISTRIBUTION MODELING
# Preferred approach for aggregate loss modeling without exposure data
# ============================================================================

source("src/utils.R")

fit_tweedie_model <- function(base_data, p_range = seq(1.1, 1.9, by = 0.05)) {
  
  print_header("PART 2: TWEEDIE AGGREGATE MODELING")
  
  cat("✅ This section provides RELIABLE results\n")
  cat("   - Models aggregate losses directly (no synthetic assumptions)\n")
  cat("   - Appropriate for available data\n")
  cat("   - Implicitly captures Compound Poisson-Gamma structure\n")
  cat("   - These results should be preferred over Part 1\n\n")
  
  # -------------------------------------------------------------------------
  # Prepare Data
  # -------------------------------------------------------------------------
  
  print_subheader("Step 1: Data Preparation")
  
  tweedie_data <- base_data %>%
    dplyr::mutate(
      Year_Centered = AccidentYear - mean(AccidentYear)
    )
  
  cat("✅ Tweedie data prepared\n")
  cat("   Observations:", nrow(tweedie_data), "\n\n")
  
  # -------------------------------------------------------------------------
  # Estimate Power Parameter
  # -------------------------------------------------------------------------
  
  print_subheader("Step 2: Tweedie Parameter Estimation")
  
  cat("Finding optimal power parameter (p)... this may take 1-2 minutes\n\n")
  
  p_profile <- tweedie::tweedie.profile(
    Loss ~ AccidentYear + log(Premium),
    data = tweedie_data,
    p.vec = p_range,
    do.plot = FALSE,
    verbose = FALSE
  )
  
  p_optimal <- p_profile$p.max
  
  cat("✅ Optimal power parameter found\n")
  cat("   p =", round(p_optimal, 3), "\n")
  cat("   95% CI:", round(p_profile$ci, 3), "\n\n")
  
  # Interpret p
  if (p_optimal < 1.3) {
    interpretation <- "Low p → frequency-dominated (many small claims)"
  } else if (p_optimal > 1.7) {
    interpretation <- "High p → severity-dominated (few large claims)"
  } else {
    interpretation <- "Moderate p → balanced frequency and severity"
  }
  cat("   Interpretation:", interpretation, "\n\n")
  
  # -------------------------------------------------------------------------
  # Fit Tweedie GLM
  # -------------------------------------------------------------------------
  
  cat("Fitting Tweedie GLM...\n\n")
  
  tweedie_model <- glm(
    Loss ~ AccidentYear + log(Premium),
    family = statmod::tweedie(var.power = p_optimal, link.power = 0),
    data = tweedie_data
  )
  
  cat("Tweedie Model Summary:\n")
  print(summary(tweedie_model))
  cat("\n")
  
  # Extract parameters
  tweedie_coefs <- coef(tweedie_model)
  phi_hat <- summary(tweedie_model)$dispersion
  
  cat("=== TWEEDIE PARAMETERS ===\n")
  cat("Power (p):", round(p_optimal, 3), "\n")
  cat("Dispersion (φ):", round(phi_hat, 2), "\n")
  cat("Intercept:", round(tweedie_coefs["(Intercept)"], 4), "\n")
  cat("Year effect:", round(tweedie_coefs["AccidentYear"], 6), "\n")
  cat("   → Annual change:", round((exp(tweedie_coefs["AccidentYear"]) - 1) * 100, 2), "%\n")
  cat("Premium elasticity:", round(tweedie_coefs["log(Premium)"], 3), "\n\n")
  
  # Add fitted values and residuals
  tweedie_data$loss_fitted_tw <- predict(tweedie_model, type = "response")
  tweedie_data$residuals_tw <- residuals(tweedie_model, type = "deviance")
  
  # -------------------------------------------------------------------------
  # Aggregate to Annual Level
  # -------------------------------------------------------------------------
  
  print_subheader("Step 3: Annual Aggregate Results")
  
  annual_tweedie <- tweedie_data %>%
    dplyr::group_by(AccidentYear) %>%
    dplyr::summarise(
      n_companies = n(),
      actual_total_loss = sum(Loss),
      fitted_total_loss = sum(loss_fitted_tw),
      .groups = "drop"
    ) %>%
    dplyr::mutate(
      pct_error = pct_error(fitted_total_loss, actual_total_loss)
    )
  
  cat("Annual Aggregate Results (Tweedie):\n")
  print(annual_tweedie)
  cat("\n")
  
  # -------------------------------------------------------------------------
  # Model Diagnostics
  # -------------------------------------------------------------------------
  
  print_subheader("Step 4: Model Diagnostics")
  
  print_model_diagnostics(tweedie_model, "Tweedie Model")
  
  # Save results
  dir.create("results", showWarnings = FALSE)
  results <- list(
    data = tweedie_data,
    model = tweedie_model,
    annual = annual_tweedie,
    parameters = list(
      p_optimal = p_optimal,
      phi = phi_hat,
      coefficients = tweedie_coefs
    )
  )
  saveRDS(results, "results/tweedie_results.rds")
  cat("✅ Results saved to results/tweedie_results.rds\n\n")
  
  return(results)
}

# Run if executed directly
if (!interactive()) {
  library(tidyverse)
  library(tweedie)
  library(statmod)
  base_data <- readRDS("data/base_data.rds")
  fit_tweedie_model(base_data)
}
