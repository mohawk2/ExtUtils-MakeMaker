package ExtUtils::MakeMaker::VRR;

use strict;
use warnings;
use Exporter;
use Carp qw(croak);

our $VERSION = '0.01';
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(vrr2text var2vrr rule2vrr text2vrrs);

# vrr = var/rule/recipe
# keys are type(var/rule), left, right(list),
#     recipes(list, only for rule),
#     append(bool, only for rule)
# if vrr is undef, inserts blank line
# if is scalar ref, is comment - # will be added
# returns chunk of text
sub vrr2text {
    my (@vrr) = @_;
    my @m;
    for my $elt (@vrr) {
        if (!defined $elt) {
            push @m, '';
        } elsif (ref $elt eq 'SCALAR') {
            push @m, "# $$elt";
        } elsif ($elt->{type} eq 'var') {
            push @m, join ' ', "$elt->{left} =", @{ $elt->{right} || [] };
        } elsif ($elt->{type} eq 'rule') {
            my $colon = $elt->{append} ? '::' : ':';
            push @m, join ' ', "$elt->{left} $colon", @{ $elt->{right} || [] };
            push @m, map {
                if (!defined) {
                    ''
                } elsif (ref eq 'SCALAR') {
                    "# $$_"
                } else {
                    "\t$_"
                }
            } @{ $elt->{recipes} || [] };
        } else {
            croak "Something went wrong! Element ($elt) unknown '$elt->{type}'";
        }
    }
    join '', map "$_\n", @m;
}

sub var2vrr {
    my ($name, @values) = @_;
    +{ type => 'var', left => $name, right => \@values };
}

# target currently singular, most correct is to also support arrayref
#  deps and recipe must be array-refs
sub rule2vrr {
    my ($target, $append, $deps, $recipes) = @_;
    +{
        type => 'rule',
        left => $target,
        right => $deps,
        append => $append,
        recipes => $recipes,
    };
}

# modifies first param, returns first line chopped from it
sub _getline { (length $_[0] && $_[0] =~ s/(.*?)(?:\n|\Z)//) ? $1 : () }
sub _is_comment { $_[0] =~ /^\s*#\s*(.*)/ ? $1 : () }
sub _is_recipe { $_[0] =~ /^\t(.*)/ ? $1 : () }
sub _is_var { $_[0] =~ /^\s*([^=]*?)\s*=\s*(.*)/ ? ($1, $2) : () }
sub _is_rule { $_[0] =~ /^\s*([^:]*?)\s*(::?)\s*(.*)/ ? ($1, $2, $3) : () }

sub text2vrrs {
    my ($text) = @_;
    my @m;
    my $line;
    my @d; # dummy to force list context on _is_var and _is_rule
    VRR: while (defined($line = _getline $text)) {
        if ($line eq '') {
            push @m, undef;
        } elsif (my ($comment) = _is_comment $line) {
            push @m, \$comment;
        } elsif (my ($recipe) = _is_recipe $line) {
            push @m, \"IGNORED unattached recipe: $recipe";
        } elsif (@d = _is_var $line) {
            my ($var, $value) = @d;
            if ($value =~ /\\$/) {
                while (defined($line = _getline $text)) {
                    $value .= "\n$line";
                    last unless $value =~ /\\$/;
                }
            }
            push @m, var2vrr($var, length($value) ? ($value) : ());
        } elsif (@d = _is_rule $line) {
            my ($target, $colons, $dep) = @d;
            my @deps = split /\s+/, $dep;
            my @recipes;
            my @d; # dummy to force list context on _is_var and _is_rule
            my $last_end_backslash;
            while (defined($line = _getline $text)) {
                if (my ($recipe) = _is_recipe $line or $last_end_backslash) {
                    push @recipes, $recipe || $line;
                    $last_end_backslash = $line =~ /\\$/;
                } elsif ($line eq '') {
                    push @recipes, undef;
                } elsif (my ($comment) = _is_comment $line) {
                    push @recipes, \$comment;
                } elsif (@d = _is_var $line or @d = _is_rule $line) {
                    last;
                }
            }
            push @m, rule2vrr($target, $colons eq '::', \@deps, \@recipes);
            redo VRR if defined $line and @d;
        }
    }
    @m;
}

1;
