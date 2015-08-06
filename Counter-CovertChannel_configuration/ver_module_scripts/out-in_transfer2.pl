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
# - The variable "csp" is assigned the full path of the directory
# that interfaces with the user's directory(USER_DIR)
# - The "auditLog" variable is assigned the full path of the file we use
# to log events that may be malicious
my $url = $ARGV[1];
my $encrypted = $ARGV[2];
my $csp = $ARGV[3];
my $auditLog = "/ver-mod_audit.log";

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

# This script monitors the "encrypted2" directory in the VERIFICATION
# container, which interfaces with the encryption container ENC_MODULE2.
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
# in the "csp" directory. If a similar copy exists, it means 
# that the file should not be sent to the "csp" directory, since it 
# has just been received from the CSP, and is being synced to the user.
# This helps distinguish between the case where a file entering the 
# "encrypted2" directory(which triggers this script), is from the CSP 
# and needs to be decrypted before being sent to the user, or is from 
# the user. We need to distinguish these two cases in order to avoid 
# getting into an infinite loop.

my $status = FileCheck($url, $fname, $csp);

if($status != 0)
  {
	# If a similar copy isn't found in the "csp" directory, 
    # it means that the file is being sent to the CSP.
    # We verify that a similar copy of this file was received in the
    # "encrypted" directory (which interfaces with the ENC_MODULE 
    # container).
	#
	# This is done to ensure that none of the two encryption applications 
	# is attempting to leak data to the CSP, either by embedding it in the
	# encrypted file, or via a covert channel where it pads the encrypted file 
	# to a certain size in order to transmit information, or even sending files
	# that were not sent by the user.
    # If we find a similar copy of the file in the "encrypted" directory,
    # we do nothing and exit.
	my $verStatus = FileCheck($url, $fname, $encrypted);
	if($verStatus != 0)
	  {
		# if a similar copy of this file isn't found in the "encrypted" directory,
		# we wait for a minute, then check again.
		#
		# we do this to force the copying of the file to the CSP, as close as possible
		# to the time when it was received by the encryption application. 
		# This prevents a malicious encryption application from being able to arbitrarily
		# decide when to send the encrypted file, and thus leak data to the colluding CSP
		# by modulating the sending time. It also reduces the time window within 
		# which a malicious encryption application can leak data via a timing channel, 
		# to 1 minute from when the file is received by the other encryption application.
		sleep(60);
		$verStatus = FileCheck($url, $fname, $encrypted);
		if($verStatus != 0)
		  {
			# if a similar copy of this file still isn't found in the "encrypted" directory,
			# we log this event, and disable incron, which coordinates synchronization,
			# so that no more file synchronization with the CSP will take place, until the user
			# restarts incron.
			# we also delete the file that triggered this script, so that later on if a similar 
			# file arrives in the "encrypted" directory, it won't get copied to the "csp" directory.
			unlink $url; 
			open(LOG, ">>$auditLog") || die("failed to open $auditLog\n");
			print LOG "File check failed! Second copy of file $fname was not seen in $encrypted!\n";
			close(LOG);
			`pkill -f incrond`; #stop incron -- this disables the file syncing process
		  }
	  }
  }