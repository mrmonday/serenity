echo '// Automatically generated, do not edit by hand' > layouts.d
echo 'module layouts;' >> layouts.d
for f in $(find example/layouts/ -name \*.d); do
    m=$(basename $f .d | perl -pe 's|/|.|g')
    echo "import example.layouts.$m;" >> controllers.d
done
