# JHEEM Ryan White Container

A containerized version of the JHEEM Ryan White HIV simulation model with automated CI/CD pipeline for serverless deployment.

## 🚀 Quick Start

### Using the Pre-built Image
```bash
# Pull the latest image from DockerHub
docker pull ncsizemore/jheem-ryan-white-model:latest

# Run locally for testing
docker run -p 8080:8080 ncsizemore/jheem-ryan-white-model:latest
```

### Building from Source
```bash
# Clone this repository
git clone [your-repo-url]
cd jheem-container-minimal

# Build the image
docker build -t jheem-ryan-white-model .

# Run the container
docker run -p 8080:8080 jheem-ryan-white-model
```

## 🏗️ Architecture

### Multi-Stage Docker Build
1. **`jheem-base`** - R environment with system dependencies and R packages
2. **`workspace-builder`** - Downloads data and creates Ryan White workspace  
3. **`ryan-white-model`** - Final runtime container with Lambda handler

### Self-Contained Build Process
- **Automated dependency fetching** via git clone of `tfojo1/jheem_analyses`
- **Dynamic data downloads** from OneDrive using cache metadata
- **Pinned versions** for reproducible builds

## 🔄 CI/CD Pipeline

### Automated Builds
The GitHub Actions workflow automatically:
- Builds Docker images on commits to main
- Pushes to DockerHub as `ncsizemore/jheem-ryan-white-model`
- Supports multi-architecture builds (currently AMD64 only)
- Uses build caching for faster iteration

### Image Tagging Strategy
- `latest` - Latest main branch build
- `v1.0.0` - Tagged releases  
- `main-abc123` - Branch + git SHA
- `pr-123` - Pull request builds

### Setup Requirements
Configure these GitHub repository secrets:
- `DOCKERHUB_USERNAME` - Your DockerHub username
- `DOCKERHUB_TOKEN` - DockerHub access token

See [GITHUB_ACTIONS_SETUP.md](GITHUB_ACTIONS_SETUP.md) for detailed setup instructions.

## 📦 Dependencies

### R Environment
- **Base**: `r-base:4.4.2` 
- **Package Management**: `renv` with Posit Package Manager for fast binaries
- **Core Package**: `jheem2` from GitHub

### Data Dependencies  
- **JHEEM Analyses**: Automatically cloned from `tfojo1/jheem_analyses`
- **Cached Data**: Downloaded from OneDrive using metadata system
- **Version Pinning**: Currently pinned to commit `fc3fe1d2d5f859b322414da8b11f0182e635993b`

### System Libraries
Comprehensive system dependencies for R packages including graphics, geospatial, networking, and development tools.

## 🎯 Production Deployment

### Current Status
- ✅ **Container Build**: Complete and automated
- ✅ **DockerHub Publishing**: Automated via GitHub Actions  
- ✅ **Local Testing**: Functional Lambda handler simulation
- 🚧 **AWS ECR**: Planned for production deployment
- 🚧 **Lambda Deployment**: Next phase development

### Performance Characteristics
- **Image Size**: ~5.2 GB (within 10 GB Lambda limit)
- **Cold Start**: Optimized workspace loading
- **Memory Usage**: Designed for Lambda deployment

## 🔧 Development

### Local Development Workflow
```bash
# Pull latest for development
docker pull ncsizemore/jheem-ryan-white-model:latest

# Interactive debugging
docker run -it --rm ncsizemore/jheem-ryan-white-model:latest /bin/bash

# Test workspace loading
docker run --rm ncsizemore/jheem-ryan-white-model:latest R -e "load('ryan_white_workspace.RData'); cat('Objects:', length(ls()))"
```

### Building with Different Dependencies
```bash
# Use different jheem_analyses commit
docker build --build-arg JHEEM_ANALYSES_COMMIT=abc123 -t test-build .

# Build specific stage for debugging
docker build --target workspace-builder -t workspace-test .
```

### Updating Dependencies
To update the pinned `jheem_analyses` version:
1. Test the new commit locally or in a branch
2. Update `JHEEM_ANALYSES_COMMIT` in `.github/workflows/build-and-push.yml`
3. Commit and push - automated build will use the new version

## 📁 Repository Structure

```
jheem-container-minimal/
├── .github/workflows/       # CI/CD automation
├── cached/                  # Local cached data files*  
├── plotting/                # Plotting utilities
├── simulation/              # Simulation modules
├── tests/                   # Test suites
├── Dockerfile              # Multi-stage container build
├── create_ryan_white_workspace.R  # Workspace creation script
├── lambda_handler.R        # AWS Lambda runtime handler
├── plotting_minimal.R      # Core plotting functionality
├── renv.lock              # R package dependencies
└── README.md              # This file

* Contains temporary workaround files pending official cache system updates
```

## 🚧 Known Issues & Workarounds

### Cached Data Files
- **Issue**: Some required data files not in official cache metadata
- **Workaround**: `google_mobility_data.Rdata` temporarily checked into repo
- **Resolution**: Working with team to add missing files to official cache system

### Platform Support  
- **Current**: AMD64 only (due to R package compilation issues on ARM64)
- **Future**: May add ARM64 support for Apple Silicon compatibility

## 🔮 Roadmap

### Phase 2: Serverless Integration
- **S3 Integration**: Download base simulations (~50MB per city)
- **Parameter Processing**: Apply user Ryan White parameters  
- **Simulation Execution**: Run 5-minute JHEEM simulations
- **Plot Generation**: Create 10 key plots in Plotly JSON format
- **ECR Deployment**: Production deployment to AWS ECR
- **API Gateway**: RESTful API for simulation requests

### Phase 3: Multi-Model Support
- **Repository Structure**: Separate Dockerfiles for different models
- **Matrix Builds**: Efficient CI/CD for multiple model types
- **Shared Base Images**: Optimize build times across models

## 🐛 Troubleshooting

### Build Issues
- **Memory**: Ensure Docker has at least 8GB RAM allocated
- **Network**: Some downloads require stable internet connection
- **Cache**: Use `docker system prune` to clear build cache if needed

### Runtime Issues  
```bash
# Check workspace integrity
docker run --rm ncsizemore/jheem-ryan-white-model:latest R -e "
  load('ryan_white_workspace.RData'); 
  cat('✅ RW.SPECIFICATION:', exists('RW.SPECIFICATION'), '\n');
  cat('✅ RW.DATA.MANAGER:', exists('RW.DATA.MANAGER'), '\n')
"

# Test plotting functionality
docker run --rm ncsizemore/jheem-ryan-white-model:latest R -e "
  source('plotting_minimal.R'); 
  if (test_plotting_functionality()) cat('✅ Plotting OK\n') else cat('❌ Plotting failed\n')
"
```

## 📚 Additional Resources

- [JHEEM Project Documentation](link-to-docs)
- [GitHub Actions Setup Guide](GITHUB_ACTIONS_SETUP.md)
- [AWS Lambda Container Documentation](https://docs.aws.amazon.com/lambda/latest/dg/images-create.html)
- [DockerHub Repository](https://hub.docker.com/r/ncsizemore/jheem-ryan-white-model)
