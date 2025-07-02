# lambda_handler.R
# Clean entry point for JHEEM Ryan White Lambda container
# Loads workspace and coordinates simulation pipeline

cat("🚀 JHEEM Ryan White Lambda handler starting...\n")

# Load the pre-built workspace (contains RW.SPECIFICATION, data managers, etc.)
cat("📦 Loading Ryan White workspace...\n")
system.time({
  load("ryan_white_workspace.RData")
  
  # Export internal jheem2 functions (needed for specifications)
  pkg_env <- asNamespace("jheem2")
  internal_fns <- ls(pkg_env, all.names = TRUE)
  for (fn in internal_fns) {
    if (exists(fn, pkg_env, inherits = FALSE) && is.function(get(fn, pkg_env))) {
      assign(fn, get(fn, pkg_env), envir = .GlobalEnv)
    }
  }
})

cat("✅ Workspace loaded with", length(ls()), "objects\n")
cat("✅ RW.SPECIFICATION available:", exists("RW.SPECIFICATION"), "\n")

# Load plotting utilities
source("plotting_minimal.R")

# Load simulation pipeline modules
source("simulation/interventions.R")
source("simulation/runner.R") 
source("plotting/plot_generator.R")

# Load test module
source("tests/test_simulation.R")

# ============================================================================
# LAMBDA HANDLER FUNCTION
# ============================================================================

#' Main Lambda handler function
#' @param event Lambda event object with city, base_simulation_path, parameters
#' @param context Lambda context object
#' @return JSON response with results or error
handle_simulation_request <- function(event, context) {
  cat("📥 Received simulation request\n")
  
  tryCatch({
    # Parse request parameters
    city <- event$city %||% "C.12580"
    base_simulation_path <- event$base_simulation_path %||% "/tmp/base_simulation.rdata"
    parameters <- event$parameters %||% list(
      adap_suppression_loss = 30,
      oahs_suppression_loss = 25,
      other_suppression_loss = 40
    )
    
    cat("🏙️ Processing simulation for city:", city, "\n")
    cat("📁 Base simulation path:", base_simulation_path, "\n")
    
    # Check that base simulation file exists
    if (!file.exists(base_simulation_path)) {
      stop("Base simulation file not found: ", base_simulation_path)
    }
    
    # Step 1: Load base simulation (already downloaded by trigger lambda)
    cat("📦 Loading base simulation data...\n")
    load(base_simulation_path)
    base_simset <- get(ls()[1])  # Get the first (and should be only) object
    cat("✅ Base simulation loaded with", length(base_simset), "simulations\n")
    
    # Validate parameters
    validate_intervention_parameters(parameters)
    
    # Step 2: Create Ryan White intervention
    cat("🔧 Creating Ryan White intervention...\n")
    intervention <- create_ryan_white_intervention(parameters)
    
    # Step 3: Run simulation  
    cat("🚀 Running custom simulation...\n")
    results <- run_custom_simulation(base_simset, intervention)
    
    # Step 4: Generate plots
    cat("📊 Generating plots...\n")
    plots <- generate_simulation_plots(results, city, parameters)
    
    # Return success response
    response <- list(
      statusCode = 200,
      body = list(
        message = "Ryan White simulation completed successfully",
        city = city,
        parameters = parameters,
        plots = plots,
        metadata = list(
          workspace_objects = length(ls()),
          specification_available = exists("RW.SPECIFICATION"),
          timestamp = Sys.time()
        )
      )
    )
    
    return(toJSON(response, auto_unbox = TRUE, pretty = TRUE))
    
  }, error = function(e) {
    cat("❌ Handler error:", e$message, "\n")
    
    error_response <- list(
      statusCode = 500,
      body = list(
        error = paste("Simulation error:", e$message),
        timestamp = Sys.time()
      )
    )
    return(toJSON(error_response, auto_unbox = TRUE))
  })
}

# ============================================================================
# TESTING (when not in Lambda environment)
# ============================================================================
if (interactive() || !exists("lambda_runtime")) {
  cat("🧪 Testing handler locally...\n")
  
  # Test the complete pipeline
  test_results <- test_simulation_pipeline("/app/test_base_sim.rdata")
  
  if (test_results$success) {
    cat("📤 Running handler test...\n")
    
    test_event <- list(
      city = "C.12580",
      base_simulation_path = "/app/test_base_sim.rdata",
      parameters = list(
        adap_suppression_loss = 50,
        oahs_suppression_loss = 30,
        other_suppression_loss = 40
      )
    )
    
    result <- handle_simulation_request(test_event, NULL)
    cat("📤 Handler result:\n")
    cat(substr(result, 1, 500), "...\n")  # Show first 500 chars
  } else {
    cat("❌ Pipeline test failed, skipping handler test\n")
  }
}

cat("✅ Ryan White Lambda handler ready\n")
