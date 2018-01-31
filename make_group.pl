#!/usr/local/bin/perl
use POSIX qw(strftime);
use warnings;
use Encode;
require 'common_functions.pl';

local $SIG{__DIE__} = sub {
	my ($message) = "ERROR: $!\n"."@_";
	SendToOutput($LOGFILE,$message,"both");
	exit 0;
};

local $SIG{__WARN__} = sub {
	my ($message) = "WARNING: $!\n"."@_";
	SendToOutput($LOGFILE,$message,"both");
};

sub Header {
my ($_OLANG,$LOCALE,$yr,$_QADATA,$_QATEMP,$_QASERVER,$_QAOUTPUT,$_QALOCAL,$_HEADER) = @_;
my $asterisks = RepeatChar(72, "*");
my $requested_header=q{};
if ( uc($_HEADER) eq "_NO_HEADER_" ) {
	$requested_header="set olang=$_OLANG /locale=\"$LOCALE\".";
} else {
	$_HEADER =~ s/\<n\>/\n/g;
	$requested_header=$_HEADER."\nset olang=$_OLANG /locale=\"$LOCALE\".";
}
$file_header = << "EOH";
$requested_header
$asterisks
**Licensed Materials - Property of IBM
**
** (C) Copyright IBM Corp. 1989, $yr.
**
**US Government Users Restricted Rights - Use, duplication or disclosure restricted
**by GSA ADP Schedule Contract with IBM Corp.
$asterisks.
FILE HANDLE QaData   /NAME="$_QADATA".
FILE HANDLE QaTemp   /NAME="$_QATEMP".
FILE HANDLE QaServer /NAME="$_QASERVER".
FILE HANDLE QaOutput /NAME="$_QAOUTPUT".
FILE HANDLE QaLocal  /NAME="$_QALOCAL".
EOH
return $file_header;
}

sub TestSyntax {
my ($id,$subtype,$select,$mo,$mday,$yr,$data,$syntax,$OMS_FORMAT,$OMS_TYPE,$_FOOTER) = @_;
my $filename=$id."_".$subtype;
my $title = "title \"zxz ".$filename."\".";
my $fname_type = $filename.$OMS_TYPE;
my $requested_footer=q{};
$datestring = "* ".sprintf("%02d-%2d-%4d", $mo,$mday,$yr)." - richardm - created.";
if ( uc($_FOOTER) eq "_NO_FOOTER_" ) {
	$requested_footer="OMSEND TAG='TemplateTag'.\n";
} else {
	$_FOOTER =~ s/\<n\>/\n/g;
	$requested_footer="OMSEND TAG='TemplateTag'.\n".$_FOOTER."\n";
}
$test_body = << "EOT";
set printback none.
OMS /SELECT $select
 /IF COMMANDS=["$id"] SUBTYPES=["$subtype"]
 /DESTINATION FORMAT=$OMS_FORMAT
  OUTFILE="QaOutput/$fname_type"
 /TAG='TemplateTag'.
title "zxz $filename".
include file 'QaData/std18.inc'.
set unicode on.

*modification history.
$datestring

*description.
* Produce $subtype for procedure $id.

GET FILE="QaServer/$data".
$syntax
*=== end of job ===.
$requested_footer
EOT
return $test_body;
}

my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
my $yr = $year += 1900;
my $mo= $mon + 1;
my $sort_by="ID";
my $hi_rand_num=200;
my $seed=123456;
my $BOM="NO";
my $OMS_FORMAT="OXML";
my $encoding="unicode";
my $_FOOTER="_NO_FOOTER_";
my $_HEADER="_NO_HEADER_";

# This script needs the variables OLANG, LOCALE, QADATA, QATEMP, QAOUTPUT, QASERVER, QALOCAL,
# a (language?) specific output directory, the name of the subtype file, how to sort the testcases, a maximum number for randomly
# generated files ($sort_by = "RANDOM_NUMBER"), a seed value for the random numbers (if using), BOM (yes/no), OMS format and filetype
# (file type is determined by OMS format and is defined in run_be.bsh).
# ${OLANG} ${LOCALE} ${QADATA} ${QATEMP} ${QALOCAL} ${QASERVER} ${QAOUTPUT} $SYNTAX_DIR $SETTINGS_FILE

