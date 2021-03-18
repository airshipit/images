#!/bin/bash

if [[ $# != 1 ]]; then
  printf "usage: ./%s <filename>\n" "$0"
  exit 1
fi

docker build . -t helm-chart-collator --build-arg "CHARTS=\"$(cat "$1")\""
