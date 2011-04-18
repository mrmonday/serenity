redo-ifchange ../configure
source ../configure
DEPS="../bootstrap.o ../controllers.o ../layouts.o ../lib/libserenity.a ../lib/libserenity-example.a"
redo-ifchange $DEPS
$DC $ARGS $DEPS ${OF}$3 
