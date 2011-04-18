find . -name \*.tmp | xargs rm
find . -name \*.tmp2 | xargs rm
find . -name \*.o | xargs rm
rm -rf .redo lib/libserenity.a lib/libserenity-example.a bin/serenity.fcgi controllers.d layouts.d
