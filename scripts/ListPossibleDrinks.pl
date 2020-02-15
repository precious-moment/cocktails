#!/usr/bin/perl
use strict;
use warnings;
use InputManage;
use Time::Local 'timelocal';

my $params_fname = "ListPossibleDrinks.in";
my $input_obj = InputManage->new($params_fname);

my @dirs = $input_obj->get_base_dirs();
my @titles = $input_obj->get_base_names();

my $date_modify = ( shift || 0 );

sub inv_array_char {
  my $char = shift;
  my $ref  = shift;
  my $idx  = -1;
  my $tmp  = 0;

  foreach my $component (@$ref) {
    if ( $component eq $char ) {
      $idx = $tmp;
      last;
    }
    $tmp++;
  }
  return $idx;
}

my $fname_header = $input_obj->{out_fname_header};
my $tex_fname = $fname_header . ".tex";
my $pdf_fname = $fname_header . ".pdf";
open(OUT,"> $tex_fname") or die "Failed to open $tex_fname (><;)\n";
print OUT "\\documentclass[11pt,dvipdfmx]{article}\n";
print OUT "\\input{NewCommands}\n";
print OUT "\\begin{document}\n";
print OUT "\\maketitle\n\n";

my @ingredients = ();
my $ingred_fname = $input_obj->{ingred_fname};
print OUT "Today's ingredients:\n";
print OUT "\\begin{itemize}\n";
open(IN,"< $ingred_fname") or die "Failed to open $ingred_fname (-_-;)\n";
while(<IN>) {
  chomp;
  s/^\s+//;
  next if /^$/;
  next if /^#/;
  my @l = split('\s+',$_);
  print OUT "\\item ";
  for ( my $i = 0 ; $i <= $#l; $i++ ) {
    print OUT " / " unless ( $i == 0 );
    print OUT $l[$i];
  }
  print OUT "\n";
  push (@ingredients,@l);
}
close(IN);
print OUT "\\end{itemize}\n\n";
print "@ingredients\n";

print OUT "\\clearpage\n";
print OUT "\\tableofcontents\n\n";

for ( my $i = 0 ; $i <= $#dirs ; $i++ ) {
  my $list_fname = $dirs[$i] . "/list.txt";
  next unless ( -f $list_fname );
  my @list = ();
  open(IN,"< $list_fname") or die "Failed to open $list_fname (x_x;\n";
  while(<IN>) {
    chomp;
    s/^\s+//;
    s/\s+$//;
    next if /^$/;
    next if /^#/;
    my $recipe_fname = $dirs[$i] . "/" . $_ . ".tex";
    unless ( -f $recipe_fname ) {
      print "error: TeX file \"$recipe_fname\" is not found (><;)\n";
      next;
    }
    my $flag = 1;
    open(REC,"< $recipe_fname") or die "Failed to open $recipe_fname ('_'?)\n";
    while(<REC>) {
      chomp;
      s/^\s+//;
      next unless /^\\item\s/;
      next if (/optional/);
      s/^\\item\s+//;
      my $cand = "";
      $cand = $1 if ( /^(\S+)\s*/ );
      next unless ( $cand =~ /^\\/ );
      my $test = &inv_array_char($cand,[@ingredients]);
      print "### $cand : $test : $_\n";
      next unless ( $test == -1 );
      if ( /\(\s*or\s+(\\\w+)\W/ ) {
        $test =  &inv_array_char($1,[@ingredients]);
        print "??? $1 : $test : $_\n";
        $flag = 0 if ( $test == -1 );
      } else {
        $flag = 0;
        print "??? $_\n";
      }
    }
    close(REC);
    if ( $flag == 0 ) {
      print "$recipe_fname skipped\n";
      next;
    }

    $recipe_fname =~ s/\.tex$//;
    push(@list,$recipe_fname);
  }
  close(IN);
  next if ( $#list == -1 );
  print OUT "\\clearpage\n";
  print OUT "\\section{$titles[$i]}\n\n";
  for ( my $j = 0 ; $j <= $#list ; $j++ ) {
    print OUT "\\clearpage\n" if ( $j > 0 && $j%4 == 0 );
    print OUT "\\input{$list[$j]}\n";
  }
  print OUT "\n";
}
print OUT "\\end{document}\n";
close(OUT);
print "LaTeX source produced\n";

print (`$input_obj->{latex_command} $input_obj->{latex_flags} $fname_header > tmp`);
print (`$input_obj->{latex_command} $input_obj->{latex_flags} $fname_header > tmp`);
#print (`ptex2pdf -l -ot "--shell-escape -synctex=1 -file-line-error" $fname_header > tmp`);
unlink("tmp");
print "LaTeX compile successful!\n";

my @date = (localtime(time+ 60*60*24*$date_modify))[3..5];
$date[2] += 1900;
$date[1]++;

my $out_dir = sprintf("%s/%4d.%02d.%02d/",
                      $input_obj->{out_dir},$date[2],$date[1],$date[0]);
print (`cp $pdf_fname ../`);
print (`mkdir -p $out_dir`);
print (`mv $tex_fname $pdf_fname $out_dir`);
foreach my $tail (".aux",".log",".synctex.gz") {
  my $del_fname = $fname_header . $tail;
  unlink($del_fname);
}

$pdf_fname = $out_dir . $pdf_fname;
print (`open $pdf_fname`);

exit 0;
