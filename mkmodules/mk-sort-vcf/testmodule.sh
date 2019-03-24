#!/usr/bin/env bash
## This small script runs a module test with the sample data

## Environment Variable
# NONE

echo "[>..] test running this module with data in test/data"
## Remove old test results, if any; then create test/reults dir
rm -rf test/results
mkdir -p test/results
echo "[>>.] results will be created in test/results"
## Execute runmk.sh, it will find the basic example in test/data
## Move results from test/data to test/results
## results files are *.sorted.bcf.gz
./runmk.sh \
&& mv test/data/*.sorted.bcf.gz tmp test/results \
&& echo "[>>>] Module Test Successful"