my $_OLANG     = $ARGV[0];
my $LOCALE     = $ARGV[1];
my $_QADATA    = $ARGV[2];
my $_QATEMP    = $ARGV[3];
my $_QALOCAL   = $ARGV[4];
my $_QASERVER  = $ARGV[5];
my $_QAOUTPUT  = $ARGV[6];
my $output_dir = $ARGV[7];
my $SETTINGS   = $ARGV[8];
my $filter     = $ARGV[9];

$/ = "\n";
open ( SETTINGS, "<", $SETTINGS );

while (<SETTINGS>) {
	chomp;
	$x = $_;
	DefineVarValue($x,"bom",$BOM,1,"NO");
	DefineVarValue($x,"encoding",$encoding,0,"unicode");
	DefineVarValue($x,"groups",$hi_rand_num,0,"200");
	DefineVarValue($x,"logfile",$LOGFILE,0,"none");
	DefineVarValue($x,"oms_format",$OMS_FORMAT,1,"OXML");
	DefineVarValue($x,"seed",$seed,0,"123456");
	DefineVarValue($x,"sort_by",$sort_by,1,"ID");
	DefineVarValue($x,"subtype_file",$subtype_file,0,"none");
	DefineVarValue($x,"header",$_HEADER,0,"_NO_HEADER_");
	DefineVarValue($x,"footer",$_FOOTER,0,"_NO_FOOTER_");
	} 

if ( substr($sort_by,0,4) =~ "RAND" ) { $sort_by = "RANDOM_NUMBER" }
close SETTINGS;

for ($OMS_FORMAT) {
	if ( /OXML/ ) { $OMS_TYPE=".xml";}
	if ( /HTML/ ) { $OMS_TYPE=".htm" ;}
	if ( /TEXT/ ) { $OMS_TYPE=".txt" ;}
	if ( /TABTEXT/ ) { $OMS_TYPE=".prn" ;}
	if ( /(PDF|XLS|XLSX|DOC|SPV)/ ) { $OMS_TYPE=".".lc($OMS_FORMAT);}
	if ( /REPORTHTML/ ) { $OMS_TYPE="htm" ;}
	if ( /REPORTMHT/ ) { $OMS_TYPE="mht";}
}

###########################
# Arrays and settings
my @gss=("sex", "race", "region", "happy", "life", "sibs", "childs", "age", "educ", "paeduc", "maeduc", "speduc", "prestg80", "occcat80", "tax", "usintl", "obey", "popular", "thnkself", "workhard", "helpoth", "hlth1", "hlth2", "hlth3", "hlth4", "hlth5", "hlth6", "hlth7", "hlth8", "hlth9", "work1", "work2", "work3", "work4", "work5", "work6", "work7", "work8", "work9", "prob1", "prob2", "prob3", "prob4");
my @emp=("id", "gender", "bdate", "educ", "jobcat", "salary", "salbegin", "jobtime", "prevexp", "minority");
my @aml=("chemo", "time", "status");
my @brk=("srcid", "gender", "TP", "BT", "EMM", "JD", "CT", "BMM", "HRB", "TMd", "BTJ", "TMn", "CB", "DP", "GD", "CC", "CMB");
my @brst=("id", "age", "pathsize", "lnpos", "histgrad", "er", "pr", "status", "pathscat", "ln_yesno", "time");
my @nhis=("STRATUM", "PSU", "WTFA_SA", "SEX", "AGE_P", "REGION", "SMKNOW", "VITANY", "VITMUL", "HERBSUPP", "VIGFREQW", "MODFREQW", "STRFREQW", "DESIREWT", "MOVE1", "LIFT", "age_cat");
my @ships=("type", "construction", "operation", "months_service", "log_months_service", "damage_incidents");
my @tst=("school", "school_setting", "school_type", "classroom", "teaching_method", "n_student", "student_id", "gender", "lunch", "pretest", "posttest");

