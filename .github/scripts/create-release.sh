#!/bin/bash

# Create Release Script for Tauri GDAL Application
# This script helps create and push version tags to trigger automated releases

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to show usage
show_usage() {
    echo "Usage: $0 <version> [options]"
    echo ""
    echo "Arguments:"
    echo "  version    Version tag (e.g., v1.0.0, v2.1.3)"
    echo ""
    echo "Options:"
    echo "  --dry-run  Show what would be done without executing"
    echo "  --help     Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 v1.0.0"
    echo "  $0 v2.1.3 --dry-run"
    echo ""
    echo "This will:"
    echo "  1. Check if the tag already exists"
    echo "  2. Create a new version tag"
    echo "  3. Push the tag to trigger GitHub Actions release"
    echo "  4. Show the release URL"
}

# Function to validate version format
validate_version() {
    local version=$1
    
    # Check if version starts with 'v' and follows semantic versioning
    if [[ ! $version =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        print_error "Invalid version format. Use semantic versioning (e.g., v1.0.0, v2.1.3)"
        exit 1
    fi
}

# Function to check if tag exists
check_tag_exists() {
    local version=$1
    
    if git tag -l | grep -q "^$version$"; then
        print_error "Tag $version already exists!"
        echo "Existing tags:"
        git tag -l | grep "^v" | sort -V | tail -5
        exit 1
    fi
}

# Function to check git status
check_git_status() {
    if [[ -n $(git status --porcelain) ]]; then
        print_warning "You have uncommitted changes:"
        git status --short
        echo ""
        read -p "Continue anyway? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            print_error "Aborted. Please commit or stash your changes first."
            exit 1
        fi
    fi
}

# Function to create and push tag
create_release() {
    local version=$1
    local dry_run=$2
    
    print_status "Creating release for version: $version"
    
    if [[ $dry_run == "true" ]]; then
        print_warning "DRY RUN - No changes will be made"
        echo "Would execute:"
        echo "  git tag $version"
        echo "  git push origin $version"
        return
    fi
    
    # Create the tag
    print_status "Creating git tag..."
    git tag $version
    
    # Push the tag
    print_status "Pushing tag to remote..."
    git push origin $version
    
    print_success "Release tag created and pushed!"
    print_status "GitHub Actions will now build and create the release automatically."
    print_status "You can monitor the progress at:"
    echo "  https://github.com/$(git config --get remote.origin.url | sed 's/.*github.com[:/]\([^/]*\/[^/]*\).*/\1/')/actions"
}

# Main script
main() {
    # Parse arguments
    local version=""
    local dry_run=false
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            --dry-run)
                dry_run=true
                shift
                ;;
            --help|-h)
                show_usage
                exit 0
                ;;
            -*)
                print_error "Unknown option: $1"
                show_usage
                exit 1
                ;;
            *)
                if [[ -z $version ]]; then
                    version=$1
                else
                    print_error "Multiple versions specified: $version and $1"
                    exit 1
                fi
                shift
                ;;
        esac
    done
    
    # Check if version was provided
    if [[ -z $version ]]; then
        print_error "Version argument is required"
        show_usage
        exit 1
    fi
    
    # Validate version format
    validate_version $version
    
    # Check git status
    check_git_status
    
    # Check if tag already exists
    check_tag_exists $version
    
    # Create the release
    create_release $version $dry_run
}

# Run main function with all arguments
main "$@" 