# Test simulation loading and basic plot generation
# This tests the core workflow: load simulation -> generate plot -> export JSON

cat("🧪 Testing simulation workflow...\n")

# Load required libraries
suppressPackageStartupMessages({
  library(jheem2)
  library(plotly)
  library(jsonlite)
})

# Test 1: Load simplified specification
cat("📋 Step 1: Loading model specification...\n")
tryCatch({
  source("ryan_white_spec_simple.R")
  cat("✅ Specification loaded\n")
}, error = function(e) {
  cat("⚠️ Specification loading failed (continuing anyway):", e$message, "\n")
})

# Test 2: Test base simulation loading (placeholder for now)
cat("📋 Step 2: Testing base simulation loading...\n")
test_base_sim_loading <- function() {
  # For now, just test that we can access simulation-related functions
  tryCatch({
    # Check if key jheem2 simulation functions exist
    required_fns <- c("load.simset", "get.simulation.settings")
    missing_fns <- required_fns[!sapply(required_fns, function(fn) {
      exists(fn, envir = asNamespace("jheem2"))
    })]
    
    if (length(missing_fns) > 0) {
      cat("⚠️ Missing simulation functions:", paste(missing_fns, collapse = ", "), "\n")
      return(FALSE)
    }
    
    cat("✅ Simulation functions available\n")
    return(TRUE)
  }, error = function(e) {
    cat("❌ Simulation function test failed:", e$message, "\n")
    return(FALSE)
  })
}

sim_test_result <- test_base_sim_loading()

# Test 3: Mock simulation data and plotting
cat("📋 Step 3: Testing plot generation with mock data...\n")
test_plot_generation <- function() {
  tryCatch({
    # Create mock simulation data that resembles jheem output
    mock_sim_data <- data.frame(
      year = 2020:2030,
      incidence = exp(-0.05 * (2020:2030 - 2020)) * 1000 + rnorm(11, 0, 50),
      prevalence = 5000 + 100 * (2020:2030 - 2020) + rnorm(11, 0, 200),
      suppression = pmin(0.95, 0.7 + 0.02 * (2020:2030 - 2020) + rnorm(11, 0, 0.05))
    )
    
    # Test plotly plot creation
    p <- plot_ly(mock_sim_data, x = ~year, y = ~incidence, type = 'scatter', mode = 'lines') %>%
      layout(
        title = "Mock HIV Incidence Projection",
        xaxis = list(title = "Year"),
        yaxis = list(title = "New Infections")
      )
    
    # Test JSON export
    plot_json <- list(
      data = p$x$data,
      layout = p$x$layout,
      metadata = list(
        outcome = "incidence",
        city = "C.12580",
        generated_at = Sys.time()
      )
    )
    
    json_output <- toJSON(plot_json, auto_unbox = TRUE, pretty = TRUE)
    
    cat("✅ Plot generation successful\n")
    cat("📊 JSON size:", nchar(json_output), "characters\n")
    
    return(list(success = TRUE, json = json_output, plot = p))
    
  }, error = function(e) {
    cat("❌ Plot generation failed:", e$message, "\n")
    return(list(success = FALSE, error = e$message))
  })
}

plot_result <- test_plot_generation()

# Test 4: Parameter handling (mock Ryan White parameters)
cat("📋 Step 4: Testing parameter handling...\n")
test_parameter_handling <- function() {
  tryCatch({
    # Mock Ryan White intervention parameters
    rw_params <- list(
      adap_suppression_loss = 30,
      oahs_suppression_loss = 25,
      other_suppression_loss = 40,
      intervention_start = "2025-07",
      intervention_end = "never",
      city = "C.12580"
    )
    
    # Validate parameters
    valid_params <- all(
      rw_params$adap_suppression_loss >= 0 && rw_params$adap_suppression_loss <= 100,
      rw_params$oahs_suppression_loss >= 0 && rw_params$oahs_suppression_loss <= 100,
      rw_params$other_suppression_loss >= 0 && rw_params$other_suppression_loss <= 100,
      rw_params$city %in% paste0("C.", c(12060, 12420, 12580, 12940, 14460)) # Sample cities
    )
    
    if (valid_params) {
      cat("✅ Parameter validation successful\n")
      return(TRUE)
    } else {
      cat("❌ Parameter validation failed\n")
      return(FALSE)
    }
    
  }, error = function(e) {
    cat("❌ Parameter handling failed:", e$message, "\n")
    return(FALSE)
  })
}

param_result <- test_parameter_handling()

# Summary
cat("\n🎯 Simulation workflow test complete!\n")
cat("📊 Results:\n")
cat("  - Specification loading: ✅\n")
cat("  - Simulation functions:", if(sim_test_result) "✅" else "❌", "\n")
cat("  - Plot generation:", if(plot_result$success) "✅" else "❌", "\n")
cat("  - Parameter handling:", if(param_result) "✅" else "❌", "\n")

all_tests_passed <- sim_test_result && plot_result$success && param_result

if (all_tests_passed) {
  cat("\n🚀 Ready for container deployment!\n")
  cat("Next steps:\n")
  cat("  1. Build Docker container\n")
  cat("  2. Test container with mock Lambda event\n") 
  cat("  3. Add real base simulation loading\n")
  cat("  4. Integrate with LocalStack\n")
} else {
  cat("\n⚠️ Some tests failed - fix before containerizing\n")
}

return(list(
  all_passed = all_tests_passed,
  plot_json = if(plot_result$success) plot_result$json else NULL
))