if ( $_OLANG eq "French") {
	@gss=("sexe", "statut", "region", "heureux", "vie", "nbfr_sr", "enfant", "age", "educ", "educpere", "educmere", "educconj", "prestg80", "catemp80", "taxe", "actafint", "obeir", "populair", "pensesoi", "travdur", "aideautr", "sante1", "sante2", "sante3", "sante4", "sante5", "sante6", "sante7", "sante8", "sante9", "travail1", "travail2", "travail3", "travail4", "travail5", "travail6", "travail7", "travail8", "travail9", "prob1", "prob2", "prob3", "prob4");
	@emp=("id", "sexe", "datenais", "educ", "catemp", "salact", "saldeb", "temps", "exp", "minorite");
} elsif ( $_OLANG eq "German") {
	@gss=("geschl", "ethgr", "region", "zufried", "leben", "geschw", "kinder", "alter", "ausbild", "vausbild", "mausbild", "pausbild", "prestg80", "beruf80", "steuer", "intl", "gehor", "beliebt", "denken", "hartarb", "andhelf", "ges1", "ges2", "ges3", "ges4", "ges5", "ges6", "ges7", "ges8", "ges9", "beruf1", "beruf2", "beruf3", "beruf4", "beruf5", "beruf6", "beruf7", "beruf8", "beruf9", "prob1", "prob2", "prob3", "prob4");
	@emp=("id", "geschl", "gebtag", "ausbild", "tätig", "gehalt", "agehalt", "dauer", "erfahr", "mind");
	@nhis=("STRATUM", "PSU", "Gewicht", "Geschlecht", "Alter", "Region", "Rauchen", "Vitaminmineral", "Multivitamin", "Kräuter", "Anstrengung_stark", "Anstrengung_mittel", "Krafttraining", "Wunschgewicht", "Bewegung", "Tragen", "Altersgruppe");
} elsif ( $_OLANG eq "Italian") {
	@gss=("sesso", "razza", "regione", "felicita", "vita", "fratsore", "figli", "eta", "istruz", "paistruz", "maistruz", "spistruz", "prestg80", "catocc80", "tasse", "usaimp", "obbedire", "popolari", "testapro", "lavorare", "aiutare", "salute1", "salute2", "salute3", "salute4", "salute5", "salute6", "salute7", "salute8", "salute9", "lavoro1", "lavoro2", "lavoro3", "lavoro4", "lavoro5", "lavoro6", "lavoro7", "lavoro8", "lavoro9", "prob1", "prob2", "prob3", "prob4");
	@emp=("id", "sesso", "datanasc", "istruz", "catlav", "stipatt", "stipiniz", "mesilav", "espeprec", "cittextr");
	@aml=("chemio", "tempo", "stato");
	@brk=("srcid", "sesso", "TP", "BT", "EMM", "JD", "CT", "BMM", "HRB", "TMd", "BTJ", "TMn", "CB", "DP", "GD", "CC", "CMB");
	@brst=("id", "eta", "dimtum", "linfopos", "gradisto", "re", "rp", "stato", "cattum", "linfsino", "tempo");
	@nhis=("STRATO", "PSU", "PESO_FA", "SESSO", "ETA", "REGIONE", "FUMO", "VITGEN", "VITMUL", "VEGSUPP", "ATT_INT", "ATT_MOD", "ALLMUSC", "PESOCONS", "MOTO", "SOLLPESI", "cat_età");
} elsif ( $_OLANG eq "Japanese") {
	@gss=("性別", "人種", "地域", "幸福", "ﾗｲﾌ", "兄弟", "子供", "年齢", "就学年数", "父就学", "母就学", "配偶就学", "prestg80", "occcat80", "tax", "usintl", "obey", "popular", "thnkself", "workhard", "helpoth", "hlth1", "hlth2", "hlth3", "hlth4", "hlth5", "hlth6", "hlth7", "hlth8", "hlth9", "work1", "work2", "work3", "work4", "work5", "work6", "work7", "work8", "work9", "prob1", "prob2", "prob3", "prob4", "z就学", "z母就学", "z父就学", "z配就学");
	@emp=("id", "性別", "生年月日", "就学年数", "職種", "給与", "初任給", "在籍月数", "職務経歴", "人種");
	@aml=("化学療法", "時間", "状態");
	@brst=("id", "年齢", "腫瘍ｻｲｽﾞ", "ﾘﾝﾊﾟ", "組織段階", "er", "pr", "ｽﾃｰﾀｽ", "腫瘍ｶﾃｺﾞ", "ﾘﾝﾊﾟ節", "時間");
	@nhis=("ｽﾄﾗｰﾀ", "PSU", "WTFA_SA", "性別", "年齢_p", "地域", "喫煙", "ﾋﾞﾀﾐﾈ", "ﾋﾞﾀﾏﾙ", "ﾊｰﾌﾞ", "活発", "穏やか", "体力", "標準体重", "移動1", "持運び", "年齢ｶﾃｺﾞ");
	@ships=("種類", "建造", "作業", "月_サービス", "log_月_サービス", "損傷_件数");
} elsif ( $_OLANG eq "Korean") {
	@gss=("성별", "인종", "지역", "행복도", "생활", "형제수", "자녀수", "연령", "졸업년도", "부친졸업", "모친졸업", "배우자", "직업점수", "직업구분", "소득세", "관심사", "준법", "인기", "자립", "근면", "구제", "건강1", "건강2", "건강3", "건강4", "건강5", "건강6", "건강7", "건강8", "건강9", "직장1", "직장2", "직장3", "직장4", "직장5", "직장6", "직장7", "직장8", "직장9", "문제1", "문제2", "문제3", "문제4");
	@emp=("번호", "성별", "생년월일", "피교육", "직종", "현재급여", "최초급여", "근무월수", "경력", "소수민족");
	@brst=("번호","연령","종양크기","임파결절","조직등급","에스트로","프로게스","상태","종양범주","결절유무","시간");
	@aml=("화학요법", "시간", "상태");
	@brk=("번호", "연령", "종양크기", "임파결절", "조직등급", "에스트로", "프로게스", "상태", "종양범주", "결절유무", "시간");
} elsif ( $_OLANG eq "Spanish") {
	@gss=("sexo", "raza", "región", "feliz", "vida", "hermanos", "hijos", "edad", "educ", "educpad", "educmad", "educesp", "prestg80", "catocu80", "impuesto", "usaimp", "obedecer", "popular", "pensprop", "trabajar", "ayudar", "salud1", "salud2", "salud3", "salud4", "salud5", "salud6", "salud7", "salud8", "salud9", "trabajo1", "trabajo2", "trabajo3", "trabajo4", "trabajo5", "trabajo6", "trabajo7", "trabajo8", "trabajo9", "prob1", "prob2", "prob3", "prob4");
	@emp=("id", "sexo", "fechnac", "educ", "catlab", "salario", "salini", "tiempemp", "expprev", "minoría");
	@aml=("quimio", "tiempo", "estado");
	@brk=("idesc", "género", "TS", "TM", "MM", "DJ", "TC", "BAM", "RM", "TMd", "TMJ", "TMg", "PC", "PD", "DG", "TCf", "BM");
	@brst=("id", "edad", "tamaño", "linpos", "nivhist", "re", "rp", "estado", "tumorcat", "lin_sino", "tiempo");
	@nhis=("ESTRATO", "PSU", "PESOF", "SEXO", "EDAD_P", "REGION", "FUMADOR", "VITACUAL", "VITMUL", "SUPHERB", "FRECVIG", "FRECMOD", "FRECFUER", "PESOIDAL", "MOVER1", "LEVANTAR", "edad_cat");
} elsif ( $_OLANG eq "SChinese") {
	@gss=("性别", "种族", "地区", "幸福", "生活", "兄弟姐妹", "子女", "年龄", "教育", "父亲教育", "母亲教育", "配偶教育", "声望80", "职业80", "税", "参与世界事务", "服从", "欢迎", "自我中心", "工作努力", "帮助别人", "健康1", "健康2", "健康3", "健康4", "健康5", "健康6", "健康7", "健康8", "健康9", "工作1", "工作2", "工作3", "工作4", "工作5", "工作6", "工作7", "工作8", "工作9", "问题1", "问题2", "问题3", "问题4");
	@emp=("员工代码", "性别", "出生日期", "教育水平", "雇佣类别", "当前薪金", "起始薪金", "雇佣时间", "经验", "少数民族");
	@aml=("化学疗法", "时间", "状态");
} elsif ( $_OLANG eq "BPortugu") {
	@gss=("sexo", "raza", "región", "feliz", "vida", "hermanos", "hijos", "edad", "educ", "educpad", "educmad", "educesp", "prestg80", "catocu80", "impuesto", "usaimp", "obedecer", "popular", "pensprop", "trabajar", "ayudar", "salud1", "salud2", "salud3", "salud4", "salud5", "salud6", "salud7", "salud8", "salud9", "trabajo1", "trabajo2", "trabajo3", "trabajo4", "trabajo5", "trabajo6", "trabajo7", "trabajo8", "trabajo9", "prob1", "prob2", "prob3", "prob4");
	@emp=("id", "sexo", "fechnac", "educ", "catlab", "salario", "salini", "tiempemp", "expprev", "minoría");
	@aml=("quimio", "tiempo", "estado");
	@brk=("idesc", "género", "TS", "TM", "MM", "DJ", "TC", "BAM", "RM", "TMd", "TMJ", "TMg", "PC", "PD", "DG", "TCf", "BM");
	@brst=("id", "edad", "tamaño", "linpos", "nivhist", "re", "rp", "estado", "tumorcat", "lin_sino", "tiempo");
	@nhis=("ESTRATO", "PSU", "PESOF", "SEXO", "EDAD_P", "REGION", "FUMADOR", "VITACUAL", "VITMUL", "SUPHERB", "FRECVIG", "FRECMOD", "FRECFUER", "PESOIDAL", "MOVER1", "LEVANTAR", "edad_cat");
}
###########################

