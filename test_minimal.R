# Test script to validate plotting functionality in minimal environment
# This will help us identify missing dependencies before containerizing

cat("🧪 Testing minimal JHEEM plotting environment...\n")

# Test 1: Basic package loading
cat("📦 Testing package imports...\n")
tryCatch({
  library(jheem2)
  library(plotly) 
  library(jsonlite)
  library(locations)
  cat("✅ Core packages loaded\n")
}, error = function(e) {
  cat("❌ Package loading failed:", e$message, "\n")
  quit(status = 1)
})

# Test 2: Check if we can load model specification
cat("🔧 Testing model specification loading...\n")
tryCatch({
  # We'll need to copy the specification files here
  # For now, just test jheem2 basic functionality
  
  # Test basic jheem2 functions are available
  if (!exists("create.jheem.specification", envir = asNamespace("jheem2"))) {
    stop("create.jheem.specification not found in jheem2")
  }
  
  cat("✅ jheem2 functions accessible\n")
}, error = function(e) {
  cat("❌ Model specification test failed:", e$message, "\n")
  # Don't quit - this might be expected without full setup
})

# Test 3: Basic plotting capability
cat("📊 Testing basic plotting...\n")
tryCatch({
  # Create simple test plot
  test_data <- data.frame(
    x = 1:10,
    y = rnorm(10)
  )
  
  p <- plotly::plot_ly(test_data, x = ~x, y = ~y, type = 'scatter', mode = 'lines')
  
  # Test JSON serialization
  json_output <- jsonlite::toJSON(list(
    data = p$x$data,
    layout = p$x$layout
  ), auto_unbox = TRUE)
  
  cat("✅ Basic plotting and JSON export work\n")
}, error = function(e) {
  cat("❌ Plotting test failed:", e$message, "\n")
})

# Test 4: locations package functionality  
cat("🗺️ Testing locations package...\n")
tryCatch({
  # Test basic locations functions
  if (exists("get.location.type", envir = asNamespace("locations"))) {
    cat("✅ locations package functions available\n")
  } else {
    cat("⚠️ locations package loaded but functions not found\n")
  }
}, error = function(e) {
  cat("❌ locations test failed:", e$message, "\n")
})

cat("🎯 Minimal environment test complete!\n")
cat("Next steps:\n")
cat("  1. Copy model specification files\n") 
cat("  2. Copy plotting utilities\n")
cat("  3. Test with actual simulation data\n")
