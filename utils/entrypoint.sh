#! /bin/bash

# Helper function
throwError() { echo "ERROR: $@" 1>&2; exit 1; }

# Unzip input files
if [ -d /mnt/inputs/inputs.zip ]; then
    unzip -q /mnt/inputs/input.zip -d /mnt/inputs/
fi

Rscript --vanilla main.r

# Zip file in the output folder if it exists
if [ -d /mnt/outputs ]; then
  cd /mnt/outputs
  zip -r /output.zip ./*
  mv /output.zip /mnt/outputs/output.zip
fi