#!/usr/bin/env bash

## find every vcf file
#find: -L option to include symlinks
find -L . \
  -type f \
  -name "*.vcf" \
  ! -name "*.edited.vcf" \
| sed 's#.vcf#.edited.vcf#' \
| xargs mk
