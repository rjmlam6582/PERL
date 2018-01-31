
local $SIG{__DIE__} = sub {
	my ($message) = "ERROR: $!\n"."@_";
};

local $SIG{__WARN__} = sub {
	my ($message) = "WARNING: $!\n"."@_";
};

sub arrays_are_same {
  my($array1, $array2) = @_;

  # immediately return false if the two arrays are not the same length
	print scalar(@$array1).", ".scalar(@$array2)."\n";
	return 0 if scalar(@$array1) != scalar(@$array2);
	return 1 if scalar(@$array1) == scalar(@$array2);
  
  # turn off warning about comparing uninitialized (undef) string values
  # (limited in scope to just this sub)
  #no warnings;

  #for (my $i = 0; $i <= $#$array1; $i++) {
  #  if ($array1->[$i] ne $array2->[$i]) {
  #    return 0;
  #  }
  #}
  #return 1;
}

sub ExtractFromSyntax {
    my $keep=0;
    my $drop=0;
    my $syntax=$_[0];
    my $LOGFILE=$_[1];
    my @include=@{$_[2]};
    my @exclude=@{$_[3]};
    my $e1=scalar @include;
    my $e2=scalar @exclude;
    
    if ( $e1 > 0 || $e2 > 0 ) {
        my $test=GetCommandArray($syntax); # Gets array of commands in the file (could also return data file names).
        for ( $test ) { s/,,/,/g; } # get rid of empty element
        my $index=index($test,",_END_OF_CMDS_");
        my @command_array=split(/,/,substr($test,0,$index));
        $index=index($test,"_END_OF_CMDS_,");
        my @data_array=split(/,/,substr($test,$index+14));
        
        foreach my $o(@command_array) {
            my $test_string = Trim(uc($o)); #there can be white space that messes up the comparison.
            if ( $e1 > 0 ) {
                if ( $keep == 0 ) {
                    foreach my $ic(@include) {
                        my $reference_string=uc($ic);
                        if ( $test_string eq $reference_string && length($reference_string) > 0 ) {
                            SendToOutput($LOGFILE,"Found included cmd: ".$ic,"both");
                            $keep=1;
                            goto Finished;
                        }
                    }
                }
            } else { $keep = 1; }
            
            if ( $e2 > 0 ) {
                if ( $drop == 0 ) {
                    foreach my $ec(@exclude) {
                        my $reference_string=uc($ec);
                        if ( $test_string eq $reference_string && length($reference_string) > 0 ) {
                            SendToOutput($LOGFILE,"Found excluded cmd: ".$ec,"both");
                            $drop=1;
                            goto Finished;
                        }
                    }
                }
            } else { $drop = 0; }
        }
    } else {
        $drop = 0; $keep = 1;
    }
Finished:
    return $keep, $drop;
}

sub Clean {
    my $text = shift;
    $text =~ s/\n//g;
    $text =~ s/\r//g;
    return $text;
}

