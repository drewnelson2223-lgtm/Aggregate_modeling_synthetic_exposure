# ============================================================================
# UNIT TESTS: TWEEDIE MODELING
# Tests for Tweedie distribution modeling functions
# ============================================================================

library(testthat)
library(tweedie)
library(statmod)

# ----------------------------------------------------------------------------
# Test: Tweedie model fitting with synthetic data
# ----------------------------------------------------------------------------

test_that("Tweedie model fits successfully with valid data", {
  skip_if_not_installed("tweedie")
  
  # Generate synthetic Tweedie data
  set.seed(123)
  n <- 100
  test_data <- data.frame(
    Premium = exp(rnorm(n, mean = 10, sd = 0.5)),
    AccidentYear = sample(1990:1995, n, replace = TRUE)
  )
  
  # Generate Tweedie response
  p <- 1.5
  mu <- exp(5 + 0.1 * test_data$AccidentYear + 0.5 * log(test_data$Premium))
  phi <- 1.5
  
  test_data$Loss <- tweedie::rtweedie(n, mu = mu, phi = phi, power = p)
  
  # Fit model
  model <- glm(Loss ~ AccidentYear + log(Premium),
               data = test_data,
               family = tweedie(var.power = 1.5, link.power = 0))
  
  expect_s3_class(model, "glm")
  expect_true(model$converged)
  expect_equal(length(coef(model)), 3)  # Intercept + 2 predictors
})

test_that("Tweedie power parameter is within valid bounds", {
  skip_if_not_installed("tweedie")
  
  # Test that power parameter must be in (1, 2)
  set.seed(123)
  test_data <- data.frame(
    Loss = rgamma(50, shape = 2, rate = 0.001),
    Premium = exp(rnorm(50, mean = 10, sd = 0.5)),
    AccidentYear = sample(1990:1995, 50, replace = TRUE)
  )
  
  # Valid power
  expect_silent({
    model <- glm(Loss ~ AccidentYear + log(Premium),
                 data = test_data,
                 family = tweedie(var.power = 1.5, link.power = 0))
  })
  
  # Invalid power (outside bounds) should error
  expect_error({
    model <- glm(Loss ~ AccidentYear + log(Premium),
                 data = test_data,
                 family = tweedie(var.power = 2.5, link.power = 0))
  })
})

test_that("Tweedie predictions are positive", {
  skip_if_not_installed("tweedie")
  
  set.seed(123)
  test_data <- data.frame(
    Loss = rgamma(50, shape = 2, rate = 0.001),
    Premium = exp(rnorm(50, mean = 10, sd = 0.5)),
    AccidentYear = sample(1990:1995, 50, replace = TRUE)
  )
  
  model <- glm(Loss ~ AccidentYear + log(Premium),
               data = test_data,
               family = tweedie(var.power = 1.5, link.power = 0))
  
  predictions <- predict(model, type = "response")
  
  expect_true(all(predictions > 0))
  expect_true(all(is.finite(predictions)))
})

test_that("Tweedie model handles edge cases", {
  skip_if_not_installed("tweedie")
  
  # Small dataset
  small_data <- data.frame(
    Loss = c(1000, 1100, 1200),
    Premium = c(500, 550, 600),
    AccidentYear = c(1990, 1991, 1992)
  )
  
  # Should still fit (though not reliable)
  expect_silent({
    model <- glm(Loss ~ AccidentYear + log(Premium),
                 data = small_data,
                 family = tweedie(var.power = 1.5, link.power = 0))
  })
})

# ----------------------------------------------------------------------------
# Test: Model diagnostics and quality checks
# ----------------------------------------------------------------------------

test_that("Tweedie model produces valid diagnostics", {
  skip_if_not_installed("tweedie")
  
  set.seed(123)
  test_data <- data.frame(
    Loss = rgamma(100, shape = 2, rate = 0.001),
    Premium = exp(rnorm(100, mean = 10, sd = 0.5)),
    AccidentYear = sample(1990:1995, 100, replace = TRUE)
  )
  
  model <- glm(Loss ~ AccidentYear + log(Premium),
               data = test_data,
               family = tweedie(var.power = 1.5, link.power = 0))
  
  # Check diagnostics
  expect_true(!is.null(model$deviance))
  expect_true(!is.null(model$null.deviance))
  expect_true(!is.null(AIC(model)))
  
  # Pseudo R-squared should be between 0 and 1
  pseudo_r2 <- 1 - (model$deviance / model$null.deviance)
  expect_true(pseudo_r2 >= 0 && pseudo_r2 <= 1)
  
  # Residuals should exist
  resids <- residuals(model, type = "deviance")
  expect_equal(length(resids), nrow(test_data))
})

test_that("Tweedie coefficient significance can be assessed", {
  skip_if_not_installed("tweedie")
  
  set.seed(123)
  n <- 200  # Larger sample for better power
  test_data <- data.frame(
    Premium = exp(rnorm(n, mean = 10, sd = 0.5)),
    AccidentYear = sample(1990:1995, n, replace = TRUE)
  )
  
  # Strong relationship with Premium, weak with Year
  mu <- exp(5 + 0.001 * test_data$AccidentYear + 0.8 * log(test_data$Premium))
  test_data$Loss <- tweedie::rtweedie(n, mu = mu, phi = 1.5, power = 1.5)
  
  model <- glm(Loss ~ AccidentYear + log(Premium),
               data = test_data,
               family = tweedie(var.power = 1.5, link.power = 0))
  
  model_summary <- summary(model)
  p_values <- model_summary$coefficients[, "Pr(>|t|)"]
  
  # Premium should be highly significant
  expect_true(p_values["log(Premium)"] < 0.05)
  
  # Can extract coefficient estimates
  expect_true(!is.null(coef(model)))
  expect_equal(length(coef(model)), 3)
})

# ----------------------------------------------------------------------------
# Test: Power parameter estimation
# ----------------------------------------------------------------------------

test_that("Power parameter profile likelihood works", {
  skip_if_not_installed("tweedie")
  skip_on_cran()  # Slow test
  
  set.seed(123)
  test_data <- data.frame(
    Loss = rgamma(100, shape = 2, rate = 0.001),
    Premium = exp(rnorm(100, mean = 10, sd = 0.5)),
    AccidentYear = sample(1990:1995, 100, replace = TRUE)
  )
  
  # Run profile likelihood (limited range for speed)
  expect_silent({
    profile <- tweedie::tweedie.profile(
      Loss ~ AccidentYear + log(Premium),
      data = test_data,
      p.vec = seq(1.2, 1.8, by = 0.2),
      do.plot = FALSE,
      verbose = FALSE
    )
  })
  
  expect_true(!is.null(profile$p.max))
  expect_true(profile$p.max > 1 && profile$p.max < 2)
})
