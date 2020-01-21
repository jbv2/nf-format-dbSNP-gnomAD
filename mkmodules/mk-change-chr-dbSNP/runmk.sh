#!/usr/bin/env bash

## find every vcf file
#find: -L option to include symlinks
find -L . \
  -type f \
  -name "*.gz" \
  ! -name "*.tsv.gz" \
| sed 's#.gz#_dbSNP.vcf.gz#' \
| xargs mk
