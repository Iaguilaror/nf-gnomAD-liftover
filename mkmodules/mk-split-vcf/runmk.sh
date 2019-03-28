#!/usr/bin/env bash

## Find files with .vcf.bgz extension

find -L . \
	-type f \
	-name '*.vcf.bgz' \
| sed 's#.vcf.bgz#.SPLITVCF#' \
| xargs mk
