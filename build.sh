#/bin/sh
find ./* -name '*.md' -print0 | while read -r -d '' file
do
  echo "$file"
  pandoc -f markdown-yaml_metadata_block -t rst "$file" -o "${file%%.md}.rst"
  sed -i .bak -e "s/\.\.\ code::/.. code-block/g" "${file%%.md}.rst"
done

find ./* -name '*.bak' -type f | xargs rm

make html

rm -r docs/*
cp -r build/html/* docs/
