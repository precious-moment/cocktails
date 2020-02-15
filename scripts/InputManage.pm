package InputManage;
use strict;
use warnings;

sub new {
  my $class = shift;
  my $in_fname = shift;
  my $this = {
    latex_command => undef,
    latex_flags => "",
    base_dirs => [],
    base_names => [],
    num_bases => 0,
    out_dir => "PartyMenu",
    ingred_fname => "ingredients.txt",
    out_fname_header => "ListedDrinks"
  };

  open(IN,"< $in_fname") or die "Failed to open $in_fname\n";
  while(<IN>) {
    chomp;
    s/^\s+//;
    next if /^#/;
    $this->{latex_command} = $1 if (/^latex_command:\s*(\S+)$/);
    $this->{latex_flags} = $1 if (/^latex_flags:\s*(.+)$/);
    $this->{out_dir} = $1 if (/^out_dir:\s*(\S+)$/);
    $this->{ingred_fname} = $1 if (/^ingred_fname:\s*(\S+)$/);
    $this->{out_fname_header} = $1 if (/^out_fname_header:\s*(\S+)$/);
    if ( s/^bases:\s*// ) {
      my @bases = split('\s*\|\s*',$_);
      my @base_dirs = @{$this->{base_dirs}};
      my @base_names = @{$this->{base_names}};
      if ( $#base_dirs == -1 ) {
        print "Introduction of cocktail bases:\n";
      } else {
        print "Additional introduction of cocktail bases:\n";
      }
      foreach my $base(@bases) {
        $this->{num_bases}++;
        if ($base=~/^([^\/]+)\/([^\/]+)/) {
          push(@base_dirs,$1);
          push(@base_names,$2);
          print "$1 $2\n";
        }
      }
      $this->{base_dirs} = [@base_dirs];
      $this->{base_names} = [@base_names];
    }
  }
  close(IN);

  bless $this, $class;

  unless ( defined $this->{latex_command} ) {
    print "error: LaTeX compiler not inputted\n";
    die;
  }

  my $check = readpipe("which $this->{latex_command}");
  if ( $check eq "" ) {
    print "error: LaTeX compiler $this->{latex_command} not found\n";
    die;
  }
  print "LaTeX compiler $this->{latex_command} found: $check\n";

  if ( $this->{num_bases} == 0 ) {
    print "error: no cocktail base inputted\n";
    die;
  }

  print "Output direcotry: $this->{out_dir}\n";

  return $this;
}

sub get_base_dirs {
  my $this = shift;
  return @{$this->{base_dirs}};
}

sub get_base_names {
  my $this = shift;
  return @{$this->{base_names}};
}


1;
