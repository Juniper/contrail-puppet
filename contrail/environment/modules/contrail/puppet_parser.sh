#!/bin/sh
for file in $(find ./manifests -iname '*.pp')
do
      echo " Parsing ${file} "
        puppet parser validate \
        --render-as s \
        --modulepath=modules \
        "${file}" || exit 1;
done

