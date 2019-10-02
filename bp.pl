#!/usr/bin/perl

#
# BluePrint v0.1
#
# Collin Mulliner and Martin Herfurt
# (c) {collin,martin}@trifinite.org
#

use Switch;

# --- config ---
# Database
$BP_DB="blueprint.db";

# --- info ---
if ($#ARGV < 0) {
	print "\nBluePrint v0.1 - by the trifinite group\n" .
		"http://www.trifinite.org\n\n" .
		" see README for more information!\n\n" .
		"usage:\n" . 
		"\tsdptool browse --tree --l2cap XX:XX:XX:XX:XX:XX | ./bp.pl XX:XX:XX:XX:XX:XX <option>\n\n" .
		"option can be one of: -mkdb  (no database lookup just generate hash)\n" .
		"                      -nomac (don't use the MAC/BD_ADDR for database lookups)\n";
	exit(0);
}

# --- parameters ---
# BD_ADDR
$BD_ADDR=$ARGV[0];
$BD_ADDR =~ s/:..:..:..$//;

$mkdb = 0;
if ($ARGV[1] eq "-mkdb") {
	$mkdb = 1;
}
$nomac = 0;
if ($ARGV[1] eq "-nomac") {
	$nomac = 1;
}

# --- calc hash ---
$state = 0;
$fp = 0;
$tmp_fp = 0;

while ($line = <STDIN>) {
	#print $line;
	chomp($line);
	$_ = $line;
	
	switch ($state) {
	case 0 {
		if (/Service RecHandle/) {
			$state = 2;
			$_ =~ s/^Service RecHandle: //;
			$tmp_fp = hex $_;
		}
		elsif (/ServiceRecordHandle/) {
			$state = 1;
		}
	}
	case 1 {
		if (/Integer/) {
			$state = 2;
			$_ =~ s/.*: //;
			$tmp_fp = hex $_;
		}
	}
	case 2 {
		if (/Channel:/) {
			$state = 0;
			$_ =~ s/Channel: //;
			$_ =~ s/^[\s\t]+//;
			$_ =~ s/[\s\t]+$//;
			$fp = $fp + ($tmp_fp * $_);
		}
		elsif (/Channel\/Port/) {
			$state = 0;
			$_ =~ s/.*: //;
			$fp = $fp + ($tmp_fp * (hex $_));
		}
	}
	}
}

# --- combine FP and BD_ADDR ---
if ($nomac == 0) {
	$fp = $BD_ADDR . "@" . $fp;
}

#print "$fp\n";

# --- in mkdfb mode just print key and exit ---
if ($mkdb == 1) {
	print "$fp\n";
	exit;
}

# --- search database ---

$p = 0;
$c = 0;
open(DB, "< $BP_DB") or die "can't open $BP_DB";
while ($line = <DB>) {
	chomp($line);
	$_ = $line;
	if ($p == 0) {
		if (/^$fp$/ && $nomac == 0) {
			$p = 1;
			$c = 1;
			print "$line\n";
		}
		if (/^.*\@$fp$/ && $nomac == 1) {
			$p = 1;
			$c = 1;
			print "$line\n";
		}
	}
	elsif ($p == 1) {
		if (/^EOD/) {
			print "\n";
			#close(DB);
			#exit(0);
			# find more then one match
			$p = 0;
		}
		else {
			print "$line\n";
		}
	}
}
close(DB);

# --- no match found ---
if ($c == 0) {
	print "\nno match found for: $fp\n\n" .
		"Please report the fingerprint and the complete SDP data plus as much\n" .
		"information about the device and the software running on it, especially\n" .
		"the software version is of interest.\n\n" .
		"See README on howto get even more information about a device\n\n" .
		"Send everything to: blueprint\@trifinite.org, thank you!\n\n";
}
