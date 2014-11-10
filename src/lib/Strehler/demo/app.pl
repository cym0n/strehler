#!/usr/bin/env perl

use FindBin;
use lib "$FindBin::Bin/../lib";

$ENV{DANCER_CONFDIR} = "$FindBin::Bin/../";

require Site;
require Demo;
require Strehler::Admin;
require Strehler::API;
Demo->dance;
