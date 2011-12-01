#!/usr/bin/perl
#
# tests Git::DB::Util::CatPage

use Test::More no_plan;
use strict;
use warnings;

BEGIN { use_ok("Git::DB::Util::CatPage") };

*Git::DB::Util::require_mock = sub {};
our @row;
*Git::DB::Util::emit_mock = sub {
        push @row, [@_];
};

# 1. test cat'ing a real file
