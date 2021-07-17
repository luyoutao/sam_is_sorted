#' This Source Code Form is subject to the terms of the Mozilla Public
#' License, v. 2.0. If a copy of the MPL was not distributed with this
#' file, You can obtain one at http://mozilla.org/MPL/2.0/.
#'
#' Youtao Lu@Kim Lab, 2016-2020

use strict;
use warnings;
use Getopt::Long;
use Log::Log4perl qw(get_logger :levels);
use Log::Log4perl::Layout::PatternLayout;

#' place shared lib to $HOME directory
use Inline Config => DIRECTORY => $ENV{HOME};
use Inline C      => <<CODE;
/* from samtools/1.9/bam_sort.c */
int strnum_cmp(const char *_a, const char *_b)
{
    const unsigned char *a = (const unsigned char*)_a, *b = (const unsigned char*)_b;
    const unsigned char *pa = a, *pb = b;
    while (*pa && *pb) {
        if (isdigit(*pa) && isdigit(*pb)) {
            while (*pa == '0') ++pa;
            while (*pb == '0') ++pb;
            while (isdigit(*pa) && isdigit(*pb) && *pa == *pb) ++pa, ++pb;
            if (isdigit(*pa) && isdigit(*pb)) {
                int i = 0;
                while (isdigit(pa[i]) && isdigit(pb[i])) ++i;
                return isdigit(pa[i])? 1 : isdigit(pb[i])? -1 : (int)*pa - (int)*pb;
            } else if (isdigit(*pa)) return 1;
            else if (isdigit(*pb)) return -1;
            else if (pa - a != pb - b) return pa - a < pb - b? 1 : -1;
        } else {
            if (*pa != *pb) return (int)*pa - (int)*pb;
            ++pa; ++pb;
        }
    }
    return *pa? 1 : *pb? -1 : 0;
}
CODE

our $VERSION = "0.4";
our $LOGGER  = get_logger(__PACKAGE__);
my ( $inFile, $inFh );
my $name        = 0;
my $header_only = 0;
my ( $version, $help ) = ( 0, 0 );
my $debug = "info";

sub usage {
    print STDERR <<DOC;
Summary:
    Test whether a SAM/BAM is coordinate/queryname sorted. It outputs 'true' if sorted, 'false' if not, and 'unknown' if cannot decide.  

Usage:
    perl $0 --inFile|-i input.[sam|bam] [--name|-n] [--header_only] [--version|-v] [--help|-h] [--debug info]

Options:
    --name, -n      whether queryname sorted. If left out, defaults to testing whether coordinate sorted;
    --header_only   determine only by the header's 'SO' field in \@HD; 
DOC
}

GetOptions(
    "inFile|i=s"  => \$inFile,
    "name|n"      => \$name,
    "header_only" => \$header_only,
    "help|h"      => \$help,
    "version|v"   => \$version,
    "debug=s"     => \$debug,
) or &usage() && exit(-1);

( print "$0 v$VERSION\n" ) && exit(0) if $version;
&usage() && exit(-1) if $help;
die("Input is not found!\n") if !defined($inFile) || !-e $inFile;

if ( $debug eq "fatal" ) {
    $LOGGER->level($FATAL);
}
elsif ( $debug eq "error" ) {
    $LOGGER->level($ERROR);
}
elsif ( $debug eq "warn" ) {
    $LOGGER->level($WARN);
}
elsif ( $debug eq "info" ) {
    $LOGGER->level($INFO);
}
elsif ( $debug eq "debug" ) {
    $LOGGER->level($DEBUG);
}
elsif ( $debug eq "trace" ) {
    $LOGGER->level($TRACE);
}
my $appender = Log::Log4perl::Appender->new("Log::Log4perl::Appender::Screen");
my $layout   = Log::Log4perl::Layout::PatternLayout->new(
    "[%d{yyyy-MM-dd HH:mm:ss.SSS Z}] %m");
$appender->layout($layout);
$LOGGER->add_appender($appender);

$LOGGER->info(
"{VERSION = $VERSION, name = $name, header_only = $header_only, help = $help, version = $version, debug = $debug}\n"
);

if ($header_only) {
    open( $inFh, "samtools view -H $inFile |" )
      or $LOGGER->fatal("Cannot open $inFile for header!\n") && die();
    while (<$inFh>) {
        if (/^\@HD/) {
            ( print "true\n" )  && close($inFh) && exit(0) if /queryname$/  && $name;
            ( print "false\n" ) && close($inFh) && exit(0) if /queryname$/  && !$name;
            ( print "true\n" )  && close($inFh) && exit(0) if /coordinate$/ && !$name;
            ( print "false\n" ) && close($inFh) && exit(0) if /coordinate$/ && $name;
        }
        $LOGGER->warn("No header available, cannot decide!\n");
        print "unknown\n";
        close($inFh);
        exit(-1);
    }
}

if ($name) {
    open( $inFh, "samtools view $inFile |" )
      or $LOGGER->fatal("Cannot open $inFile for records!\n") && die();
    my ( $readID, $prev_readID );
    $prev_readID = ( split( "\t", <$inFh>, -1 ) )[0];
    while (<$inFh>) {
        $readID = ( split( "\t", $_, -1 ) )[0];
        if ( &strnum_cmp( $prev_readID, $readID ) == 1 ) {
            $LOGGER->info(
                "Unsorted records: prev = $prev_readID, next = $readID\n");
            close($inFh);
            print "false\n";
            exit(0);
        }
        $prev_readID = $readID;
    }
    close($inFh);
    print "true\n";
    exit(0);
}

open( $inFh, "samtools view $inFile |" )
  or $LOGGER->fatal("Cannot open $inFile for records!\n") && die();
while (<$inFh>) {
    my ( $chr, $pos, $prev_chr, $prev_pos );
    ( $prev_chr, $prev_pos ) = ( split( "\t", <$inFh>, -1 ) )[ 2 .. 3 ];
    while (<$inFh>) {
        ( $chr, $pos ) = ( split( "\t", $_, -1 ) )[ 2 .. 3 ];
        if ( $chr eq $prev_chr && $pos < $prev_pos ) {
            $LOGGER->info(
"Unsorted records: prev = $prev_chr:$prev_pos, next = $chr:$pos\n"
            );
            close($inFh);
            print "false\n";
            exit(0);
        }
        $prev_chr = $chr;
        $prev_pos = $pos;
    }
    close($inFh);
    print "true\n";
    exit(0);
}
