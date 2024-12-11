#! /usr/bin/env bash

# Install fish terminal
sudo apt update -y
sudo apt-get install fish -y
pip install dvc



# Install Dependencies
# poetry install
make install

# Install pre-commit hooks
# poetry run pre-commit install --install-hooks
