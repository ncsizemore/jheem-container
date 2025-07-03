# create_ryan_white_workspace.R - Clean version with proper directory structure
# Runs from subdirectory where ../jheem_analyses/ naturally exists

args <- commandArgs(trailingOnly = TRUE)
if (length(args) == 0) {
  stop("Usage: Rscript create_ryan_white_workspace.R <output_workspace_file.RData>", call. = FALSE)
}
output_file <- args[1]

cat("🔧 Starting Ryan White workspace creation (clean directory structure)\n")
cat("📁 Output file:", output_file, "\n")
cat("📁 Working directory:", getwd(), "\n")

start_time <- Sys.time()

# Verify we're in the expected directory structure
if (!dir.exists("../jheem_analyses")) {
  cat("❌ Expected directory structure not found\n")
  cat("📁 Current directory:", getwd(), "\n")
  cat("🔍 Looking for: ../jheem_analyses/\n")
  cat("💡 This script should run from a subdirectory with jheem_analyses/ at parent level\n")
  quit(status = 1)
}

cat("✅ Directory structure verified: ../jheem_analyses/ found\n")

# 1. Load jheem2 and export internal functions
cat("📦 Loading jheem2 package...\n")
library(jheem2)
cat("✅ jheem2 version:", as.character(packageVersion("jheem2")), "\n")

cat("🔓 Exporting jheem2 internal functions...\n")
pkg_env <- asNamespace("jheem2")
internal_fns <- ls(pkg_env, all.names = TRUE)
functions_exported_count <- 0

for (fn_name in internal_fns) {
  if (exists(fn_name, pkg_env, inherits = FALSE)) {
    fn_obj <- get(fn_name, pkg_env, inherits = FALSE)
    if (is.function(fn_obj)) {
      assign(fn_name, fn_obj, envir = .GlobalEnv)
      functions_exported_count <- functions_exported_count + 1
    }
  }
}
cat("✅", functions_exported_count, "internal functions exported to .GlobalEnv\n")


use_package_file <- "../jheem_analyses/use_jheem2_package_setting.R"
ryan_white_spec_file <- "../jheem_analyses/applications/ryan_white/ryan_white_specification.R"



# 3. Source Ryan White model specification
cat("🧬 Loading Ryan White model specification...\n")
tryCatch(
  {
    source("../jheem_analyses/applications/ryan_white/ryan_white_specification.R")
    cat("✅ Ryan White specification loaded successfully\n")
  },
  error = function(e) {
    cat("❌ ERROR loading specification:", e$message, "\n")
    quit(status = 1)
  }
)

# 4. Verify key objects are available
cat("🔍 Verifying key objects...\n")
required_objects <- c("RW.SPECIFICATION", "RW.DATA.MANAGER")
missing_objects <- c()

for (obj_name in required_objects) {
  if (exists(obj_name, envir = .GlobalEnv)) {
    cat("✅", obj_name, "available\n")
  } else {
    cat("❌", obj_name, "MISSING\n")
    missing_objects <- c(missing_objects, obj_name)
  }
}

if (length(missing_objects) > 0) {
  cat("❌ FATAL: Missing required objects:", paste(missing_objects, collapse = ", "), "\n")
  quit(status = 1)
}

# 4.5 Capture VERSION.MANAGER state after registration
cat("\n📦 Capturing JHEEM2 VERSION.MANAGER state...\n")
tryCatch(
  {
    # First, let's investigate what's in VERSION.MANAGER
    vm <- asNamespace("jheem2")$VERSION.MANAGER
    
    if (!is.environment(vm)) {
      cat("❌ VERSION.MANAGER is not an environment\n")
      quit(status = 1)
    }
    
    # List what's in VERSION.MANAGER
    vm_names <- ls(vm, all.names = TRUE)
    cat("  VERSION.MANAGER contains", length(vm_names), "elements:\n")
    cat("  Elements:", paste(vm_names, collapse = ", "), "\n")
    
    # Check if 'rw' version is registered
    if ("versions" %in% vm_names && "rw" %in% vm$versions) {
      cat("  ✅ 'rw' version is registered\n")
      
      # Test serialization
      cat("\n  🧪 Testing VERSION.MANAGER serialization...\n")
      test_state <- as.list(vm)
      
      # Try to save and reload to test
      test_file <- tempfile(fileext = ".rds")
      saveRDS(test_state, test_file)
      restored <- readRDS(test_file)
      unlink(test_file)
      
      if (identical(names(test_state), names(restored))) {
        cat("  ✅ Serialization test passed\n")
        
        # Now create the hidden object with SELECTIVE state capture
        # Only capture the essential elements needed for 'rw' version
        essential_elements <- c("versions", "specification", "set.parameters", 
                                "apply.set.parameters.function", "prior.versions")
        
        selective_state <- list()
        for (elem in essential_elements) {
          if (elem %in% names(test_state)) {
            selective_state[[elem]] <- test_state[[elem]]
          }
        }
        
        .jheem2_state <- list(
          version_manager = selective_state,
          captured_at = Sys.time(),
          jheem2_version = packageVersion("jheem2"),
          n_elements = length(selective_state),
          capture_mode = "selective"
        )
        
        # Save to global environment
        assign(".jheem2_state", .jheem2_state, envir = .GlobalEnv)
        
        cat("  ✅ VERSION.MANAGER state captured in .jheem2_state\n")
        cat("  📊 Captured", .jheem2_state$n_elements, "VERSION.MANAGER elements\n")
        
        # Show some details about what we captured
        if (!is.null(vm$specification$rw)) {
          cat("  ✅ RW specification captured\n")
        }
        if (!is.null(vm$set.parameters$rw)) {
          cat("  ✅ RW parameters registration captured\n")
        }
        
      } else {
        cat("  ❌ Serialization test failed - names don't match\n")
        cat("  Original names:", paste(names(test_state), collapse = ", "), "\n")
        cat("  Restored names:", paste(names(restored), collapse = ", "), "\n")
      }
      
    } else {
      cat("  ⚠️ 'rw' version not found in VERSION.MANAGER\n")
      cat("  Registered versions:", paste(vm$versions, collapse = ", "), "\n")
    }
    
  },
  error = function(e) {
    cat("❌ ERROR capturing VERSION.MANAGER state:", e$message, "\n")
    cat("  Continuing without VERSION.MANAGER capture...\n")
  }
)

# =============================================================
# CORRECTED VERSION of Sections 5 and 6
# =============================================================

# 5. Save workspace to the path provided by the command line argument
cat("💾 Saving workspace to", output_file, "...\n")
file_size_mb <- NA # Initialize in case tryCatch fails before assignment

tryCatch(
  {
    save.image(file = output_file)

    # Check file size using the correct path
    file_size <- file.info(output_file)$size
    file_size_mb <- round(file_size / 1024^2, 2)
    cat("✅ Workspace saved successfully\n")
    cat("📊 File size:", file_size_mb, "MB\n")
  },
  error = function(e) {
    cat("❌ ERROR saving workspace:", e$message, "\n")
    quit(status = 1)
  }
)

# 6. Final summary
end_time <- Sys.time()
total_time <- as.numeric(difftime(end_time, start_time, units = "secs"))
current_objects <- ls(envir = .GlobalEnv)

cat("\n🎯 Ryan White workspace creation complete!\n")
cat("⏱️  Total time:", round(total_time, 2), "seconds\n")
cat("📁 Output file:", output_file, "\n") # Use the correct variable
cat("📊 File size:", file_size_mb, "MB\n") # Use the correct variable
cat("🔧 Objects included:", length(current_objects), "\n")
cat("✅ Ready for container deployment\n")
