# syntax=docker/dockerfile:1  # Enable Docker BuildKit features
# Keep this syntax directive! It's used to enable Docker BuildKit

########################################################
# PYTHON-BASE
# Sets up all our shared environment variables
########################################################

# Base image with Python
FROM bitnami/python:3.11 AS python-base

# Set the timezone to America/New_York
ENV TZ=UTC
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# Set environment variables for Python 
ENV \
    # Ensures Python output is sent directly to the terminal
    PYTHONUNBUFFERED=1 \
    # Disables unnecessary version check for pip
    PIP_DISABLE_PIP_VERSION_CHECK=on \
    # Sets a timeout for pip operations to prevent hangs
    PIP_DEFAULT_TIMEOUT=100 \
    # Path to the virtual environment
    VIRTUAL_ENV="/venv"

# Prepend venv to path
ENV PATH="$VIRTUAL_ENV/bin:$PATH"

# Prepare virtual env
RUN python -m venv $VIRTUAL_ENV

RUN mkdir -p /usr/app
WORKDIR /usr/app

########################################################
# BUILDER-BASE
# Used to build deps + create our virtual environment
########################################################
FROM python-base AS builder-base

RUN apt-get update \
    && apt-get install --no-install-recommends -y curl \
    # cleaning up unused files
    && apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false \
    && rm -rf /var/lib/apt/lists/*

# Copy only setup.py for efficient caching
COPY setup.py ./

# install runtime deps to VIRTUAL_ENV
RUN --mount=type=cache,target=/root/.cache \
    pip install --no-cache-dir .

WORKDIR /usr/app

# Copy project files
COPY . ./

########################################################
# PRODUCTION
# Final image used for runtime
########################################################
FROM python-base AS production

WORKDIR /usr/app
COPY . ./

# install runtime deps to VIRTUAL_ENV
RUN --mount=type=cache,target=/root/.cache \
    pip install --no-cache-dir .

# Run bash
USER 1001
