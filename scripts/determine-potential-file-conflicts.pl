#!/usr/bin/perl -w

# first get all the id3 tags from the music

# load all the existing file using dlocate and locate

use BOSS::Config;
use PackageManager::Util;
use PerlLib::EasyPersist;
use PerlLib::Util;

use Data::Dumper;

$specification = q(
	-d <deb>		Debian file
);

my $config =
  BOSS::Config->new
  (Spec => $specification);
my $conf = $config->CLIConfig;
# $UNIVERSAL::systemdir = "/var/lib/myfrdcsa/codebases/minor/package-installation-manager";
my $overwrite = 0;

my $debfile = $conf->{'-d'};
die "no debian file\n" unless -f$debfile;

my $packagefiles = GetFilesForPackage(PackageFile => $debfile);

my $easypersist = PerlLib::EasyPersist->new;
my $res = $easypersist->Get
  (
   Command => "`dlocate .`",
   Overwrite => $overwrite,
  );

die "Can't get dlocate\n" unless $res->{Success};
my $dlocate = $res->{Result};

Start("Loading locate");
my $locate = `cat /var/lib/myfrdcsa/codebases/minor/better-locate/data/split/*`;
Finish();

#   my $locate = $easypersist->Get
#     (
#      Command => "`locate .`",
#      # Overwrite => $overwrite,
#     );

FindConflicts(
	      SetA => {
		       PackageFiles => $packagefiles,
		      },
	      SetB => {
		       Locate => $locate,
		       DLocate => $dlocate,
		      },
	     );
# now load a list of all the files and see if there are conflicts

sub FindConflicts {
  my %args = @_;
  my $seta = {};
  foreach my $name (keys %{$args{SetA}}) {
    Start("Processing $name");

    my $entries = GetEntries(Files => $args{SetA}->{$name});
    foreach my $file (keys %$entries) {
      $seta->{$file}->{$name}++;
    }

    Finish();
  }
  my $setb = {};
  my $shared = {};
  foreach my $name (keys %{$args{SetB}}) {
    Start("Processing $name");

    my $entries = GetEntries(Files => $args{SetB}->{$name});
    foreach my $file (keys %$entries) {
      $setb->{$file}->{$name}++;

      if (exists $seta->{$file}) {
	if (! exists $shared->{$file}) {
	  $shared->{$file} = $seta->{$file};
	}
	$shared->{$file}->{$name}++;
      }

    }

    Finish();
  }

  # now find items that are in both sets
  print Dumper($shared);
}

sub GetEntries {
  my %args = @_;
  my $files = {};
  foreach my $item (split /\n/, $args{Files}) {
    if ($item !~ /^\//) {
      $item =~ s/^.+?: //;
    }
    if ($item =~ /\/$/) {
      # this is a dir, we can safely ignore
    } else {
      # this is a file
      $files->{$item} = 1;
    }
  }
  return $files;
}
