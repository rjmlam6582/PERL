# Get commands in file

sub mkdirp($) {
    my $dir = shift;
    return if (-d $dir);
    mkdirp($dir);
    mkdir $dir;
}

sub uniq {
    my %seen;
    grep !$seen{$_}++, @_;
}

sub Trim {
	my $g=$_[0];
	$g =~ s/^\s*(.*?)\s*$/$1/;
#	$_[0] =~ s/^\s+//; #remove leading spaces
#	$_[0] =~ s/\s+$//; #remove trailing spaces
	return $g;
}

sub quote {
	my $q='"'.$_[0].'"';
	return $q;
}

sub getfiles {
	my $FILE_FILTER=$_[0];
	my $source_extension=$_[1];
	my @dirs = @{$_[2]};
	my @all_files;
	my @files;
	
	foreach my $d(@dirs) {
		$d =~ s/^\s+|\s+$//g; #trim leading or trailing spaces
		opendir(TARGETDIR, $d ) or die "Problem opening directory $d.\n";
		@files = grep { (!/^\./) && ( /$FILE_FILTER/ && /$source_extension/i) } readdir(TARGETDIR);
		closedir(TARGETDIR);
		foreach my $file(@files) { my $f=$d.'/'.$file ; push (@all_files, $f) } ;
		@all_files = sort {$a cmp $b} @all_files;
	}
	return @all_files;
}

