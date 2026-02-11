# ============================================================================
# UTILITY FUNCTIONS
# Shared helper functions used across multiple analysis scripts
# ============================================================================

#' Print section header
#' @param title Section title
#' @param width Width of header line
print_header <- function(title, width = 80) {
  cat(rep("=", width), "\n", sep = "")
  cat(title, "\n")
  cat(rep("=", width), "\n\n", sep = "")
}

#' Print subsection header
#' @param title Subsection title
print_subheader <- function(title) {
  cat("---", title, "---\n\n")
}

#' Calculate percentage error
#' @param fitted Fitted values
#' @param actual Actual values
#' @return Percentage error
pct_error <- function(fitted, actual) {
  ((fitted - actual) / actual) * 100
}

#' Print model diagnostics
#' @param model GLM model object
#' @param model_name Name of model for printing
print_model_diagnostics <- function(model, model_name = "Model") {
  cat(model_name, "Diagnostics:\n")
  cat("   - Deviance:", round(deviance(model), 2), "\n")
  cat("   - AIC:", round(AIC(model), 2), "\n")
  if (!is.null(model$null.deviance)) {
    pseudo_r2 <- 1 - deviance(model) / model$null.deviance
    cat("   - Pseudo R²:", round(pseudo_r2, 4), "\n")
  }
  cat("\n")
}

#' Interpret annual change from coefficient
#' @param coef Model coefficient
#' @return List with coefficient and percentage change
interpret_annual_change <- function(coef) {
  list(
    coefficient = coef,
    pct_change = (exp(coef) - 1) * 100,
    direction = ifelse(coef > 0, "Increasing", "Decreasing")
  )
}

#' Save plot to file
#' @param filename Filename (without path)
#' @param plot_function Function that generates the plot
#' @param width Width in pixels
#' @param height Height in pixels
save_plot <- function(filename, plot_function, width = 800, height = 600) {
  filepath <- file.path("reports", "figures", filename)
  
  # Create directory if it doesn't exist
  dir.create("reports/figures", recursive = TRUE, showWarnings = FALSE)
  
  png(filepath, width = width, height = height)
  plot_function()
  dev.off()
  
  cat("   ✅ Saved:", filepath, "\n")
}
