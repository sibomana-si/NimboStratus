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
# that interfaces with the CSP client container
# - The "auditLog" variable is assigned the full path of the file we use
# to log events that may be malicious
my $url = $ARGV[1];
my $encrypted2 = $ARGV[2];
my $csp = $ARGV[3];
my $auditLog = "/ver-mod_audit.log";
my $dispatchTime;

sub FileVerification
  {
	# This function takes in 3 input parameters, the URL of the file
	# that triggered this script, the name of the file, and the path
	# to the "encrypted2" directory.
	# It then checks whether a similar (content) copy of the file that 
	# triggered this script, exists in the "encrypted2" directory.
	# If it finds one, it copies the file that triggered this script to
	# the "csp" directory.
	# It returns a status code indicating whether or not a similar file 
	# was found.
	my $fileURL = $_[0];
	my $fileName = $_[1];
	my $dir = $_[2];

	my $compareFile = $dir . $fileName;
    my $compareStatus = compare($fileURL, $compareFile);
	
	if ($compareStatus == 0)
	  {
		my $currentTime = `date +"%M:%S"`;
		chomp($currentTime);
		my @time = split(':', $currentTime);
		my $minute = $time[0];
		my $seconds = $time[1];
		
		if (($minute % 2) == 0)
		  {
			$dispatchTime = 120;
		  }
		else
		  {
			$dispatchTime = 180;
		  }
		# Assigning the dispatchTime value as above ensures that the file
		# is always sent out at the top of an even minute. This prevents a
		# malicious encryption application from leaking information to the
		# CSP client by modulating the file send time between odd and even 
		# minutes.
		
		my $dispatchCountDown = $dispatchTime - $seconds;
		sleep($dispatchCountDown);
		copy($fileURL, $csp);
	  }
	return $compareStatus;
  }

sub Main
  { 
	# This script monitors the "encrypted" directory in the VERIFICATION
	# container, which interfaces with the encryption container ENC_MODULE.
	# When a file, to be synced to the CSP, or which has just been received 
	# from the CSP, lands on this directory, this script is triggered, by the 
	# matching rule specified in the incrontab file(/var/spool/incron/root). 
	# The matching rule passes the url of the file to this script.
	#
	# Note that the rules, specifiying the directories to be monitored by incron,
	# the events to monitor, and the actions to take when the events occur,
	# are created during the configuration setup phase 
	# (counter-covertchannels_config.sh -- specifically in the Aux_Image_Setup () 
	# function)

	chomp($url);

	# we extract the file name from the url
	my $fname = fileparse($url);
	my $compareFile = $csp . $fname;

	# We check if the file that triggered the script has a similar copy
	# in the "csp" directory. If a similar copy exists, it means 
	# that the file should not be sent to the CSP's directory, since it 
	# has just been received from the CSP, and is being synced to the user.
	# This helps distinguish between the case where a file entering the 
	# "encrypted" directory(which triggers this script), is from the CSP 
	# and needs to be decrypted before being sent to the user, or is from 
	# the user. We need to distinguish these two cases in order to avoid 
	# getting into an infinite loop.
	my $fileCheck = compare($url, $compareFile);
  
	if($fileCheck != 0)
	  {
		# If a similar copy isn't found in the "csp" directory, 
		# it means that the file is being sent to the CSP, and is to
		# be copied to the "csp" directory.
		
		# Before sending the encrypted file to the "csp" directory,
		# we need to verify that the two encrypted files produced by the
        # ENC_MODULE and ENC_MODULE2 containers have been seen, and that 
		# they have the same content.
		# This is done to ensure that none of the two encryption applications 
		# is attempting to leak data to the CSP, either by embedding it in the
		# encrypted file, or via a covert channel where it pads the encrypted file 
		# to a certain size in order to transmit information, or arbitrarily sending 
		# files that were not sent by the user.
		#
		# We therefore stall for one minute, and then verify that a similar
		# copy of the encrypted file that triggered this script exists in 
		# the "encrypted2" directory (which interfaces with the ENC_MODULE2 
		# container).
		
		sleep(60);
		my $verStatus = FileVerification($url, $fname, $encrypted2);
		if($verStatus != 0)
		  {
			# if a similar copy of this file isn't found in the "encrypted2" directory,
			# we disable incron, which coordinates synchronization, so that no more file 
			# synchronization with the CSP will take place, until the user restarts incron.
			# We also log the event.
			`pkill -f incrond`; 
			open(LOG, ">>$auditLog") || die("failed to open $auditLog\n");
			print LOG "File check failed! Second copy of file $fname was not seen in $encrypted2!\n";
			close(LOG);
		  }
		 
	  }
  }
  
Main();