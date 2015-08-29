#!/bin/sh
for file in $(find ./manifests -iname '*.pp')
do
      echo " Validating ${file} "
        puppet parser validate \
        --render-as s \
        --modulepath=modules \
        "${file}" || exit 1;
done

for file in $(find ./manifests -iname '*.pp')
do
      echo " Checking with puppet-lint ${file} "
        puppet-lint --no-80chars-check \
        "${file}" || exit 1;
done
