#!/usr/bin/env bash

## Find files with .vcf extension

find -L . \
	-type f \
	-name '*.vcf' \
	! -name '*filtered.vcf' \
| sed "s#.vcf\$#.PASSfiltered.vcf#" \
| xargs mk
