#!/usr/bin/env bash

## Find files with .vcf extension

find -L . \
	-type f \
	-name '*.vcf' \
| sed 's#.vcf#.sorted.bcf.gz#' \
| xargs mk
