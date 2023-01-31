#!/usr/bin/perl -w
#===============================================================================
#  DESCRIPTION: When imker is broken but you shall to downloade...
#
#         TODO: 
#
#       AUTHOR: ΜΗΛΟΝ
#      CREATED: 31-01-2023 01:22
#      LICENSE: Artistic License 1.0
#===============================================================================
use Modern::Perl '2020';
use utf8;
use strict;
use autodie;
use warnings;
use English;

# Unicode
use warnings  qw/FATAL utf8/;
use open      qw/:std :utf8/;
use charnames qw/:full/;
use feature   qw/unicode_strings/;

use Carp;                       # 'carp' for warn, 'croak' for die
                                # https://perldoc.perl.org/Carp.html

use Data::Printer;              # Usage: p @array;
# or use DDP;                   # https://metacpan.org/pod/Data::Printer

use MediaWiki::API;         # https://metacpan.org/pod/MediaWiki::API

my $version = '0.1';

sub save_file {
    my $title = shift;

    unless ($_[0]) {
        carp "No data to save\n";
        return undef;
    }

    my ($name) = $title =~ /^File:(.+)/;

    unless ($name) {
        carp "Can't get filename from the title '$title'\n";
        return undef;
    }

    open my $fh, '>:raw', $name or die $!;

    print $fh $_[0];

    close $fh or die $!;
}

sub get_api {
    my $mw = MediaWiki::API->new();
    $mw->{config}->{api_url} = 'https://commons.wikimedia.org/w/api.php';
    return $mw;
}

sub help {
    print <<"_HELP_";
piki-dl.pl
    Simple downloader from Wikimedia Commons by category.

SYNOPSIS
    piki-dl.pl [category name]

EXAMPLES
    piki-dl.pl 'Dioscuri statue from Baiae'

DEPENDENCIES
    MediaWiki::API
_HELP_
}

sub main {
    my $category = shift;

    unless ($category) {
        help();
        return 0;
    }

    my $mw = get_api();

    # get a list of articles in category
    my $articles = $mw->list ({
            action  => 'query',
            list    => 'categorymembers',
            cmtitle => 'Category:' . $category,
            cmlimit => 'max',
    }) or die $mw->{error}->{code} . ': ' . $mw->{error}->{details};

    foreach (@{$articles}) {
        print "$_->{title}\n";

        # ns => 6 is a file type?
        next unless $_->{ns} == 6;

        my $data = $mw->download( { title => $_->{title} } )
            or croak $mw->{error}->{code} . ': ' . $mw->{error}->{details};

        save_file($_->{title}, $data);
    }

    0;
}

exit main(@ARGV);
