#! /bin/bash

# The USER_DIR directory is created on the user's filesystem,
# and mounted onto the ENC_MODULE docker container (with read
# and write permissions). This is the directory through which
# the user updates (plaintext) files to be synced to the cloud,
# and receives updated (plaintext) files from the cloud.
#
# The ENC_CSP_INTERFACE directory is also created on the user's
# filesystem, and is mounted onto the ENC_MODULE and CSP_MODULE
# docker containers (with read and write permissions).
# This is the directory through which the two docker containers
# exchange encrypted files.
#
# These (USER_DIR and ENC_CSP_INTERFACE) are the only two 
# directories, on the user's filesystem, that applications 
# running within the docker containers are allowed to access.

BASE_DIR=~/framework_space
USER_DIR=${BASE_DIR}/plain_dir
ENC_CSP_INTERFACE=${BASE_DIR}/enc-csp_dir

# DECRYPTED_DIR is the name given to the USER_DIR directory, within
# the ENC_MODULE container. It is where the user's plaintext files
# are placed, before being encrypted and sent to the CSP, or after
# being received from the CSP, and decrypted.
# ENCRYPTED_DIR is the name given to the ENC_CSP_INTERFACE directory,
# within the ENC_MODULE container. It is where the user's ciphertext 
# files are placed, after being encrypted.
# The TMP_ENC_DIR and TMP_DEC_DIR directories, are used to 
# temporarily hold the files that are being encrypted/decrypted.
# The SCRIPTS_DIR directory is where the scripts that coordinate 
# the encryption/decryption process are located.
#
# All of these directories are created in the ENC_MODULE container,
# and, (apart from the DECRYPTED_DIR and ENCRYPTED_DIR directories, 
# which are shared) can only be accessed by applications running in 
# this container.
DECRYPTED_DIR=/decrypted/
ENCRYPTED_DIR=/encrypted/
TMP_ENC_DIR=/enc_int/
TMP_DEC_DIR=/dec_int/
SCRIPTS_DIR=/scripts/
ENC_MODULE="automated-enc_module"
IMAGE="framework:enc_module"

# CSP_DIR is the name given to the ENC_CSP_INTERFACE directory,
# within the CSP_MODULE container. This is the directory (shared with
# the ENC_MODULE container) which the CSP client monitors, and syncs with 
# the CSP infrastructure.
# Note that the CSP client application running in the CSP_MODULE container
# has access only to the ENC_CSP_INTERFACE directory on the user's file
# system.
CSP_DIR=/csp/
CSP_MODULE="automated-csp_module"


Enc_Image_Setup () 
  {
	# This line creates a docker container (with ubuntu as the 
	#operating system), running in the background (-d), with a 
	# pseudo terminal attached (-t), and the capability to receive
	# input from the keyboard (-i)
	docker run -d -i -t --name="ENC_IMAGE" ubuntu
	
	# The following line runs a shell in the created docker container, 
	# and executes commands to:
	# - create the temp directories used during the encryption/
	#   decryption process, as well as the directory for holding the 
	#   scripts
	#
	# - update the list of Ubuntu repository packages ("apt-get update"),
	#   which is used when installing packages from the Ubuntu repositories
	#   via the apt-get install <package> command. 
	#   The command "apt-get update" doesn't install anything in the container.
	#   Here, we are trusting that when this command is executed, a connection is
	#   established to the Ubuntu repositories, and the list of packages, with
	#   the correct signature for each package, is retrieved from the repository
	#
	# - install the build-essential package from Ubuntu's repository 
	#   ("apt-get -y install build-essential"), that 
	#   is  needed for building applications from source. We need this package to 
    #   build the encryption application.
	# 	This package consists of references to packages needed for building 
	#   software on Ubuntu, including compilers (gcc and g++), GNU C library, and 
	#   the MAKE utility
	#
	#   NOTE: If any of these packages is malicious, then it has access to the
	#   user's unencrypted files, and may be able to access the user's 
	#   crypto key.
	#   Since we are assuming non-collusion for this configuration, this 
	#   isn't an issue. The encryption container has no network access, 
	#   and these packages are not installed in the CSP client container.
	#   Thus there's no way to leak the user's data/crypto key.
	# 
	# - install the incron filesystem monitoring utility ("apt-get install incron")
	#
	#   NOTE: This is a third party application, that has access to the user's 
	#   unencrypted files, and also may be able to access the user's crypto key.
	#   However, since the encryption container has no network access, and this 
	#   application isn't installed in the CSP client container, even if
	#   this application is malicious, it has no way to leak the user's data
	#   under this configuration.
	#
	# - enable the "root" user to use incron within the container 
	#   ("echo 'root' > /etc/incron.allow")
	# - create the filesystem monitoring rules for incron, and save them 
	#   (in /var/spool/incron/root)
	# The rules specify which directory to monitor (e.g. $DECRYPTED_DIR), 
	# which event to monitor for (e.g. IN_CLOSE_WRITE), and what action to 
	# take (e.g. $SCRIPTS_DIR/encrypt_script.pl $% $'@'$'#' \
	# $ENCRYPTED_DIR $TMP_ENC_DIR $TMP_DEC_DIR $SCRIPTS_DIR/keyfile' -- this
    # calls the "encrypt_script" (which we provide, and the user can audit), 
	# and passes it the name of the event {$%} that triggered incron, 
	# the url {$@$#} of the file that triggered incron, the names of the
	# directories used during the encryption/decryption process, 
	# as well as the url of the keyfile containing the encryption key/password).
	docker exec ENC_IMAGE sh -c "mkdir $TMP_ENC_DIR $TMP_DEC_DIR $SCRIPTS_DIR; apt-get update; apt-get -y install build-essential; \
	apt-get install incron; \
	echo 'root' > /etc/incron.allow; \
	echo '$DECRYPTED_DIR IN_CLOSE_WRITE $SCRIPTS_DIR/encrypt_script.pl $% $'@'$'#' \
$ENCRYPTED_DIR $TMP_ENC_DIR $TMP_DEC_DIR $SCRIPTS_DIR/keyfile' >> /var/spool/incron/root; \
	echo '$ENCRYPTED_DIR IN_CLOSE_WRITE $SCRIPTS_DIR/decrypt_script.pl $% $'@'$'#' \
$DECRYPTED_DIR $TMP_ENC_DIR $TMP_DEC_DIR $SCRIPTS_DIR/keyfile' >> /var/spool/incron/root"
	
	# The following three lines, stop the ENC_IMAGE container, save 
	# its image, and then delete the container.
	#
	# NOTE: We required network access to download and install the components 
	# to build the encryption application, however our security
	# requirements are that the encryption container should have no network access.
	# We therefore delete this container which was built with network access,
	# and then later (in the Enc_Mod_Setup function) use the saved image 
	#(which has the libraries/tools require to build the encryption application) 
	# to create an encryption container that has no network access.
	docker stop ENC_IMAGE 
	docker commit ENC_IMAGE $IMAGE
	docker rm ENC_IMAGE
  }

