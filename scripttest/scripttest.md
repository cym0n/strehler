Create a Dancer2 site named StrehlerTest

    dancer2 -a StrehlerTest

Copy config file from support directory

    cp config.yml StrehlerTest

Under StrehlerTest (remeber: export DANCER_CONFDIR=.) run 

    strehler batch

Add Strehler to bin/app.pl

Test the site, example create a category and a content.

cp categories.txt

    strehler categories

Commands about entities

    strehler testelement Strehler::Element::Article

    strehler initentity Strehler::Element::Extra::Artwork

(here a new schemadump is needed)

Add artwork to config.yml

Create an artwork

Last commands

    strehler layout

    pwdchange


On a fresh new directory

    strehler demo
