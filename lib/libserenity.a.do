DEPS=$(find ../serenity -name \*.d | perl -pe 's/\.d/.o/g')
redo-ifchange $DEPS
ar rs $3 $DEPS 2>/dev/null
