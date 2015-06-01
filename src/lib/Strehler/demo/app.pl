#!/usr/bin/env perl

use strict;

use FindBin;
use lib "$FindBin::Bin/../lib";

$ENV{DANCER_CONFDIR} = "$FindBin::Bin/../"; ## no critic qw(Variables::RequireLocalizedPunctuationVars)

require Site;
require Strehler::Admin;
require Strehler::API;
Site->dance;
