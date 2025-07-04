#!/bin/bash

# MkDocs development helper script
# This script manages the Python virtual environment and provides convenient commands for building and serving docs

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VENV_DIR="$SCRIPT_DIR/venv"

# Function to display usage
show_usage() {
    echo -e "${BLUE}MkDocs Development Helper${NC}"
    echo ""
    echo "Usage: $0 <command>"
    echo ""
    echo "Commands:"
    echo "  setup     - Set up the virtual environment and install dependencies"
    echo "  build     - Build the documentation"
    echo "  serve     - Serve the documentation locally (http://127.0.0.1:8000)"
    echo "  clean     - Clean the build directory"
    echo "  help      - Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 setup"
    echo "  $0 build"
    echo "  $0 serve"
}

# Function to check if virtual environment exists
check_venv() {
    if [ ! -d "$VENV_DIR" ]; then
        echo -e "${RED}❌ Virtual environment not found at $VENV_DIR${NC}"
        echo -e "${YELLOW}💡 Run '$0 setup' to create the virtual environment first${NC}"
        exit 1
    fi
}

# Function to activate virtual environment
activate_venv() {
    check_venv
    source "$VENV_DIR/bin/activate"
}

# Function to set up the virtual environment
setup_venv() {
    echo -e "${BLUE}🔧 Setting up virtual environment...${NC}"

    # Create virtual environment if it doesn't exist
    if [ ! -d "$VENV_DIR" ]; then
        echo -e "${YELLOW}📦 Creating virtual environment...${NC}"
        python3 -m venv "$VENV_DIR"
    fi

    # Activate virtual environment
    source "$VENV_DIR/bin/activate"

    echo -e "${YELLOW}📦 Installing dependencies...${NC}"
    pip install --upgrade pip
    pip install mkdocs
    pip install pymdown-extensions
    pip install git+https://github.com/skedgo/skedgo-mkdocs-theme

    echo -e "${GREEN}✅ Virtual environment setup complete!${NC}"
    echo -e "${BLUE}📍 Virtual environment location: $VENV_DIR${NC}"
}

# Function to build documentation
build_docs() {
    echo -e "${BLUE}🔨 Building documentation...${NC}"
    echo -e "${YELLOW}💡 Using --no-strict mode for local development${NC}"
    activate_venv
    mkdocs build --no-strict
    echo -e "${GREEN}✅ Documentation built successfully!${NC}"
    echo -e "${BLUE}📁 Output directory: $SCRIPT_DIR/site${NC}"
}

# Function to serve documentation
serve_docs() {
    echo -e "${BLUE}🚀 Starting development server...${NC}"
    echo -e "${YELLOW}📍 Documentation will be available at: http://127.0.0.1:8000${NC}"
    echo -e "${YELLOW}💡 Using --no-strict mode for local development${NC}"
    echo -e "${YELLOW}💡 Press Ctrl+C to stop the server${NC}"
    echo ""
    activate_venv
    mkdocs serve --no-strict
}

# Function to clean build directory
clean_docs() {
    echo -e "${BLUE}🧹 Cleaning build directory...${NC}"
    if [ -d "$SCRIPT_DIR/site" ]; then
        rm -rf "$SCRIPT_DIR/site"
        echo -e "${GREEN}✅ Build directory cleaned!${NC}"
    else
        echo -e "${YELLOW}💡 Build directory already clean${NC}"
    fi
}

# Main script logic
case "${1:-}" in
    setup)
        setup_venv
        ;;
    build)
        build_docs
        ;;
    serve)
        serve_docs
        ;;
    clean)
        clean_docs
        ;;
    help|--help|-h)
        show_usage
        ;;
    "")
        echo -e "${RED}❌ No command provided${NC}"
        echo ""
        show_usage
        exit 1
        ;;
    *)
        echo -e "${RED}❌ Unknown command: $1${NC}"
        echo ""
        show_usage
        exit 1
        ;;
esac
