echo '// Automatically generated, do not edit by hand' > $3
echo 'module controllers;' >> $3
DEPS=$(find example/controllers/ -name \*.d)
for f in $DEPS; do
    m=$(basename $f .d | perl -pe 's|/|.|g')
    echo "import example.controllers.$m;" >> $3
done