sub GetCommandArray {
    my $syntax=$_[0];
    $syntax =~ s/^\x{FEFF}//;
    my $contents=$syntax;
    for ( $contents ) { /\r\n\/\n/g; s/\t/ /g; }
    my @lines=split '\n', $contents;
    #create array of commands from the lines (some lines should probably be concatenated)
    my $ncmd=0;
    my @cmds;
    my $my_cmd="";
    foreach my $c(@lines) {
        my $trimmed=Trim($c);
        my $lc=lc($trimmed);
        my $endcmd=0;
        my $last_char="";
        $last_char=substr($trimmed,length($trimmed)-1,1);
        $endcmd=( $last_char eq "." ); # = 1 if found period as the last non-blank character on the line
        if ( $endcmd eq "1" || $lc =~ "begin data" || $lc =~ "end data" ) {
            if ( $lc =~ "begin data" ) {
                $my_cmd = "begin data."
            } elsif ( $lc =~ "end data" ) {
                $my_cmd = "end data."
            } else {
                if ( Trim($my_cmd) eq "" ) { $my_cmd = $trimmed; } else { $my_cmd= Trim(join(' ', $my_cmd, $trimmed )); }
            }
            $ncmd++;
            $cmds[$ncmd]=$my_cmd;
            $my_cmd="";
        } else {
            $my_cmd= Trim(join (' ', $my_cmd, $trimmed ));
        }
    }
    
    my $f=0;
    my $cmd="";
    $i=0;
    my @code_array;
    my @cmd_array;
    my @count_array;
    my $join=0;
    my $input_file;
    foreach $cmd(@cmds) {
        $input_file="_NO_INPUT_DATA_";
        my $char1=substr($cmd,0,1);
        for ( $char1 ) {
            if ( /\*/ ) { $code = 3; $cmd_count[$code]++; $join=1; }
            elsif ( /\.|\+/ ) {
                my $cmd2=Trim(substr($cmd,1,length($cmd)-1));
                $char1=substr($cmd2,0,1);
                ($code, $input_file)=FindCommand($char1,$cmd2);
                $cmd_count[$code]++;
                $join=1;
                my $tf=Trim($input_file);
                if ( $tf ne "_NO_INPUT_DATA_" && $tf ne "" ) {
                    $f++; $needed_files[$f]=$input_file
                }
            }
            elsif ( /\+/ ) { my $donothing = 1; }
            elsif ( / / ) { my $blank = 0; $code = 0; }
            elsif ( /[A-Za-z]/ || substr(uc($cmd),0,2) eq "2S" ) {
                ($code, $input_file)=FindCommand($char1,$cmd);
                $cmd_count[$code]++;
                $join=1;
                if ( $input_file ne "_NO_INPUT_DATA_" ) { $f++; $needed_files[$f]=$input_file }
            }
            else { my $blank = 0; $code=-1; }
        }
        if ( $join == 1 ) { push @code_array, $code; push @cmd_array, $cmd; push @count_array, $cmd_count[$code]; $join=0; $i++; }
    } #$code_array[$i]=join('|', $cmd_count[$code], $code, $cmd); $join=0; $i++;
    
    $i=0;
    my $total=0;
    my @sorted;
    my $counter=0;
    my $c1="";
    my $j=0;
    for ($j = 0; $j < $#code_array; $j++) {
        my $c=AssignCode($code_array[$j]); my $f=sprintf '%04d', $count_array[$j]; push @sorted, "$f\t$c\n"; $total=$total+$j;
    }
    
    my @sorted_cmds = sort {$b cmp $a} @sorted;
    
    foreach my $c(@sorted_cmds) { $c=substr($c,5,length($c)); }
    
    my @sorted_data = uniq(@sorted_cmds);
    my $arrSize = @sorted_data;
    
    @sorted_cmds = uniq(@sorted_cmds);
    foreach my $c(@sorted_cmds) { chop $c; }
    
    @sorted_data = uniq(@needed_files);
    $arrSize = @sorted_data;
    
    my $rec = join(',',@sorted_cmds,"_END_OF_CMDS_",@sorted_data);
    
    return $rec ;
}

