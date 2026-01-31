# ============================================================================
# COMPARISON AND VISUALIZATION
# Compare CP-Gamma vs Tweedie and generate diagnostic plots
# ============================================================================

source("src/utils.R")

create_comparison_and_plots <- function(cp_results, tweedie_results, evt_results) {
  
  print_header("COMPARISON AND VISUALIZATION")
  
  # -------------------------------------------------------------------------
  # Model Comparison
  # -------------------------------------------------------------------------
  
  print_subheader("Model Comparison")
  
  comparison <- cp_results$annual %>%
    dplyr::select(AccidentYear, 
                  actual = actual_total_loss,
                  fitted_cp = fitted_total_loss) %>%
    dplyr::left_join(
      tweedie_results$annual %>% dplyr::select(AccidentYear, fitted_tw = fitted_total_loss),
      by = "AccidentYear"
    ) %>%
    dplyr::mutate(
      error_cp = pct_error(fitted_cp, actual),
      error_tw = pct_error(fitted_tw, actual),
      diff_cp_tw = pct_error(fitted_cp, fitted_tw)
    )
  
  cat("Comparison Table:\n")
  print(comparison)
  cat("\n")
  
  cat("Summary Comparison:\n")
  cat("   Mean Absolute Error (CP-Gamma):", round(mean(abs(comparison$error_cp)), 2), "%\n")
  cat("   Mean Absolute Error (Tweedie):", round(mean(abs(comparison$error_tw)), 2), "%\n")
  cat("   Mean Difference (CP vs TW):", round(mean(comparison$diff_cp_tw), 2), "%\n\n")
  
  cat("Key Insights:\n")
  if (mean(abs(comparison$error_tw)) < mean(abs(comparison$error_cp))) {
    cat("   ✅ Tweedie has LOWER average error (more reliable)\n")
  } else {
    cat("   ⚠️  CP-Gamma appears to fit better, but this may be spurious\n")
    cat("      (synthetic exposure was calibrated to match data)\n")
  }
  cat("\n")
  
  cat("Why Results Differ:\n")
  cat("   1. CP-Gamma uses synthetic exposure (strong assumptions)\n")
  cat("   2. Tweedie models aggregates directly (no assumptions)\n")
  cat("   3. CP-Gamma split freq/sev may not match true split\n")
  cat("   4. Tweedie captures actual compound structure from data\n\n")
  
  cat("📊 RECOMMENDATION: Use Tweedie results for actual estimates\n\n")
  
  # -------------------------------------------------------------------------
  # Generate Plots
  # -------------------------------------------------------------------------
  
  print_subheader("Creating Visualizations")
  
  dir.create("reports/figures", recursive = TRUE, showWarnings = FALSE)
  
  # Plot 1: Annual Totals Comparison
  save_plot("annual_comparison.png", function() {
    plot(comparison$AccidentYear, comparison$actual / 1e6,
         type = "b", pch = 16, col = "black", lwd = 2,
         main = "Annual Total Losses: Actual vs Models",
         xlab = "Accident Year", ylab = "Total Loss ($ Millions)",
         ylim = c(0, max(comparison$actual) / 1e6 * 1.1))
    lines(comparison$AccidentYear, comparison$fitted_tw / 1e6,
          type = "b", pch = 18, col = "red", lwd = 2, lty = 2)
    legend("topleft", 
           legend = c("Actual", "Tweedie (Preferred)"),
           col = c("black", "red"), 
           pch = c(16, 18),
           lty = c(1, 2),
           lwd = 2)
    grid()
  }, width = 1000, height = 600)
  
  # Plot 2: Percentage Errors
  save_plot("error_comparison.png", function() {
    barplot(comparison$error_tw,
            names.arg = comparison$AccidentYear,
            col = "lightcoral",
            main = "Tweedie Prediction Errors by Year",
            xlab = "Accident Year",
            ylab = "Error (%)",
            ylim = c(min(comparison$error_tw) * 1.2, 0))
    abline(h = 0, lwd = 2)
    grid()
  }, width = 1000, height = 600)
  
  # Plot 3: Tweedie Diagnostics - Residuals vs Fitted
  save_plot("tweedie_residuals.png", function() {
    plot(tweedie_results$data$loss_fitted_tw, 
         tweedie_results$data$residuals_tw,
         pch = 16, col = rgb(0, 0, 1, 0.3),
         main = "Tweedie: Residuals vs Fitted",
         xlab = "Fitted Values", ylab = "Deviance Residuals")
    abline(h = 0, col = "red", lwd = 2)
    lines(lowess(tweedie_results$data$loss_fitted_tw, 
                 tweedie_results$data$residuals_tw),
          col = "blue", lwd = 2)
    grid()
  }, width = 800, height = 600)
  
  # Plot 4: Tweedie Diagnostics - Q-Q Plot
  save_plot("tweedie_qq.png", function() {
    qqnorm(tweedie_results$data$residuals_tw, 
           pch = 16, col = rgb(0, 0, 1, 0.3),
           main = "Tweedie: Normal Q-Q Plot")
    qqline(tweedie_results$data$residuals_tw, col = "red", lwd = 2)
    grid()
  }, width = 800, height = 600)
  
  # Plot 5: GEV Diagnostic
  save_plot("gev_diagnostic.png", function() {
    annual_maxima <- evt_results$gev$annual_maxima
    gev_params <- evt_results$gev$params
    
    plot(sort(annual_maxima), 
         (1:length(annual_maxima)) / (length(annual_maxima) + 1),
         pch = 16, col = "blue",
         main = "GEV: Empirical vs Fitted CDF",
         xlab = "Annual Maximum Loss",
         ylab = "Cumulative Probability")
    x_seq <- seq(min(annual_maxima), max(annual_maxima), length = 100)
    lines(x_seq, 
          evd::pgev(x_seq, loc = gev_params["loc"], 
                    scale = gev_params["scale"], 
                    shape = gev_params["shape"]),
          col = "red", lwd = 2)
    legend("bottomright", 
           legend = c("Empirical", "GEV Fitted"),
           col = c("blue", "red"),
           pch = c(16, NA),
           lty = c(NA, 1),
           lwd = 2)
    grid()
  }, width = 800, height = 600)
  
  # Plot 6: GPD Diagnostic
  save_plot("gpd_diagnostic.png", function() {
    threshold <- evt_results$gpd$threshold
    gpd_params <- evt_results$gpd$params
    
    exceedances <- tweedie_results$data$Loss[tweedie_results$data$Loss > threshold] - threshold
    plot(sort(exceedances),
         (1:length(exceedances)) / (length(exceedances) + 1),
         pch = 16, col = "blue",
         main = "GPD: Empirical vs Fitted CDF",
         xlab = "Exceedance Amount",
         ylab = "Cumulative Probability")
    x_seq <- seq(0, max(exceedances), length = 100)
    lines(x_seq,
          evd::pgpd(x_seq, scale = gpd_params["scale"], shape = gpd_params["shape"]),
          col = "red", lwd = 2)
    legend("bottomright",
           legend = c("Empirical", "GPD Fitted"),
           col = c("blue", "red"),
           pch = c(16, NA),
           lty = c(NA, 1),
           lwd = 2)
    grid()
  }, width = 800, height = 600)
  
  cat("\n✅ All visualizations created and saved to reports/figures/\n\n")
  
  # Save comparison
  saveRDS(comparison, "results/model_comparison.rds")
  write.csv(comparison, "results/model_comparison.csv", row.names = FALSE)
  cat("✅ Comparison saved to results/\n\n")
  
  return(comparison)
}

# Run if executed directly
if (!interactive()) {
  library(tidyverse)
  library(evd)
  
  cp_results <- readRDS("results/cp_gamma_results.rds")
  tweedie_results <- readRDS("results/tweedie_results.rds")
  evt_results <- readRDS("results/evt_results.rds")
  
  create_comparison_and_plots(cp_results, tweedie_results, evt_results)
}
