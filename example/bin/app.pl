#!/usr/bin/env perl

use FindBin;
use lib "$FindBin::Bin/../lib";

use Strehler::Admin;
use Site;

Site->dance;
