DEPS=$(find ../example -name \*.d | perl -pe 's/\.d/.o/g')
echo $DEPS | xargs redo-ifchange
ar rs $3 $DEPS 2>/dev/null
