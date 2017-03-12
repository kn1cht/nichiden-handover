#/bin/sh
find ./* -name '*.md' -print0 | while read -r -d '' file
do
  echo "$file"
  pandoc -f markdown-yaml_metadata_block -t rst "$file" -o "${file%%.md}.rst" # translate Markdown to reST
done

find ./* -name '*.rst' -print0 | while read -r -d '' file
do
  echo "$file"
  sed -i .bak -e 's/\.\.\ code::/.. code-block/g' "${file}" # substitution for code hilighting
  sed -i .bak -e $'1s/^/.. meta::\\\n   :ROBOTS: NOINDEX,NOFOLLOW,NOARCHIVE\\\n\\\n/' "${file}" # insert meta tag in all .rst file
done

find ./* -name '*.bak' -type f | xargs rm

make html

rm -r docs/*
cp -r build/html/* docs/
touch docs/.nojekyll
