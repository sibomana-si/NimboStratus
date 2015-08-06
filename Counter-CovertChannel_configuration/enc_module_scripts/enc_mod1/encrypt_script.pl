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
# where encrypted files are stored
# - The "tmpEnc" and "tmpDec" directories are assigned the full paths of the
# the directories used to temporarily hold files during the encryption/
# decryption process.
# - The "keyFile" variable is assigned the full path of the file containing
# the key, and initialisation vector (IV), used for encryption
my $url = $ARGV[1];
my $encrypted = $ARGV[2];
my $tmpEnc = $ARGV[3];
my $tmpDec = $ARGV[4];
my $keyFile = $ARGV[5];
my $key = "";
my $iv = "";

sub Encrypt
  {
	# This function should be modified, to suit the requirements
	# of the encryption application being used.
	#
	# It receives the url of the file to be encrypted, its name,
	# and the encryption key and IV.
	# We then specify the name(path + extension) of the output file
	# to be created after encryption, call the encryption 
	# application, and return the full path to the encrypted file.
	# Note that the encrypted file is placed in the tmpEnc 
	# directory. It is later (after this function returns) copied
	# to the encrypted directory.
 	my $fileURL = $_[0];
 	my $fileName = $_[1];
	my $encKey = $_[2];
	my $encIV = $_[3];
	my $ext = '.enc';
 	my $file = "$tmpEnc"."$fileName";
 	my $output = "$tmpEnc"."$fileName"."$ext";

	copy($fileURL, $tmpEnc);
	`sisicrypt -e -f $file -k $encKey -i $encIV`;
	unlink $file;
 	return $output;
  }
 
# This script monitors the "decrypted" directory via which, plaintext 
# files are exchanged with the INIT container.
# When a file, to be encrypted (received from the INIT container), or 
# which has just been decrypted (to be sent to the INIT container), 
# lands on this directory, this script is triggered, and the url of the 
# file is passed to this script.

chomp($url);

# we extract the file name from the url
my $fname = fileparse($url);
my $compareFile = $tmpDec . $fname;  

# We check if the file that triggered the script has a similar copy
# in the "tmpDec" directory. If a similar copy exists in the tmpDec 
# directory, it means that the file should not be encrypted, since 
# it has just been decrypted.
# When the "decrypt_script", in charge of decryption, decrypts a file,
# it places a copy of the decrypted plaintext file in the tmpDec 
# directory, before copying the file to the "decrypted" directory.
# This helps distinguish between the case where a file entering the "decrypted"
# directory(which triggers this script), is from the CSP and has just 
# been decrypted, or is from the user and needs to be encrypted before being 
# sent to the CSP.
my $fileCheck = compare($url, $compareFile);  

if ($fileCheck == 0)
  {
	# if a similar copy of the file exists in the tmpDec directory,
	# we delete the copy of the file in the tmpDec directory, and exit.
	# There's nothing else to do.
	unlink $compareFile;
  }
else
  {
	# otherwise, we open the file containing the encryption key and IV,
	# extract the two values, and close the file.
	open(KEYFILE, "<$keyFile") || die("failed to open $keyFile\n");
	if ((read KEYFILE, $key, 16) != 16) {die("failed to read key\n")};
	if ((read KEYFILE, $iv, 16) != 16) {die("failed to read iv\n")};
	close(KEYFILE);

	# we then pass the url of the file to be encrypted, the filename, and
	# the encryption key and IV, to the encryption function.
	# The encryption function encrypts the file, then returns the full path
	# to the encrypted file.
	# The encrypted file is then copied to the encrypted directory, and this
	# script's work is done.
	my $outFile = Encrypt($url, $fname, $key, $iv); 
 	copy($outFile, $encrypted);
  }