#/bin/sh
find ./* -name '*.md' -print0 | while read -r -d '' file
do
  echo "[1] Converting Markdown to reST : $file"
  pandoc -f markdown-yaml_metadata_block -t rst "$file" -o "${file%%.md}.rst" # translate Markdown to reST
done

str="   :ROBOTS: NOINDEX,NOFOLLOW,NOARCHIVE"

find ./* -name '*.rst' -print0 | while read -r -d '' file
do
  sed -i .bak -e 's/\.\.\ code::/.. code-block/g' "${file}" # substitution for code hilighting
  if [ "$str" != "`sed -n 2p "${file}"`" ]
  then
    echo "[2] Adding meta tag for refusing robots : $file"
    sed -i .bak -e $'1s/^/.. meta::\\\n   :ROBOTS: NOINDEX,NOFOLLOW,NOARCHIVE\\\n\\\n/' "${file}" # insert meta tag in all .rst file
  fi
done

echo "[3] Deleting backup files..."
find ./* -name '*.bak' -type f | xargs rm

make html

echo "[4] Copying all files to docs/ ..."
rm -r docs/*
cp -r build/html/* docs/
touch docs/.nojekyll

echo "[5] Done."
