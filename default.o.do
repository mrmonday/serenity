redo-ifchange configure $1.d
source configure
DEPS=$($DC $ARGS -c $1.d ${OF}$3 -v | grep ^import | grep -v ^importall | perl -pe 's/[^\(]+\(([^\)]+)\)/\1/g')
redo-ifchange $DEPS
