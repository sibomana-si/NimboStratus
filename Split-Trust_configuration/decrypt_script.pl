#! /usr/bin/perl 

use warnings;
use strict;

use File::Compare;
use File::Basename;
use File::Copy;
 
# The following variables are initialised using values passed from
# the configuration setup script (split-trust_config.sh)
# - The variable "url" is assigned the full path of the file that triggered
# this script.
# - The variable "decrypted" is assigned the full path of the directory
# where encrypted files are stored
# - The "tmpEnc" and "tmpDec" directories are assigned the full paths of the
# the directories used to temporarily hold files during the encryption/
# decryption process.
# - The "passFile" variable is assigned the full path of the file containing
# the password/key used for decryption
my $url = $ARGV[1];
my $decrypted = $ARGV[2];
my $tmpEnc = $ARGV[3];
my $tmpDec = $ARGV[4];
my $passFile = $ARGV[5]; 

sub Decrypt
  {
	# This function should be modified, to suit the syntax
	# of the encryption application being used.
	#
	# It receives the url of the file to be decrypted, its name,
	# and the decryption password/key.
	# We then specify the name of the output file to be created 
	# after decryption(path), call the encryption 
	# application, and return the full path to the decrypted file.
	#
	# Note that the decrypted file is placed in the tmpDec 
	# directory. 
	# This helps the "encrypt_script" distinguish between the case 
	# where a file entering the "Dec" directory, is from the user and 
	# needs to be encrypted, or is from the CSP and has just been decrypted.
	# We need to distinguish these two cases in order to avoid
	# getting into an infinite loop of encryption/decryption over the same file.
	#
	# After this function returns, the decrypted file is copied 
	# to the "Dec" directory.
 	my $fileURL = $_[0];
 	my $fileName = $_[1];
	my $pWord = $_[2];
 	my $output = "$tmpDec"."$fileName";
 	$output =~ s/.aes//;
 	`aescrypt -d -p $pWord -o $output $fileURL`;
 	return $output;
  }
  
# This script monitors the "Enc" directory which holds the user's
# ciphertext files.
# When a file uploaded by the user is encrypted, and placed in this
# directory, or an encrypted file is received from the CSP, this script 
# is triggered, by the matching rule specified in the incrontab file
# (/var/spool/incron/root), and this matching rule passes the url of 
# the file to this script.
# Note that the rules, specifiying the directories to be monitored by incron,
# the events to monitor, and the actions to take when the events occur,
# are created during the configuration setup phase (split-trust_config.sh 
# -- specifically in the Enc_Image_Setup () function)
chomp($url);

# we extract the file name from the url
my $fname = fileparse($url);
my $compareFile = $tmpEnc . $fname;

# We check if the file that triggered the script has a similar copy
# in the "tmpEnc" directory. If a similar copy exists in the tmpEnc 
# directory, it means that the file should not be decrypted, since 
# it has just been encrypted.
# When the "encrypt_script", in charge of encryption, encrypts a file,
# it places a copy of the encrypted file in the tmpEnc 
# directory, before copying the file to the "Enc" directory.
# This helps distinguish between the case where a file entering the 
# "Enc" directory(which triggers this script), is from the CSP and 
# needs to be decrypted, or is from the user and has just been encrypted.
# We need to distinguish these two cases in order to avoid
# getting into an infinite loop of encryption/decryption over the same file.
my $fileCheck = compare($url, $compareFile);
  
if ( $fileCheck == 0 )
  {
    # if a similar copy of the file exists in the tmpEnc directory,
	# it means the received file has just been encrypted, and shouldn't
	# be decrypted.
	# we delete the copy of the file in the tmpEnc directory, and exit.
	# There's nothing else to do.
   	unlink $compareFile;
  }
else
  { 
	# otherwise, the file needs to be decrypted, and we proceed as follows:
	# we open the file containing the decryption password/key,
	# extract the password/key, and close the file.
	open(PASSFILE, "<$passFile") || die ("failed to open $passFile\n");
	my $passWord = <PASSFILE>;
	chomp($passWord);
	close(PASSFILE);
	
	# we then pass the url of the file to be decrypted, the filename, and
	# the decryption password/key to the decryption function.
	# The decryption function decrypts the file, then returns the full path
	# to the decrypted file.
	# The decrypted file is then copied to the decrypted directory, and this
	# script's work is done.
 	my $outFile = Decrypt($url, $fname, $passWord);
 	copy($outFile, $decrypted);
  }