Enc_Mod_Setup ()
  {
	# This line creates the encryption container, from the previously saved image,
	# with the two interface directories, USER_DIR and ENC-CSP_INTERFACE mounted 
	# in the container (-v), and with no network access (--net=none).
	docker run -d -i -t --net=none -v $1:$DECRYPTED_DIR -v $2:$ENCRYPTED_DIR --name=$3 $IMAGE
	
	# The following line runs a shell in the created encryption container, and executes commands to:
	# - generate a file containing random data ("dd if=/dev/urandom of=$SCRIPTS_DIR/keyfile.data bs=1024 count=100")
	# - generate a hash of the "random data" file, and store the hash value in a separate file 
	# ("md5sum $SCRIPTS_DIR/keyfile.data | cut -d ' ' -f1 > $SCRIPTS_DIR/keyfile")
	# we use this hash value as the password/key for encryption/decryption, depending on the 
	# requirements of the encryption application selected by the user.
	#
	# NOTE: This 32 byte password/key, is generated randomly each time this configuration setup script 
	# is run (making it very hard to guess), and is used by default for encryption/decryption.
	# The user can modify this value, at any time, by editing the "keyfile" file, located in the scripts
	# directory. The goal is to generate a default password/key for the user that is hard to guess, and can 
	# be easily customized by the user. 
	# In order to share files with multiple devices, each running this configuration, the user will need to 
	# ensure that each encryption container has the same copy of the "keyfile". Thus the user needs to find
	# a way to securely transfer one of the "keyfile" copies to the encryption containers on the other devices.
	docker exec $3 sh -c "dd if=/dev/urandom of=$SCRIPTS_DIR/keyfile.data bs=1024 count=100; \
	md5sum $SCRIPTS_DIR/keyfile.data | cut -d ' ' -f1 > $SCRIPTS_DIR/keyfile"
  }

CSP_Mod_Setup ()
  {
	# This line creates the CSP client container,  with the "ENC-CSP_INTERFACE" 
	# directory mounted in the container.
	# This container has network access enabled, so that the CSP client can 
	# communicate with the CSP servers.
	docker run -d -i -t -v $1:$CSP_DIR --name=$2 ubuntu
	docker exec $2 apt-get update
  }

# We start by creating the "Base" directory, and the two shared
# directories.
mkdir ${BASE_DIR} ${USER_DIR} ${ENC_CSP_INTERFACE} 

# We then create, and save, a template for the Encryption container to be
# built.
Enc_Image_Setup

# We then build the Encryption container, with no network access.
# The Enc_Mod_Setup function takes in 3 parameters:
# - 2 names of the interface directories through which 
# the encryption container receives data to be encrypted, and delivers 
# encrypted data.
# - 1 name of the encryption container
Enc_Mod_Setup ${USER_DIR} ${ENC_CSP_INTERFACE} ${ENC_MODULE}

# Finally, we build the CSP client container.
# The CSP_Mod_Setup function takes in 2 parameters:
# - 1 name of the interface directory through which 
# the CSP module receives data from, or to be synced to, the CSP
# - 1 name of the CSP module container
CSP_Mod_Setup ${ENC_CSP_INTERFACE} ${CSP_MODULE}