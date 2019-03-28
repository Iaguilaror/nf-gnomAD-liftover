#!/usr/bin/env bash

## This runmk requires an env variable called FILTER_FLAG

## Decide which filename will be generated
if [ "$FILTER_FLAG" == "true" ]
then
	## Find files with .vcf extension
	find -L . \
		-type f \
		-name '*.vcf' \
		! -name '*.PASSfiltered.vcf' \
	| sed "s#.vcf\$#.PASSfiltered.vcf#" \
	| xargs mk
else
	## Find files with .vcf extension
	find -L . \
		-type f \
		-name '*.vcf' \
		! -name '*.unfiltered.vcf' \
	| sed "s#.vcf\$#.unfiltered.vcf#" \
	| xargs mk
fi
