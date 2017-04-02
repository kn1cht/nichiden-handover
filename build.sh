#/bin/sh
find ./* -name '*.md' -print0 | while read -r -d '' file
do
  echo "[1] Converting Markdown to reST : $file"
  pandoc -f markdown-yaml_metadata_block -t rst "$file" -o "${file%%.md}.rst" # translate Markdown to reST
done


find ./* -name '*.rst' -print0 | while read -r -d '' file
do
  echo "[2] Processing reST code : $file"
  sed -i .bak -e 's/\.\.\ code::/.. code-block/g' "${file}" # substitution for code hilighting
done

echo "[3] Deleting backup files..."
find ./* -name '*.bak' -type f | xargs rm

make html

echo "[4] Copying all files to docs/ ..."
rm -r docs/*
cp -r build/html/* docs/
touch docs/.nojekyll

echo "[5] Done."