open (IN, "<".$subtype_file) or die "Having trouble reading from the file $subtype_file.";

my $file = do { local $/; <IN> }; # slurp!
my @testcases = split( "_EOT_", $file);
my $max = scalar @testcases; #Each test case is in an array now
my $iCount = 0;
my @testcase=q{};
srand($seed);

my @matching_cases=0;
my $flt = $filter;

if ( $flt ne "_EMPTY_" ) {
	SendToOutput($LOGFILE,"Matching only test cases that contain $filter.","both");
	my $i=0;
	foreach $case(@testcases) {
		if ( $case =~ $filter ) {
			$i++;
			$matching_cases[$i]=$case;
		}
	}
} else {
	@matching_cases = @testcases;
}

my $casenum=scalar @matching_cases;

if ( $casenum == 0 ) {
	SendToOutput($LOGFILE,"No cases selected. Nothing to do!","both");
	exit;
}

foreach $case(@matching_cases) {
	my $r = 1+int(rand($hi_rand_num));
	my $id = ExtractValue($case, "ID=","\n");
	my $subtype = ExtractValue($case, "SUBTYPE=","\n");
	my $select = uc ExtractValue($case, "SELECT=","\n");
	my $data = ExtractValue($case, "DATA=","\n");
	my $syntax = q{};
	my $s = q{};
	if ( index($case,"SYNTAX=") > 0 ) {	$syntax = substr($case,index($case,"SYNTAX=")+7) } ;
	if ( $data =~ "Employee data.sav" ) {
		$s = ReplaceArrayValues (\@emp, $syntax);
	} elsif ( $data =~ "1991 U.S. General Social Survey.sav" ) {
		$s = ReplaceArrayValues (\@gss, $syntax);
	} elsif ( $data =~ "AML survival.sav" ) {
		$s = ReplaceArrayValues (\@aml, $syntax);
	} elsif ( $data =~ "breakfast.sav" ) {
		$s = ReplaceArrayValues (\@brk, $syntax);
	} elsif ( $data =~ "Breast cancer survival.sav" ) {
		$s = ReplaceArrayValues (\@brst, $syntax);
	} elsif ( $data =~ "nhis2000_subset.sav" ) {
		$s = ReplaceArrayValues (\@nhis, $syntax);
	} elsif ( $data =~ "ships.sav" ) {
		$s = ReplaceArrayValues (\@ships, $syntax);
	} elsif ( $data =~ "test_scores.sav" ) {
		$s = ReplaceArrayValues (\@tst, $syntax);
	}
	$s =~ s/\n/{eol}/g;
	my $fi = sprintf("%4i",$iCount);
	$fi =~ s/ /0/g;
	my $l = length($hi_rand_num);
	my $num = sprintf("%".$l."i",$r);
	$num =~ s/ /0/g; 
	$testcase[$iCount]=join('~',"TEST=".$fi,"ID=".$id,"SUBTYPE=".$subtype,"SELECT=".$select,"DATA=".$data,"SYNTAX=".$s,"RANDOM_NUMBER=".$num);
	$iCount++;
}
close IN;

