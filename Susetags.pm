package Susetags;

use strict;
use warnings;
use Data::Dumper;

sub parse {
  my ($file, $tmap, $order, @arches) = @_;
  # if @arches is empty take all arches

  my @needed = keys %$tmap;
  my $r = '(' . join('|', @needed) . '|Pkg):\s*(.*)';

  if (!open(F, '<', $file)) {
    if (!open(F, '-|', "gzip -dc $file".'.gz')) {
      die "$file: $!";
    }
  }

  my $cur;
  my $pkgs = {};
  while (<F>) {
    chomp;
    next unless $_ =~ /([\+=])$r/;
    my ($multi, $tag, $data) = ($1, $2, $3);
    if ($multi eq '+') {
      while (<F>) {
        chomp;
        last if $_ =~ /-$tag/;
        push @{$cur->{$tmap->{$tag}}}, $_;
      }
    } elsif ($tag eq 'Pkg') {
      $pkgs->{"$cur->{'name'}-$cur->{'arch'}"} = $cur if defined $cur && (!@arches || grep { /$cur->{'arch'}/ } @arches);
      # keep order (or should we use Tie::IxHash?)
      push @{$order}, "$cur->{'name'}-$cur->{'arch'}" if defined $order && defined $cur;
      $cur = {};
      ($cur->{'name'}, $cur->{'version'}, $cur->{'release'}, $cur->{'arch'}) = split(' ', $data);
    } else {
      $cur->{$tmap->{$tag}} = $data;
    }
  }
  $pkgs->{"$cur->{'name'}-$cur->{'arch'}"} = $cur if defined $cur && (!@arches || grep { /$cur->{'arch'}/ } @arches);
  push @{$order}, "$cur->{'name'}-$cur->{'arch'}" if defined $order && defined $cur;
  close(F);
  return $pkgs;
}

1;