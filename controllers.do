echo '// Automatically generated, do not edit by hand' > controllers.d
echo 'module controllers;' >> controllers.d
DEPS=$(find example/controllers/ -name \*.d)
for f in ; do
    m=$(basename $f .d | perl -pe 's|/|.|g')
    echo "import example.controllers.$m;" >> controllers.d
done
