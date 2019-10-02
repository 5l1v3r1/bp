#!/usr/bin/perl

#
# BluePrint database generator
#
# v0.1 Collin Mulliner <collin(AT)trinite.org>
#

$BP_CMD = "./bp.pl";
$BP_DB = "blueprint.db";
$BP_DEVICE_DIR = "devices";

@sdp_scan_files = `ls $BP_DEVICE_DIR`;

foreach $curfile (@sdp_scan_files) {
	chomp($curfile);
	$mac = `head -n 1 $BP_DEVICE_DIR/$curfile`;
	$mac = substr($mac, 0, 8);
	
	open(TMPSDP, "> .mkdb_temp_sdp") or die "can't open sdp temp file";
	open(TMPINFO, "> .mkdb_temp_info") or die "can't open info temp file";
	open(CUR, "< $BP_DEVICE_DIR/$curfile") or die "can't open current file";

	while ($line = <CUR>) {
		$switch = 0;
		chomp($line);
		$_ = $line;
		if (/^---sdp/) {
			$state = 1;
			$switch = 1;
		}
		if (/^\/---sdp/) {
			$state = 2;
		}
		if ($state == 1 && $switch == 0) {
			print TMPSDP "$line\n";
		}
		if (/^---info/) {
			$state = 3;
			$switch = 1;
		}
		if (/^\/---info/) {
			$state = 2;
		}
		if ($state == 3 && $switch == 0) {
			print TMPINFO "$line\n";
		}
	}
	close(TMPSDP);
	close(TMPINFO);
	close(CUR);

	$key = `cat .mkdb_temp_sdp |$BP_CMD $mac -mkdb`;
	chomp($key);
	$bla = `echo $key >>$BP_DB`;
	$bla = `cat .mkdb_temp_info >>$BP_DB`;
	$bla = `echo EOD >>$BP_DB`;
}
$bla = `cat blueprint.db_static >>blueprint.db`;
