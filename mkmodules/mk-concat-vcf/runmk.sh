#!/usr/bin/env bash

# find ever file with chunk
find -L . \
  -type f \
  -name "*.chunk*" \
| sed "s#.chunk[0-9]*##" \
| sort -u \
| xargs mk
