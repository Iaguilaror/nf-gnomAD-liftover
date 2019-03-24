#!/usr/local/env bash

echo -e "======\n Testing NF execution \n======" \
&& rm -rf test/results/ \
&& nextflow run liftover.nf \
	--vcf_dir test/data/ \
	--genome_fasta /home/acerlap/Databases/genomes/hs_ref_GRCh38.p12.fa \
	--chainfile test/reference/chainfile/GRCh37_to_GRCh38.chain \
	--output_dir test/results \
	-resume \
	-with-report test/results/`date +%Y%m%d_%H%M%S`_report.html \
	-with-dag test/results/`date +%Y%m%d_%H%M%S`.DAG.html \
&& echo -e "======\n Extend Align: Basic pipeline TEST SUCCESSFUL \n======"
