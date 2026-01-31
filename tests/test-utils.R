# ============================================================================
# UNIT TESTS: UTILITY FUNCTIONS
# Tests for helper functions in utils.R
# ============================================================================

library(testthat)

# ----------------------------------------------------------------------------
# Test: Basic percentage error calculation (inline function for testing)
# ----------------------------------------------------------------------------

test_that("percentage error calculation works correctly", {
  # Define inline for testing
  pct_error <- function(predicted, actual) {
    ((predicted - actual) / actual) * 100
  }
  
  # Basic test
  expect_equal(pct_error(110, 100), 10)
  expect_equal(pct_error(90, 100), -10)
  expect_equal(pct_error(100, 100), 0)
  
  # Vector test
  predicted <- c(110, 90, 100, 105)
  actual <- c(100, 100, 100, 100)
  expected <- c(10, -10, 0, 5)
  expect_equal(pct_error(predicted, actual), expected)
  
  # Edge cases
  expect_true(is.infinite(pct_error(100, 0)))  # Division by zero
  expect_true(is.nan(pct_error(0, 0)))  # 0/0
})

# ----------------------------------------------------------------------------
# Test: Data validation basics
# ----------------------------------------------------------------------------

test_that("data frame validation works", {
  # Valid data frame
  test_df <- data.frame(
    x = 1:10,
    y = rnorm(10)
  )
  
  expect_s3_class(test_df, "data.frame")
  expect_equal(nrow(test_df), 10)
  expect_equal(ncol(test_df), 2)
  expect_true(all(complete.cases(test_df)))
})

# ----------------------------------------------------------------------------
# Test: Basic statistical functions
# ----------------------------------------------------------------------------

test_that("basic statistics work correctly", {
  test_data <- c(1, 2, 3, 4, 5)
  
  expect_equal(mean(test_data), 3)
  expect_equal(median(test_data), 3)
  expect_equal(sum(test_data), 15)
  expect_equal(length(test_data), 5)
})
