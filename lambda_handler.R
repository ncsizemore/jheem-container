# Lambda handler using workspace approach
# Fast startup - just load workspace and handle requests

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

# Handler function for simulation requests
handle_simulation_request <- function(event, context) {
  cat("📥 Received simulation request\n")
  
  tryCatch({
    # Parse request parameters
    city <- event$city %||% "C.12580"
    parameters <- event$parameters %||% list(
      adap_suppression_loss = 30,
      oahs_suppression_loss = 25,
      other_suppression_loss = 40
    )
    
    cat("🏙️ Processing simulation for city:", city, "\n")
    
    # TODO: Load base simulation from S3
    # TODO: Apply custom parameters  
    # TODO: Run simulation
    # TODO: Generate plots
    
    # For now, return success with workspace info
    response <- list(
      statusCode = 200,
      body = list(
        message = "Ryan White simulation handler ready",
        city = city,
        parameters = parameters,
        workspace_objects = length(ls()),
        specification_available = exists("RW.SPECIFICATION"),
        timestamp = Sys.time()
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

# For testing outside Lambda
if (interactive() || !exists("lambda_runtime")) {
  cat("🧪 Testing handler locally...\n")
  
  test_event <- list(
    city = "C.12580",
    parameters = list(
      adap_suppression_loss = 50,
      oahs_suppression_loss = 30,
      other_suppression_loss = 40
    )
  )
  
  result <- handle_simulation_request(test_event, NULL)
  cat("📤 Handler result:\n")
  cat(result, "\n")
}

cat("✅ Ryan White Lambda handler ready\n")
