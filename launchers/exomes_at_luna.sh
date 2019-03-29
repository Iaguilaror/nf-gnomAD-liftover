#!/usr/local/env bash

nextflow run liftover.nf \
	--vcf_dir real-data/exomes/ \
	--genome_fasta /home/iao/PhD/Databases/Genomes/hs_ref_GRCh38.p12.fa \
	--chainfile test/reference/chainfile/GRCh37_to_GRCh38.chain \
	--chunks 10 \
	--rehead false \
	--filter_PASS false \
	--output_dir real-data/exomes/results/ \
	-resume \
	-with-report real-data/exomes/results/logs/`date +%Y%m%d_%H%M%S`_report.html \
	-with-dag real-data/exomes/results/logs/`date +%Y%m%d_%H%M%S`.DAG.html
