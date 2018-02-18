#!/usr/bin/perl -w

use BOSS::Config;
use PackageManager::Util;

use Data::Dumper;

$specification = q(
	-d <deb>		Debian file
);

my $config =
  BOSS::Config->new
  (Spec => $specification);
my $conf = $config->CLIConfig;
# $UNIVERSAL::systemdir = "/var/lib/myfrdcsa/codebases/minor/package-installation-manager";
my $files = GetFilesForPackage
  (
   PackageFile => $conf->{'-d'},
  );

print Dumper($files);
