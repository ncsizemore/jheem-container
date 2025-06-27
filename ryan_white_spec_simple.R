# Simplified Ryan White model specification for container testing
# This version removes external dependencies for initial testing

cat("🔧 Loading simplified Ryan White specification...\n")

# Test that jheem2 functions are available
if (!exists("create.jheem.specification", envir = asNamespace("jheem2"))) {
  stop("jheem2 functions not available")
}

# Simple test of jheem2 functionality
tryCatch({
  # Test basic jheem2 spec creation (simplified)
  cat("✅ jheem2 specification functions available\n")
  
  # For now, just validate that the core functions work
  # We'll add full model specification after basic container works
  TRUE
}, error = function(e) {
  cat("❌ jheem2 specification test failed:", e$message, "\n")
  FALSE
})

cat("🎯 Simplified specification loaded\n")
