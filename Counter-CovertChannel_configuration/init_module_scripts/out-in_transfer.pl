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
# - The variable "encrypted2" is assigned the full path of the directory
# that interfaces with the ENC_MODULE2 container
# - The variable "plainDir" is assigned the full path of the directory
# that interfaces with the user's directory(USER_DIR)

my $url = $ARGV[1];
my $encrypted2 = $ARGV[2];
my $plainDir = $ARGV[3];


sub Main
  {
	# This script monitors the "encrypted" directory in the INIT
	# container, which interfaces with the encryption container
	# ENC_MODULE.
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
	my $compareFile = $plainDir . $fname; 
  
	# We check if the file that triggered the script has a similar copy
	# in the plainDir directory. If a similar copy exists, it means 
	# that the file should not be sent to the user's directory, since it 
	# has just been received from the user, and is being synced to the CSP.
	# This helps distinguish between the case where a file entering the 
	# "encrypted" directory(which triggers this script), is from the CSP 
	# and has just been decrypted, or is from the user and needs to be 
	# encrypted before being sent to the CSP. We need to distinguish these 
	# two cases in order to avoid getting into an infinite loop.
	my $fileCheck = compare($url, $compareFile);

	if($fileCheck != 0)
	  {
		# If a similar copy isn't found in the plainDir directory, 
		# it means that the file has been received from the CSP, and is to
		# be copied to the user's directory.
		copy($url, $plainDir);
	  }
  }
  
Main();