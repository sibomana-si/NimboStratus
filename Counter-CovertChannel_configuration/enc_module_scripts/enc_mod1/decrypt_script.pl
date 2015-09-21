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
# - The variable "decrypted" is assigned the full path of the directory
# where decrypted files are stored
# - The "tmpEnc" and "tmpDec" directories are assigned the full paths of the
# the directories used to temporarily hold files during the encryption/
# decryption process.
# - The "keyFile" variable is assigned the full path of the file containing
# the key and initialisation vector (IV) used for decryption
my $url = $ARGV[1];
my $decrypted = $ARGV[2];
my $tmpEnc = $ARGV[3];
my $tmpDec = $ARGV[4];
my $keyFile = $ARGV[5];
my $key = "";
my $iv = "";
 
sub Decrypt
  {
	# This function should be modified, to suit the requirements
	# of the encryption application being used.
	#
	# It receives the url of the file to be decrypted, its name,
	# and the decryption key and IV.
	# We then specify the name(path) of the output file to be created 
	# after decryption, call the encryption 
	# application, and return the full path to the decrypted file.
	# Note that the decrypted file is placed in the tmpDec 
	# directory. It is later (after this function returns) copied
	# to the "decrypted" directory.
 	my $fileURL = $_[0];
 	my $fileName = $_[1];
	my $encKey = $_[2];
	my $encIV = $_[3];
 	my $file = "$tmpDec"."$fileName";
 	my $output = "$tmpDec"."$fileName";
 	$output =~ s/.enc//;

	copy($fileURL, $tmpDec);
 	`sisicrypt -d -f $file -k $encKey -i $encIV`;
	unlink $file;
 	return $output;
  }

sub Main 
  {
	# This script monitors the "encrypted" directory which holds 
	# ciphertext files.
	# When an encrypted file, received from, or being sent to, the 
	# VERFICATION container, lands in this directory, this script 
	# is triggered, and the url of the file is passed to this script.

	chomp($url);

	# we extract the file name from the url
	my $fname = fileparse($url);
	my $compareFile = $tmpEnc . $fname; 

	# We check if the file that triggered the script has a similar copy
	# in the tmpEnc directory. If a similar copy exists in the tmpEnc 
	# directory, it means that the file should not be decrypted, since 
	# it has just been encrypted.
	# When the "encrypt_script", in charge of encryption, encrypts a file,
	# it places a copy of the encrypted file in the tmpEnc 
	# directory, before copying the file to the "encrypted" directory.
	# This helps distinguish between the case where a file entering the 
	# "encrypted" directory(which triggers this script), is from the CSP and 
	# needs to be decrypted, or is from the user and has just been encrypted. 
	my $fileCheck = compare($url, $compareFile);  
  
	if ( $fileCheck == 0 )
	 {
		# if a similar copy of the file exists in the tmpEnc directory,
		# we delete the copy of the file in the tmpEnc directory, and exit.
		# There's nothing else to do.
		unlink $compareFile;
	 }
	else
	 { 
		# otherwise, we open the file containing the decryption key and IV,
		# extract the two values, and close the file.
		open(KEYFILE, "<$keyFile") || die("failed to open $keyFile\n");
		if ((read KEYFILE, $key, 16) != 16) {die("failed to read key\n")};
		if ((read KEYFILE, $iv, 16) != 16) {die("failed to read iv\n")};
		close(KEYFILE);

		# we then pass the url of the file to be decrypted, the filename, and
		# the decryption key and IV, to the Decrypt function.
		# The Decrypt function decrypts the file, then returns the full path
		# to the decrypted file.
		# The decrypted file is then copied to the "decrypted" directory, and this
		# script's work is done.
		my $outFile = Decrypt($url, $fname, $key, $iv);
		copy($outFile, $decrypted);
	 }
  }
  
Main();