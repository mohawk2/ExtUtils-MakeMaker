#!/usr/bin/env perl -w

# Inform the user early and clearly that their Perl is broken beyond redemption

use strict;
use warnings;

use Test::More;

note "The 0.01 / Gconvert bug"; {
    my $number = 0.01;
    my $string = "VERSION=$number";

    is "VERSION=$number", "VERSION=0.01" or do {
        diag <<END;
Sorry, but your perl's ability to translate decimal numbers to strings
is broken.  You should probably recompile it with -Dd_Gconvert=sprintf
or upgrade to a newer version of Perl.
END
    };
}

done_testing;
