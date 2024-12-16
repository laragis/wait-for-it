# syntax=docker/dockerfile:1  # Enable Docker BuildKit features
# Keep this syntax directive! It's used to enable Docker BuildKit

########################################################
# PYTHON-BASE
# Sets up all our shared environment variables
########################################################

# Allow dynamic specification
ARG PY_VERSION=3.11

# Base image with Python
FROM bitnami/python:${PY_VERSION} AS python-base

# Add a maintainer label for documentation purposes
LABEL maintainer="Truong Thanh Tung <ttungbmt@gmail.com>"

# Set the timezone to UTC
ENV TZ=UTC
# Set the system timezone and update /etc/timezone
RUN ln -snf /usr/share/zoneinfo/${TZ} /etc/localtime && echo ${TZ} > /etc/timezone

# Set environment variables for Python 
ENV \
    # Ensures Python output is sent directly to the terminal
    PYTHONUNBUFFERED=1 \
    # Disables unnecessary version check for pip
    PIP_DISABLE_PIP_VERSION_CHECK=on \
    # Sets a timeout for pip operations to prevent hangs
    PIP_DEFAULT_TIMEOUT=100 \
    # Specifies the directory where Pip caches its data
    PIP_CACHE_DIR=/root/.cache/pip \
    # Path to the virtual environment
    VIRTUAL_ENV="/opt/venv"

# Prepend the virtual environment to the PATH
ENV PATH="$VIRTUAL_ENV/bin:$PATH"

# Create a virtual environment in the specified directory
RUN python -m venv ${VIRTUAL_ENV}

# Set the working directory to the application directory
WORKDIR /usr/app

########################################################
# BUILDER-BASE
# Used to build deps + create our virtual environment
########################################################
FROM python-base AS builder-base

# Update apt package manager and install curl (used for network operations)
RUN apt-get update \
    && apt-get install --no-install-recommends -y \
    curl \
    make \
    neovim \
    zsh \
    # Clean up unused files to reduce image size
    && apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false \
    && rm -rf /var/lib/apt/lists/*

# Copy the setup.py file to the container for dependency installation
COPY setup.py ./

# Install runtime dependencies into the virtual environment
RUN --mount=type=cache,target=${PIP_CACHE_DIR} \
    pip install --no-cache-dir .

# Set the working directory
WORKDIR /usr/app

# Copy all project files to the container
COPY . ./

########################################################
# PRODUCTION
# Final image used for runtime
########################################################
FROM python-base AS production

# Set the working directory
WORKDIR /usr/app

# Copy all project files to the production stage
COPY . ./

# Install runtime dependencies into the virtual environment
RUN --mount=type=cache,target=${PIP_CACHE_DIR} \
    pip install --no-cache-dir .

# Switch to a non-root user for better security
USER 1001
