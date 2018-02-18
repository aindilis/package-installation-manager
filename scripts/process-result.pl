#!/usr/bin/perl -w

use PerlLib::SwissArmyKnife;

use Data::Dumper;

my $conflicts = read_file_dedumper("result.dat");
print Dumper($conflicts);

my @packages;
my @files;
foreach my $file (keys %$conflicts) {
  if ($conflicts->{$file}->{DLocate}) {
    my $res = DelocateFile(File => $file);
    if ($res->{Success}) {
      push @packages, {
		       Package => $res->{Result},
		       File => $file,
		      };
    }
  } elsif ($conflicts->{$file}->{Locate}) {
    push @files, $file;
  }
}

print Dumper
  ({
    Files => \@files,
    Packages => \@packages,
   });

sub DelocateFile {
  my %args = @_;
  my $file1 = $args{File};
  my $quotedfile1 = shell_quote($file1);
  foreach my $line (split /\n/, `dlocate $quotedfile1`) {
    if ($line =~ /^(.+?): (.+)$/) {
      my $package = $1;
      my $file2 = $2;
      if ($file1 eq $file2) {
	return {
		Success => 1,
		Result => $package,
	       };
      }
    }
  }
  return {
	  Success => 0,
	 };
}
