# These are subroutines that are used when diffing files.
use Encode;

local $SIG{__DIE__} = sub {
	my ($message) = "ERROR: $!\n"."@_";
	SendToOutput($LOGFILE,$message,"both");
};

local $SIG{__WARN__} = sub {
	my ($message) = "WARNING: $!\n"."@_";
	SendToOutput($LOGFILE,$message,"both");
};

sub ReturnDiffTypes {
	my ($DIFFILE)=@_;
	my $diffs=0;
	my $n_ignore=0;
	my $i=0;
	my $v1;
	my $v2;
	my $n1=0;
	my $n2=0;
	my $min;
	my $max;
	my $same=0;
	my @baseline;
	my @compare;

	open ( DIFFILE, "<", $DIFFILE );
	foreach my $case(<DIFFILE>) {
		chomp $case;
		if ( $case eq "---" ) {
			$diffs++;
		} elsif ( $case =~ "IGNORE THIS LINE" ) {
			$n_ignore++;
		} elsif ( $case =~ /[0-9]+[cd]+[0-9]+/ ) {
			#A diff instruction - do nothing
		} else {
			my $first=substr($case,0,1);
			if ( $first eq "<" ) {
				$n1++;
				push(@baseline,substr($case,2));
			} elsif ( $first eq ">" ) {
				$n2++;
				push(@compare,substr($case,2));
			}
		}
	}
	close DIFFILE;

	$min=$n1;
	$max=$n1;
	if ( $n2 < $n1 ) { $min=$n2; }
	if ( $n2 > $n1 ) { $max=$n2; }

	#baseline or compare may be empty.
	if ( $n1 <= 0 || $n2 <= 0 ) {
		$diffs=$max;
		$same=0;
		goto GetOut;
	}

	#Restrict this only to the case where baseline and comparison have the same number of cases.
	#if ( $n1 != $n2 ) { goto GetOut; }

	for ($i=0; $i<=$min-1; $i++) {
		$a1=scalar @arr1;
		$a2=scalar @arr2;
		if ( $a1 == $a2 ) {
			my $j=0;
			my $now_same=0;
			for ($j=0; $j<=$a1-1; $j++) {
				if ( $arr1[$j] ne $arr2[$j] ) {
					if ( index($arr1[$j],"number=\"") > 0 ) {
						$v1=ExtractValue($arr1[$j], "number=\"", '"');
						$v2=ExtractValue($arr2[$j], "number=\"", '"');
						if (( abs($v1) - abs($v2) ) == 0 ) { $now_same++; }
					}
				} else {
					$now_same++;
				}
			}
			my $x=scalar(@arr1)-1;
			if ( $now_same == $x ) { $same++; }
		}
	}
	GetOut:
	my $ret_value=join(":",$n_ignore,$diffs,$same);
	return $ret_value;
}

