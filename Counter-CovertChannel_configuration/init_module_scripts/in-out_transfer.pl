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
# - The variable "encrypted2" is assigned the full path of the directory
# that interfaces with the ENC_MODULE2 container
my $url = $ARGV[1];
my $encrypted = $ARGV[2];
my $encrypted2 = $ARGV[3];
 
# This script monitors the "decrypted" directory in the INIT
# container, which interfaces with the User's directory.
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
my $compareFile = $encrypted . $fname;

# We check if the file that triggered the script has a similar copy
# in the "encrypted" directory. If a similar copy exists, it means 
# that the file should not be sent to the two encryption containers
# (ENC_MODULE and ENC_MODULE2), since it has just been received from
# the "encrypted" directory, and is present in both "encrypted" and 
# "encrypted2" directories.
# (We know that it is present in both direcories, just by checking one 
# directory, since the mechanism that copies the encrypted file from the 
# "encrypted" directory to the "decrypted" directory, only does so when it 
# finds an exact copy of the file in the "encrypted2" directory within a 
# specified time constraint. Refer to the out-in_transfer.pl script to
# see how this works.) 
#
# This helps distinguish between the case where a file entering the 
# "decrypted" directory(which triggers this script), is from the CSP 
# and has just been decrypted, or is from the user and needs to be 
# encrypted before being sent to the CSP. We need to distinguish 
# these two cases to avoid getting into an infinite loop.
my $fileCheck = compare($url, $compareFile);
  
if ($fileCheck != 0)
  {
   # If a similar copy isn't found in the "encrypted" directory, 
   # it means that the file is to be encrypted, then sent to the CSP.
   # We thus copy the file to the directories that interface with
   # the two encryption containers(ENC_MODULE and ENC_MODULE2).
   # The objective is to have the same file encrypted by the two 
   # encryption applications in ENC_MODULE and ENC_MODULE2 respectively,
   # using the same key and initialization vector, so that we can verify
   # whether they are both producing the same output
   copy($url, $encrypted);
   copy($url, $encrypted2);
  }