#!/usr/bin/env perl
# vim:set sw=2 sts=2 et:

use warnings;
use strict;
use Getopt::Std;

sub usage {
  print STDERR "Usage: diff -qsr DIR1 DIR2 | $0 [-v] [-n|-f]\n";
  print STDERR "    -n  dry run (only print commands; no modifications)\n";
  print STDERR "    -f  execute (perform deduplication)\n";
  print STDERR "    -v  verbose (explain actions)\n";
  exit;
}

my %args;
getopts('nvfh', \%args);

my $dryrun = $args{'n'} ? 1 : 0;
my $verbose = $args{'v'} ? 1 : 0;
my $force = $args{'f'} ? 1 : 0;

if ($args{'h'}) {
  usage;
}

if ($dryrun && $force) {
  print STDERR "-n and -f conflict.\n\n";
  usage;
}

if (!$dryrun && !$force) {
  print STDERR "-n or -f must be specified.\n\n";
  usage;
}

if (-t) {
  print STDERR "Input is from a terminal.\n\n";
  usage;
}

# Given two file names $a and $b that point to content-identical files,
# hardlink one to the other.
# If $b has 1 hardlink, unlink $b and link $a to $b.
# If $a has 1 hardlink, unlink $a and link $b to $a.
# Otherwise, do nothing.
sub dedup_files {
  my ($a, $b) = @_;
  my @astat = stat $a;
  my @bstat = stat $b;
  if (!@astat) {
    print STDERR "$a: $!\n";
    return;
  }
  if (!@bstat) {
    print STDERR "$a: $!\n";
    return;
  }

  # Compare inode numbers
  if ($astat[1] == $bstat[1]) {
    if ($verbose) {
      print STDERR "$a and $b have identical inode numbers; skipping\n";
    }
    return;
  }

  # Check number of existing hardlinks
  if ($bstat[3] != 1) {
    if ($astat[3] != 1) {
      print STDERR "$a: $astat[3] links\n";
      print STDERR "$b: $bstat[3] links\n";
      print STDERR "Both files have more than one link; skipping\n";
    } else {
      ($a, $b) = ($b, $a);
    }
  }

  if ($dryrun || $verbose) {
    my $acmd = $a;
    my $bcmd = $b;
    $acmd =~ s/'/'\\''/g;
    $bcmd =~ s/'/'\\''/g;
    print "cp -l '$acmd' '$bcmd'\n";
  }
  if ($force) {
    if (!unlink($b)) {
      print STDERR "unlink($b): $!\n";
      return;
    }
    if (!link($a, $b)) {
      print STDERR "link($a, $b): $!\n";
      return;
    }
  }
}

my $first = 1;

while (<>) {
  chomp;
  if (/^Files (.*) and (.*) are identical$/) {
    dedup_files($1, $2);
  } elsif (/^Files .* and .* differ$/) {
  } elsif (/^Only in .*: .*$/) {
  } else {
    print STDERR "Unrecognized line in input\n";
    print STDERR "[$_]\n";
    if ($first) {
      usage;
    }
  }
  $first = 0;
}
