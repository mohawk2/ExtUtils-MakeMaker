#!/usr/bin/perl -w

BEGIN {
    unshift @INC, 't/lib';
}

use strict;
use ExtUtils::MakeMaker;

use MakeMaker::Test::Utils;
use Config;
use ExtUtils::MM;
use Test::More;
use File::Spec;
use File::Path;
use File::Temp qw[tempdir];

MakeMaker::Test::Setup::Plugins->import;

chdir 't';
perl_lib; # sets $ENV{PERL5LIB} relative to t/

my $CLEANUP = 1;
plan tests => 5 + ($CLEANUP && 1);
my $tmpdir = tempdir( DIR => '../t', CLEANUP => $CLEANUP );
use Cwd; my $cwd = getcwd; END { chdir $cwd } # so File::Temp can cleanup
chdir $tmpdir;

$| = 1;

ok( setup_recurs(), 'setup' );
END {
    chdir File::Spec->updir;
    ok teardown_recurs(), "teardown" if $CLEANUP;
}

ok( chdir('Big-Dummy'), "chdir'd to Big-Dummy" ) ||
  diag("chdir failed: $!");

my $perl = which_perl();
my @mpl_out = run(qq{$perl Makefile.PL});

cmp_ok( $?, '==', 0, 'Makefile.PL exited with zero' ) ||
  diag(@mpl_out);
my $make = make_run();

my $make_out = run("$make funky");
like( $make_out, qr/stuff/, 'make funky' );
is( $?, 0,                                 '  exited normally' ) ||
    diag $make_out;

package MakeMaker::Test::Setup::Plugins;

BEGIN {
our @ISA = qw(Exporter);
require Exporter;
our @EXPORT = qw(setup_recurs teardown_recurs);
}

use strict;
use File::Path;
use File::Basename;
use MakeMaker::Test::Utils;

my %Files;
BEGIN {
%Files = (
    'Big-Dummy/lib/Big/Dummy.pm' => <<'END',
package Big::Dummy;
use strict; use warnings;
$VERSION = 0.01;
1;
END

    'Big-Dummy/Makefile.PL' => <<'END',
use strict; use warnings;
use ExtUtils::MakeMaker;
use lib 'inc';
WriteMakefile(
    AUTHOR => 'Funkmeister',
    NAME => 'Big::Dummy',
    VERSION_FROM => 'lib/Big/Dummy.pm',
    PLUGINS => [
        [ qw(Funky stuff) ],
    ],
);
END

    'Big-Dummy/inc/ExtUtils/MakeMaker/Plugin/Funky.pm' => <<'END',
package ExtUtils::MakeMaker::Plugin::Funky;
use strict; use warnings;
sub filter {
    my ($class, $section2text, @args) = @_;
    for my $section (keys %$section2text) {
        $section2text->{$section} = "# FUNKY $section (@args)\n" .
            $section2text->{$section};
    }
    $section2text->{top_targets} .=
        "\nfunky :\n\t\$(NOECHO) \$(ECHO) @args\n\n";
}
1;
END

    'Big-Dummy/t/sanity.t' => <<'END',
use strict; use warnings;
print "1..1\n";
print eval "use Big::Dummy; 1;" ? "ok 1\n" : "not ok 1\n";
END

);
}

sub setup_recurs {
    while(my($file, $text) = each %Files) {
        # Convert to a relative, native file path.
        $file = File::Spec->catfile(File::Spec->curdir, @_, split m{\/}, $file);
        $file = File::Spec->rel2abs($file);
        my $dir = dirname($file);
        mkpath $dir or die "$dir: $!" unless -d $dir;
        open(FILE, ">$file") || die "Can't create $file: $!";
        print FILE $text;
        close FILE;
    }

    return 1;
}

sub teardown_recurs {
    foreach my $file (keys %Files) {
        my $dir = dirname($file);
        if( -e $dir ) {
            rmtree($dir) || return;
        }
    }
    return 1;
}

1;
