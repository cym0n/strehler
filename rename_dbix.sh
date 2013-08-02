#!/bin/sh
project=$1
if [ -z "${project}" ]; then
    echo "Project not set"
    exit 1
fi
find . -type f | while read line; do
    command='sed -i -e "s|Strehler::StrehlerDB|'$project'::'$project'DB|" '$line
    eval $command
done
cd src/lib
mv Strehler $project
cd $project
eval "mv StrehlerDB "$project"DB"
eval "mv StrehlerDB.pm "$project"DB.pm"
