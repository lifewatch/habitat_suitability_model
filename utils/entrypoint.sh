#! /bin/bash

# Unzip input files if input.zip exists
if [ -f /mnt/inputs/input.zip ]; then
  cd /mnt/inputs
  unzip -o input.zip
fi

cd /wrp

# Call main.r script with input arguments
Rscript --vanilla main.r "$@"

# Zip file in the output folder if it exists and if not empty
if [ -d /mnt/outputs ]; then
  cd /mnt/outputs
  if [ "$(ls -A .)" ]; then
    zip -r output.zip .
    echo "Output zipped to output.zip"
  else
    echo "No files to zip in /mnt/outputs"
  fi
else
  echo "/mnt/outputs directory does not exist."
fi