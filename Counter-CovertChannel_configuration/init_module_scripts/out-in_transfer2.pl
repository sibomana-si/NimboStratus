#! /usr/bin/perl 
  
use warnings;
use strict;

use File::Compare;
use File::Basename;
use File::Copy;

# The following variables are initialised using values passed from
# the configuration setup file (counter-covertchannels_config.sh)
# - The variable "url" is assigned the full path of the file that triggered
# this script.
# - The variable "encrypted" is assigned the full path of the directory
# that interfaces with the ENC_MODULE container
# - The variable "plainDir" is assigned the full path of the directory
# that interfaces with the user's directory(USER_DIR)
# - The "auditLog" variable is assigned the full path of the file we use
# to log events that may be malicious
my $url = $ARGV[1];
my $encrypted = $ARGV[2];
my $plainDir = $ARGV[3];
my $auditLog = "/init-mod_audit.log";

sub FileCheck
  {
    # This function takes in 3 input parameters, the URL of the file
	# that triggered this script, the name of the file, and the path
	# of the directory, that we want to check has a similar copy of the 
	# file.
	# It then checks whether a similar (content) copy of the file that 
	# triggered this script, exists in the directory.
	# It returns a status code indicating whether or not a similar file 
	# was found.
 	my $fileURL = $_[0];
 	my $fileName = $_[1];
	my $dir = $_[2];

	my $compareFile = "$dir"."$fileName";  
	my $fileCheck = compare($fileURL, $compareFile);  
	return $fileCheck;
  }

# This script monitors the "encrypted2" directory in the INIT
# container, which interfaces with the encryption container
# ENC_MODULE2.
# When a file, to be synced to the CSP (created, or updated by the 
# user), or which has just been received from the CSP, 
# lands on this directory, this script is triggered, by the matching rule
# specified in the incrontab file(/var/spool/incron/root), 
# and this matching rule passes the url of the file to this script.
#
# Note that the rules, specifiying the directories to be monitored by incron,
# the events to monitor, and the actions to take when the events occur,
# are created during the configuration setup phase 
# (counter-covertchannels_config.sh -- specifically in the Aux_Image_Setup () 
# function)
  
chomp($url);

# we extract the file name from the url
my $fname = fileparse($url);
  
# We check if the file that triggered the script has a similar copy
# in the plainDir directory. If a similar copy exists, it means 
# that the file should not be sent to the user's directory, since it 
# has just been received from the user, and is being synced to the CSP.
# This helps distinguish between the case where a file entering the 
# "encrypted2" directory(which triggers this script), is from the CSP 
# and has just been decrypted, or is from the user and needs to be 
# encrypted before being sent to the CSP.
# We need to distinguish these two cases in order to avoid getting into 
# an infinite loop.
my $status = FileCheck($url, $fname, $plainDir);

if($status != 0)
  {
    # If a similar copy isn't found in the plainDir directory, 
    # it means that the file has been received from the CSP.
    # We verify that a similar copy of this file was received in the
    # "encrypted" directory (which interfaces with the ENC_MODULE 
    # container).
	# This is done to ensure that both encryption containers are operating correctly,
    # and that neither is modifying the files being received from the CSP.
	#
    # If we find a similar copy of the file in the "encrypted" directory,
    # we do nothing and exit.
	my $verStatus = FileCheck($url, $fname, $encrypted);
	if($verStatus != 0)
	  {
	    # if a similar copy of this file isn't found in the "encrypted" directory,
		# we wait for a minute, then check again
		sleep(60);
		$verStatus = FileCheck($url, $fname, $encrypted);
		if($verStatus != 0)
		  {
		    # if a similar copy of this file still isn't found in the "encrypted" directory,
			# we log this event, and disable incron, which coordinates synchronization,
			# so that no more file synchronization with the CSP will take place, until the user
			# restarts incron.
			# we also delete the file that triggered this script, so that later on if a similar 
			# file arrives in the "encrypted" directory, it won't get copied to the user's directory.
			unlink $url; 
			open(LOG, ">>$auditLog") || die("failed to open $auditLog\n");
			print LOG "File check failed! Second copy of file $fname was not seen in $encrypted!\n";
			close(LOG);
			`pkill -f incrond`; #stop incron -- this disables the file syncing process
		  }
	  }
  }