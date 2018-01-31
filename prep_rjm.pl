#!/usr/local/bin/perl
# filename: prep_rjm.pl
#
# This perl script translates numbers from an unspecified number of
# significant digits to 7 significant digits.  It also assumes a number
# is 0 if abs(number)<threshold.
#
# Usage: perl prep_rjm.pl <args>
#
# History
#  01 Mar 04 kphelan - Initial version
#     Jan 14 richardm - Extensive changes

require 'common_functions.pl';

local $SIG{__DIE__} = sub {
	my ($message) = "ERROR: $!\n"."@_";
	SendToOutput($LOGFILE,$message,"both");
};

local $SIG{__WARN__} = sub {
	my ($message) = "WARNING: $!\n"."@_";
	SendToOutput($LOGFILE,$message,"both");
};

my $args = $#ARGV + 1;
if ($args<7 || $args>7) {
    print "Error: Usage: perl prep2.pl\n";
    print "       Input read from stdin.  Output sent to stdout.\n";
	print "       Saw this many arguments: ", $args, ".";
    exit;
}

#DEFAULTS
$precision = "6";
$threshold = "1E-12";
$decimal_separator = "." ;

# inputs to program: "${c_f}" "${DMP_FILE}" "${PRECISION}" "${THRESHOLD}"
my $inputfilename = $ARGV[0];
my $dmpfilename = $ARGV[1].".dmp";
my $txtfilename = $ARGV[1].".txt";
$precision = $ARGV[2];
$threshold = uc($ARGV[3]);
$notes_print = lc($ARGV[4]);
$active_dataset_print = lc($ARGV[5]);
my $ds = lc($ARGV[6]);

if ( $ds = "dot" ) { $decimal_separator = "." ; } else { $decimal_separator = "," }
$find_number_pattern = "(-?[0-9]+)(".$decimal_separator."[0-9]{1,})?([Ee][\+\-][0-9]{1,})?";
$model_pattern = "(chiSquare|adjPValue|pValue|x-volume|noiseVolume|value|improvement|importance|score|stdDev|mean|fStats|maximum|minimum|beta|fieldWeight|interQuartileRange|quantile|dataUsage)=\"";
$pmml_pattern = "&lt;(LinearNorm |MiningField |Importance |NumericInfo |Quantile |Goodness |Counts |Cluster )";

# Fix any PMML input so that its output is more understandable in the DMP files.
my $content;
open FILE, "<".$inputfilename;
$content = do { local $/; <FILE> };
close FILE;
$content =~ s#\r\n#\n#g; #Change crlf to lf

my $find_start = '<model>';
my $find_end = '</model>';

my $offset = 1;
my $model_statement = 0;
$model_statement = index($content, $find_start, $offset);

if ( $model_statement > 0 ) {
	my @fields = split /$find_start/, $content;
	my $i=0;
	open (FILE, ">",$inputfilename);
	for $fields (@fields) {
		if ( index($fields, $find_end) > 0 ) { #<model> ... </model>
			print FILE "<model>\n";
			#$fields =~ s/(?:\G|^)[ ]{2}/\t/mg;
			$fields =~ s/\r\n/\n/g;
			$fields =~ s/&gt;[ ]*&lt;/&gt;\n&lt;/g;
		}
		print FILE "$fields\n";
	}
	close FILE;
}

open (IN, '<:encoding(UTF-8)',$inputfilename) || die;
open (DMP, '>:encoding(UTF-8)', $dmpfilename) || die;
open (TXT, '>:encoding(UTF-8)', $txtfilename) || die;

$format = "%.".$precision."E";
#$x=binmode(STDOUT);  # do not terminate lines with carriage ret, linefeed
$notesTable = 0;
$PrintLine = "True";
$tempBlock = "False";
$PrintedNumberToTXT = "False";
$OntextBlock = 0;
$OntextLog = 0;
$OnModel = 0;
$OnTreeModel = 0;
$PrintLineToText = 0;
#$OnDataList = 0;
my @lineblock = q{};
my $lineCount = 0;
my $onSimpleTable = 0;

