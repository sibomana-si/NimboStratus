#! /usr/bin/perl 
 
use warnings;
use strict;

use File::Compare;
use File::Basename;
use File::Copy;
  
# The following variables are initialised using values passed from
# the configuration setup file (counter-collusion_config.sh)
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
	# This function should be modified, to suit the requirements
	# of the encryption application being used.
	# It receives the url of the file to be decrypted, its name,
	# and the decryption password/key.
	# We then specify the name of the output file to be created 
	# after decryption(path), call the encryption 
	# application, and return the full path to the decrypted file.
	# Note that the decrypted file is placed in the tmpDec 
	# directory. It is later (after this function returns) copied
	# to the decrypted directory.
 	my $fileURL = $_[0];
 	my $fileName = $_[1];
	my $pWord = $_[2];
 	copy($fileURL, $tmpDec);
 	my $output = "$tmpDec"."$fileName";
 	$output =~ s/.cpt//;
 	`ccrypt -d -K $pWord ${tmpDec}${fileName}`;
 	return $output;
  }
 
sub Main
  { 
	# This script monitors the "encrypted" directory which holds the user's
	# ciphertext files.
	# When a file uploaded by the user is encrypted, and placed in this
	# directory, or an encrypted file is received from the CSP, this script 
	# is triggered, and the url of the file is passed to this script.
	# The following line removes any newline that may exist at the end of the 
	# url string.
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
	# directory, before copying the file to the encrypted directory.
	# This helps distinguish between the case where a file entering the 
	# encrypted directory(which triggers this script), is from the CSP and 
	# needs to be decrypted, or is from the user and has just been encrypted.
	my $fileCheck = compare($url, $compareFile);
  
	if ($fileCheck == 0)
	 {
		# if a similar copy of the file exists in the tmpEnc directory,
		# we delete the copy of the file in the tmpEnc directory, and exit.
		# There's nothing else to do.
		unlink $compareFile;
	 }
	else
	 { 
		# otherwise, we open the file containing the decryption password/key,
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
  }
  
Main();