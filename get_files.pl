#!/usr/local/bin/perl
#given an array of directories, get all the target files

my $FILE_FILTER=".*";
my $target_extension="txt";
my $all_dirs=("C:/Temp, C:/output_files/compare/en, C:/test/csv");
my @files;
my @all_files;

my @dir = split /,/, $all_dirs;

foreach my $d(@dir) {
	$d =~ s/^\s+|\s+$//g; #trim leading or trailing spaces
	opendir(TARGETDIR, $d ) or die "Problem opening directory $d.\n";
	@files = grep { (!/^\./) && ( /$FILE_FILTER/ && /$target_extension/i) } readdir(TARGETDIR);
	closedir(TARGETDIR);
	foreach my $file(@files) { my $f=$d.'/'.$file ; push (@all_files, $f) } ;
}

@all_files = sort {$a cmp $b} @all_files;

#START LOOPING THROUGH FILES
foreach my $file(@all_files) {
	print "$file\n";
}