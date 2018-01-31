# These are subroutines that may be called by multiple PERL scripts.
use Encode;

local $SIG{__DIE__} = sub {
	my ($message) = "ERROR: $!\n"."@_";
	SendToOutput($LOGFILE,$message,"both");
};

local $SIG{__WARN__} = sub {
	my ($message) = "WARNING: $!\n"."@_";
	SendToOutput($LOGFILE,$message,"both");
};

sub Trim { my $s = shift; $s =~ s/^\s+|\s+$//g; return $s };

sub SendToOutput {
	my ($log,$output,$where)=@_;
	for ( $where ) {
		if ( /log|both/ ) {
			open (LOGOUT, ">>", $log) or warn;
			print LOGOUT "$output\n";
			close LOGOUT;
		}
		if ( /stdout|both/ ) { print STDOUT "$output\n"; }
	}	
	return;
}

sub CheckDir {
	my ($dir) = @_;
	if (-d $dir) {
		# Nothing to do
	} else {
		umask 0777 ;
		mkdir $dir ;
	}
	return;
}

sub get_sorted_files {
   my $path = shift;
   opendir my($dirh), $path or die "Cannot opendir $path: $!";
   my @flist = sort {  -M $a <=> -M $b } # Sort by modification time
               map  { "$path/$_" } # We need full paths for sorting
               readdir $dirh;
   closedir $dirh;
   return @flist;
}

sub DefineVarValue {
my ($line,$option,$value,$uc,$default) = @_;
	if ( lc($line) =~ lc($option) ) {
		$value = substr($line,index($line,"=")+1);
		if ( $value eq q{} ) { $value = $default; }
		if ( $uc ) { $_[2]=uc($value); } else { $_[2]=$value; }
		return;
	}
}

sub Enclose {
	my ($string,$value) = @_;
	my $new_value=$string=$value.$string.$value;
	return $new_value;
}

sub Remove {
	my $target=$_[0];
	my $remove=$_[1];
	$x=$target;
	$x=~s/$remove//g;
	return $x;
}

sub RemoveLast {
	my ($char,$var)=@_;
	$l=length($var)-1;
	$z=substr($var,$l,1);
	if ( $z eq $char ) { $var=substr($var,0,$l); }
	return $var;
}

sub GetOption {
my $line = $_[0];
my $program_option = $_[1];
my $option_value = $_[2];
if ( $option_value eq q{} ) {
	my $option_length = length($program_option);
	if ( substr($line,0,$option_length) eq $program_option ) {
		$option_value = ExtractValue($program_option."=\"", '"');
	} else {
		$option_value = $_[2]; }
}
$_[2] = $option_value;
return $option_value;
}

sub FixDuration {
my $line= $_[0];
	s/PT[0-9]+H[0-9]+M[0-9]+[.]?[0-9]?[0-9]?[0-9]?[S]?/** DURATION **/g;
	s/[0-2]?[0-9]:[0-5][0-9]:[0-5][0-9][.,]?[0-9]?[0-9]?[S]?/** DTIME **/g;
	s/xx:xx:xx.[0-9][0-9]/** TIME **/g;
	return $line;
}

sub Trim {
	$_[0] =~ s/^\s+//; #remove leading spaces
	$_[0] =~ s/\s+$//; #remove trailing spaces
	return $_[0];
}

sub ExtractValue {
my $line = $_[0];
my $lhs = $_[1];
my $rhs = $_[2];
if ( $line =~ $lhs && $line =~ $rhs ) {
	my $n = index($line, $lhs);
	my $l = length($lhs);
	my $start = $n + $l;
	my $y = index($line, $rhs, $start );
	my $len = $y - $start;
	my $value = substr($line, $start, $len);
	return $value;
	}
}

sub RepeatChar {
my $n = $_[0];
my $char = $_[1] ;
my $text = "";
$text =~ s/^(.*)/$char x $n . $1/mge;
return $text;
}

sub ReplaceArrayValues {
	my @array = @{$_[0]};
	my $this_syntax = $_[1];
	for ($i = scalar(@array)-1; $i >= 0; $i--) {
		my $find = "_DATAVAR_".$i;
		my $replace = decode('UTF-8', $array[$i]);
		if ( $this_syntax =~ $find ) { $this_syntax =~ s/$find/$replace/g; }
	}
	return $this_syntax;
}

sub CreateSortedTestCases {
	@testcase = @{$_[0]};
	@sorted_testcases = @{$_[1]};
	$sort_by = $_[2];
	my $choose = 0;
	my $s0 = q{};
	my $s1 = q{};
	for ($sort_by) {
		if (/ID/) { $choose = 1; }
		elsif (/SUBTYPE/) { $choose = 2; }
		elsif (/SELECT/) { $choose = 3; }
		elsif (/RANDOM_NUMBER/) { $choose = 6; }
		else { $choose = 1; }
    }
	my $iCount = -1;
	foreach $case(@testcase) {
		my @line = split('\~', $case);
		$iCount++;
		$s0 = $line[0];
		$s0 =~ s/TEST=//g;
		$s1 = $line[$choose];
		$s1 =~ s/$sort_by=//g;
		$array[$iCount]=join('~',$s1,$s0,$case);
	}
	@sorted_array = sort {$a cmp $b} @array;
	$iCount = -1;
	my $iTestCase = 0;
	foreach $case(@sorted_array) {
		my @line = split('\~', $case);
		$iCount++;
		foreach $testcase(@testcase) {
			my @testline = split('\~', $testcase);
			if ( $testline[0] =~ $line[1] ) {
				$sorted_testcases[$iTestCase] = sprintf("%s", $testcase);
				$iTestCase++;
				last;
			}
		}
	}
	return @sorted_testcases;
}
sub ChangeLine {
my ($input_value,$output_value) = @_;
my $line = $_;
if ( /$input_value/ ) {
	s/$input_value/$output_value/i;  #Change line
} else {
	my $x = index($line,$input_value);
	my $old_len=length($input_value);
	my $lhs = substr($line,0,$x);
	my $rhs = substr($line,$x+$old_len);
	$line = $lhs.$output_value.$rhs;
	$_ = $line; #Change line without using s///
}
return $_;
}

sub GetFormattedValue {
my ($input_value,$threshold,$precision,$format,$decimal_separator,$find_number_pattern) = @_;
if ( $input_value =~ /$find_number_pattern/ ) {
	if ( $3 ne "" ) {
		my $f_format="%".$precision."f";
		my $sign = substr($3,1,1);
		if ( $sign eq "-" && abs($input_value) < $threshold ) { $output_value = "0"; } else { $output_value = sprintf($f_format,$1.$2).uc($3); }
	} else {
		$output_value=ReturnFormattedValue($input_value,$threshold,$precision,$format,$decimal_separator);
	}
	if ( $output_value =~ /E/ ) {
		$output_value =~ s/(-?[0-9]?)($decimal_separator)?([1-9]?)(0+)(E.*)/$1$2$3$5/;
		my $esc = "\\";
		my $d = $esc.$decimal_separator ;
		my $bad = $d."E";
		if ( $output_value =~ /$bad/ ) { $output_value =~ s/$d//; }
	}
}
return $output_value;
}

sub ReturnFormattedValue {
my ($value,$threshold,$precision,$format,$decimal_separator) = @_;
my $numdigits = q{};
$numdigits++ while ($value =~ m/[0-9]/g); # count how many actual digits are in the value
if ( $numdigits > $precision ) {
	if ( abs($value) < $threshold ) { $result = "0"; } else { $result = sprintf($format,$value); }
		my $findstring=$decimal_separator."0{".$precision."}E".'\+'."00";
		$result =~ s/$findstring//g;
} else {
	$result = sprintf("%s", $value);
}
return $result;
}

sub ReturnArray {
    my $arg=@_[0];
    my @array=q{};
    chomp($arg);
    if ( $arg ne "" ) {
        for ($arg) { @array=split(/,/,$arg); }
    } else {
        @array = ();
    }
    return @array;
}

sub ConvertNumerics {
    my($reg_expr, $prefix, $suffix) = @_;
    while (/$reg_expr/) {
        $num = substr($&, $prefix, $suffix);
        if (abs($num) < 1e-12) {  # assume 0 if abs(num)<1E-12
            $num = 0.0;
        }
        $value = sprintf "%s%.6E %s", substr($reg_expr, 0, $prefix), $num, substr($reg_expr, $suffix);
        $qmatch = quotemeta $&;
        s/$qmatch/$value/g;
    }
}
###### The final line of such a file MUST be "true"....
1;
