#!/usr/local/env bash

nextflow run liftover.nf \
	--vcf_dir real-data/exomes/ \
	--genome_fasta /home/iaguilar/Ongoing_projects/lifting_over_gnomAD/nf-gnomAD-liftover/real-data/reference/Homo_sapiens_assembly38.fa \
	--chainfile test/reference/chainfile/GRCh37_to_GRCh38.chain \
	--output_dir real-data/genomes/results/ \
	-resume \
	-with-report real-data/genomes/results/logs/`date +%Y%m%d_%H%M%S`_report.html \
	-with-dag real-data/genomes/results/logs/`date +%Y%m%d_%H%M%S`.DAG.html
