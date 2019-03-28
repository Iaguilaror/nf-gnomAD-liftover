#!/usr/bin/env bash

## find every vcf file
#find: -L option to include symlinks
find -L . \
  -type f \
  -name "*.liftover*.vcf" \
| sed 's#.vcf#_report.pdf#' \
| xargs mk
