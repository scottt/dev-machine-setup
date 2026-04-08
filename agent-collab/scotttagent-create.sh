#!/bin/bash
set -euo pipefail

# Create the 'scotttagent' user
sudo useradd -m scotttagent

# Create the 'coder' group
sudo groupadd coder

# Add 'scottt' and 'scotttagent' to the 'coder' group
sudo usermod -aG coder scottt
sudo usermod -aG coder scotttagent