while (<IN>) { # loop through input file one line at a time
	$end = 0;
	$onRow = 0;
	$tempBlock = "False";
	$onComment = "False";
	
	if ( $onSimpleTable == 1 ) { #This is to place a title for a table found in at least some PMML
		$value=ExtractValue($_,"name=\"","\"");
		print TXT "SimpleTable: $value","\n";
		$onSimpleTable = 0;
	}
	
	if ( /^<pivotTable / ){
		$value=ExtractValue($_,"subType=\"","\"");
		print TXT "pivotTable: $value","\n";
		$OntextBlock = 0;
	} elsif ( /^<chartTitle / ){
		$value=ExtractValue($_,"text=\"","\"");
		print TXT "chartTitle: $value","\n";
		$OntextBlock = 0;
	} elsif ( /^<textBlock text="Text Output"/ ){
		$value=ExtractValue($_,"text=\"","\"");
		print TXT "textBlock: $value","\n";
		$OntextBlock = 1;
	} elsif ( /^<textBlock text="Log"/ ){
		$OntextLog = 1;
	} elsif ( /^<modelTitle / ) {
		$OnModel = 1;
		$value=ExtractValue($_,"text=\"","\"");
		print TXT "modelTitle: $value","\n";
	} elsif ( /^<treeTitle / ) {
		$OnTreeModel = 1;
		$lineCount = 0;
		$value=ExtractValue($_,"text=\"","\"");
		print TXT "treeTitle: $value","\n";
	} elsif ( /&lt;SimpleTable/ ) {
		$onSimpleTable = 1;
	} elsif ( /^<\/modelTitle>/ ) {
		$OnModel = 0;
	} elsif ( /^<\/treeTitle>/ ) {
		$OnTreeModel = 0;
	}
	
	#if ( /^<line>[Bb][Ee][Gg][Ii][Nn]\s[Dd][Aa][Tt][Aa]/ ) {$OnDataList = 1 ;}
	#if ( /^<line>[Ee][Nn][Dd]\s[Dd][Aa][Tt][Aa]/ )         {$OnDataList = 0 ;}
	
	$value=q{};
	
	if ( $active_dataset_print eq "no" && /^<textBlock text="/ ){
				if ( /Conjunto de dados ativo/ || /Active Dataset/ || /Jeu de données actif/
 				|| /Aktiver Datensatz/ || /Dataset attivo/ || /アクティブ データセット/
				|| /활성 데이터 세트/ || /Aktywny zbiór danych/ || /Активный набор данных/
				|| /Conjunto de datos activo/ || /作用中資料集/ || /活动数据集/ ) {
					$PrintLine = "False"
				} else {
					$PrintLine = "True"
				}
			}
    if ( $notesTable ) {
		# special processing for Notes tables only
		if ( /cell text="/ ){ s/\r//g; }
		if ( /number="/ ){
			my $line = $_;
			if ( $line =~ /(number=\")($find_number_pattern)(\")/ ) {
				$value=ReturnFormattedValue($2,$threshold,$precision,$format,$decimal_separator);
				$_ =~ s/$2/$result/;
			if ( $value ne "" ) { print TXT "$value\n"; $PrintedNumberToTXT = "True";}
			}
		}	
		$value = q{};

        SWITCH: {
		
          /^<dimension axis="/
              && do {
                      s/displayLastCategory="[a-z]*" //g;
                      last SWITCH;
                    };
		  /^<cell duration=/
              && do {
			  		my $line = $_;
					FixDuration($line);
                    last SWITCH;
					};
		  /^<cell date=/
              && do {
					if ( /format="datetime"/ ) {
					   #    2    0    1    4  -  0   3  -  1    8  T  0    9  :  3    9  :  3   8
						s/[12][0-9][0-9][0-9]-[01][0-9]-[0-3][0-9]T[0-2][0-9]:[0-5][0-9]:[0-5][0-9]\.?[0-9]?[0-9]?/** DATETIME **/g;
						s/[0-3][0-9]-[A-Z][A-Z][A-Z]-[12][0-9][0-9][0-9]\s[0-2]?[0-9]:[0-5][0-9]:[0-5][0-9]/** DATETIME ** /g;
					} else {
						s/[0-3][0-9]-[A-Z][A-Z][A-Z]-([12][0-9])?[0-9][0-9]/** DATE **/g;
						s/[12][0-9][0-9][0-9]-[01][0-9]-[0-3][0-9]/** DATE **/g;
						s/[0-2]?[0-9]:[0-5][0-9]:[0-5][0-9]/** TIME **/g;
						s/xx:xx:xx.[0-9][0-9]/** TIME **/g;
					}
					last SWITCH;
                    };
		  /^<\/pivotTable>$/
              && do {
                      $notesTable = 0;
					  if ( $PrintLine eq "False" ) {
						$PrintLine = "True";
						$tempBlock = "True"; }
                      last SWITCH;
					};
		#2014-01-08T16:25:12.73
		 #    2   0    1    4  - 0    1  -  0    4  T  1    1  :  4    6  :  4    7  .?   0?     4?
		  s/[12][0-9][0-9][0-9]-[01][0-9]-[0-3][0-9]T[0-2][0-9]:[0-5][0-9]:[0-5][0-9].?[0-9]?[0-9]?/** DATETIME **/g;
		 #    0    4  -  J    A    N  -  2   0    1    4      1     1  :  4    8  :  4    4
		 #    0    8  -  J    A    N  -  2   0    1    4      1     6  :  2    5  :  1    2
          s/[0-3][0-9]-[A-Z][A-Z][A-Z]-[12][0-9][0-9][0-9]\s[0-2]?[0-9]:[0-5][0-9]:[0-5][0-9]/** DATETIME ** /g;
          s/[12][0-9][0-9][0-9]-[01][0-9]-[0-3][0-9]/** DATE **/g;
          s/[0-2]?[0-9]:[0-5][0-9]:[0-5][0-9]/** TIME **/g;
          s/xx:xx:xx.[0-9][0-9]/** TIME **/g;
          s/T[0-2][0-9]H[0-5][0-9]M[0-5][0-9].?[0-9]?[0-9]?S/** TIME **/g;
          s%^<cell text="[1-9][0-9]* bytes"/>$%<cell text="? bytes"/>%g;
		  };
    } else {
        # processing for all tables except Notes
		
		if ( $OnModel )
			{ s/^\s+//; } #{ s/[\s]{2,}//g; } #Trim left spaces in model blocks
		if ( $OnTreeModel ) {
			s#&lt;#<#g;
			s#&gt;#>#g;
		}
		
        SWITCH: {
          /^<pivotTable subType="Notes"/
              && do {
                      $notesTable = 1;
					  $OntextBlock = 0;
					  if ( $notes_print eq "no" ) { $PrintLine = "False"; } else { $PrintLine = "True"; }
                      last SWITCH;
                    };
		  /<?xml /
              && do {
					$tempBlock = "True";
					last SWITCH;
					};
		  /^\*/
			  && do {
					$onComment = "True";
					last SWITCH;
					};			  
		  /^<\/textBlock>/
              && do {
					if ( $active_dataset_print eq "no" && $PrintLine eq "False" ){ $tempBlock = "True"; }
					$PrintLine = "True";
					if ( $OntextBlock ) { $tempBlock = "True"; }
					$OntextLog = 0;
					last SWITCH;
                    };
		  /^<dimension axis="/
              && do {
                      s/displayLastCategory="[a-z]*" //g;
                      last SWITCH;
                    };
          /^<line>[012][0-9]:[0-5][0-9]:[0-5][0-9] /
              && do {
                      $qmatch = quotemeta $&;
                      s/$qmatch/<line>xx:xx:xx /g;
                      last SWITCH;
                    };
          /^<line>[0123][0-9] [A-Z][a-z][a-z] [0-9][0-9]/
              && do {
                      $qmatch = quotemeta $&;
                      s/$qmatch/<line>dd MMM yy/g;
                      last SWITCH;
                    };
		  /^<[r|R]ow>|^&lt;Row&gt;/
              && do {
					chomp;
					s/<row>//;
					s/<\/row>//;
					s/&lt;Row&gt;//;
					s/&lt;\/Row&gt;//;
					$onRow = 1;
					my @row = split(/;/, $_);
					my $size = scalar(@row);
					$iCount = 0;
					$result = q{};
					print DMP "<row>";
					print TXT "row: ";
					$PrintedNumberToTXT = "True";
					foreach my $row(@row) {
						$result=q{};
						if ( $row == 0 && $row ne '0') {
							$result=$row;
						} else {
							$result=GetFormattedValue($row,$threshold,$precision,$format,$decimal_separator,$find_number_pattern);
						}
						my $list_separator=",";
						if ( $decimal_separator ne "." ) { my $list_separator=";" ; };
						if ( $iCount < $size - 1 ) {
							for my $fh ( \*DMP, \*TXT ) { print $fh $result.$list_separator; }
						} else {
							for my $fh ( \*DMP, \*TXT ) { print $fh $result; }
						}
						++$iCount;
					}
					print DMP "</row>";
					for my $fh ( \*DMP, \*TXT ) { print $fh "\n"; }
                    last SWITCH;
                    };
           /number="/
              && do {
					my $line = $_;
					my $output_value;
					my $input_value=ExtractValue($line,"number=\"","\"");
					$output_value = GetFormattedValue($input_value,$threshold,$precision,$format,$decimal_separator,$find_number_pattern);
					ChangeLine($input_value,$output_value);
					if ( $PrintLine eq "True" ) {
						print DMP $_;
						if ( $output_value ne "" ) { print TXT $output_value,"\n"; $PrintedNumberToTXT = "True"; }
						goto NEXT_LINE;
						$tempBlock="True";
						}
					last SWITCH;
					};
           /$pmml_pattern|$model_pattern/
              && do {
			  		chomp;
					my $line = $_;
					my @row = split(/ /, $line);
					my $size = scalar(@row);
					my $output_value = q{};
					my $quote = '"';
					foreach my $row(@row) {
						if ( $row =~ /(\")($find_number_pattern)(\")/) {
							$output_value=GetFormattedValue($2,$threshold,$precision,$format,$decimal_separator,$find_number_pattern);
							ChangeLine($2,$output_value);
						}
					}
					$_ = $_."\n"; #add newline back
					if ( $PrintLine eq "True" ) {
						if ( $output_value ne "" ) { print TXT $output_value,"\n"; $PrintedNumberToTXT = "True"; }
					}
					last SWITCH;
                    };
           /&lt;Array n=/
              && do {
					chomp;
                    my $y = index($_,"&gt;");
					my $lhs = substr($_,0,$y+4);
					my $line = substr($_,$y+4);
					$line =~ s#&lt;\/Array&gt;##g;
					my @row = split(/ /, $line);
					my $result=q{};
					my $newline=q{};
					foreach my $row(@row) {
							$output_value=GetFormattedValue($row,$threshold,$precision,$format,$decimal_separator,$find_number_pattern);
							$newline=$newline.' '.$output_value;
					}
					$_ = $lhs.$newline."</Array>\n" ;
					$_ =~ s#&lt;#<#g; #change to < and >
					$_ =~ s#&gt;#>#g;					
					$line = $_ ;
					$line =~ s#\/Array>##g;
					$line =~ s#> #\n#g;
					$line =~ s#[\<\>\"]##g; #finally, remove <, >, and double quotes
					if ( $PrintLine eq "True" ) { print TXT $line; $PrintedNumberToTXT = "True"; }
                    last SWITCH;
                    };
		   /^<dataValue /
              && do {
                      ConvertNumerics("\">-?[0-9]*[.][0-9]*(e[\+-][0-9]+){0,1}</dataValue>", 2, -12);
                      last SWITCH;
                    };
          /^<location /
              && do {
                      ConvertNumerics("\"-?[0-9]*[.][0-9]*(e[\+-][0-9]+){0,1}%\"", 1, -2);
                      last SWITCH;
                    };
          /^<line> *\(Entered [0123][0-9]-[A-Z][a-z][a-z]-[0-9]{4}\)<\/line>$/
              && do {
                      s/^.*$/<line> (Entered ** DATE **)<\/line>/g;
                      last SWITCH;
                    };
          /^<line>\$.*=.* \$(DATE|DATE11|JDATE|TIME) *= */
              && do {
                      $match = $&;
                      $match .= "random text</line>";
                      s/^.*$/$match/g;
                      last SWITCH;
                    };
          /^<line> +Server locale: /
              && do {
                      $match = $&;
                      $match .= substr($', 0, 2);
                      $match .= "</line>";
                      s/^.*$/$match/g;
                      last SWITCH;
                    };
          /^<line>[0-9,]* megabytes of disk/
              && do {
                      $qmatch = quotemeta $&;
                      $match = "<line>? megabytes of disk";
                      $match .= $';
                      s/^.*$/$match/g;
                      last SWITCH;
                    };
          /^<line>/
              && do {
                    s/[1-9][,0-9]* bytes /*** bytes /g;
					my $line = $_;
					my $x=substr($line,6,9);
					my $first=substr($x,0,1);
					my $BlanksAreRight="NO";
					my $Char4Numeric="NO";
					my $Char7_0thru5="NO";
					my $Char1_isRight="NO";
					my $Char23_isRight="NO";
					if ( $first =~ /[ 1-9]/ ) { $Char1_isRight = "YES" ; }
					if ( substr($x,1,2) =~ /[ 0-9]/ ) { $Char23_isRight="YES";}
					if ( substr($x,4,2) eq "  " && substr($x,7,2) eq "  " ) { $BlanksAreRight="YES" ; }
					if ( substr($x,3,1) =~ /[0-9]/ ) { $Char4Numeric="YES";}
					if ( substr($x,6,1) =~ /[0-5]/ ) { $Char7_0thru5="YES";}
					if ( $Char1_isRight eq "YES" && $Char23_isRight eq "YES" && $BlanksAreRight eq "YES" && $Char4Numeric eq "YES" && $Char7_0thru5 eq "YES" ) {
						$_ = "<line>".substr($_,15); # I think the first part is "include numbers" and should be gone.
					}
					last SWITCH;
                    };
		  /^<cell duration=/
              && do {
			  		my $line = $_;
					FixDuration($line);
                    last SWITCH;
					};
          /^<graph lang="/
              && do {
                      $endquote = index($', "\"");
                      $endstr = substr($', $endquote);
                      $midstr1 = substr($', 0, $endquote);
                      $endspace = index($midstr1, ' ');
                      if ($endspace>0) {
                        $midstr2 = substr($midstr1, 0, $endspace);
                      } else {
                        $midstr2 = $midstr1;
                      }
                      $newstr = $& . $midstr2 . $endstr;
                      s/^.*$/$newstr/g;
                      last SWITCH;
                    };
        }
    }
    /^<cell |^<note |^<caption /
          && do {
				s/\(Entered [0-3][0-9]-[A-Z][A-Za-z][A-Za-z]-[12][0-9][0-9][0-9]\)/\(Entered ** DATE **)/g; # Gets rid of "(Entered dd-Mmm-yyyy)" (at least in English)
                if (/ text=".*[\\\/]Backend[\\\/](DATA|Temp)[\\\/].*"\/>/) {
                  s/\\/\//g;
                  s/ +"\/>$/"\/>/g;
                  if (/ text=".*[\/]Backend[\/](DATA|Temp)[\/]/) {
                     $reg = quotemeta $&;
                     $newvalue = sprintf " text=\"Backend/%s", substr($&, -5);
                     s/$reg/$newvalue/g;
                  }
                  s/\/solaris_sparc\//\//g;
                  s/\/solaris_sparc64\//\//g;
                  s/\/aix\//\//g;
                  s/\/linux\//\//g;
                }
				s/\r//g; #remove line feeds from captions and cell texts
             };
    /^<line>/
          && do {
                if (/ [\\\/].*[\\\/]Backend[\\\/](DATA|Temp)[\\\/]/) {
                  s/\\/\//g;
                  if (/ [\/].*[\/]Backend[\/](DATA|Temp)[\/]/) {
                     $reg = quotemeta $&;
                     $newvalue = sprintf " Backend/%s", substr($&, -5);
                     s/$reg/$newvalue/g;
                  }
                  s/\/solaris_sparc\//\//g;
                  s/\/solaris_sparc64\//\//g;
                  s/\/aix\//\//g;
                  s/\/linux\//\//g;
                }
             };
    /^<line>           Date and time:  |^<line>    Originating software:  /
          && do {
                  $newvalue = sprintf "%s</line>\n", $&;
                  s/.*/$newvalue/g;
             };
			 
	PRINT_LINE:
	if ( $onRow == 0 ){
		if ( $OnModel ) {
			s/^\s+//;
			s#&lt;#<#g; #change to < and >
			s#&gt;#>#g;
		} elsif ( $OnTreeModel ) {
			if ( $PrintLine eq "True" && $tempBlock eq "False" ) {
				s/[\t\n\f\r]/ /g;
				s/^\s+//;
				my $line = sprintf("%s",substr($_,0,length($_)-1));
				$lineCount++;
				@lineblock[$lineCount] = $line;
				my $len = length($line);
				my $lastchar = substr($line,$len-1,1);
				my $firstchar = substr($line,1,1);
				if ( $lastchar eq ">" || $firstchar eq "<" ) {
					print DMP "@lineblock[1..$lineCount]\n";
					@lineblock = q{};
					$lineCount = 0;
				}
			}
			$tempBlock = "True";
		}
		if ( $PrintLine eq "True" && $tempBlock eq "False" ) { print DMP $_; }
		if ( $OntextBlock ) { 
			if ( /<\/textBlock/ ) {
				print DMP $_;
				$OntextBlock = 0;
			}
			s/<line>\s*|<\/line>|<textBlock.*$|<\/textBlock.*$//g;
			print TXT $_;
		}
	}
NEXT_LINE:
}
close IN;
close DMP;
close TXT;

if ( $PrintedNumberToTXT eq "False" ) {
	open (TXT, ">", $txtfilename);
	print TXT;
	close TXT;
}
