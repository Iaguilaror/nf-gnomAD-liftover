#!/usr/bin/env bash

## find every vcf file
#find: -L option to include symlinks
find -L . \
  -type f \
  -name "*.vcf" \
  ! -name "*.reheaded.vcf" \
| sed 's#.vcf#.reheaded.vcf#' \
| xargs mk
