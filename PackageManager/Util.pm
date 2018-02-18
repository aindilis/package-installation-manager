package PackageManager::Util;

require Exporter;
@ISA = qw(Exporter);
@EXPORT = qw (InstallCPANModule InstallCPANModules InstallScriptDependencies GetFilesForPackage );

use Manager::Dialog qw(Choose);

use Data::Dumper;
use File::Basename;
use File::Temp qw(tempdir);

my $seen = {};

sub InstallCPANModules {
  my %args = @_;
  foreach my $module (@{$args{Modules}}) {
    InstallCPANModule
      (
       Module => $module,
       Force => $args{Force},
      );
  }
}

sub InstallCPANModule {
  my %args = @_;
  my $act = 1;
  my $module = $args{Module};
  $module =~ s|/|::|g;
  # since radar isn't available necessarily, install by hand
  print $module."\n";
  my @items = split /::/, $module;
  my @packages;
  my $packages = {};
  while (scalar @items) {
    my $package = "lib".lc(join("-",@items))."-perl";
    $packages->{$package} = 1;
    push @packages, $package;
    pop @items;
  }
  my $debianpackageregex = "(".join("|",@packages).")";
  my $res2 = `apt-cache search '$debianpackageregex'`;
  my @choices = ("None of these");
  my $override;
  foreach my $line (split /\n/, $res2) {
    if ($line =~ /^(.+?) - (.*)$/) {
      my $package = $1;
      if (exists $packages->{$package}) {
	$override = $package;
	last;
      }
      push @choices, $package;
    }
  }
  my $package = $override || Choose(@choices);
  if ($package ne "None of these") {
    print "APT-GET!\n";
    my $addition = "";
    if (exists $ENV{NONINTERACTIVE} and $ENV{NONINTERACTIVE} eq "true") {
      $addition = " -y";
    }
    my $c = "sudo apt-get$addition install $package";
    print Dumper($c);
    system $c if $act;
  } else {
    # install via cpan
    # preferably do tests at this point
    # do a cpan search at this point
    print "CPAN!\n";
    my $force = $args{Force} ? " -f " : "";
    if (0) {
      my $c = "sudo cpan $force $module";
      print "$c\n";
      system $c if $act;
    } else {
      my $perlmmusedefault = $ENV{PERL_MM_USE_DEFAULT};
      $ENV{PERL_MM_USE_DEFAULT} = 1;
      my $c = "sudo cpanm $force $module";
      print "$c\n";
      system $c if $act;
      $ENV{PERL_MM_USE_DEFAULT} = $perlmmusedefault
    }
  }
}

sub InstallScriptDependencies {
  my %args = @_;
  foreach my $script (@{$args{Scripts}}) {
    my $exit = 0;
    while (! $exit) {
      my $res = `$script 2>&1`;
      if ($res =~ /^Can't locate (.+?).pm /sm) {
	my $module = $1;
	if (exists $seen->{$module}) {
	  print "Already seen $module, exiting!\n";
	  $exit = 1;
	} else {
	  $seen->{$module} = 1;
	  InstallModule();
	}
      } else {
	print "Nothing left to install, exiting!\n";
	$exit = 1;
      }
    }
  }
}

sub GetFilesForPackage {
  my %args = @_;
  my $debfile = $args{PackageFile};
  my $dir = tempdir( CLEANUP => 1 );
  my $debfilebasename = basename($debfile);
  system "cp $debfile $dir";
  system "cd $dir && ar x $debfilebasename";
  my $packagefiles = `cd $dir && tar tzf data.tar.gz`;
  my @items;
  foreach my $line (split /\n/, $packagefiles) {
    $line =~ s/^\.\//\//;
    push @items, $line;
  }
  return join("\n", @items);
}

1;
