# Copy essential specification files to container directory
# This identifies which files we actually need for Ryan White model

cat("📋 Identifying required specification files...\n")

# The files we need to copy from jheem_analyses:
required_files <- list(
  # Core specification
  "ryan_white_specification.R" = "/Users/cristina/wiley/Documents/jheem/code/jheem_analyses/applications/ryan_white/ryan_white_specification.R",
  
  # Dependencies (we'll need to trace these)
  "ehe_specification.R" = "/Users/cristina/wiley/Documents/jheem/code/jheem_analyses/applications/EHE/ehe_specification.R",
  "ryan_white_specification_helpers.R" = "/Users/cristina/wiley/Documents/jheem/code/jheem_analyses/applications/ryan_white/ryan_white_specification_helpers.R",
  "ryan_white_parameters.R" = "/Users/cristina/wiley/Documents/jheem/code/jheem_analyses/applications/ryan_white/ryan_white_parameters.R"
)

# Check which files exist
cat("📁 Checking file availability:\n")
for (name in names(required_files)) {
  path <- required_files[[name]]
  if (file.exists(path)) {
    cat("  ✅", name, "\n")
  } else {
    cat("  ❌", name, "- NOT FOUND\n")
  }
}

# The approach:
# 1. Copy these files to the container directory
# 2. Modify paths to be relative (remove ../ references)
# 3. Pre-source them in the container build

cat("\n🎯 Next steps:\n")
cat("  1. Copy required .R files to container directory\n")  
cat("  2. Fix relative path references\n")
cat("  3. Build container with pre-loaded specifications\n")
cat("  4. Test simulation loading\n")