sub ExtractValue {
	my $line = $_;
	my $lhs = $_[0];
	my $rhs = $_[1];
	chomp($line);
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

sub DeleteLine {
	my @array = @{$_[0]};
	my $x = $_;
	my $find = '';
	my $n = 0;
	my $l = 0;
	chomp($x);
	for ($i = 0; $i <= scalar(@array)-1; $i++) {
		$find = Trim($array[$i]);
		$l = length($find);
		$n = index($x, $find);
		if ( $n >= 0 && $l > 0 ) {
			$_ = "IGNORE THIS LINE\n";
			last;
		}
	}
	return $_;
}

sub DeleteWords {
	my @array = @{$_[0]};
	my $replace = "";
	my $find = "";
	for ($i = 0; $i <= scalar(@array)-1; $i++) {
		$find = Trim($array[$i]);
		if ( $_ =~ $find ) { $_ =~ s/$find/$replace/g; }
	}
	return $_;
}

sub SnipSection {
	my @array = @{$_[0]} ;
	for ($i = 0; $i <= scalar(@array)-1; $i++) {
		my @snip =  split /~/, $array[$i] ;
		my $left_arg = $snip[0] ;
		my $right_arg = $snip[1] ;
		my $found_left = index($_,$left_arg) ;
		my $found_right = index($_,$right_arg,$found_left);
		if ( $found_left ge 0 && $found_right gt 0 ) {
			$string_to_cut = substr($_,$found_left,$found_right+length($right_arg));
			s/$string_to_cut/SECTION_SNIPPED/g ;
		}
	}
	return $_ ;
}

sub Replace {
	my @array = @{$_[0]};
	my $replace = "";
	my $find = "";
	for ($i = 0; $i <= scalar(@array)-2; $i++) {
		$find = Trim($array[$i]);
		$replace = Trim($array[$i+1]);
		if ( $_ =~ $find ) { $_ =~ s/$find/$replace/g; }
	}
	return $_;
}

sub MakeEdits {
	$diffs = 0;
	my $file = $_[0];
	my $temp = $_[1];
	my @array1 = @{$_[2]};
	my @array2 = @{$_[3]};
	my @array3 = @{$_[4]};
	my @array4 = @{$_[5]};
	open( F, "<", "$file") || warn;
	open( DIF, ">", "$temp" );
	while (<F>) {
		if ( $#array1 > 0 ) { DeleteWords (\@array1); }
		if ( $#array2 > 0 ) { DeleteLine (\@array2); }
		if ( $#array3 > 0 ) { Replace(\@array3); }
		if ( $#array4 > 0 ) { SnipSection(\@array4); }
		print DIF $_ ;
		if ( $_ =~ "IGNORE THIS LINE" || $_ =~ "SECTION_SNIPPED" ) { $diffs++ ; }
	}
	close DIF;
	close F;
	return $diffs;
}


sub Diff {
	my $root=$_[0];
	my $my_diff_ext=$_[1];
	my $LANGSHORT=$_[2];
	my $COMP_OUTPUT=$_[3];
	my $identical = "False";
	my $b_ignore_these = 0;
	my $c_ignore_these = 0;
	my $result = "UNDEFINED";
	my $sev = 5;
	my $baseline;
	my $baselinedir=q{};
	
	$jobs++;
	local $/;
	
	if ( $LANGSHORT eq "NONE" ) { $baselinedir=$DIFF_BASELINE; } else {	$baselinedir=$DIFF_BASELINE."/".$LANGSHORT; }
	
	my $comparisondir=$COMP_OUTPUT;
	my $b = $baselinedir."/".$root.$my_diff_ext;
	my $c = $comparisondir."/".$root.$my_diff_ext;
	my $d = $diffdir."/".$root.".dif";
	my $d_tmp = $TEMP_DIR."/d.txt";
	my $n_ignore = 0;
	my $n_not_ignore = 0;
	my $filedatetime;
	my $only_ignorable_diffs=0;
		
	if ( -e $c ) { #Comparison file exists
		my $csz = -s $c ;
		my $bsz = -s $b ;
		if ( ($bsz / 2) > $csz || ($csz / 2) > $bsz  ) {
			$sev = 5 ;
			$result = "NOT DIFFED (File sizes too different)";
			$n_not_ignore = "?";
			goto BYPASS;
		}

		$/ = "\n";
		#The files may already be identical. Check that and go to the next file if they are
		my $q='"';
		my $cmd = "diff -s ".$q.$b.$q." ".$q.$c.$q." 1>".$d_tmp;
		system( $cmd );							# run diff program
		
		$identical = "False";
		my $firstLine = q{};
		open my $file, '<', "$d_tmp" or warn "$!"; 
		$firstLine = <$file>;
		close $file;
		unlink $file;
		print STDOUT "Diffing $root...";
		my $this_max = length($root);
		if ( $this_max > $max_name_width ) { $max_name_width = $this_max }; 
		if ( $firstLine =~ " are identical" ) {
			$identical = "True" ;
			if ( $move == 1 ) {
				if ( $print_line == 1 ) {
					printf MOVE_FILES "mkdir -p $new_baseline\r\n" ;
					printf MOVE_FILES "set b=$new_baseline\r\n" ;
					printf MOVE_FILES "set c=$comparisondir\r\n" ;
					$print_line = 0;
				}
				my $arg = "mv \"%%c%%/$root\"".".* %%b%%" ;
				printf MOVE_FILES "$arg\r\n" ;
			}
		} else {
			$identical = "False" ;
			my $b_tmp = "$TEMP_DIR"."/b.txt";
			my $c_tmp = "$TEMP_DIR"."/c.txt";
			$b_ignore_these = 0;
			$c_ignore_these = 0;
			$n_ignore = 0;
			$b_ignore_these = MakeEdits ($b, $b_tmp, \@delete_words, \@delete_line, \@replace, \@delete_from_to) ;
			$c_ignore_these = MakeEdits ($c, $c_tmp, \@delete_words, \@delete_line, \@replace, \@delete_from_to) ;
			$n_ignore = $b_ignore_these + $c_ignore_these ;
			my $q='"';
			my $cmd = "diff -bisw $q$b_tmp$q $q$c_tmp$q 1>$q$d_tmp$q";
			my $mv_cmd = "mv $d_tmp $q$d$q";
			system( $cmd );							# run diff program
			# There could be a bunch of ignorable differences in this file ($d_tmp).
			my $triv_diff_data=ReturnDiffTypes($d_tmp);
			my @info=split(":",$triv_diff_data);
			my $ignorable=$info[0];
			my $found=$info[1];
			my $removed=$info[2];
			if ( $found > 0 && $found == $removed ) {
				$n_ignore = $removed;
				$only_ignorable_diffs=1;
				} else {
				# $d_tmp may contain only lines containing the phrase "IGNORE THIS LINE".
				# If so, then there really are no differences.
				if ( $found == 0 && $ignorable > 0 ) {
					$only_ignorable_diffs=1;
				} else {				
					system( $mv_cmd );
					$only_ignorable_diffs=0;
				}
			}
			unlink $b_tmp, $c_tmp;
		}
		if ( $identical eq "False" ) {
			if ( $only_ignorable_diffs==0 ) {				
				open( DIF, "<", "$d");
				$n_not_ignore = 0;
				while (<DIF>) {
					my $ch1 = substr( $_, 0, 1);
					if ( $ch1 =~ ">" || $ch1 =~ "<" ) { $n_not_ignore++ ;}
					}
				close DIF;
			} else {
				$n_not_ignore = 0;
				$b_ignore_these = 0;
				$c_ignore_these = 0;
			}
			if ( $n_not_ignore == 0 ) { #Somehow the files are virtually identical
				unlink $d;
				if ( $b_ignore_these > 0 || $c_ignore_these > 0 ) {
					$result = "VIRTUALLY IDENTICAL ($b_ignore_these ignorable diff(s) (baseline); $c_ignore_these (comparison))";
					$sev = 2 ;
				} else {
					$result = "VIRTUALLY IDENTICAL ($n_ignore ignorable diff(s))";
					$sev = 3 ;
				}
			} else {
				$sev = 4 ;
				$result = "NOT IDENTICAL ($n_not_ignore non-ignorable diffs, $n_ignore ignorable)";
			}
		} else {
			$sev = 1 ;
			$result = "ABSOLUTELY IDENTICAL";
			unlink $d;
		}
	} else {
		print "Cannot find $c\n";
		$sev = 5 ;
		$result = "NOT DIFFED (Comparison file does not exist)";
		$n_not_ignore = "?";
	}
				
	print STDOUT "$result\n";
	
	BYPASS:
	#$arr_diff_totals[$sev]++;
	#$arr_result_string[$jobs] = join ":", $sev, $root, $result, $n_not_ignore;
	
	$job_result=join ":", $sev, $root, $result, $n_not_ignore;
	
	if ( -e $c ) {
		#use Time::localtime;
		$datetime_string = ctime(stat($c)->mtime);
	} else {
		$datetime_string = "N/A";
	}

	#                 BUILD (A12) PLATFORM (A12) TEST_CASE (A120) TEST_SUITE (A12) TEST_RESULT (A12) TEST_DATE (A40) LANGUAGE (A12)
	$print_string="'".$BUILD."','".$PLATFORM."','".$root."','".$TEST_SUITE."','".$sev."','".$datetime_string."','".$OLANG."'";
	print SYNTAX "$print_string\n";
	return $job_result;
}