sub MakeDirs {  # dir(sub-dir`sub-dir`etc)
	my @array = @{$_[0]};
	my $c;
	my $i;
	$i=0;
	my @expanded;
	foreach my $c(@array) {
   		my $o;
    	my @ds;
    	if ( index($c,"(") > 0 ) {
        	my $d=index($c,"(");
        	my $e=index($c,")");
        	my $r=substr($c,0,$d);
        	my $list=substr($c,$d+1,($e-1)-$d);
        	@ds=split /`/,$list;
        	foreach my $o(@ds) {
            	$expanded[$i]=$r.$o;
            	$i++;
        	}
    	} else {
        	$expanded[$i]=$c;
        	$i++;
    	}
	}
	@array=@expanded;
	return @expanded;
}

sub GetPathFromFileName {
	my ( $test, $use_this_dir_if_none ) = @_;
	my $separator=q{};
	my $mypath=q{};
	my $element_max=0;
	my $s="\\";
	my $n = () = $s =~ /\//;
	if ( $n > 0 ) { $separator="\\"; } else { $separator="/"; }
	my @path_elements=split /$separator/, $test;
	$element_max=scalar @path_elements;
	if ( $element_max == 1 ) {
		$mypath=$use_this_dir_if_none;
	} elsif ( $element_max == 2 ) {
		$mypath=$path_elements[0];
	} else {
		delete $path_elements[$element_max-1];
		$mypath=join("/",@path_elements);
	}
	return $mypath;
}

sub WaitForJobToBegin {
	my ($start_date,$start_time)=@_;
	my $days=0;
	my $hours=0;
	my $minutes=0;
	my $seconds_left=0;
	my $wait_seconds=0;
	my $msg=q{};

	if ( uc($start_date) eq "TODAY" && uc($start_time) eq "NOW" ) {
		#Do nothing;
	} else {
		print "This job is scheduled to start $START_DATE at $START_TIME.\n";
		my $date_now=strftime('%m/%d/%Y',localtime);
		my $time_now=strftime('%H:%M:%S',localtime);
		my $job_start_date=uc($start_date);
		my $job_start_time=uc($start_time);
		if ( $job_start_date eq "TODAY" ) { $job_start_date=$date_now; }
		if ( $job_start_time eq "NOW" ) { $job_start_time=$time_now; }
		my $d1=GetSecondsFrom($date_now, $time_now);
		my $d2=GetSecondsFrom($job_start_date, $job_start_time);
		if( $d2 < $d1 ) {
			die "The starting date or time has already past. Fix that date and/or time and start again.\n";
		} else {
			$wait_seconds = ($d2 - $d1);
			while ( $wait_seconds > 0 ) {
				$seconds_left=$wait_seconds;
				$days=int($seconds_left / 86400);
				$seconds_left=$seconds_left-($days*86400) ;
				$hours=int($seconds_left / 3600) ;
				$seconds_left=$seconds_left-($hours*3600) ;
				$minutes=int($seconds_left / 60) ;
				$seconds_left=$seconds_left-($minutes*60) ;
				$msg="Waiting $days days, $hours hours, $minutes minutes, and $seconds_left seconds.          ";
				$| = 1;  # Turn off buffering on STDOUT.
				print "$msg\r";
				sleep 1;
				$wait_seconds--;
			}
		}	
	}
}

sub Remainder {
    my ($a, $b) = @_;
    return 0 unless $b && $a;
    return $a / $b - int($a / $b);
}

sub GetSecondsFrom {
	my ($date,$time)=@_;
	my ($mo,$da,$yr)=split("/",$date);
	my ($hr,$mn,$sc)=split(":",$time);
	my $time1 = timelocal( $sc,$mn,$hr,$da,$mo-1, $yr );
	my $date1 = localtime( $time1 );
	return $date1;
}

sub MakeFileName {
	my $location=$_[0];
	my $script=$_[1];
	my $myfile=q{};
	$location =~ s#\"##g;
	$location =~ s#[\\]#/#g;
	
	if ( $script eq "" ) {
		$myfile=$location;
	} else {
		$myfile=$location."/".$script;
	}
	
	return $myfile;
}

sub MakeGlobalEdits {
	my ( $x, $HEADER, $QADATA, $QALOCAL, $QAOUTPUT, $QASERVER, $QATEMP, $QARESULTS, @edits ) = @_;
	$x =~ s/^\x{feff}//;	
	if ( uc($HEADER) ne "_NO_HEADER_" ) { $x = $HEADER."\n".$x; }
	$x =~ s#%QADATA%#$QADATA#g;
	$x =~ s#%QATEMP%#$QATEMP#g;
	$x =~ s#%QAOUTPUT%#$QAOUTPUT#g;
	$x =~ s#%QASERVER%#$QASERVER#g;
	$x =~ s#%QALOCAL%#$QALOCAL#g;
	$x =~ s#%QARESULTS%#$QARESULTS#g;
	
	foreach my $change(@edits) {
		my ($from,$to)=split("=",$change);
		$x =~ s#$from#$to#g;
	}
	return $x;
}

sub MakeDMPTXT {
	my ( $file, $QADATA, $QALOCAL, $QAOUTPUT, $QASERVER, $QATEMP, $LOGFILE, $SCRIPT_LOCATION, $TEMP_DIR, $PRECISION, $THRESHOLD, $NOTES_PRINT, $ACTIVE_DATASET_PRINT, $DECIMAL ) = @_;
	my $N++;
	chomp $file;
	my $xml=MakeFileName($QAOUTPUT,$file);
	SendToOutput($LOGFILE,"Creating DMP & TXT files for $xml...","both");
	open (IN,"<",$xml) or warn;
	my $xml_contents = do { local $/; <IN> };
	close IN;
	$xml_contents =~ s#><#>\n<#g;
	$xml_contents =~ s#.000000E+00##g;
	$xml_contents =~ s#\(E[+-][0-9][0-9]\)\( \)#\$1#g;
	$xml_contents =~ s#[\\]#/#g;
	$xml_contents =~ s#\$QALOCAL#QaLocal#g;
	$xml_contents =~ s#\$QADATA#QaData#g;
	$xml_contents =~ s#\$QAOUTPUT#QaOutput#g;
	$xml_contents =~ s#\$QASERVER#QaServer#g;
	$xml_contents =~ s#\$QATEMP#QaTemp#g;
	$xml_contents =~ s#$QALOCAL#QaLocal#g;
	$xml_contents =~ s#$QADATA#QaData#g;
	$xml_contents =~ s#$QAOUTPUT#QaOutput#g;
	$xml_contents =~ s#$QASERVER#QaServer#g;
	$xml_contents =~ s#$QATEMP#QaTemp#g;
	my $rootname=$file;
	$rootname=~ s/\.xml//g;
	my $PREP_PERL=MakeFileName($SCRIPT_LOCATION,"prep_rjm.pl");
	my $FILE_INFO=MakeFileName($QAOUTPUT,$rootname);
	$FILE_INFO='"'.$FILE_INFO.'"';
	my $C_F=MakeFileName($TEMP_DIR,"tmp_".$N.".txt");
	open (PREP, ">", $C_F);
	print PREP $xml_contents;
	close PREP;
	system("perl $PREP_PERL $C_F $FILE_INFO $PRECISION $THRESHOLD $NOTES_PRINT $ACTIVE_DATASET_PRINT $DECIMAL");
	unlink $C_F;
}

sub get_lang {
	my $_olang = uc($_[0]);
	my $short=q{};
	if    ( $_olang eq "ENGLISH" ) { $short="en";}
	elsif ( $_olang eq "FRENCH" ) {	$short="fr";}
	elsif ( $_olang eq "GERMAN" ) {	$short="de";}
	elsif ( $_olang eq "ITALIAN" ) { $short="it";}
	elsif ( $_olang eq "JAPANESE" ) { $short="ja";}
	elsif ( $_olang eq "KOREAN" ) {	$short="ko";}
	elsif ( $_olang eq "POLISH" ) {	$short="pl";}
	elsif ( $_olang eq "RUSSIAN" ) { $short="ru";}
	elsif ( $_olang eq "SPANISH" ) { $short="es";}
	elsif ( $_olang eq "SCHINESE" ) { $short="zh_CN";}
	elsif ( $_olang eq "TCHINESE" ) { $short="zh_TW";}
	elsif ( $_olang eq "BPORTUGU" ) { $short="pt_BR";}
	elsif ( uc($_olang) eq "NONE" ) { $short="NONE";}
	else {$short="en"};
	return $short;
}

sub RepeatChar {
my $n = $_[0];
my $char = $_[1] ;
my $text = "";
$text =~ s/^(.*)/$char x $n . $1/mge;
return $text;
}

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
		} elsif ( $case =~ /[0-9]+[a-d]+[0-9]+/ ) {
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
		my $a1=scalar @baseline;
		my $a2=scalar @compare;
		if ( $a1 == $a2 ) {
			my $j=0;
			my $now_same=0;
			for ($j=0; $j<=$a1-1; $j++) {
				if ( $baseline[$j] ne $compare[$j] ) {
					if ( index($baseline[$j],"number=\"") > 0 ) {
						my $v1=ExtractValue($baseline[$j], "number=\"", '"');
						my $v2=ExtractValue($compare[$j], "number=\"", '"');
						if (( abs($v1) - abs($v2) ) == 0 ) { $now_same++; }
					}
				} else {
					$now_same++;
				}
			}
			my $x=scalar(@baseline)-1;
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
	my $i = 0;
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
	my $newline=$_;
	my $i = 0 ;
	my $n = 0;
	my $lhs;
	my $rhs;
	chomp($newline);
	for ($i = 0; $i <= scalar(@array)-1; $i++) {
		$find = Trim($array[$i]) ;
		$n = index($newline, $find);
		if ( $n > -1 ) {
			$lhs=substr($_,0,$n);
			$rhs=substr($_,$n+length($find));
			$_ = join("WORD_DELETED",$lhs,$rhs);
		}
	}
	return $_;
}

sub SnipSection {
	my $i = 0;
	my @array = @{$_[0]};
	for ($i = 0; $i <= scalar(@array)-1; $i++) {
		my $find = Trim($array[$i]) ;
		my @snip =  split /\[~\]/, $find ;
		my $left_arg = $snip[0] ;
		my $right_arg = $snip[1] ;
		my $found_left = index($_,$left_arg) ;
		my $found_right = index($_,$right_arg,$found_left);
		if ( $found_left ge 0 && $found_right gt 0 ) {
			my $string_to_cut = quotemeta(substr($_,$found_left,$found_right+length($right_arg)));
			s#$string_to_cut#SECTION_SNIPPED#g ;
		}
	}
	return $_ ;
}

sub Replace {
	my @array = @{$_[0]};
	my $replace = "";
	my $find = "";
	my $nextfind = "";
	my $i = 0;
	for ($i = 0; $i <= scalar(@array)-2; $i++) {
		$find = Trim($array[$i]) ;
		$replace = Trim($array[$i+1]);
		if ( $_ =~ $find ) { $_ =~ s/$find/$replace/g; }
	}
	return $_;
}

sub MakeEdits {
	my @delete_words;
	my @delete_line;
	my @replace;
	my @delete_from_to;
	my $diffs = 0;
	my $file = $_[0];
	my $temp = $_[1];
	if ( $_[2] ne q{} ) { @delete_words = split /,/, $_[2]; } else { @delete_words = "_NOTHING_TO_DO_HERE_" ;}
	if ( $_[3] ne q{} ) { @delete_line = split /,/, $_[3] ; } else { @delete_line = "_NOTHING_TO_DO_HERE_" ;}
	if ( $_[4] ne q{} ) { @replace = split /,/, $_[4] ; } else { @replace = "_NOTHING_TO_DO_HERE_" ;}
	if ( $_[5] ne q{} ) { @delete_from_to = split /,/, $_[5] ; } else { @delete_from_to = "_NOTHING_TO_DO_HERE_" ;}
	open( F, "<", "$file") || warn;
	open( DIF, ">", "$temp" );
	while (<F>) {
		if ( $#delete_words > 0 ) { DeleteWords (\@delete_words); }
		if ( $#delete_line > 0 ) { DeleteLine (\@delete_line); }
		if ( $#replace > 0 ) { Replace(\@replace); }
		if ( $#delete_from_to > 0 ) { SnipSection(\@delete_from_to); }
		print DIF $_ ;
		if ( $_ =~ "IGNORE THIS LINE" || $_ =~ "SECTION_SNIPPED" || $_ =~ "WORD_DELETED" ) { $diffs++ ; }
	}
	close DIF;
	close F;
	return $diffs;
}

sub Diff {
	my ( $root,$my_diff_ext,$baselinedir,$comparisondir,$TEMP_DIR,$diffdir,$new_baseline,$max_name_width,
   	     $MOVE,$print_line,$LANGSHORT,$COMP_OUTPUT,$lang,$BUILD,$PLATFORM,$TEST_SUITE,
         $DELETE_WORDS,$DELETE_LINE,$REPLACE,$DELETE_FROM_TO )=@_;
		 
	my $identical = "False";
	my $b_ignore_these = 0;
	my $c_ignore_these = 0;
	my $result = "UNDEFINED";
	my $sev = 5;
	my $baseline=q{};
	my $datetime_string=q{};
	local $/;

	my $b = $baselinedir."/".$root.$my_diff_ext;
	my $c = $comparisondir."/".$root.$my_diff_ext;
	my $d = $diffdir."/".$root.".dif";
	my $d_tmp = $TEMP_DIR."/d.txt";
	my $n_ignore = 0;
	my $n_not_ignore = 0;
	my $filedatetime;
	my $only_ignorable_diffs=0;
	my $job_result=q{};
	
	my $date_now=strftime('%m/%d/%Y',localtime);
	my $time_now=strftime('%H:%M:%S',localtime);
	my $ratio=0;
	
	if ( -e $b ) {
		#Baseline file exists
		if ( -e $c ) { #Comparison file exists
			my $csz = -s $c ;
			my $bsz = -s $b ;
			my $min=$bsz;
			my $max=$bsz;
			if ( $csz < $bsz ) { $min=$csz; }
			if ( $csz > $bsz ) { $max=$csz; }
			if ( $min == 0 ) { $ratio=-1; } else { $ratio= $max / $min; }
			if ( $ratio == -1 ) {
				$sev = 5 ;
				$result = "NOT DIFFED (A file is empty)";
				$n_not_ignore = "?";
				goto BYPASS;
			} elsif ( ($ratio > 1.2) | ($max-$min)>1000 ) {
				$sev = 5 ;
				$result = "NOT DIFFED (File sizes of $root are too different)";
				$n_not_ignore = "?";
				goto BYPASS;
			}
			$/ = "\n";
			my $q='"';
			my $cmd = "diff -s ".$q.$b.$q." ".$q.$c.$q." 1>".$d_tmp;
			system( $cmd );							# run diff program
			#The files may already be identical. Check that and go to the next file if they are
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
				if ( $MOVE == 1 ) {
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
				$b_ignore_these = MakeEdits ($b, $b_tmp, $DELETE_WORDS,$DELETE_LINE,$REPLACE,$DELETE_FROM_TO) ;
				$c_ignore_these = MakeEdits ($c, $c_tmp, $DELETE_WORDS,$DELETE_LINE,$REPLACE,$DELETE_FROM_TO) ;
				$n_ignore = $b_ignore_these + $c_ignore_these ;
				my $q='"';
				my $cmd = "diff -bisw $q$b_tmp$q $q$c_tmp$q 1>$q$d_tmp$q";
				my $mv_cmd = "mv $d_tmp $q$d$q";
				system( $cmd );							# run diff program
				# There could be a bunch of ignorable differences in this file ($d_tmp).
				# This next part may be time-consuming; may need to figure out some rules to abandon diffing
				# (too many diffs or taking too long)
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
						my $ch1 = substr( $_, 0, 3);
						#if ( $ch1 =~ ">" || $ch1 =~ "<" ) { $n_not_ignore++ ;}
						if ( $ch1 eq "---" ) { $n_not_ignore++ ;}
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
			$sev = 0 ;
			$result = "NOT DIFFED (Comparison file for $root does not exist)";
			$n_not_ignore = "?";
		}
	} else {
		$sev = 0 ;
		$result = "NOT DIFFED (Baseline file for $root does not exist)";
		$n_not_ignore = "?";
		goto BYPASS;
	}
	
	BYPASS:
	$job_result=join ":", $sev, $root, $result, $n_not_ignore;
	print STDOUT "$result\n";
	
	if ( -e $c ) {
		#use Time::localtime;
		$datetime_string = localtime;
	} else {
		$datetime_string = "N/A";
	}

	#                 BUILD (A12) PLATFORM (A12) TEST_CASE (A120) TEST_SUITE (A12) TEST_RESULT (A12) TEST_DATE (A40) LANGUAGE (A12)
	my $print_string="'".$BUILD."','".$PLATFORM."','".$root."','".$TEST_SUITE."','".$sev."','".$datetime_string."','".$lang."'";
	print SYNTAX "$print_string\n";
	return $job_result;
}
