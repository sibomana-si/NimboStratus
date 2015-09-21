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
# - The variable "encrypted" is assigned the full path of the directory
# where encrypted files are to be placed.
# - The "tmpEnc" and "tmpDec" directories are assigned the full paths of the
# the directories used to temporarily hold files during the encryption/
# decryption process.
# - The "passFile" variable is assigned the full path of the file containing
# the password/key used for encryption
my $url = $ARGV[1];
my $encrypted = $ARGV[2];
my $tmpEnc = $ARGV[3];
my $tmpDec = $ARGV[4];
my $passFile = $ARGV[5];
 
sub Encrypt
  {
	# This function should be modified, to suit the syntax
	# of the encryption application being used.
	#
	# It receives the url of the file to be encrypted, its name,
	# and the encryption password/key.
	# We then specify the name of the output file to be created 
	# after encryption(path + extension), call the encryption 
	# application, and return the full path to the encrypted file.
	#
	# Note that the encrypted file is placed in the tmpEnc 
	# directory. 
	# This helps the "decrypt_script" distinguish between the case 
	# where a file entering the "Enc" directory, is from the CSP and 
	# needs to be decrypted, or is from the user and has just been encrypted.
	# We need to distinguish these two cases in order to avoid
	# getting into an infinite loop of encryption/decryption over the same file.
	# 
	# After this function returns, the encrypted file is copied 
	# to the encrypted directory.
 	my $fileURL = $_[0];
 	my $fileName = $_[1];
	my $pWord = $_[2];
	my $ext = '.aes';
 	my $output = "$tmpEnc"."$fileName"."$ext";
	`aescrypt -e -p $pWord -o $output $fileURL`;
 	return $output;
  }

sub Main
  {  
	# This script monitors the "Dec" directory which holds the user's
	# plaintext files.
	# When the user uploads a file to "USER_DIR" which interfaces with the
	# encryption container, this script is triggered, by the matching rule
	# specified in the incrontab file(/var/spool/incron/root), 
	# and this matching rule passes the url of the file to this script.
	# Note that the rules, specifiying the directories to be monitored by incron,
	# the events to monitor, and the actions to take when the events occur,
	# are created during the configuration setup phase (split-trust_config.sh 
	# -- specifically in the Enc_Image_Setup () function)
	chomp($url);

	# we extract the file name from the url
	my $fname = fileparse($url);
	my $compareFile = $tmpDec . $fname;

	# We check if the file that triggered the script has a similar copy
	# in the tmpDec directory. If a similar copy exists in the tmpDec 
	# directory, it means that the file should not be encrypted, since 
	# it has just been decrypted.
	# When the "decrypt_script", in charge of decryption, decrypts a file,
	# it places a copy of the decrypted plaintext file in the tmpDec 
	# directory, before copying the file to the user's directory.
	# This helps distinguish between the case where a file entering the "Dec"
	# directory(which triggers this script), is from the CSP and has just 
	# been decrypted, or is from the user and needs to be encrypted before being 
	# sent to the CSP. We need to distinguish these two cases in order to avoid
	# getting into an infinite loop of encryption/decryption over the same file.
	my $fileCheck = compare($url, $compareFile);
  
	if ($fileCheck == 0)
	 {
		# if a similar copy of the file exists in the tmpDec directory,
		# it means the received file has just been decrypted, and shouldn't
		# be encrypted again.
		# we delete the copy of the file in the tmpDec directory, and exit.
		# There's nothing else to do.
		unlink $compareFile;
	 }
	else
	 {
		# otherwise, the file needs to be encrypted, and we proceed as follows:
		# we open the file containing the encryption password/key,
		# extract the password/key, and close the file.
		open(PASSFILE, "<$passFile") || die ("failed to open $passFile\n");
		my $passWord = <PASSFILE>;
		chomp($passWord);
		close(PASSFILE);
	
		# we then pass the url of the file to be encrypted, the filename, and
		# the encryption password/key to the encryption function.
		# The encryption function encrypts the file, then returns the full path
		# to the encrypted file.
		# The encrypted file is then copied to the encrypted directory, and this
		# script's work is done.
		my $outFile = Encrypt($url, $fname, $passWord); 
		copy($outFile, $encrypted);
	 }
  }
  
Main();