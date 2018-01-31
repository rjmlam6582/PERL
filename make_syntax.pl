#!/usr/local/bin/perl
use POSIX qw(strftime);
use warnings;

my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
my $yr = $year += 1900;
my $mo= $mon + 1;

sub ReplaceArrayValues {
	my @array = @{$_[0]};
	my $this_syntax = $_[1];
	for ($i = scalar(@array)-1; $i >= 0; $i--) {
		my $find = "_DATAVAR_".$i;
		my $replace = $array[$i];
		if ( $this_syntax =~ $find ) { $this_syntax =~ s/$find/$replace/g; }
	}
	return $this_syntax;
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
	my $len = $y - $start - 1;
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

# Needs Subtype file, OLANG, LOCALE, QADATA, QATEMP, QAOUTPUT, QASERVER, and QALOCAL.
my $_OLANG       = $ARGV[0];
my $LOCALE       = $ARGV[1];
my $_QADATA      = $ARGV[2];
my $_QATEMP      = $ARGV[3];
my $_QALOCAL     = $ARGV[4];
my $_QASERVER    = $ARGV[5];
my $_QAOUTPUT    = $ARGV[6];
my $output_dir   = $ARGV[7];
my $subtype_file = $ARGV[8];

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

my $file_handles="FILE HANDLE QaData   /NAME=\"$_QADATA\".
FILE HANDLE QaTemp   /NAME=\"$_QATEMP\".
FILE HANDLE QaServer /NAME=\"$_QASERVER\".
FILE HANDLE QaOutput /NAME=\"$_QAOUTPUT\".
FILE HANDLE QaLocal  /NAME=\"$_QALOCAL\".\n"
;

 my $document = do {
    local $/ = undef;
    open my $fh, "<", $subtype_file or die "Could not open $subtype_file: $!";
	@blocks = split ( '_EOT_\n', <$fh> );
	$my_block = 0;
	my $my_id = q{};
	my $my_subtype = q{};
	my $my_select = q{};
	my $my_data = q{};
	my $my_last_id = q{};
	my $my_last_subtype = q{};
	my $my_last_select = q{};
	my $my_last_data = q{};

	while ( $my_block <= $#blocks ) {
		my $oms_command =
		"OMS /SELECT _SELECT_'{n}' /IF COMMANDS=[\"_ID_\"] SUBTYPES=[\"_SUBTYPE_\"]'{n}' /DESTINATION FORMAT=OXML'{n}' OUTFILE=\"QaOutput/_ID___SUBTYPE_.xml\"'{n}' /TAG='TemplateTag'." ;
        my $start_block = index( $blocks[$my_block], "ID=" );
        my $end_block = index ( $blocks[$my_block], "SYNTAX=" );
	    my $block1 = substr( $blocks[$my_block], $start_block, $end_block );
		$block1 =~ s/\n/'{n}'/g ;

	    $my_last_id = $my_id;
	    $my_last_subtype = $my_subtype;
	    $my_last_select = $my_select;
	    $my_last_data = $my_data;

        $my_id = ExtractValue($block1, "ID=",'{n}');
        $my_subtype = ExtractValue($block1, "SUBTYPE=",'{n}');
		$my_select = uc ExtractValue($block1, "SELECT=",'{n}');
		$my_data = "GET FILE=\"QaServer/".ExtractValue($block1, "DATA=",'{n}')."\".";
		$block1 =~ s/DATA=/GET FILE=/g;
		$oms_command =~ s/_ID_/$my_id/g;
		$oms_command =~ s/_SUBTYPE_/$my_subtype/g;
		$oms_command =~ s/_SELECT_/$my_select/g;
		$oms_command =~ s/'{n}'/\n/g;

        if ( $my_last_id ne $my_id ) {
		    my $sps_file = "$output_dir"."/".$my_id.".sps";
			open( SYNTAX_FILE, ">", $sps_file);
			print "Writing $sps_file.\n";
			print {SYNTAX_FILE} "set olang=$_OLANG /locale=\"$LOCALE\".\n";
			my $asterisk=RepeatChar(72, "*");
			print {SYNTAX_FILE} "$asterisk\n";
			print {SYNTAX_FILE} "**Licensed Materials - Property of IBM\n**\n** (C) Copyright IBM Corp. 1989, $yr.\n**\n**US Government Users Restricted Rights - Use, duplication or disclosure restricted\n**by GSA ADP Schedule Contract with IBM Corp.\n";
			print {SYNTAX_FILE} $asterisk.".\n";
		    print {SYNTAX_FILE} $file_handles ;
        }
        print {SYNTAX_FILE} "\nset printback none.\n";
		print {SYNTAX_FILE} "$oms_command\n\n";
		print {SYNTAX_FILE} "title \"zxz ".$my_id."_".$my_subtype."\".\n";
        print {SYNTAX_FILE} "include file 'QaData/std18.inc'.\n";
        print {SYNTAX_FILE} "set unicode on.\n\n";
        print {SYNTAX_FILE} "*modification history.\n";
        printf {SYNTAX_FILE} "* %02d-%2d-%4d - richardm - created.\n\n", $mo,$mday,$yr;
        print {SYNTAX_FILE} "*description.\n";
        print {SYNTAX_FILE} "* Produce $my_subtype for procedure $my_id.\n\n";
		print {SYNTAX_FILE} "$my_data\n\n";
		
		my $syntax = substr ( $blocks[$my_block], $end_block );
	    $syntax =~ s/\n/'{n}'/g ;
	    $syntax =~ s/SYNTAX=//g ;
	    $syntax =~ s#\$QADATA#QaData#g ;
	    $syntax =~ s#\$QATEMP#QaTemp#g ;
	    $syntax =~ s#\$QALOCAL#QaLocal#g ;
	    $syntax =~ s#\$QASERVER#QaServer#g ;
		$syntax =~ s#\^#/#g ;
	    
		if ( $my_data =~ "Employee data.sav" ) {
			$syntax = ReplaceArrayValues (\@emp, $syntax);
		} elsif ( $my_data =~ "1991 U.S. General Social Survey.sav" ) {
			$syntax = ReplaceArrayValues (\@gss, $syntax);
		} elsif ( $my_data =~ "AML survival.sav" ) {
			$syntax = ReplaceArrayValues (\@aml, $syntax);
		} elsif ( $my_data =~ "breakfast.sav" ) {
			$syntax = ReplaceArrayValues (\@brk, $syntax);
		} elsif ( $my_data =~ "Breast cancer survival.sav" ) {
			$syntax = ReplaceArrayValues (\@brst, $syntax);
		} elsif ( $my_data =~ "nhis2000_subset.sav" ) {
			$syntax = ReplaceArrayValues (\@nhis, $syntax);
		} elsif ( $my_data =~ "ships.sav" ) {
			$syntax = ReplaceArrayValues (\@ships, $syntax);
		} elsif ( $my_data =~ "test_scores.sav" ) {
			$syntax = ReplaceArrayValues (\@tst, $syntax);
		}
		$syntax =~ s/'{n}'/\n/g;

        print {SYNTAX_FILE} "$syntax";
		print {SYNTAX_FILE} "*=== end of job ===.\n";
        print {SYNTAX_FILE} "OMSEND TAG='TemplateTag'.\n";
		
	    $my_block++;
	}
}
