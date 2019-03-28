#!/usr/bin/env bash
## This small script runs a module test with the sample data

## Export variables
# FILTER_FLAG="true or false value to decide if variants are filtered or not"
export FILTER_FLAG=false

echo "[>..] test running this module with data in test/data"
## Remove old test results, if any; then create test/reults dir
rm -rf test/results
mkdir -p test/results
echo "[>>.] results will be created in test/results"
## Execute runmk.sh, it will find the basic example in test/data
## Move results from test/data to test/results
## results files are *.PASSfiltered.vcf
./runmk.sh \
&& mv test/data/*.PASSfiltered.vcf test/results \
&& echo "[>>>] Module Test Successful"
