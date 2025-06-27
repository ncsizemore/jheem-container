# Test workspace creation with clean directory structure
# Sets up the expected file layout before testing

cat("🧪 Testing workspace creation with clean directory structure...\n")

jheem_analyses_source <- "/Users/cristina/wiley/Documents/jheem/code/jheem_analyses"
build_subdir <- "workspace_build"

cat("📁 Current directory:", getwd(), "\n")

# Clean up any existing test setup
if (dir.exists("jheem_analyses")) {
  cat("🧹 Removing existing jheem_analyses...\n")
  unlink("jheem_analyses", recursive = TRUE)
}
if (dir.exists(build_subdir)) {
  cat("🧹 Removing existing build directory...\n")
  unlink(build_subdir, recursive = TRUE)
}

# Set up clean directory structure
cat("📋 Setting up directory structure...\n")

# 1. Copy jheem_analyses to current directory (parent level)
cat("📂 Copying jheem_analyses to parent level...\n")
copy_result <- system(paste("cp -r", jheem_analyses_source, "jheem_analyses"))
if (copy_result != 0) {
  cat("❌ Failed to copy jheem_analyses\n")
  stop("Copy failed")
}

# 2. Create build subdirectory
cat("📁 Creating build subdirectory...\n")
dir.create(build_subdir)

# 3. Copy workspace creation script to build directory
file.copy("create_ryan_white_workspace.R", file.path(build_subdir, "create_ryan_white_workspace.R"))

# 4. Test the workspace creation from the build directory
cat("🔧 Testing workspace creation from proper directory structure...\n")
cat("📁 Structure:\n")
cat("   jheem-container-minimal/\n")
cat("   ├── jheem_analyses/           # ← copied here\n")
cat("   └── workspace_build/          # ← running from here\n")
cat("       └── create_ryan_white_workspace.R\n\n")

# Change to build directory and run script
original_dir <- getwd()
setwd(build_subdir)

system_result <- system("Rscript create_ryan_white_workspace.R test_workspace.RData", intern = FALSE)

# Change back to test results
setwd(original_dir)

if (system_result == 0) {
  cat("✅ Workspace creation script succeeded\n")
  
  # Test loading the workspace
  workspace_file <- "test_workspace.RData"
  if (file.exists(workspace_file)) {
    cat("🧪 Testing workspace loading...\n")
    
    # Test in fresh R session
    test_result <- system(paste('R --slave -e "
      load(\\"', workspace_file, '\\")
      cat(\\"✅ Workspace loaded with\\", length(ls()), \\"objects\\\\n\\")
      cat(\\"✅ RW.SPECIFICATION available:\\", exists(\\"RW.SPECIFICATION\\"), \\"\\\\n\\")
      cat(\\"✅ RW.DATA.MANAGER available:\\", exists(\\"RW.DATA.MANAGER\\"), \\"\\\\n\\")
      
      file_size_mb <- round(file.info(\\"', workspace_file, '\\")\\$size / 1024^2, 2)
      cat(\\"📊 Workspace size:\\", file_size_mb, \\"MB\\\\n\\")
      
      quit(status = 0)
    "', sep = ""), intern = FALSE)
    
    if (test_result == 0) {
      cat("✅ Workspace loading test passed\n")
    } else {
      cat("❌ Workspace loading test failed\n")
    }
    
    # Clean up test file
    file.remove(workspace_file)
    cat("🧹 Test workspace file cleaned up\n")
    
  } else {
    cat("❌ Workspace file was not created\n")
  }
} else {
  cat("❌ Workspace creation script failed with exit code:", system_result, "\n")
}

# Clean up test setup
cat("🧹 Cleaning up test files...\n")
if (dir.exists("jheem_analyses")) {
  unlink("jheem_analyses", recursive = TRUE)
}
if (dir.exists(build_subdir)) {
  unlink(build_subdir, recursive = TRUE)
}

cat("\n🎯 Clean directory structure test complete!\n")
cat("✅ Original files were not modified\n")
cat("Next step: Update Dockerfile to use this clean approach\n")
