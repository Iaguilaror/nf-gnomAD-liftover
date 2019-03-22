#!/usr/bin/env bash
## This small script runs a module test with the sample data

## Environment Variable
# CHAINFILE="path to the chain file for liftover"
# REFERENCE_GENOME="genome sequence file of 'target assembly' in FASTA format."
export CHAINFILE="test/reference/GRCh37_to_GRCh38.chain"
export REFERENCE_GENOME="test/reference/hs_ref_GRCh38.p12.fa"

echo "[>..] test running this module with data in test/data"
## Remove old test results, if any; then create test/reults dir
rm -rf test/results
mkdir -p test/results
echo "[>>.] results will be created in test/results"
## Execute runmk.sh, it will find the basic example in test/data
## Move results from test/data to test/results
## results files are *.liftover.vcf
./runmk.sh \
&& mv test/data/*.liftover.vcf test/results \
&& echo "[>>>] Module Test Successful"
