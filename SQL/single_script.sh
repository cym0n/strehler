#!/bin/sh

GLOBAL_SCRIPT=INIT_STREHLER.sql

if [ -e $GLOBAL_SCRIPT ]
then
    rm $GLOBAL_SCRIPT
fi

for f in `ls -a *.sql`; do
  if [[ "$f" =~ ^[0-9] ]]
  then
      echo "Adding $f"
      cat $f >> $GLOBAL_SCRIPT
  fi
done
