# Three-stage Dockerfile - build from parent directory version
# Assumes build context includes both jheem-container-minimal/ and jheem/code/

# =============================================================================
# STAGE 1: Base R Environment (Reusable across models)
# =============================================================================
FROM r-base:4.4.2 AS jheem-base

# Install system dependencies and create compatibility symlinks for RSPM binaries
RUN apt-get update && apt-get install -y \
  build-essential \
  libcurl4-openssl-dev \
  libssl-dev \
  libxml2-dev \
  libgit2-dev \
  libgdal-dev \
  libproj-dev \
  zlib1g-dev \
  libicu-dev \
  pkg-config \
  libfreetype6-dev \
  libpng-dev \
  libjpeg-dev \
  libtiff5-dev \
  libtiff6 \
  libjpeg62-turbo \
  libpng16-16 \
  libfreetype6 \
  libfontconfig1-dev \
  && rm -rf /var/lib/apt/lists/* \
  && ln -s /usr/lib/x86_64-linux-gnu/libtiff.so.6 /usr/lib/x86_64-linux-gnu/libtiff.so.5 \
  && ln -s /usr/lib/x86_64-linux-gnu/libjpeg.so.62 /usr/lib/x86_64-linux-gnu/libjpeg.so.8

# Install pak for faster package management
RUN R -e "install.packages('pak', repos = 'https://r-lib.github.io/p/pak/stable/')"

# Set up working directory
WORKDIR /app

# Copy renv lockfile and configure RSPM for binaries
COPY jheem-container-minimal/renv.lock ./
COPY jheem-container-minimal/Rprofile.site /etc/R/

# Install renv and check ICU version before restoring packages
RUN R -e "pak::pkg_install('renv')" && \
  R -e "renv::init(bare = TRUE)"

# Debug: Check ICU version before attempting package restore
RUN echo "🔍 Checking ICU version..." && \
  pkg-config --modversion icu-i18n || echo "pkg-config failed" && \
  ls -la /usr/lib/x86_64-linux-gnu/libicu* || echo "libicu files not found in x86_64-linux-gnu" && \
  ls -la /usr/lib/libicu* || echo "libicu files not found in /usr/lib"

# Install packages: problematic ones from source, others as binaries
RUN echo "📦 Installing stringi from source with bundled ICU..." && \
  R -e "options(configure.args = c(stringi = '--disable-pkg-config')); install.packages('stringi', type = 'source'); cat('✅ stringi installed from source\n')" && \
  echo "📦 Installing graphics packages from source..." && \
  R -e "install.packages(c('systemfonts', 'textshaping'), type = 'binary'); cat('✅ ragg dependencies installed as binaries\n')" && \
  R -e "install.packages(c('ragg', 'jpeg'), type = 'source', dependencies = FALSE); cat('✅ graphics packages installed from source\n')" && \
  echo "📦 Installing remaining packages as binaries..." && \
  R -e "renv::restore()" && \
  echo "✅ All packages installed successfully"

# Test that all packages are working
RUN R --slave -e "\
  library(jheem2); \
  library(plotly); \
  library(jsonlite); \
  library(locations); \
  cat('✅ Base R environment ready\\n')"

# =============================================================================
# STAGE 2: Workspace Builder (Corrected Logic)
# =============================================================================
FROM jheem-base AS workspace-builder

# Set the WORKDIR to /app to inherit the renv context.
# We will NOT change this WORKDIR for the rest of this stage.
WORKDIR /app

# Copy necessary source files for building the workspace.
COPY jheem/code/jheem_analyses/ jheem_analyses/
# No need to copy jheem2_interactive source if it's installed as a package.
# The create script now resides in the project root.
COPY jheem-container-minimal/create_ryan_white_workspace.R ./

# Apply path fixes (no change here)
RUN echo "🔧 Applying path fixes..." && \
  sed -i 's/USE.JHEEM2.PACKAGE = F/USE.JHEEM2.PACKAGE = T/' jheem_analyses/use_jheem2_package_setting.R && \
  # The path fix for the rdata file may need adjustment now that we run from /app
  sed -i 's|../../cached/ryan.white.data.manager.rdata|jheem_analyses/cached/ryan.white.data.manager.rdata|' jheem_analyses/applications/ryan_white/ryan_white_specification.R && \
  echo "✅ Path fixes applied"

# Create the workspace by running the script from the project root.
# Because R is started in /app where the .Rprofile (from the base stage) exists,
# renv will be activated automatically and will find all the installed packages.
RUN echo "🔧 Creating workspace..." && \
  Rscript create_ryan_white_workspace.R ryan_white_workspace.RData

# Verify workspace was created in /app (no need to move it)
RUN R --slave -e "\
  if (!file.exists('ryan_white_workspace.RData')) { \
  cat('❌ Workspace file not found\\n'); \
  quit(status = 1); \
  }; \
  file_size_mb <- round(file.info('ryan_white_workspace.RData')\$size / 1024^2, 2); \
  cat('✅ Workspace created:', file_size_mb, 'MB\\n')"

# The final stage will then copy the workspace from /app/ryan_white_workspace.RData

# =============================================================================
# STAGE 3: Final Runtime Container (Minimal)
# =============================================================================
FROM jheem-base AS ryan-white-model

# Copy only the generated workspace from builder stage
COPY --from=workspace-builder /app/ryan_white_workspace.RData ./

# Copy runtime scripts from container directory
COPY jheem-container-minimal/lambda_handler.R ./
COPY jheem-container-minimal/plotting_minimal.R ./

# Test that workspace loads correctly in final container
RUN R --slave -e "\
  cat('🧪 Testing workspace loading in final container...\\n'); \
  system.time(load('ryan_white_workspace.RData')); \
  cat('✅ Workspace loaded with', length(ls()), 'objects\\n'); \
  cat('✅ RW.SPECIFICATION available:', exists('RW.SPECIFICATION'), '\\n'); \
  cat('✅ RW.DATA.MANAGER available:', exists('RW.DATA.MANAGER'), '\\n'); \
  source('plotting_minimal.R'); \
  if (test_plotting_functionality()) { \
  cat('✅ Plotting functionality working\\n'); \
  } else { \
  cat('❌ Plotting test failed\\n'); \
  quit(status = 1); \
  }"

# Set up for Lambda runtime
EXPOSE 8080
CMD ["R", "--slave", "-e", "source('lambda_handler.R')"]

# =============================================================================
# Build Instructions:
#
# cd /Users/cristina/wiley/Documents/
# docker build -f jheem-container-minimal/Dockerfile --target workspace-builder -t workspace-test .
# =============================================================================