#!/usr/bin/env bash

## Find files with .vcf extension

find -L . \
	-type f \
	-name '*.vcf' \
	! -name '*.liftover.vcf' \
| sed 's#.vcf#.liftover.vcf#' \
| xargs mk
