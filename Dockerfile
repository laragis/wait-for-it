# syntax=docker/dockerfile:1  # Enable Docker BuildKit features
# Keep this syntax directive! It's used to enable Docker BuildKit

########################################################
# PYTHON-BASE
# Sets up all our shared environment variables
########################################################

# Base image with Python
FROM python:3.11-slim as python-base

# Set the timezone to America/New_York
ENV TZ=Asia/Ho_Chi_Minh
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

RUN mkdir -p /app
WORKDIR /app

########################################################
# BUILDER-BASE
# Used to build deps + create our virtual environment
########################################################
FROM python-base as builder-base

RUN apt-get update \
    && apt-get install --no-install-recommends -y curl \
    # cleaning up unused files
    && apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false \
    && rm -rf /var/lib/apt/lists/*

# Copy only setup.py for efficient caching
COPY setup.py ./

WORKDIR /app

# Copy project files
COPY . ./

########################################################
# DEVELOPMENT
# Image used during development / testing
########################################################

FROM builder-base as development

RUN apt-get update \
    && apt-get install -y git zsh exa && \
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh) --keep-zshrc" && \
    echo yes | bash -c "$(curl --fail --show-error --silent --location https://raw.githubusercontent.com/zdharma-continuum/zinit/HEAD/scripts/install.sh)"

RUN echo '\n# ZSH Plugins' >> ~/.zshrc && \
    echo "zinit light spaceship-prompt/spaceship-prompt" >> ~/.zshrc && \
    echo "zinit light zsh-users/zsh-syntax-highlighting" >> ~/.zshrc && \
    echo "zinit light zsh-users/zsh-autosuggestions" >> ~/.zshrc && \
    echo "zinit light zsh-users/zsh-completions" >> ~/.zshrc && \
    echo '\n# ZSH Snippet' >> ~/.zshrc && \
    echo "zinit snippet https://raw.githubusercontent.com/laragis/zsh-snippets/main/bash_aliases.sh" >> ~/.zshrc


WORKDIR /app

########################################################
# PRODUCTION
# Final image used for runtime
########################################################
FROM python-base as production

WORKDIR /app
COPY . ./

# Run wait_for_it
CMD ["pip", "install", "."]