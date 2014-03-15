#!/usr/bin/bash
cd ../src/lib
dbicdump -o dump_directory=. -o components='["InflateColumn::DateTime"]' Strehler::Schema dbi:mysql:database=strehler strehler strehler  

