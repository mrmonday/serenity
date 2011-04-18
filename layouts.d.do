echo '// Automatically generated, do not edit by hand' > $3
echo 'module layouts;' >> $3
for f in $(find example/layouts/ -name \*.d); do
    m=$(basename $f .d | perl -pe 's|/|.|g')
    echo "import example.layouts.$m;" >> $3
done
