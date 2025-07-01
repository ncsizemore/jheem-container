# JHEEM Ryan White Docker Container

This repository contains the Docker containerization for the JHEEM Ryan White HIV simulation model, designed to replace the existing Shiny application with a serverless Lambda-based architecture.

## 🚀 Quick Start

### Using Pre-built Image (Recommended)
```bash
# Pull the latest image from DockerHub
docker pull ncsizemore/jheem-ryan-white-model:latest

# Run locally for testing
docker run -p 8080:8080 ncsizemore/jheem-ryan-white-model:latest
```

### Building from Source

**Directory Structure Required:**
```
Documents/
├── jheem/
│   └── code/
│       └── jheem_analyses/        # Source JHEEM analysis files
└── jheem-container-minimal/       # This repository
    ├── Dockerfile
    ├── renv.lock
    └── ...
```

**Build Commands:**
```bash
# Navigate to the Documents directory (parent of both repositories)
cd /Users/[username]/wiley/Documents/

# Build the complete pipeline
docker build -f jheem-container-minimal/Dockerfile -t jheem-ryan-white-model .

# Or build just to test workspace creation
docker build -f jheem-container-minimal/Dockerfile --target workspace-builder -t workspace-test .
```

## 🏗️ Architecture

### Multi-Stage Build Process

1. **`jheem-base`** - Foundation layer with R, system dependencies, and all R packages
2. **`workspace-builder`** - Creates the Ryan White workspace (`ryan_white_workspace.RData`)
3. **`ryan-white-model`** - Final runtime container with workspace and Lambda handler

### Key Technical Features

- **Hybrid Package Installation**: Fast binaries where possible, source compilation for compatibility
- **Strategic Library Symlinks**: Resolves version mismatches between RSPM binaries and system libraries
- **Cross-Platform Support**: Works on both Intel (x86_64) and Apple Silicon (ARM64)
- **Optimized Performance**: Fast workspace loading for Lambda deployment

## 📦 Package Installation Strategy

The container uses a sophisticated approach to handle R package dependencies:

```dockerfile
# 1. Install most packages as fast binaries
RUN renv::install(c('units', 'gert', 'V8'))

# 2. Install ABI-incompatible packages from source  
RUN renv::install('sf', type = 'source')

# 3. Restore remaining packages as binaries
RUN renv::restore()
```

This minimizes build time while ensuring compatibility.

## 🔧 System Dependencies

The container includes comprehensive system libraries to support R packages:

- **Graphics**: `libfreetype6-dev`, `libpng-dev`, `libjpeg-dev`, `libtiff5-dev`
- **Geospatial**: `libgdal-dev`, `libproj-dev` 
- **Network**: `libcurl4-openssl-dev`, `libssl-dev`
- **Development**: `libgit2-dev`, `libnode-dev`, `cmake`
- **Text/Locale**: `libicu-dev`, `libfontconfig1-dev`

## 🌐 Repository Configuration

Uses Posit Package Manager for fast binary installation:

```r
# In Rprofile.site
options(repos = "https://packagemanager.posit.co/cran/__linux__/bookworm/latest")
options(renv.config.repos.override = r)  # Forces renv to use RSPM
```

## 🎯 Performance Targets

- **Image Size**: ~5.2 GB (well within 10 GB Lambda limit)
- **Memory Usage**: Designed for Lambda deployment with sufficient memory allocation

## 🔄 Development Workflow

### Local Development
```bash
# Pull latest image for development
docker pull ncsizemore/jheem-ryan-white-model:latest

# Test Lambda handler locally
docker run -p 8080:8080 ncsizemore/jheem-ryan-white-model:latest

# Enter interactive terminal in the container
docker run -it --rm ncsizemore/jheem-ryan-white-model:latest /bin/bash

# Run R interactively inside the container
docker run -it --rm ncsizemore/jheem-ryan-white-model:latest R
```

### Building Updates
```bash
# Build and tag new version
docker build -f jheem-container-minimal/Dockerfile -t ncsizemore/jheem-ryan-white-model:v1.1 .

# Push to DockerHub
docker push ncsizemore/jheem-ryan-white-model:v1.1
```

## 📁 File Structure

```
jheem-container-minimal/
├── Dockerfile                          # Multi-stage build configuration
├── Rprofile.site                       # Repository configuration for fast binaries
├── create_ryan_white_workspace.R       # Workspace creation script
├── lambda_handler.R                    # AWS Lambda runtime handler
├── plotting_minimal.R                  # Basic plotting utilities
├── renv.lock                          # R package dependencies
└── README.md                          # This file
```

## 🚧 Current Status

- ✅ **Container Build**: Complete and validated
- ✅ **Package Dependencies**: All R packages install successfully  
- ✅ **Workspace Creation**: Ryan White model loads correctly
- ✅ **Cross-Platform**: Works on Intel and ARM architectures
- 🚧 **S3 Integration**: Next phase - base simulation loading
- 🚧 **Simulation Pipeline**: Next phase - custom parameter processing
- 🚧 **Plot Generation**: Next phase - production plot creation

## 🎯 Next Phase: Serverless Integration

The container is ready for Phase 2 development:

1. **S3 Integration**: Download base simulations (~50MB per city)
2. **Parameter Processing**: Apply user Ryan White parameters
3. **Simulation Execution**: Run 5-minute JHEEM simulations  
4. **Plot Generation**: Create 10 key plots in Plotly JSON format
5. **Lambda Deployment**: Deploy to AWS with API Gateway integration

## 🐛 Troubleshooting

### Common Build Issues

- **Library version errors**: The container includes strategic symlinks for common version mismatches
- **Architecture warnings**: ARM builds compile more from source (expected)
- **Memory during build**: Ensure Docker has at least 8GB RAM allocated

### Testing the Container

```bash
# Test workspace loading
docker run --rm ncsizemore/jheem-ryan-white-model:latest R -e "load('ryan_white_workspace.RData'); cat('Objects:', length(ls()))"

# Test Lambda handler
docker run -p 8080:8080 ncsizemore/jheem-ryan-white-model:latest

# Interactive debugging
docker run -it --rm ncsizemore/jheem-ryan-white-model:latest /bin/bash
```

## 📚 Additional Resources

- [JHEEM Project Documentation](link-to-docs)
- [Ryan White Specification](link-to-specification)
- [AWS Lambda Container Documentation](https://docs.aws.amazon.com/lambda/latest/dg/images-create.html)
