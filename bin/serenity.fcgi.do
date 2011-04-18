redo-ifchange ../configure
source ../configure
DEPS="../controllers.o ../layouts.o ../bootstrap.o ../lib/libserenity.a ../lib/libserenity-example.a"
redo-ifchange $DEPS
$DC $ARGS $DEPS ${OF}$3 
