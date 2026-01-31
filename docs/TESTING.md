# Testing and Validation Guide

## Overview

This project includes comprehensive unit tests and validation checks to ensure code reliability and model accuracy.

## Test Structure

```
tests/
├── testthat.R                    # testthat configuration
├── run_tests.R                   # Master test runner
└── testthat/                     # Test files
    ├── test-utils.R              # Utility function tests
    ├── test-validation.R         # Validation function tests
    ├── test-data-prep.R          # Data preparation tests
    ├── test-tweedie.R            # Tweedie modeling tests
    └── test-evt.R                # Extreme value theory tests
```

## Running Tests

### Run All Tests

```r
# From project root
source("tests/run_tests.R")
```

This will:
- Execute all unit tests
- Generate test summary report
- Save results to `results/tests/`
- Display pass/fail statistics

### Run Specific Test Files

```r
library(testthat)

# Test utilities
test_file("tests/testthat/test-utils.R")

# Test Tweedie modeling
test_file("tests/testthat/test-tweedie.R")

# Test EVT analysis
test_file("tests/testthat/test-evt.R")
```

### Run Tests for Specific Module

```r
# Test validation functions only
test_dir("tests/testthat", filter = "validation")

# Test data preparation only
test_dir("tests/testthat", filter = "data-prep")
```

## Validation Framework

### Built-in Validation Functions

The `src/validation.R` module provides:

#### 1. Data Validation
```r
# Validate raw CAS data
result <- validate_raw_data(raw_data)

# Validate prepared model data
result <- validate_model_data(model_data)
```

#### 2. Model Validation
```r
# Validate Tweedie model
result <- validate_tweedie_model(model, p_optimal)

# Validate EVT models
result <- validate_evt_models(gev_fit, gpd_fit)
```

#### 3. Prediction Validation
```r
# Check prediction accuracy
result <- validate_predictions(actual, predicted, tolerance_pct = 20)
```

### Running Analysis with Validation

```r
# Run analysis with automatic validation checks
source("run_analysis_with_validation.R")
```

This enhanced script:
- Validates data quality before modeling
- Checks model convergence and diagnostics
- Verifies prediction accuracy
- Generates validation report
- Stops if critical validations fail

## Test Coverage

### What's Tested

**Utility Functions:**
- Percentage error calculations
- Header/subheader printing
- Model diagnostic output

**Data Preparation:**
- Data structure and dimensions
- Missing value handling
- Transformation accuracy
- Aggregation correctness

**Tweedie Modeling:**
- Model fitting and convergence
- Parameter bounds (1 < p < 2)
- Prediction positivity
- Coefficient significance
- Diagnostic statistics

**Extreme Value Theory:**
- GEV parameter estimation
- GPD threshold exceedances
- Return level calculations
- Different shape parameter regimes

**Validation Functions:**
- Raw data quality checks
- Model data requirements
- Prediction error metrics
- Report generation

### Expected Test Results

```
Total Tests:      ~50-60
✅ Passed:        ~48-58
❌ Failed:        0
⚠️  Warnings:     0-2
⏭️  Skipped:      0-5 (if packages missing)
Success Rate:     95-100%
```

## Continuous Integration

### Pre-commit Checklist

Before committing code:

1. **Run all tests:**
   ```r
   source("tests/run_tests.R")
   ```

2. **Check validation report:**
   ```r
   source("run_analysis_with_validation.R")
   cat(readLines("results/validation_report.txt"), sep = "\n")
   ```

3. **Verify no warnings/errors:**
   - All tests should pass
   - Validation report should show ✅ PASSED

### Adding New Tests

When adding new functionality:

1. Create test file in `tests/testthat/`
2. Follow naming convention: `test-[module].R`
3. Use descriptive test names: `test_that("description", { ... })`
4. Test both happy path and edge cases
5. Run tests to verify they pass

Example test structure:
```r
test_that("function handles valid input correctly", {
  result <- my_function(valid_input)
  expect_equal(result, expected_output)
  expect_true(result > 0)
})

test_that("function handles edge cases", {
  expect_error(my_function(NULL))
  expect_warning(my_function(edge_case_input))
})
```

## Validation Report

The validation report includes:

- **Data Quality:** Checks for missing values, negative values, outliers
- **Model Diagnostics:** Convergence, parameter bounds, significance
- **Prediction Accuracy:** MAE, bias, extreme errors
- **EVT Parameters:** Scale positivity, shape reasonableness

Example report output:
```
================================================================================
VALIDATION REPORT
================================================================================

--- MODEL_DATA ---
✅ PASSED

Metrics:
  n_obs: 1166
  complete_cases: 1166
  loss_ratio_mean: 1.0234
  loss_cv: 2.1456

--- TWEEDIE_MODEL ---
✅ PASSED

Diagnostics:
  pseudo_r2: 0.9766
  aic: 24532.45
  resid_mean: 0.0012

--- TWEEDIE_PREDICTIONS ---
✅ PASSED

Metrics:
  mae_pct: 5.12
  bias_pct: 0.34

================================================================================
✅ ALL CHECKS PASSED
================================================================================
```

## Troubleshooting

### Tests Fail Due to Random Seed

Some tests use random data generation. If tests fail intermittently:
- Check if `set.seed()` is used consistently
- Increase tolerance in `expect_equal()` for numeric comparisons

### Package Installation Issues

If tests skip due to missing packages:
```r
install.packages(c("testthat", "tweedie", "evd", "statmod"))
```

### Validation Warnings (Not Errors)

Validation warnings don't stop analysis but indicate:
- Insignificant coefficients (may be OK)
- Minor systematic bias (<5%)
- Small sample sizes for EVT

Review warnings but proceed if not critical.

## Best Practices

1. **Always run tests before committing** code changes
2. **Use validation in production** analysis (not just testing)
3. **Document test failures** and fixes in commit messages
4. **Update tests** when adding new features
5. **Keep tolerance realistic** (not too strict, not too loose)

## References

- [testthat documentation](https://testthat.r-lib.org/)
- [R Package Testing](https://r-pkgs.org/testing-basics.html)
- Project-specific validation in `src/validation.R`
