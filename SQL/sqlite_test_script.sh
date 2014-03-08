#!/bin/sh

GLOBAL_SCRIPT=SQLITE_TEST_STREHLER.sql

if [ -e $GLOBAL_SCRIPT ]
then
    rm $GLOBAL_SCRIPT
fi

for f in `ls -a *.sql`; do
  if [[ "$f" =~ ^[0-9] ]]
  then
      if [ -e "LITE$f" ]
      then
          echo "Adding LITE$f"
          cat LITE$f >> $GLOBAL_SCRIPT
      else
          echo "Adding $f"
          cat $f >> $GLOBAL_SCRIPT
      fi
  fi
done
echo "Changing autoincrement keyword"
sed -i s/AUTO_INCREMENT/AUTOINCREMENT/ $GLOBAL_SCRIPT
echo "Adding admin user"
cat >> $GLOBAL_SCRIPT <<ADMINQUERY
INSERT INTO USERS (USER, PASSWORD_HASH, PASSWORD_SALT, ROLE) 
VALUES ('admin', 'SnbwVypRtNBehDfZrMMUKEIVfCEDZcW', 
'AdFvGp4nXVVfj984NWlYI.', 'admin');
ADMINQUERY
echo "Adding editor user"
cat >> $GLOBAL_SCRIPT <<EDITORQUERY 
INSERT INTO USERS (USER, PASSWORD_HASH, PASSWORD_SALT, ROLE) VALUES ('editor', 'eeweUXIyBjo57zOGiMgL8o8w9U.nWfa', 'cyQydJO6C6mxueKrDdFAE.', 'editor');
EDITORQUERY

