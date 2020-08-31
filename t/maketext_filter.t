#!/usr/bin/perl -w

use strict;
use warnings;

use Test::More tests => 3;

use ExtUtils::MakeMaker::VRR qw(vrr2text text2vrrs);

sub test_filter {
    my($text, $vms_text) = @_;
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    is vrr2text(text2vrrs $text), $vms_text;
}


# VMS filter puts a space after the target
test_filter(<<'END', <<'VMS');
foo: bar
	thing: splat
END
foo : bar
	thing: splat
VMS


# And it does it for all targets
test_filter(<<'END', <<'VMS');
foo: bar
	thing: splat

up: down
	yes
END
foo : bar
	thing: splat

up : down
	yes
VMS


# And it doesn't mess with macros
test_filter(<<'END', <<'VMS');
CLASS=Foo: Bar

target: stuff
	$(PROGRAM) And::Stuff -e 'print arg => 1' \\
  -e 'print arg => 1'
END
CLASS = Foo: Bar

target : stuff
	$(PROGRAM) And::Stuff -e 'print arg => 1' \\
	  -e 'print arg => 1'
VMS
