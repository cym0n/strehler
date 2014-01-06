#!/bin/sh

GLOBAL_SCRIPT=INIT_STREHLER.sql

if [ -e $GLOBAL_SCRIPT ]
then
    rm $GLOBAL_SCRIPT
fi

for f in `ls -a *.sql`; do
  cat $f >> $GLOBAL_SCRIPT
done
