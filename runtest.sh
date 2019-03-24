#!/usr/local/env bash

# NOT IMPLEMENTEDCheck that command requirements are reachable from CLI
## then remove test/results dir
## then Run NF
# bash test/requirements/dependency_checker.sh \
# && echo -e "======\n Testing NF execution \n======" \
echo -e "======\n Testing NF execution \n======" \
&& rm -rf test/results/ \
&& nextflow run liftover.nf \
	--vcf_dir test/data/ \
	--genome_fasta /home/iaguilar/Ongoing_projects/lifting_over_gnomAD/nf-gnomAD-liftover/real-data/reference/Homo_sapiens_assembly38.fa \
	--chainfile test/reference/chainfile/GRCh37_to_GRCh38.chain \
	--output_dir test/results \
	-resume \
	-with-report test/results/`date +%Y%m%d_%H%M%S`_report.html \
	-with-dag test/results/`date +%Y%m%d_%H%M%S`.DAG.html \
&& echo -e "======\n Extend Align: Basic pipeline TEST SUCCESSFUL \n======"
