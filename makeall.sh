make html > /dev/null
echo 'HTML build complete.'
rm -f build/latex/*
make latexpdfja
echo 'PDF build complete.'
open build/latex/Nichiden.pdf