sub FindCommand {
my $char1=$_[0];
my $cmd=$_[1];
my $input_data="_NO_INPUT_DATA_";
my $x=-1;
if ( grep /[2,A-Z]/, uc($char1) ) {
	my @words=split ' ',$cmd;
	my $last=scalar(@words);
	my $third_word=substr(uc($words[2]),0,3);
	my $second_word=substr(uc($words[1]),0,3);
	my $first_word=uc($words[0]);
	my $first1=substr($first_word,0,1);
	my $first2=substr($first_word,0,2);
	my $first3=substr($first_word,0,3);
	my $first4=substr($first_word,0,4);
	my $first5=substr($first_word,0,5);
	my $first6=substr($first_word,0,6);
	for ( $first3 ) {
		if     ( $first3 eq "2SL" ) { $x=1 } #2SLS 1
		elsif  ( $first3 eq "2SC" ) { $x=2 } #TWOSTEP CLUSTER 2
		elsif  ( $first1 eq "*" )   { $x=3 } #COMMENT 3
		elsif  ( /\@PR/ ) { $x=4 } #UNKNOWN 4
		elsif  ( /_CH/ ) { $x=5 } #_CHECKPO 5
		elsif  ( /_CL/ && $second_word eq "MOD" && $third_word eq "PRO" ) { $x=6 } #_CLEAR MODEL PROGRAMS 6
		elsif  ( /_CL/ && $second_word eq "TIM" && $third_word eq "PRO" ) { $x=7 } #_CLEAR TIME PROGRAM 7
		elsif  ( /_CO/ ) { $x=8 } #_COMPUTE 8
		elsif  ( /_DA/ && $second_word eq "NAM" ) { $x=9 } #_DATASET NAME 9
		elsif  ( /_EC/ ) { $x=10 } #_ECHO 10
		elsif  ( /_EN/ ) { $x=11 } #_ENDLOG 11
		elsif  ( /_FI/ ) { $x=12 } #_FINISH 12
		elsif  ( /_IF/ ) { $x=13 } #_IF 13
		elsif  ( /_LO/ ) { $x=14 } #_LOGICAL 14
		elsif  ( /_MO/ && $second_word eq "PAR" ) { $x=15 } #_MODEL PARAMETERS 15
		elsif  ( /_MO/ && $second_word eq "PRO" ) { $x=16 } #_MODEL PROGRAM 16
		elsif  ( /_TE/ ) { $x=17 } #_TESTAS 17
		elsif  ( /_SE/ ) { $x=18 } #_SET 18
		elsif  ( /_SI/ ) { $x=19 } #_SIMPLAN 19
		elsif  ( /_SL/ ) { $x=20 } #_SLINE 20
		elsif  ( /_SY/ ) { $x=21 } #_SYNC 21
		elsif  ( /_TI/ && $second_word eq "PRO" ) { $x=22 } #_TIME PROGRAM
		elsif  ( /_TS/ ) { $x=23 } #_TSET 23
		elsif  ( /ACF/ ) { $x=24 } #ACF 24
		elsif  ( /ADD/ && $second_word eq "DOC" ) { $x=25 } #ADD DOC 25
		elsif  ( /ADD/ && $second_word eq "FIL" ) { $x=26 } #ADD FILES 26
		elsif  ( /ADD/ && $second_word eq "VAL" && $third_word eq "LAB" ) { $x=27 } #ADD VAL LAB 27
		elsif  ( /ADP/ ) { $x=358 }
		elsif  ( /AGG/ ) { $x=28 } #AGGREGATE 28
		elsif  ( /AIM/ ) { $x=29 } #AIM 29
		elsif  ( /ALS/ ) { $x=30 } #ALSCAL 30
		elsif  ( /ALT/ && $second_word eq "TYP" ) { $x=31 } #ALTER TYPES 31
		elsif  ( /ANA/ ) { $x=32 } #ANACOR 32
		elsif  ( /ANO/ ) { $x=33 } #ANOVA 33
		elsif  ( /APP/ && $second_word eq "DIC" ) { $x=34} #APPLY DICTIONARY 34
		elsif  ( /ARE/ ) { $x=35 } #AREG 35
		elsif  ( /ARI/ ) { $x=36 } #ARIMA 36
		elsif  ( /ASS/ && $second_word eq "BLA" ) { $x=37 } #ASSIGN BLANKS 37
		elsif  ( /AUT/ ) { $x=38 } #AUTORECODE 38
		elsif  ( /BAR/ ) { $x=39 } #BARCHART 39
		elsif  ( /BAY/ && $second_word eq "ANO" ) { $x=391 } #BAYES ANOVA
		elsif  ( /BAY/ && $second_word eq "COR" ) { $x=392 } #BAYES CORRELATION
		elsif  ( /BAY/ && $second_word eq "IND" ) { $x=393 } #BAYES INDEPENDENT
		elsif  ( /BAY/ && $second_word eq "LOG" ) { $x=394 } #BAYES LOGLINEAR
		elsif  ( /BAY/ && $second_word eq "ONE" ) { $x=395 } #BAYES ONESAMPLE
		elsif  ( /BAY/ && $second_word eq "REL" ) { $x=396 } #BAYES RELATED
		elsif  ( /BAY/ && $second_word eq "REG" ) { $x=397 } #BAYES REGRESSION
		elsif  ( /BEG/ && $second_word eq "DAT" ) { $x=40 } #BEGIN DATA 40
		elsif  ( /BEG/ && $second_word eq "EXP" ) { $x=41 } #BEGIN EXPR 41
		elsif  ( /BEG/ && $second_word eq "GPL" ) { $x=42 } #BEGIN GPL 42
		elsif  ( /BEG/ && $second_word eq "PRE" ) { $x=43 } #BEGIN PRE 43
		elsif  ( /BEG/ && $second_word eq "PRO" ) { $x=44 } #BEGIN PROGRAM 44
		elsif  ( /BOO/ ) { $x=45 } #BOOTSTRAP 45
		elsif  ( /BOX/ && $second_word eq "JEN" ) { $x=46 } #BOX 46
		elsif  ( /BRE/ ) {
			$x = 47 ; #BREAK 47
			if ( $first_word =~ "BREAKD" ) { $x = 48 } #BREAKDOWNS 48
			}
		elsif  ( /C2V/ ) { $x=49 } #CASESTOVARS 49
		elsif  ( /CAC/ ) { $x=50 } #CACHE 50
		elsif  ( /CAS/ ) {
			for ( $first5 ) {
				if    ( /CASEP/ ) { $x=51 } #CASEPLOT 51
				elsif ( /CASES/ ) { $x=49 } #CASESTOVARS 49
				elsif ( $second_word eq "TO" && $third_word eq "VAR" ) { $x=49 }
				}
			}
		elsif  ( $first4 eq "CATP" ) { $x=52 } #CATPCA 52
		elsif  ( $first4 eq "CATR" ) { $x=53 } #CATREG 53
		elsif  ( /CCF/ ) { $x=54 } #CCF 54
		elsif  ( /CD/ ) { $x=55 } #CD 55
		elsif  ( /CLE/ && $second_word eq "MOD" && $third_word eq "PRO" ) { $x=56 } #CLEAR MODEL PROGRAM 56
		elsif  ( /CLE/ && $second_word eq "TIM"  && $third_word eq "PRO" ) { $x=57 } #CLEAR TIME PROGRAM 57
		elsif  ( /CLE/ && $second_word eq "TRA" ) { $x=58 } #CLEAR TRANSFORMATIONS 58
		elsif  ( /CLU/ ) { $x=59; if ( $second_word eq "PLU" ) { $x=60 } } #CLUSETER 59
		elsif  ( /CNL/ ) { $x=61 } #CNLR 61
		elsif  ( /COD/ ) { $x=62 } #CODEBOOK 62
		elsif  ( $first4 eq "COMM" ) { $x=3 } 
		elsif  ( $first5 eq "COMPU" ) { $x=63 } #COMPUTE
		elsif  ( $first5 eq "COMPA" ) { $x=64 } #COMPARE DATASETS
		elsif  ( /CON/ ) {
			$x=65; #CONDESCRIPTIVES 65
			if ( $first4 eq "CONJ" ) { $x=66 } #CONJOINT 66
			if ( $first4 eq "CONS" ) { $x=67 } #CONSTRAINED FUNCTION 67
			}
		elsif  ( /COR/ ) {
			$x=68; #CORRELATIONS 68
			if ( $first6 eq "CORRES" ) { $x=69 } #CORRESPONDENCE 69
			}
		elsif  ( /COU/ ) { $x=70 } #COUNT 70
		elsif  ( /COX/ ) { $x=71 } #COXREG 71
		elsif  ( /CRE/ ) { $x=72 } #CREATE 72
		elsif  ( /CRO/ ) { $x=73 } #CROSSTABS 73
		elsif  ( /CSC/ ) { $x=74 } #CSCOXREG 74
		elsif  ( /CSD/ ) { $x=75 } #CSDESCRIPTIVES 75
		elsif  ( /CSG/ ) { $x=76 } #CSGLM 76
		elsif  ( /CSL/ ) { $x=77 } #CSLOGISTIC 77
		elsif  ( /CSO/ ) { $x=78 } #CSORDINAL 78
		elsif  ( /CSP/ ) { $x=79 } #CSPLAN 79
		elsif  ( /CSS/ ) { $x=80 } #CSSELECT 80
		elsif  ( /CST/ ) { $x=81 } #CSTABULATE 81
		elsif  ( /CTA/ ) { $x=82 } #CTABLES 82
		elsif  ( /CUR/ ) { $x=83 } #CURVEFIT 83
		elsif  ( /DAT/ ) {
			$x=84; #DATE 84
			for ( $second_word ) {
				if  ( /LIS/ ) { $x=85;  #DATA LIST FILE="something" or FILE "something" or FILE=something or FILE something
					my $c=Trim($cmd);
					my $l1=index(uc($c),"FIL");	# Only take file if there is a quote or apostrophe
					if ( $l1 gt 0 ) {
						my $l2=length($c);
						my $substring=substr($c,$l1,$l2);
						my $d1=index($substring,"'");
						if ( $d1 == -1 ) { $d1=index($substring,'"'); }
						if ( $d1 > -1 ) {
							my $char=substr($substring,$d1,1);
							my $temp=substr($substring,$d1+1);
							$d2=index($temp,$char);
							$input_data=$char.substr($substring,$d1+1,$d2).$char;
						}
					}
				}  #DATA LIST 85
				elsif  ( /ATT/ ) { $x=86 } #DATAFILE ATTRIBUTES 86
				elsif  ( /ACT/ ) { $x=87 } #DATASET ACTIVATE 87
				elsif  ( /CLO/ ) { $x=88 } #DATASET CLOSE 88
				elsif  ( /COP/ ) { $x=89 } #DATASET COPY 89
				elsif  ( /DEC/ ) { $x=90 } #DATASET DECLARE 90
				elsif  ( /DIS/ ) { $x=91 } #DATASET DISPLAY 91
				elsif  ( /NAM/ ) { $x=92 } #DATASET NAME 92
			}
			}
		elsif  ( /DEB/ ) { $x=93 } #DEBUG 93
		elsif  ( /DEF/ ) { $x=94 } #DEFINE 94
		elsif  ( /DEL/ && $second_word eq "VAR" ) { $x=95 } #DELETE VARIABLES 95
		elsif  ( /DER/ ) { $x=96 } #DERIVATIVES 96
		elsif  ( /DES/ ) { $x=65 } #DESCRIPTIVES 65
		elsif  ( /DET/ ) { $x=97 } #DETECTANOMALY 97
		elsif  ( /DEV/ ) { $x=98 } #DEVPRC 98
		elsif  ( /DIS/ ) {
			for ( $first4 ) {
				if    ( /DISC/ ) { $x=99 } #DISCRIM 99
				elsif ( /DISP/ ) { $x=100 } #DISPLAY 100
			}
		}
		elsif ( /DMC/ ) {
			for ( $first4 ) {
				if    ( /DMCL/ ) { $x=101 } #DMCLUSTER 101
				elsif ( /DMCR/ ) { $x=102 } #DMCROSSTAB 102
			}
		}
		elsif  ( /DMG/ ) { $x=103 } #DMGRAPH 103
		elsif  ( /DML/ ) { $x=104 } #DMLOGISTIC 104
		elsif  ( /DMR/ ) { $x=105 } #DMROC 105
		elsif  ( $first4 eq "DMTA" ) { $x=106 } #DMTABLES 106
		elsif  ( $first4 eq "DMTR" ) { $x=107 } #DMTREE 107
		elsif  ( $first2 eq "DO" && $second_word eq "IF" ) { $x=108 } #DO IF 108
		elsif  ( $first2 eq "DO" && $second_word eq "REP" ) { $x=109 } #DO REPEAT 109
		elsif  ( /DOC/ ) { $x=110 } #DOCUMENTS 110
		elsif  ( /DRO/ && $second_word eq "DOC" ) { $x=111 } #DROP DOCUMENTS 111
		elsif  ( /DSC/ ) { $x=99 } #DISCRIM 99
		elsif  ( /DUM/ ) { $x=112 } #DUMP 112
		elsif  ( /ECH/ ) { $x=113 } #ECHO 113
		elsif  ( /EDI/ ) { $x=114 } #EDIT 114
		elsif  ( /ELS/ ) {
			$x=115; #ELSE 115
			if ( $second_word eq "IF" ) { $x=116 } #ELSE IF 116
		}
		elsif  ( /END/ ) {
			for ( $second_word ) {
				if     ( /CAS/ ) { $x=117 } #END CASE 117
				elsif  ( /DAT/ ) { $x=118 } #END DATA 118
				elsif  ( /EXP/ ) { $x=119 } #END EXPR 119
				elsif  ( /FIL/ ) { $x=120; if ( $third_word eq "TYP" ) { $x=121 } } #END FILE 120 or END FILE TYPE 121
				elsif  ( /IF/ )  { $x=122 } #END IF 122
				elsif  ( /INP/ ) { $x=123 } #END INPUT PROGRAM 123
				elsif  ( /LOO/ ) { $x=124 } #END LOOP 124
				elsif  ( /MAT/ ) { $x=369 } #END MATRIX 1240
				elsif  ( /PRE/ ) { $x=125 } #END PREPEXPR 125
				elsif  ( /REP/ ) { $x=126 } #END REPEAT 126
			}
			if ( $first4 eq "ENDL" ) { $x=127 } #ENDLOG 127
		}
		elsif  ( /ERA/ ) { $x=128 } #ERASE 128
		elsif  ( /EXA/ ) { $x=129 } #EXAMINE 129
		elsif  ( /EXE/ ) { $x=130 } #EXECUTE 130
		elsif  ( /EXP/ ) { $x=131 } #EXPORT 131
		elsif  ( /EXS/ ) { $x=132 } #EXSMOOTH 132
		elsif  ( /EXT/ ) { $x=133 } #EXTENSION 133
		elsif  ( /FAC/ ) { $x=134 } #FACTOR 134
		elsif  ( /FIL/ ) {
			for ( $second_word ) {
				if     ( /HAN/ ) { $x=135; $cmd =~ m/([\'\"][^\'\"]+[\'\"])/; $input_data=$1 } #FILE HANDLE 135 $input_data=$1." (FH)" 
				elsif  ( /LAB/ ) { $x=136 } #FILE LABEL 136
				elsif  ( /TYP/ ) { $x=137 } #FILE TYPE 137
			}
			if  ( $first4 eq "FILT" ) { $x=138 } #FILTER 138
		}
		elsif  ( /FIN/ ) { $x=139 } #FINISH 139
		elsif  ( /FIT/ ) { $x=140 } #FIT 140
		elsif  ( /FLI/ ) { $x=141 } #FLIP 141
		elsif  ( /FOR/ ) { $x=142 } #FORMATS 142
		elsif  ( /FRE/ ) { $x=143 } #FREQUENCIES 143
		elsif  ( /GEN/ ) { $x=144; if ( $first_word eq "GENLINMIXED" ) { $x=146 } elsif ( $first5 eq "GENLI" ) { $x=145 } } #GENLOG 144 or GENLIN 145
		 #GENLINMIXED 146
		elsif  ( /GET/ && $second_word eq "BMD" ) { $x=1460 } #GET BMDP 146
		elsif  ( /GET/ && $second_word eq "CAP" ) { $x=147 } #GET CAPTURE 147
		elsif  ( /GET/ && $second_word eq "DAT" ) { $x=148; $cmd =~ m/([\'\"][^\'\"]+[\'\"])/; $input_data=$1 } #GET DATA 148
		elsif  ( /GET/ && $second_word eq "FIL" ) { $x=149; $cmd =~ m/([\'\"][^\'\"]+[\'\"])/; $input_data=$1 } #GET FILE 149
		elsif  ( /GET/ && $second_word eq "OSI" ) { $x=150 } #GET OSIRIS 150
		elsif  ( /GET/ && $second_word eq "SAS" ) { $x=151; $cmd =~ m/([\'\"][^\'\"]+[\'\"])/; $input_data=$1 } #GET SAS 151
		elsif  ( /GET/ && $second_word eq "SCS" ) { $x=152 } #GET SCSS 152
		elsif  ( /GET/ && $second_word eq "STA" ) { $x=153; $cmd =~ m/([\'\"][^\'\"]+[\'\"])/; $input_data=$1 } #GET STATA 153
		elsif  ( /GET/ && $second_word eq "TRA" ) { $x=154; $cmd =~ m/([\'\"][^\'\"]+[\'\"])/; $input_data=$1 } #GET TRANSLATE 154
		elsif  ( /GGR/ ) { $x=155 } #GGRAPH 155
		elsif  ( /GLM/ ) { $x=156 } #GLM 156
		elsif  ( /GRA/ && $second_word eq "OUT" ) { $x=157 } #GRAPHICS OUTPUT 157
		elsif  ( /GRA/ ) { $x=158 } #GRAPH 158
		elsif  ( /HEL/ ) { $x=159 } #HELP 159
		elsif  ( /HIL/ ) { $x=160 } #HILOGLINEAR 160
		elsif  ( /HOM/ ) { $x=161 } #HOMALS 161
		elsif  ( /HOS/ ) { $x=162 } #HOST 162
		elsif  ( $first2 eq "IF" )  { $x=163 } #IF 163
		elsif  ( /IGR/ ) { $x=164 } #IGRAPH 164
		elsif  ( /IMA/ ) { $x=165 } #IMAP 165
		elsif  ( /IMP/ ) { $x=166 } #IMPORT 166
		elsif  ( /INC/ ) { $x=167; $cmd =~ m/([\'\"][^\'\"]+[\'\"])/; $input_data=$1 } #INCLUDE 167
		elsif  ( /INF/ ) { $x=168 } #INFO 168
		elsif  ( /INP/ && $second_word eq "MAT" ) { $x=169 } #INPUT MATRIX 169
		elsif  ( /INP/ && $second_word eq "PRO" ) { $x=170 } #INPUT PROGRAM 170
		elsif  ( /INS/ ) { $x=171; $cmd =~ m/([\'\"][^\'\"]+[\'\"])/; $input_data=$1 } #INSERT 171
		elsif  ( /KEY/ && $second_word eq "DAT" && $third_word eq "LIS" ) { $x=172 } #KEYED DATA LIST
		elsif  ( /KM/ ) { $x=173 } #KM
		elsif  ( /K-M/ ) { $x=173 }
		elsif  ( /KNN/ ) { $x=197 }
		elsif  ( /LAY/ && $second_word eq "REP" ) { $x=174 } #LAYERED REPORTS 174
		elsif  ( /LEA/ ) { $x=175 } #LEAVE 175
		elsif  ( /LIN/ ) { $x=176 } #LINECHAR 176
		elsif  ( /LIS/ ) { $x=177 } #LIST 177
		elsif  ( /LOG/ ) {
			if  ( $second_word eq "REG" ) { $x=179 }
			for ( $first4 ) {
				if     ( /LOG-/ ) { $x=178 } #LOGLIN
				elsif  ( /LOGI/ ) { $x=179 } #LOGISTIC REG
				elsif  ( /LOGL/ ) { $x=178 } #LOGLIN
				elsif  ( /LOGR/ ) { $x=179 } #LOGISTIC REG
			}
		}
		elsif  ( /LOO/ ) { $x=180 } #LOOP 180
		elsif  ( /MAN/ ) { $x=181 } #MANOVA 181
		elsif  ( /MAP/ ) { $x=182 } #MAPS or MAPX, both obsolete 182
		elsif  ( /MAT/ ) {
			if     ( $second_word eq "FIL" ) { $x=183 } #MATCH FILES 183
			elsif  ( $second_word eq "DAT" ) { $x=184 } #MATRIX DATA 184
			else   { $x=185 } #MATRIX 185
		}
		elsif  ( /MCO/ ) { $x=186 } #MCONVERT 186
		elsif  ( /MEA/ ) { $x=48 } #same as BREAKDOWNS
		elsif  ( /MIS/ && $second_word eq "VAL" ) { $x=187 } #MISSING VALUES 187
		elsif  ( /MIX/ ) { $x=188 } #MIXED 188
		elsif  ( /MLP/ ) { $x=189 } #MLP 189
		elsif  ( /MOD/ && $second_word eq "CLO" ) { $x=190 } #MODEL CLOSE 190
		elsif  ( /MOD/ && $second_word eq "HAN" ) { $x=191 } #MODEL HANDLE 191
		elsif  ( /MOD/ && $second_word eq "LIS" ) { $x=192 } #MODEL LIST 192
		elsif  ( /MOD/ && $second_word eq "NAM" ) { $x=193 } #MODEL NAME 193
		elsif  ( /MOD/ && $second_word eq "PAR" ) { $x=194 } #MODEL PARAMETER 194
		elsif  ( /MOD/ && $second_word eq "PRO" ) { $x=195 } #MODEL PROGRAM 195
		elsif  ( /MRS/ ) { $x=196 } #MRSET(S) 196
		elsif  ( /MUL/ ) {
			if     ( $second_word eq "RES" ) { $x=198 } #MULT RESPONSE 198
			elsif  ( $second_word eq "COR" ) { $x=199 } #MULTIPLE CORRESP 199
			elsif  ( $second_word eq "IMP" ) { $x=200 } #MULTIPLE IMPUTATION 200
		}
		elsif  ( /MVA/ ) { $x=201 } #MVA 201
		elsif  ( $first_word eq "N" && $second_word eq "OF" && $third_word eq "CAS" ) { $x=202 }
		elsif  ( $first_word eq "N" ) { $x=202 } #N 202
		elsif  ( /NAI/ ) { $x=203 } #NAIVEBAYES 203
		elsif  ( /NEW/ && $second_word eq "FIL" ) { $x=204 } #NEW FILE 204
		elsif  ( /NEW/ && $second_word eq "REG" ) { $x=205 } #NEW REGRESSION 205
		elsif  ( /NLR/ ) { $x=205 } #NLR 206
		elsif  ( /NOM/ ) { $x=207 } #NOMREG 207
		elsif  ( /NON/ && $second_word eq "COR" ) { $x=208 } #NONPAR CORR 208
		elsif  ( /NON/ && $second_word eq "TES" ) { $x=209 } #NONPAR TESTS 209
		elsif  ( /NPA/ && $second_word eq "COR" ) { $x=208 } 
		elsif  ( /NPA/ && $second_word eq "TES" ) { $x=209 } 
		elsif  ( /NPP/ ) { $x=210 } #NPPLOT 210
		elsif  ( /NPT/ ) { $x=368 } #NPTESTS 368
		elsif  ( $first4 eq "NUMB" ) { $x=211 } #NUMBERED 211
		elsif  ( /NUM/ ) { $x=212 } #NUMERIC 212
		elsif  ( /OLA/ && $second_word eq "CUB" ) { $x=213 } #OLAP CUBES 213
		elsif  ( /OMS/ ) {
			$x=214 ; #OMS 214
			if     ( $first4 eq "OMSE" ) { $x=215 } #OMSEND 215
			elsif  ( $first4 eq "OMSI" ) { $x=216 } #OMSINFO 216
			elsif  ( $first4 eq "OMSL" ) { $x=217 } #OMSLOG 217
		}
		elsif  ( /ONE/ ) { $x=218 } #ONEWAY 218
		elsif  ( /OPT/ && $second_word eq "BIN" ) { $x=219 } #OPTIMAL BINNING 219
		elsif  ( /ORT/ ) { $x=220 } #ORTHOPLAN 220
		elsif  ( /OUT/ && $second_word eq "ACT" ) { $x=221 } #OUTPUT ACTIVATE 221
		elsif  ( /OUT/ && $second_word eq "CLO" ) { $x=222 } #OUTPUT CLOSE 222
		elsif  ( /OUT/ && $second_word eq "COM" ) { $x=223 } #OUTPUT COMMENT 223
		elsif  ( /OUT/ && $second_word eq "DIS" ) { $x=224 } #OUTPUT DISPLAY 224
		elsif  ( /OUT/ && $second_word eq "EXP" ) { $x=225 } #OUTPUT EXPORT 225
		elsif  ( /OUT/ && $second_word eq "MOD" ) { $x=226 } #OUTPUT MODIFY 226
		elsif  ( /OUT/ && $second_word eq "NAM" ) { $x=227 } #OUTPUT NAME 227
		elsif  ( /OUT/ && $second_word eq "NEW" ) { $x=228 } #OUTPUT NEW 228
		elsif  ( /OUT/ && $second_word eq "OPE" ) { $x=229 } #OUTPUT OPEN 229
		elsif  ( /OUT/ && $second_word eq "SAV" ) { $x=230 } #OUTPUT SAVE 230
		elsif  ( /OVE/ ) { $x=231 } #OVERALS 231
		elsif  ( /PAC/ ) { $x=232 } #PACF 232
		elsif  ( /PAG/ ) { $x=233 } #PAGETITLE 233
		elsif  ( /PAR/ && $second_word eq "COR" ) { $x=234 } #PARTIAL CORR 234
		elsif  ( /PEA/ && $second_word eq "COR" ) { $x=68 } #CORRELATIONS 68
		elsif  ( /PER/ ) {
			if     ( $second_word eq "ATT" ) { $x=235 } #PER ATTRIBUTES 235
			elsif  ( $second_word eq "CON" ) { $x=236 } #PER CONNECT 236
			elsif  ( $second_word eq "COP" ) { $x=237 } #PER COPY 237
			elsif  ( $first4 eq "PERM" ) { $x=238 } #PERMISSIONS 238
		}
		elsif  ( /PLA/ ) { $x=239 } #PLANCARDS 239
		elsif  ( /PIE/ ) { $x=240 } #PIECHART 240
		elsif  ( /PLO/ ) { $x=241 } #PLOT 241
		elsif  ( /PLU/ ) { $x=242 } #PLUM 242
		elsif  ( /POI/ ) { $x=243 } #POINT 243
		elsif  ( /PPL/ ) { $x=244 } #PPLOT 244
		elsif  ( /PRE/ ) {
			if     ( $first4 eq "PRED" )  { $x=245 } #PREDICT 245
			elsif  ( $first4 eq "PREF" ) { $x=246 } #PREFSCAL 246
			elsif  ( $first4 eq "PREL" )   { $x=247 } #PRELIS 247
			elsif  ( $first4 eq "PRES" ) { $x=248 } #PRESERVE 248
		}
		elsif  ( $first5 eq "PRINC" ) { $x=249 } #PRINCALS 249
		elsif  ( /PRI/ ) {
			$x=250 ; #PRINT
			if     ( $second_word eq "EJE" ) { $x=251 } #PRINT EJECT 251
			elsif  ( $second_word eq "FOR" ) { $x=252 } #PRINT FORMAT 252
			elsif  ( $second_word eq "SPA" ) { $x=253 } #PRINT SPACE 253
		}
		elsif  ( /PRO/ ) {
			if     ( $first4 eq "PROB" ) { $x=254 } #PROBIT 254
			elsif  ( $first4 eq "PROC" )   { $x=255 } #PROCEDURE OUTPUT 255
			elsif  ( $first5 eq "PROXI" )  { $x=256 } #PROXIMITIES 256
			elsif  ( $first5 eq "PROXS" )  { $x=257 } #PROXSCAL 257
		}
		elsif  ( /QUI/ ) { $x=258 } #QUICK CLUSTER 258
		elsif  ( /RAN/ ) { $x=259 } #RANK 259
		elsif  ( /RAT/ ) { $x=260 } #RATIO STATISTICS 260
		elsif  ( /RAW/ && $second_word eq "OUT" ) { $x=261 } #RAW OUTPUT 261
		elsif  ( /RBF/ ) { $x=262 } #RBF 262
		elsif  ( /REA/ && $second_word eq "MOD" ) { $x=263 } #READ MODEL 263
		elsif  ( $first4 eq "REAT" ) { $x=264 } #REATTACH 264
		elsif  ( $first4 eq "RECO" ) { $x=265 } #RECODE 265
		elsif  ( /REC/ && $second_word eq "TYP" ) { $x=266 } #RECORD TYPE 266
		elsif  ( /REF/ ) { $x=267 } #REFORMAT 267
		elsif  ( /REG/ ) { $x=268 } #REGRESSION 268
		elsif  ( /REL/ ) { $x=269 } #RELIABILITY 269
		elsif  ( /REN/ && $second_word eq "VAR" ) { $x=270 } #RENAME VARIABLES 270
		elsif  ( /RES/ && $second_word eq "RAT" ) { $x=271 } #RESPONSE RATE 271
		elsif  ( /REP/ ) {
			$x=272 ; #REPORT 272
			if     ( $second_word eq "DAT" ) { $x=273 } #REPEATING DATA 273
			elsif  ( $second_word eq "ATT" ) { $x=274 } #REPOSITORY ATTRIBUTES 274
			elsif  ( $second_word eq "CON" ) { $x=275 } #REPOSITORY CONNECT 275
			elsif  ( $second_word eq "COP" ) { $x=276 } #REPOSITORY COPY 276
		}
		elsif  ( /RER/ ) { $x=277 } #REREAD 277
		elsif  ( /RES/ ) { $x=278 } #RESPONSE RATE 278
		elsif  ( /RMV/ ) { $x=279 } #RMV 279
		elsif  ( /ROC/ ) { $x=280 } #ROC 280
		elsif  ( /RUN/ && $second_word eq "NAM" ) { $x=281 } #RUN NAME 281
		elsif  ( $first4 eq "RUND" ) { $x=282 } #RUNDETACHED 282 
		elsif  ( /SAM/ ) { $x=283 } #SAMPLE 283 
		elsif  ( /SAV/ ) {
			$x=284; #SAVE OUTFILE 284 
			if     ( $second_word eq "MOD" ) { $x=285 } #SAVE MODEL 285
			elsif  ( $second_word eq "SCS" ) { $x=286 } #SAVE SCSS 286
			elsif  ( $second_word eq "TRA" ) { $x=287 } #SAVE TRANSLATE 287
		}
		elsif  ( /SCA/ ) { $x=288 } #SCATTERPLOT 288
		elsif  ( /SCR/ ) { $x=289 } #SCRIPT 289
		elsif  ( /SEA/ ) { $x=290 } #SEASON 290
		elsif  ( /SEL/ ) {
			if  ( $second_word eq "IF" ) { $x=291 } #SELECT IF 291
			else  { $x=292 } #SELECTPRED 292
		}
		elsif  ( /SET/ ) { $x=293 } #SET 293
		elsif  ( /SHI/ && $second_word eq "VAL" ) { $x=294 } #SHIFT VALUES 294
		elsif  ( /SHO/ ) { $x=295 } #SHOW 295
		elsif  ( /SIM/ ) {
			#x=296 ; #SIMPLIS 296- obsolete
			if     ( $first5 eq "SIMPL" ) { $x=296 } #SIMPLAN 296
			elsif  ( $first5 eq "SIMPR" && $second_word eq "BEG" ) { $x=297 } #SIMPREP BEGIN 297
			elsif  ( $first5 eq "SIMPR" && $second_word eq "END" ) { $x=298 } #END 298
			elsif  ( $first4 eq "SIMR" ) { $x=299 } #SIMRUN 299
			elsif  ( $first4 eq "SIMT" && $second_word eq "BEG" ) { $x=300 } #SIMTMS BEGIN 300
			elsif  ( $first4 eq "SIMT" && $second_word eq "END" ) { $x=301 } #SIMTMS END 301
		}
		elsif ( /SOR/ ) {
			if     ( $second_word eq "CAS" ) { $x=302 } #SORT CASES 302
			else   { $x=303 } #SORT VARIABLES 303
		}
		elsif ( /SPA/ ) {
			if     ( $second_word eq "ASS" ) { $x=304 } #SPATIAL ASSOCIATION RULES 304
			elsif  ( $second_word eq "MAP" ) { $x=305 } #SPATIAL ASSOCIATION MAPPREP 305
			elsif  ( $second_word eq "TEM" ) { $x=306 } #SPATIAL TEMPORAL PREDICTION 306
		}
		elsif  ( /SPC/ ) { $x=307 } #SPCHART 307
		elsif  ( /SPE/ ) { $x=308 } #SPECTRAL 308
		elsif  ( /SPL/ && $second_word eq "FIL" ) { $x=309 } #SPLIT FILE 309
		elsif  ( /STA/ && $second_word eq "JOI" ) { $x=310 } #STAR JOIN 310
		elsif  ( /STB/ && $second_word eq "PRI" ) { $x=311 } #STB PRINT 311
		elsif  ( /STR/ ) { $x=312 } #STRING 312
		elsif  ( /SUB/ ) { $x=313 } #SUBTITLE 313
		elsif  ( /SUM/ ) { $x=314 } #SUMMARIZE 314
		elsif  ( /SUR/ ) { $x=315 } #SURVIVAL 315
		elsif  ( /SYS/ && $second_word eq "INF" ) { $x=316 } #SYSFILE INFO 316
		elsif  ( /T-T/ ) { $x=317 } #T-TEST 317
		elsif  ( /TAB/ ) { $x=318 } #TABLES 318
		elsif  ( /TAS/ && $second_word eq "NAM" ) { $x=319 } #TASK NAME 319
		elsif  ( /TCM/ && $second_word eq "ANA" ) { $x=320 } #TCM ANALYSIS 320
		elsif  ( /TCM/ && $second_word eq "APP" ) { $x=321 } #TCM APPLY 321
		elsif  ( /TCM/ && $second_word eq "MOD" ) { $x=322 } #TCM MODEL 322
		elsif  ( /TDI/ ) { $x=323 } #TDISPLAY 323
		elsif  ( /TEM/ ) { $x=324 } #TEMPORARY 324
		elsif  ( /TIM/ && $second_word eq "PRO" ) { $x=325 } #TIME PROGRAM 325
		elsif  ( /TIT/ ) { $x=326 } #TITLE 326
		elsif  ( /TMS/ ) {
			if     ( $first4 eq "TMSB" ) { $x=327 } #TMSBEGIN 327
			elsif  ( $first4 eq "TMSE" ) { $x=328 } #TMSEND 328
			elsif  ( $first4 eq "TMSI" ) { $x=329 } #TMSIMPORT 329
			elsif  ( $first4 eq "TMSM" ) { $x=330 } #TMSMERGE 330
			elsif  ( $second_word eq "BEG" ) { $x=327 }
			elsif  ( $second_word eq "END" ) { $x=328 }
			elsif  ( $second_word eq "IMP" ) { $x=329 }
			elsif  ( $second_word eq "MER" ) { $x=330 }
		}
		elsif  ( /TRA/ ) { $x=331 } #TRADEOFF 331
		elsif  ( /TRE/ ) { $x=332 } #TREE 332
		elsif  ( /TS/ && $second_word eq "EXP" ) { $x=333 } #TS EXPLORE 333
		elsif  ( /TSA/ ) { $x=334} #TSAPPLY 334
		elsif  ( /TSE/ ) { $x=335 } #TSET 335
		elsif  ( /TSH/ ) { $x=336 } #TSHOW 336
		elsif  ( /TSM/ ) { $x=337 } #TSMODEL 337
		elsif  ( /TSP/ ) { $x=338 } #TSPLOT 338
		elsif  ( /TTE/ ) { $x=317 } #TTEST 317
		elsif  ( /TWO/ && $second_word eq "CLU" ) { $x=339 } #TWOSTEP CLUSTER 339
		elsif  ( /UNI/ ) { $x=340 } #UNIANOVA 340
		elsif  ( /UNN/ ) { $x=341 } #UNNUMBERED 341
		elsif  ( /UPD/ ) { $x=342 } #UPDATE 342
		elsif  ( /USE/ ) {
			$x=343 ; #USE 343
			if     ( $second_word eq "GET" ) { $x=344 } #USER GET 344
			elsif  ( $second_word eq "PRO" ) { $x=345 } #USER PROC 345
			elsif  ( $first5 eq "USERG" ) { $x=344 } #USERGET
			elsif  ( $first5 eq "USERP" ) { $x=345 } #USERPROC
		}
		elsif  ( /V2C/ ) { $x=346 } #VARSTOCASES 346
		elsif  ( $first4 eq "VALI" ) { $x=347 } #VALIDATEDATA 347
		elsif  ( /VAL/ && $second_word eq "LAB" ) { $x=348 } #VALUE LABELS 348
		elsif  ( /VAR/ ) {
			if     ( $first4 eq "VARC" )     { $x=349 } #VARCOMP 349
			elsif  ( $second_word eq "COM" ) { $x=349 } #SAME
			elsif  ( $second_word eq "ALI" ) { $x=350 } #VARIABLE ALIGNMENT 350
			elsif  ( $second_word eq "ATT" ) { $x=351 } #VARIABLE ATTRIBUTES 351
			elsif  ( $second_word eq "JUS" ) { $x=352 } #VARIABLE JUSTIFICATION 352
			elsif  ( $second_word eq "LAB" ) { $x=353 } #VARIABLE LABELS 353
			elsif  ( $second_word eq "LEV" ) { $x=354 } #VARIABLE LEVEL 354
			elsif  ( $second_word eq "ROL" ) { $x=355 } #VARIABLE ROLE 355
			elsif  ( $second_word eq "TOU" ) { $x=356 } #VARIABLE TOUCHED 356
			elsif  ( $second_word eq "WID" ) { $x=357 } #VARIABLE WIDTH 357
			elsif  ( $second_word eq "TO" && $third_word eq "CAS" ) { $x=346 }
			elsif  ( $first4 eq "VARS" ) { $x=346 } #VARSTOCASES 346
		}
		elsif  ( /VEC/ ) { $x=359 } #VECTOR 359
		elsif  ( /VER/ ) { $x=360 } #VERIFY 360
		elsif  ( /WEI/ ) { $x=361 } #WEIGHT 361
		elsif  ( /WLS/ ) { $x=362 } #WLS 362
		elsif  ( /WRI/ ) { 
			$x=363 ; #WRITE 363
			if  ( $second_word eq "FOR" ) { $x=364 } #WRITE FORMATS 364
		}
		elsif  ( /X11/ ) { $x=365 } #X11ARIMA 365
		elsif  ( /XGR/ ) { $x=366 } #XGRAPH 366
		elsif  ( /XSA/ ) { $x=367 } #XSAVE 367
	}
	if ( $input_data eq '' ) { $input_data="_NO_INPUT_DATA_";}
	return $x, $input_data, $last;
}
}
sub AssignCode {
	my $value=$_[0];
	my $x="0";
	if ( $value eq "0") { $x="EMPTY" }
	elsif ( $value eq "1") { $x="2SLS"; }
	elsif ( $value eq "2") { $x="2STEP CLUSTER" }
	elsif ( $value eq "3") { $x="COMMENT" }
	elsif ( $value eq "4") { $x="UNKNOWN" }
	elsif ( $value eq "5") { $x="_CHECKPO" }
	elsif ( $value eq "6") { $x="_CLEAR MODEL PROGRAMS" }
	elsif ( $value eq "7") { $x="_CLEAR TIME PROGRAM" }
	elsif ( $value eq "8") { $x="_COMPUTE" }
	elsif ( $value eq "9") { $x="_DATASET NAME" }
	elsif ( $value eq "10") { $x="_ECHO" }
	elsif ( $value eq "11") { $x="_ENDLOG" }
	elsif ( $value eq "12") { $x="_FINISH" }
	elsif ( $value eq "13") { $x="_IF" }
	elsif ( $value eq "14") { $x="_LOGICAL" }
	elsif ( $value eq "15") { $x="_MODEL PARAMETERS" }
	elsif ( $value eq "16") { $x="_MODEL PROGRAM" }
	elsif ( $value eq "17") { $x="_TESTAS" }
	elsif ( $value eq "18") { $x="_SET" }
	elsif ( $value eq "19") { $x="_SIMPLAN" }
	elsif ( $value eq "20") { $x="_SLINE" }
	elsif ( $value eq "21") { $x="_SYNC" }
	elsif ( $value eq "22") { $x="_TIME PROGRAM" }
	elsif ( $value eq "23") { $x="_TSET" }
	elsif ( $value eq "24") { $x="ACF" }
	elsif ( $value eq "25") { $x="ADD DOC" }
	elsif ( $value eq "26") { $x="ADD FILES" }
	elsif ( $value eq "27") { $x="ADD VAL LAB" }
	elsif ( $value eq "358") { $x="ADP" }
	elsif ( $value eq "28") { $x="AGGREGATE" }
	elsif ( $value eq "29") { $x="AIM" }
	elsif ( $value eq "30") { $x="ALSCAL" }
	elsif ( $value eq "31") { $x="ALTER TYPES" }
	elsif ( $value eq "32") { $x="ANACOR" }
	elsif ( $value eq "33") { $x="ANOVA" }
	elsif ( $value eq "34") { $x="APPLY DICTIONARY" }
	elsif ( $value eq "35") { $x="AREG" }
	elsif ( $value eq "36") { $x="ARIMA" }
	elsif ( $value eq "37") { $x="ASSIGN BLANKS" }
	elsif ( $value eq "38") { $x="AUTORECODE" }
	elsif ( $value eq "39") { $x="BARCHART" }
	elsif ( $value eq "391") { $x="BAYES ANOVA" }
	elsif ( $value eq "392") { $x="BAYES CORRELATION" }
	elsif ( $value eq "393") { $x="BAYES INDEPENDENT" }
	elsif ( $value eq "394") { $x="BAYES LOGLINEAR" }
	elsif ( $value eq "395") { $x="BAYES ONESAMPLE" }
	elsif ( $value eq "396") { $x="BAYES RELATED" }
	elsif ( $value eq "397") { $x="BAYES REGRESSION" }
	elsif ( $value eq "40") { $x="BEGIN DATA" }
	elsif ( $value eq "41") { $x="BEGIN EXPR" }
	elsif ( $value eq "42") { $x="BEGIN GPL" }
	elsif ( $value eq "43") { $x="BEGIN PRE" }
	elsif ( $value eq "44") { $x="BEGIN PROGRAM" }
	elsif ( $value eq "45") { $x="BOOTSTRAP" }
	elsif ( $value eq "46") { $x="BOX" }
	elsif ( $value eq "47") { $x="BREAK" }
	elsif ( $value eq "48") { $x="BREAKDOWNS" }
	elsif ( $value eq "48") { $x="MEANS" }
	elsif ( $value eq "49") { $x="CASESTOVARS" }
	elsif ( $value eq "49") { $x="CASESTOVARS" }
	elsif ( $value eq "50") { $x="CACHE" }
	elsif ( $value eq "51") { $x="CASEPLOT" }
	elsif ( $value eq "52") { $x="CATPCA" }
	elsif ( $value eq "53") { $x="CATREG" }
	elsif ( $value eq "54") { $x="CCF" }
	elsif ( $value eq "55") { $x="CD" }
	elsif ( $value eq "56") { $x="CLEAR MODEL PROGRAM" }
	elsif ( $value eq "57") { $x="CLEAR TIME PROGRAM" }
	elsif ( $value eq "58") { $x="CLEAR TRANSFORMATIONS" }
	elsif ( $value eq "59") { $x="CLUSETER" }
	elsif ( $value eq "61") { $x="CNLR" }
	elsif ( $value eq "62") { $x="CODEBOOK" }
	elsif ( $value eq "63") { $x="COMPUTE" }
	elsif ( $value eq "64") { $x="COMPARE DATASETS" }
	elsif ( $value eq "65") { $x="DESCRIPTIVES" }
	elsif ( $value eq "66") { $x="CONJOINT" }
	elsif ( $value eq "67") { $x="CONSTRAINED FUNCTION" }
	elsif ( $value eq "68") { $x="CORRELATIONS" }
	elsif ( $value eq "68") { $x="CORRELATIONS" }
	elsif ( $value eq "69") { $x="CORRESPONDENCE" }
	elsif ( $value eq "70") { $x="COUNT" }
	elsif ( $value eq "71") { $x="COXREG" }
	elsif ( $value eq "72") { $x="CREATE" }
	elsif ( $value eq "73") { $x="CROSSTABS" }
	elsif ( $value eq "74") { $x="CSCOXREG" }
	elsif ( $value eq "75") { $x="CSDESCRIPTIVES" }
	elsif ( $value eq "76") { $x="CSGLM" }
	elsif ( $value eq "77") { $x="CSLOGISTIC" }
	elsif ( $value eq "78") { $x="CSORDINAL" }
	elsif ( $value eq "79") { $x="CSPLAN" }
	elsif ( $value eq "80") { $x="CSSELECT" }
	elsif ( $value eq "81") { $x="CSTABULATE" }
	elsif ( $value eq "82") { $x="CTABLES" }
	elsif ( $value eq "83") { $x="CURVEFIT" }
	elsif ( $value eq "84") { $x="DATE" }
	elsif ( $value eq "85") { $x="DATA LIST" }
	elsif ( $value eq "86") { $x="DATAFILE ATTRIBUTES" }
	elsif ( $value eq "87") { $x="DATASET ACTIVATE" }
	elsif ( $value eq "88") { $x="DATASET CLOSE" }
	elsif ( $value eq "89") { $x="DATASET COPY" }
	elsif ( $value eq "90") { $x="DATASET DECLARE" }
	elsif ( $value eq "91") { $x="DATASET DISPLAY" }
	elsif ( $value eq "92") { $x="DATASET NAME" }
	elsif ( $value eq "93") { $x="DEBUG" }
	elsif ( $value eq "94") { $x="DEFINE" }
	elsif ( $value eq "95") { $x="DELETE VARIABLES" }
	elsif ( $value eq "96") { $x="DERIVATIVES" }
	elsif ( $value eq "97") { $x="DETECTANOMALY" }
	elsif ( $value eq "98") { $x="DEVPRC" }
	elsif ( $value eq "99") { $x="DISCRIM" }
	elsif ( $value eq "99") { $x="DISCRIM" }
	elsif ( $value eq "100") { $x="DISPLAY" }
	elsif ( $value eq "101") { $x="DMCLUSTER" }
	elsif ( $value eq "102") { $x="DMCROSSTAB" }
	elsif ( $value eq "103") { $x="DMGRAPH" }
	elsif ( $value eq "104") { $x="DMLOGISTIC" }
	elsif ( $value eq "105") { $x="DMROC" }
	elsif ( $value eq "106") { $x="DMTABLES" }
	elsif ( $value eq "107") { $x="DMTREE" }
	elsif ( $value eq "108") { $x="DO IF" }
	elsif ( $value eq "109") { $x="DO REPEAT" }
	elsif ( $value eq "110") { $x="DOCUMENTS" }
	elsif ( $value eq "111") { $x="DROP DOCUMENTS" }
	elsif ( $value eq "112") { $x="DUMP" }
	elsif ( $value eq "113") { $x="ECHO" }
	elsif ( $value eq "114") { $x="EDIT" }
	elsif ( $value eq "115") { $x="ELSE" }
	elsif ( $value eq "116") { $x="ELSE IF" }
	elsif ( $value eq "117") { $x="END CASE" }
	elsif ( $value eq "118") { $x="END DATA" }
	elsif ( $value eq "119") { $x="END EXPR" }
	elsif ( $value eq "120") { $x="END FILE" }
	elsif ( $value eq "121") { $x="END FILE TYPE" }
	elsif ( $value eq "122") { $x="END IF" }
	elsif ( $value eq "123") { $x="END INPUT PROGRAM" }
	elsif ( $value eq "124") { $x="END LOOP" }
	elsif ( $value eq "369") { $x="END MATRIX" }
	elsif ( $value eq "125") { $x="END PREPEXPR" }
	elsif ( $value eq "126") { $x="END REPEAT" }
	elsif ( $value eq "127") { $x="ENDLOG" }
	elsif ( $value eq "128") { $x="ERASE" }
	elsif ( $value eq "129") { $x="EXAMINE" }
	elsif ( $value eq "130") { $x="EXECUTE" }
	elsif ( $value eq "131") { $x="EXPORT" }
	elsif ( $value eq "132") { $x="EXSMOOTH" }
	elsif ( $value eq "133") { $x="EXTENSION" }
	elsif ( $value eq "134") { $x="FACTOR" }
	elsif ( $value eq "135") { $x="FILE HANDLE" }
	elsif ( $value eq "136") { $x="FILE LABEL" }
	elsif ( $value eq "137") { $x="FILE TYPE" }
	elsif ( $value eq "138") { $x="FILTER" }
	elsif ( $value eq "139") { $x="FINISH" }
	elsif ( $value eq "140") { $x="FIT" }
	elsif ( $value eq "141") { $x="FLIP" }
	elsif ( $value eq "142") { $x="FORMATS" }
	elsif ( $value eq "143") { $x="FREQUENCIES" }
	elsif ( $value eq "144") { $x="GENLOG" }
	elsif ( $value eq "145") { $x="GENLIN" }
	elsif ( $value eq "146") { $x="GENLINMIXED" }
	elsif ( $value eq "1460") { $x="GET BMDP" }
	elsif ( $value eq "147") { $x="GET CAPTURE" }
	elsif ( $value eq "148") { $x="GET DATA" }
	elsif ( $value eq "149") { $x="GET FILE" }
	elsif ( $value eq "150") { $x="GET OSIRIS" }
	elsif ( $value eq "151") { $x="GET SAS" }
	elsif ( $value eq "152") { $x="GET SCSS" }
	elsif ( $value eq "153") { $x="GET STATA" }
	elsif ( $value eq "154") { $x="GET TRANSLATE" }
	elsif ( $value eq "155") { $x="GGRAPH" }
	elsif ( $value eq "156") { $x="GLM" }
	elsif ( $value eq "157") { $x="GRAPHICS OUTPUT" }
	elsif ( $value eq "158") { $x="GRAPH" }
	elsif ( $value eq "159") { $x="HELP" }
	elsif ( $value eq "160") { $x="HILOGLINEAR" }
	elsif ( $value eq "161") { $x="HOMALS" }
	elsif ( $value eq "162") { $x="HOST" }
	elsif ( $value eq "163") { $x="IF" }
	elsif ( $value eq "164") { $x="IGRAPH" }
	elsif ( $value eq "165") { $x="IMAP" }
	elsif ( $value eq "166") { $x="IMPORT" }
	elsif ( $value eq "167") { $x="INCLUDE" }
	elsif ( $value eq "168") { $x="INFO" }
	elsif ( $value eq "169") { $x="INPUT MATRIX" }
	elsif ( $value eq "170") { $x="INPUT PROGRAM" }
	elsif ( $value eq "171") { $x="INSERT" }
	elsif ( $value eq "172") { $x="KEYED DATA LIST" }
	elsif ( $value eq "173") { $x="K-M" }
	elsif ( $value eq "173") { $x="KM" }
	elsif ( $value eq "197") { $x="KNN" }
	elsif ( $value eq "174") { $x="LAYERED REPORTS" }
	elsif ( $value eq "175") { $x="LEAVE" }
	elsif ( $value eq "176") { $x="LINECHAR" }
	elsif ( $value eq "177") { $x="LIST" }
	elsif ( $value eq "178") { $x="LOGLIN" }
	elsif ( $value eq "179") { $x="LOGISTIC REG" }
	elsif ( $value eq "180") { $x="LOOP" }
	elsif ( $value eq "181") { $x="MANOVA" }
	elsif ( $value eq "182") { $x="MAP" }
	elsif ( $value eq "183") { $x="MATCH FILES" }
	elsif ( $value eq "184") { $x="MATRIX DATA" }
	elsif ( $value eq "185") { $x="MATRIX" }
	elsif ( $value eq "186") { $x="MCONVERT" }
	elsif ( $value eq "187") { $x="MISSING VALUES" }
	elsif ( $value eq "188") { $x="MIXED" }
	elsif ( $value eq "189") { $x="MLP" }
	elsif ( $value eq "190") { $x="MODEL CLOSE" }
	elsif ( $value eq "191") { $x="MODEL HANDLE" }
	elsif ( $value eq "192") { $x="MODEL LIST" }
	elsif ( $value eq "193") { $x="MODEL NAME" }
	elsif ( $value eq "194") { $x="MODEL PARAMETER" }
	elsif ( $value eq "195") { $x="MODEL PROGRAM" }
	elsif ( $value eq "196") { $x="MRSETS" } #197 is open
	elsif ( $value eq "198") { $x="MULT RESPONSE" }
	elsif ( $value eq "199") { $x="MULTIPLE CORRESP" }
	elsif ( $value eq "200") { $x="MULTIPLE IMPUTATION" }
	elsif ( $value eq "201") { $x="MVA" }
	elsif ( $value eq "202") { $x="N OF CASES" }
	elsif ( $value eq "203") { $x="NAIVEBAYES" }
	elsif ( $value eq "204") { $x="NEW FILE" }
	elsif ( $value eq "205") { $x="NEW REGRESSION" }
	elsif ( $value eq "206") { $x="NLR" }
	elsif ( $value eq "207") { $x="NOMREG" }
	elsif ( $value eq "208") { $x="NONPAR CORR" }
	elsif ( $value eq "209") { $x="NONPAR TESTS" }
	elsif ( $value eq "210") { $x="NPPLOT" }
	elsif ( $value eq "368") { $x="NPTESTS" }
	elsif ( $value eq "211") { $x="NUMBERED" }
	elsif ( $value eq "212") { $x="NUMERIC" }
	elsif ( $value eq "213") { $x="OLAP CUBES" }
	elsif ( $value eq "214") { $x="OMS" }
	elsif ( $value eq "215") { $x="OMSEND" }
	elsif ( $value eq "216") { $x="OMSINFO" }
	elsif ( $value eq "217") { $x="OMSLOG" }
	elsif ( $value eq "218") { $x="ONEWAY" }
	elsif ( $value eq "219") { $x="OPTIMAL BINNING" }
	elsif ( $value eq "220") { $x="ORTHOPLAN" }
	elsif ( $value eq "221") { $x="OUTPUT ACTIVATE" }
	elsif ( $value eq "222") { $x="OUTPUT CLOSE" }
	elsif ( $value eq "223") { $x="OUTPUT COMMENT" }
	elsif ( $value eq "224") { $x="OUTPUT DISPLAY" }
	elsif ( $value eq "225") { $x="OUTPUT EXPORT" }
	elsif ( $value eq "226") { $x="OUTPUT MODIFY" }
	elsif ( $value eq "227") { $x="OUTPUT NAME" }
	elsif ( $value eq "228") { $x="OUTPUT NEW" }
	elsif ( $value eq "229") { $x="OUTPUT OPEN" }
	elsif ( $value eq "230") { $x="OUTPUT SAVE" }
	elsif ( $value eq "231") { $x="OVERALLS" }
	elsif ( $value eq "232") { $x="PACF" }
	elsif ( $value eq "233") { $x="PAGETITLE" }
	elsif ( $value eq "234") { $x="PARTIAL CORR" }
	elsif ( $value eq "235") { $x="PER ATTRIBUTES" }
	elsif ( $value eq "236") { $x="PER CONNECT" }
	elsif ( $value eq "237") { $x="PER COPY" }
	elsif ( $value eq "238") { $x="PERMISSIONS" }
	elsif ( $value eq "239") { $x="PLANCARDS" }
	elsif ( $value eq "240") { $x="PIECHART" }
	elsif ( $value eq "241") { $x="PLOT" }
	elsif ( $value eq "242") { $x="PLUM" }
	elsif ( $value eq "243") { $x="POINT" }
	elsif ( $value eq "244") { $x="PPLOT" }
	elsif ( $value eq "245") { $x="PREDICT" }
	elsif ( $value eq "246") { $x="PREFSCAL" }
	elsif ( $value eq "247") { $x="PRELIS" }
	elsif ( $value eq "248") { $x="PRESERVE" }
	elsif ( $value eq "249") { $x="PRINCALS" }
	elsif ( $value eq "250") { $x="PRINT" }
	elsif ( $value eq "251") { $x="PRINT EJECT" }
	elsif ( $value eq "252") { $x="PRINT FORMAT" }
	elsif ( $value eq "253") { $x="PRINT SPACE" }
	elsif ( $value eq "254") { $x="PROBIT" }
	elsif ( $value eq "255") { $x="PROCEDURE OUTPUT" }
	elsif ( $value eq "256") { $x="PROXIMITIES" }
	elsif ( $value eq "257") { $x="PROXSCAL" }
	elsif ( $value eq "258") { $x="QUICK CLUSTER" }
	elsif ( $value eq "259") { $x="RANK" }
	elsif ( $value eq "260") { $x="RATIO STATISTICS" }
	elsif ( $value eq "261") { $x="RAW OUTPUT" }
	elsif ( $value eq "262") { $x="RBF" }
	elsif ( $value eq "263") { $x="READ MODEL" }
	elsif ( $value eq "264") { $x="REATTACH" }
	elsif ( $value eq "265") { $x="RECODE" }
	elsif ( $value eq "266") { $x="RECORD TYPE" }
	elsif ( $value eq "267") { $x="REFORMAT" }
	elsif ( $value eq "268") { $x="REGRESSION" }
	elsif ( $value eq "269") { $x="RELIABILITY" }
	elsif ( $value eq "270") { $x="RENAME VARIABLES" }
	elsif ( $value eq "271") { $x="RESPONSE RATE" }
	elsif ( $value eq "272") { $x="REPORT" }
	elsif ( $value eq "273") { $x="REPEATING DATA" }
	elsif ( $value eq "274") { $x="REPOSITORY ATTRIBUTES" }
	elsif ( $value eq "275") { $x="REPOSITORY CONNECT" }
	elsif ( $value eq "276") { $x="REPOSITORY COPY" }
	elsif ( $value eq "277") { $x="REREAD" }
	elsif ( $value eq "278") { $x="RESPONSE RATE" }
	elsif ( $value eq "279") { $x="RMV" }
	elsif ( $value eq "280") { $x="ROC" }
	elsif ( $value eq "281") { $x="RUN NAME" }
	elsif ( $value eq "282") { $x="RUNDETACHED " }
	elsif ( $value eq "283") { $x="SAMPLE " }
	elsif ( $value eq "284") { $x="SAVE OUTFILE " }
	elsif ( $value eq "285") { $x="SAVE MODEL" }
	elsif ( $value eq "286") { $x="SAVE SCSS" }
	elsif ( $value eq "287") { $x="SAVE TRANSLATE" }
	elsif ( $value eq "288") { $x="SCATTERPLOT" }
	elsif ( $value eq "289") { $x="SCRIPT" }
	elsif ( $value eq "290") { $x="SEASON" }
	elsif ( $value eq "291") { $x="SELECT IF" }
	elsif ( $value eq "292") { $x="SELECTPRED" }
	elsif ( $value eq "293") { $x="SET" }
	elsif ( $value eq "294") { $x="SHIFT VALUES" }
	elsif ( $value eq "295") { $x="SHOW" }
	elsif ( $value eq "296") { $x="SIMPLAN" }
	elsif ( $value eq "297") { $x="SIMPREP BEGIN" }
	elsif ( $value eq "298") { $x="END" }
	elsif ( $value eq "299") { $x="SIMRUN" }
	elsif ( $value eq "300") { $x="SIMTMS BEGIN" }
	elsif ( $value eq "301") { $x="SIMTMS END" }
	elsif ( $value eq "302") { $x="SORT CASES" }
	elsif ( $value eq "303") { $x="SORT VARIABLES" }
	elsif ( $value eq "304") { $x="SPATIAL ASSOCIATION RULES" }
	elsif ( $value eq "305") { $x="SPATIAL ASSOCIATION MAPPREP" }
	elsif ( $value eq "306") { $x="SPATIAL TEMPORAL PREDICTION" }
	elsif ( $value eq "307") { $x="SPCHART" }
	elsif ( $value eq "308") { $x="SPECTRAL" }
	elsif ( $value eq "309") { $x="SPLIT FILE" }
	elsif ( $value eq "310") { $x="STAR JOIN" }
	elsif ( $value eq "311") { $x="STB PRINT" }
	elsif ( $value eq "312") { $x="STRING" }
	elsif ( $value eq "313") { $x="SUBTITLE" }
	elsif ( $value eq "314") { $x="SUMMARIZE" }
	elsif ( $value eq "315") { $x="SURVIVAL" }
	elsif ( $value eq "316") { $x="SYSFILE INFO" }
	elsif ( $value eq "317") { $x="T-TEST" }
	elsif ( $value eq "317") { $x="TTEST" }
	elsif ( $value eq "318") { $x="TABLES" }
	elsif ( $value eq "319") { $x="TASK NAME" }
	elsif ( $value eq "320") { $x="TCM ANALYSIS" }
	elsif ( $value eq "321") { $x="TCM APPLY" }
	elsif ( $value eq "322") { $x="TCM MODEL" }
	elsif ( $value eq "323") { $x="TDISPLAY" }
	elsif ( $value eq "324") { $x="TEMPORARY" }
	elsif ( $value eq "325") { $x="TIME PROGRAM" }
	elsif ( $value eq "326") { $x="TITLE" }
	elsif ( $value eq "327") { $x="TMSBEGIN" }
	elsif ( $value eq "328") { $x="TMSEND" }
	elsif ( $value eq "329") { $x="TMSIMPORT" }
	elsif ( $value eq "330") { $x="TMSMERGE" }
	elsif ( $value eq "331") { $x="TRADEOFF" }
	elsif ( $value eq "332") { $x="TREE" }
	elsif ( $value eq "333") { $x="TS EXPLORE" }
	elsif ( $value eq "334") { $x="TSAPPLY" }
	elsif ( $value eq "335") { $x="TSET" }
	elsif ( $value eq "336") { $x="TSHOW" }
	elsif ( $value eq "337") { $x="TSMODEL" }
	elsif ( $value eq "338") { $x="TSPLOT" }
	elsif ( $value eq "339") { $x="TWOSTEP CLUSTER" }
	elsif ( $value eq "340") { $x="UNIANOVA"}
	elsif ( $value eq "341") { $x="UNNUMBERED" }
	elsif ( $value eq "342") { $x="UPDATE" }
	elsif ( $value eq "343") { $x="USE" }
	elsif ( $value eq "344") { $x="USER GET" }
	elsif ( $value eq "345") { $x="USER PROC" }
	elsif ( $value eq "346") { $x="VARSTOCASES" }
	elsif ( $value eq "347") { $x="VALIDATEDATA" }
	elsif ( $value eq "348") { $x="VALUE LABELS" }
	elsif ( $value eq "349") { $x="VARCOMP" }
	elsif ( $value eq "350") { $x="VARIABLE ALIGNMENT" }
	elsif ( $value eq "351") { $x="VARIABLE ATTRIBUTES" }
	elsif ( $value eq "352") { $x="VARIABLE JUSTIFICATION" }
	elsif ( $value eq "353") { $x="VARIABLE LABELS" }
	elsif ( $value eq "354") { $x="VARIABLE LEVEL" }
	elsif ( $value eq "355") { $x="VARIABLE ROLE" }
	elsif ( $value eq "356") { $x="VARIABLE TOUCHED" }
	elsif ( $value eq "357") { $x="VARIABLE WIDTH" } #358 open
	elsif ( $value eq "359") { $x="VECTOR" }
	elsif ( $value eq "360") { $x="VERIFY" }
	elsif ( $value eq "361") { $x="WEIGHT" }
	elsif ( $value eq "362") { $x="WLS" }
	elsif ( $value eq "363") { $x="WRITE" }
	elsif ( $value eq "364") { $x="WRITE FORMATS" }
	elsif ( $value eq "365") { $x="XARIMA" }
	elsif ( $value eq "366") { $x="XGRAPH" }
	elsif ( $value eq "367") { $x="XSAVE" }
	return $x;
}
###### The final line of such a file MUST be "true"....
1;