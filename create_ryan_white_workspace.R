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

# 2. Apply the same path fixes as setup_local_dev.sh
cat("🔧 Applying path fixes (same as setup_local_dev.sh)...\n")

use_package_file <- "../jheem_analyses/use_jheem2_package_setting.R"
ryan_white_spec_file <- "../jheem_analyses/applications/ryan_white/ryan_white_specification.R"

# Fix 1: Update USE.JHEEM2.PACKAGE setting
if (file.exists(use_package_file)) {
  system(paste0("sed -i '' 's/USE.JHEEM2.PACKAGE = F/USE.JHEEM2.PACKAGE = T/' '", use_package_file, "'"))
  cat("✅ Updated USE.JHEEM2.PACKAGE setting\n")
} else {
  cat("⚠️  USE.JHEEM2.PACKAGE file not found, skipping\n")
}

# Fix 2: Update RW.DATA.MANAGER path
if (file.exists(ryan_white_spec_file)) {
  system(paste0("sed -i '' 's|../../cached/ryan.white.data.manager.rdata|../jheem_analyses/cached/ryan.white.data.manager.rdata|' '", ryan_white_spec_file, "'"))
  cat("✅ Updated RW.DATA.MANAGER path\n")
} else {
  cat("❌ Ryan White specification file not found\n")
  quit(status = 1)
}

# 3. Source Ryan White model specification
cat("🧬 Loading Ryan White model specification...\n")
tryCatch({
  source("../jheem_analyses/applications/ryan_white/ryan_white_specification.R")
  cat("✅ Ryan White specification loaded successfully\n")
}, error = function(e) {
  cat("❌ ERROR loading specification:", e$message, "\n")
  quit(status = 1)
})

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

# 5. Save workspace to parent directory (where it's expected)
workspace_path <- paste0("../", output_file)
cat("💾 Saving workspace to", workspace_path, "...\n")
tryCatch({
  save.image(file = workspace_path)
  
  # Check file size
  file_size <- file.info(workspace_path)$size
  file_size_mb <- round(file_size / 1024^2, 2)
  cat("✅ Workspace saved successfully\n")
  cat("📊 File size:", file_size_mb, "MB\n")
  
}, error = function(e) {
  cat("❌ ERROR saving workspace:", e$message, "\n")
  quit(status = 1)
})

# 6. Final summary
end_time <- Sys.time()
total_time <- as.numeric(difftime(end_time, start_time, units = "secs"))
current_objects <- ls(envir = .GlobalEnv)

cat("\n🎯 Ryan White workspace creation complete!\n")
cat("⏱️  Total time:", round(total_time, 2), "seconds\n")
cat("📁 Output file:", workspace_path, "\n")
cat("📊 File size:", file_size_mb, "MB\n")
cat("🔧 Objects included:", length(current_objects), "\n")
cat("✅ Ready for container deployment\n")
