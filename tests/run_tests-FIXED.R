# ============================================================================
# MASTER TEST RUNNER - SIMPLIFIED
# Execute all unit tests and generate comprehensive report
# ============================================================================

# Clear environment
rm(list = ls())

cat("\n")
cat(rep("=", 80), "\n", sep = "")
cat("ACTUARIAL MODEL TESTING SUITE\n")
cat("Project: Aggregate Loss Modeling - Tweedie vs Synthetic Exposure\n")
cat(rep("=", 80), "\n\n", sep = "")

# ----------------------------------------------------------------------------
# Check Working Directory
# ----------------------------------------------------------------------------

cat("Checking working directory...\n")
current_wd <- getwd()
cat("Current directory:", current_wd, "\n")

# Check if we're in the right place
if (!dir.exists("tests/testthat")) {
  cat("❌ ERROR: tests/testthat/ directory not found!\n")
  cat("   Make sure you're running from the project root directory.\n")
  cat("   Current directory:", getwd(), "\n\n")
  cat("   Try running: setwd('path/to/your/project')\n\n")
  stop("Tests directory not found")
}

cat("✅ Tests directory found\n\n")

# ----------------------------------------------------------------------------
# Load Required Packages
# ----------------------------------------------------------------------------

cat("Loading required packages...\n")

required_packages <- c("testthat", "dplyr")
optional_packages <- c("MASS", "tweedie", "statmod", "evd")

# Check and install required packages
missing_required <- required_packages[!sapply(required_packages, requireNamespace, quietly = TRUE)]
if (length(missing_required) > 0) {
  cat("❌ Missing required packages:", paste(missing_required, collapse = ", "), "\n")
  cat("   Installing...\n")
  install.packages(missing_required)
}

# Check optional packages
missing_optional <- optional_packages[!sapply(optional_packages, requireNamespace, quietly = TRUE)]
if (length(missing_optional) > 0) {
  cat("⚠️  Missing optional packages:", paste(missing_optional, collapse = ", "), "\n")
  cat("   Some tests may be skipped. To install:\n")
  cat("   install.packages(c('", paste(missing_optional, collapse = "', '"), "'))\n\n", sep = "")
}

suppressPackageStartupMessages({
  library(testthat)
  library(dplyr)
})

cat("✅ Required packages loaded\n\n")

# ----------------------------------------------------------------------------
# Run Unit Tests
# ----------------------------------------------------------------------------

cat(rep("-", 80), "\n", sep = "")
cat("RUNNING UNIT TESTS\n")
cat(rep("-", 80), "\n\n", sep = "")

# Record start time
start_time <- Sys.time()

# Run tests with error handling
test_results <- tryCatch({
  testthat::test_dir(
    "tests/testthat",
    reporter = "progress",
    stop_on_failure = FALSE
  )
}, error = function(e) {
  cat("\n❌ Error running tests:\n")
  cat("  ", e$message, "\n\n")
  return(NULL)
})

# Record end time
end_time <- Sys.time()
elapsed_time <- difftime(end_time, start_time, units = "secs")

# ----------------------------------------------------------------------------
# Generate Test Summary
# ----------------------------------------------------------------------------

cat("\n")
cat(rep("=", 80), "\n", sep = "")
cat("TEST SUMMARY\n")
cat(rep("=", 80), "\n\n", sep = "")

if (is.null(test_results)) {
  cat("❌ Tests failed to run properly\n")
  cat("   Check error messages above\n\n")
} else {
  # Extract test statistics (handle different testthat versions)
  tryCatch({
    # Try newer testthat format
    n_passed <- sum(test_results$result == "success", na.rm = TRUE)
    n_failed <- sum(test_results$result == "failure", na.rm = TRUE)
    n_warnings <- sum(test_results$result == "warning", na.rm = TRUE)
    n_skipped <- sum(test_results$result == "skip", na.rm = TRUE)
    n_tests <- length(test_results$result)
  }, error = function(e) {
    # Fallback for older format
    n_passed <<- attr(test_results, "n_pass") %||% 0
    n_failed <<- attr(test_results, "n_fail") %||% 0
    n_warnings <<- attr(test_results, "n_warn") %||% 0
    n_skipped <<- attr(test_results, "n_skip") %||% 0
    n_tests <<- n_passed + n_failed + n_warnings + n_skipped
  })
  
  cat("Total Tests:     ", n_tests, "\n")
  cat("✅ Passed:       ", n_passed, "\n")
  cat("❌ Failed:       ", n_failed, "\n")
  cat("⚠️  Warnings:     ", n_warnings, "\n")
  cat("⏭️  Skipped:      ", n_skipped, "\n")
  cat("⏱️  Time Elapsed: ", round(elapsed_time, 2), " seconds\n\n")
  
  # Success rate
  if (n_tests > 0) {
    success_rate <- (n_passed / n_tests) * 100
    cat("Success Rate:   ", round(success_rate, 1), "%\n\n")
  }
}

# ----------------------------------------------------------------------------
# Save Test Results
# ----------------------------------------------------------------------------

if (!is.null(test_results)) {
  cat(rep("-", 80), "\n", sep = "")
  cat("SAVING RESULTS\n")
  cat(rep("-", 80), "\n\n", sep = "")
  
  # Create results directory
  dir.create("results/tests", showWarnings = FALSE, recursive = TRUE)
  
  # Save detailed results
  results_file <- "results/tests/test_results.rds"
  saveRDS(test_results, results_file)
  cat("✅ Detailed results saved to:", results_file, "\n\n")
}

# ----------------------------------------------------------------------------
# Final Status
# ----------------------------------------------------------------------------

cat(rep("=", 80), "\n", sep = "")

if (!is.null(test_results) && exists("n_failed") && n_failed == 0) {
  cat("✅ ALL TESTS PASSED\n")
  cat(rep("=", 80), "\n\n", sep = "")
  cat("🎉 Testing suite completed successfully!\n")
  if (exists("n_tests")) {
    cat("   All", n_tests, "tests passed in", round(elapsed_time, 2), "seconds.\n\n")
  }
} else {
  cat("⚠️  TESTING COMPLETED WITH ISSUES\n")
  cat(rep("=", 80), "\n\n", sep = "")
  if (exists("n_failed") && n_failed > 0) {
    cat("❌ ", n_failed, "tests failed\n")
  }
  if (exists("n_skipped") && n_skipped > 0) {
    cat("⏭️  ", n_skipped, "tests skipped (missing packages)\n")
  }
  cat("\n   Review output above for details\n\n")
}

cat("📁 Test results location: results/tests/\n\n")

# Define %||% operator if not available
if (!exists("%||%", mode = "function")) {
  `%||%` <- function(x, y) if (is.null(x)) y else x
}
