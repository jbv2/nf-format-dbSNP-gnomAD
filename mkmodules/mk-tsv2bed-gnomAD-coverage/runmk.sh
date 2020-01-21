#!/usr/bin/env bash

## find every vcf file
#find: -L option to include symlinks
find -L . \
  -type f \
  -name "*.tsv.bgz" \
| sed 's#.tsv.bgz#.bed.gz#' \
| xargs mk