@sorted_testcases=CreateSortedTestCases(\@testcase,\@sorted_testcases,$sort_by);

my $last_block = q{};
my $current_block = q{};
my $change = 0;
my $sps_file = q{};
my $dir = $output_dir;
system ("mkdir -p $dir 2> /dev/null") == 0 or warn;

foreach $case(@sorted_testcases) {
	my @line = split('\~', $case);
	my $id = $line[1];
	$id =~ s/ID=//g;
	my $subtype = $line[2];
	$subtype =~ s/SUBTYPE=//g;
	my $select = $line[3];
	$select =~ s/SELECT=//g;
	my $data = $line[4];
	$data =~ s/DATA=//g;
	my $syntax = $line[5];
	$syntax =~ s/SYNTAX=//g;
    $syntax =~ s#\$QADATA#QaData#g ;
    $syntax =~ s#\$QATEMP#QaTemp#g ;
    $syntax =~ s#\$QALOCAL#QaLocal#g ;
    $syntax =~ s#\$QASERVER#QaServer#g ;
	$syntax =~ s#\^#/#g ;
	$syntax =~ s/{eol}/\n/g;
	my $rand = $line[6];
	$rand =~ s/RANDOM_NUMBER=//g;
	
	for ($sort_by) {
		if (/ID/) { $current_block = $id; }
		elsif (/SUBTYPE/) { $current_block = $subtype; }
		elsif (/SELECT/) { $current_block = $select; }
		elsif (/RANDOM_NUMBER/) { $current_block = $rand; }
		else { $current_block = $id; }
    }

	if ( $current_block ne $last_block ) {
		if ( $current_block eq "" ) {
			goto BYPASS ;
		} else {
			if ( $change ) { close SYNTAX_FILE or warn; }
			$change = 1;
			if ( $current_block eq $rand ) {
				$sps_file = "$output_dir"."/RAND".$current_block.".sps";
			} else {
				$sps_file = "$output_dir"."/".$current_block.".sps";
			}
		}
		$e = ">:encoding(".$encoding.")";
		open SYNTAX_FILE, $e, $sps_file or warn;
		if ( $BOM eq "YES" ) {
			print {SYNTAX_FILE} "\x{FEFF}"; #prints BOM (for some reason Statistics needs this)
		}
		
		SendToOutput($LOGFILE,"Writing $sps_file.","stdout");
		my $file_header = Header($_OLANG,$LOCALE,$yr,$_QADATA,$_QATEMP,$_QASERVER,$_QAOUTPUT,$_QALOCAL,$_HEADER);
		print {SYNTAX_FILE} $file_header;
	}

	my $test_case = TestSyntax($id,$subtype,$select,$mo,$mday,$yr,$data,$syntax,$OMS_FORMAT,$OMS_TYPE,$_FOOTER);
	print {SYNTAX_FILE} $test_case;

	for ($sort_by) {
		if (/ID/) { $last_block = $id; }
		elsif (/SUBTYPE/) { $last_block = $subtype; }
		elsif (/SELECT/) { $last_block = $select; }
		elsif (/RANDOM_NUMBER/) { $last_block = $rand; }
		else { $last_block = $id; }
    }
BYPASS:
}
exit;