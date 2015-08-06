#! /bin/bash

# NOTE: The applications running in each of the five containers, INIT_MODULE,
# ENC_MODULE, ENC_MODULE2, VERIFICATION_MODULE, and the CSP_MODULE, can only access
# the directories(and files)in their respective containers. Apart from being 
# able to access (read and write) the directories, USER_DIR, INIT_ENC1_INTERFACE, 
# INIT_ENC2_INTERFACE, ENC1_VER_INTERFACE, ENC2_VER_INTERFACE, and VER_CSP_INTERFACE,
# that are mounted from the user's filesystem, the applications running in each of 
# these containers have no access to any other part of the user's filesystem. 
BASE_DIR=~/framework_space
USER_DIR=${BASE_DIR}/plain_dir
INIT_ENC1_INTERFACE=${BASE_DIR}/init-enc1_dir
INIT_ENC2_INTERFACE=${BASE_DIR}/init-enc2_dir
ENC1_VER_INTERFACE=${BASE_DIR}/enc1-ver_dir
ENC2_VER_INTERFACE=${BASE_DIR}/enc2-ver_dir
VER_CSP_INTERFACE=${BASE_DIR}/ver-csp_dir

ENC_MODULE="automated-enc_module"
ENC_MODULE2="automated-enc_module2"
CSP_MODULE="automated-csp_module"
VERIFICATION_MODULE="automated-ver_module"
INIT_MODULE="automated-init_module"
ENC_IMAGE="framework:enc_module"
AUX_IMAGE="framework:aux_module"

DECRYPTED_DIR=/decrypted/
ENCRYPTED_DIR=/encrypted/
ENCRYPTED_DIR2=/encrypted2/
TMP_ENC_DIR=/enc_int/
TMP_DEC_DIR=/dec_int/
SCRIPTS_DIR=/scripts/
CSP_DIR=/csp/

Enc_Image_Setup () 
  {
	# This line creates a docker container (with ubuntu as the 
	# operating system), running in the background (-d), with a 
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
	#   NOTE: We assume that these packages are not malicious, since they are 
	#   obtained from the Ubuntu repository, and we are trusting our operating system,
	#   and by extension the OS provider.
	#   However, even if any of these packages is malicious, and it colludes with the
	#   CSP client (under this configuration, we assume some malicious components
	#   may collude), it would only be able to leak the user's data, or cryptographic 
	#   keys via some covert channel that isn't addressed by our design. Because, though
	#   these packages are installed in each of the encryption containers, and thus
	#   would be able to access the user's unencrypted data, as well as cryptographic
	#   keys, they are not installed in the Verification container.
	# 
	# - install the incron filesystem monitoring utility ("apt-get install incron")
	#
	#   NOTE: This is a third party application, that has access to the user's 
	#   unencrypted files, and also may be able to access the user's crypto keys.
	#   Under this configuration, we assume some malicious components
	#   may collude,  therefore if this filesystem monitoring tool is malicious,
	#   and colludes with the CSP client application, it would be able to leak the
	#   the user's data, or cryptographic keys.
	#   We assume that this application is trusted not to collude with the CSP client
	#   client application.
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
	#
	# For this configuration, we require the two encryption applications to use
	# the same key and initialization vector when encrypting the user's files, so 
	# that we can verify that the resulting ciphertext is the same.
	# We therefore generate the key and IV at this level, and store the values
	# in the file "keyfile". This is achieved with the following commands:
	# dd if=/dev/urandom of=$SCRIPTS_DIR/keyfile.data bs=1024 count=100; \
	# md5sum $SCRIPTS_DIR/keyfile.data | cut -d ' ' -f1 > $SCRIPTS_DIR/keyfile
	# 
	# The value stored in the "keyfile" is a 32 byte string, from which a 16 byte
	# key and a 16 byte IV are extracted, by the scripts (encrypt_script.pl and 
	# decrypt_script.pl) in the encryption containers, and then passed to the 
	# encryption application during encryption/decryption.
	# A new value is generated randomly each time this configuration script is run,
	# and the user can also edit the keyfile, to manually change/update this value.
	# Our goal here is to generate a default key/IV, that is hard to guesss and that can 
	# be used by the user for encryption/decryption of files, as well as give the user
	# the flexibility to change the key/IV values whenever he/she wants to.
	# 
	# So when the Enc_Mod_Setup() function is called to create the encryption
	# containers from this image, they will both have the same keyfile copy in the 
	# SCRIPTS_DIR.
	# In order to share files with multiple devices, each running this configuration, 
	# the user will need to securely transfer one of the "keyfile" copies from an 
	# encryption container, to the encryption containers created on the other devices.
	docker exec ENC_IMAGE sh -c "mkdir $TMP_ENC_DIR $TMP_DEC_DIR $SCRIPTS_DIR; apt-get update; apt-get -y install build-essential; \
	apt-get install incron; \
	echo 'root' > /etc/incron.allow; \
	echo '$DECRYPTED_DIR IN_CLOSE_WRITE $SCRIPTS_DIR/encrypt_script.pl $% $'@'$'#' \
$ENCRYPTED_DIR $TMP_ENC_DIR $TMP_DEC_DIR $SCRIPTS_DIR/keyfile' >> /var/spool/incron/root; \
	echo '$ENCRYPTED_DIR IN_CLOSE_WRITE $SCRIPTS_DIR/decrypt_script.pl $% $'@'$'#' \
$DECRYPTED_DIR $TMP_ENC_DIR $TMP_DEC_DIR $SCRIPTS_DIR/keyfile' >> /var/spool/incron/root; \
	dd if=/dev/urandom of=$SCRIPTS_DIR/keyfile.data bs=1024 count=100; \
	md5sum $SCRIPTS_DIR/keyfile.data | cut -d ' ' -f1 > $SCRIPTS_DIR/keyfile"

	# The following three lines, stop the ENC_IMAGE container,
	# save its image, and then delete the container.
	#
	# NOTE: We required network access to download and install the components 
	# to build the encryption application, however our security
	# requirements are that the encryption container should have no network access.
	# We therefore delete this container which was built with network access,
	# and then later (in the Enc_Mod_Setup function) use the saved image 
	#(which has the libraries/tools require to build the encryption application) 
	# to create an encryption container that has no network access.
	docker stop ENC_IMAGE
	docker commit ENC_IMAGE $1
	docker rm ENC_IMAGE
  }

Aux_Image_Setup ()
  {
	# This function builds, and saves the image from which
	# we create the INIT_MODULE, and VERIFICATION_MODULE
	# containers, which have a similar structure.
	docker run -d -i -t --name="AUX_IMAGE" ubuntu
	
	docker exec AUX_IMAGE sh -c "mkdir $SCRIPTS_DIR; apt-get update; apt-get install incron; \
	echo 'root' > /etc/incron.allow; \
	echo '$DECRYPTED_DIR IN_CLOSE_WRITE $SCRIPTS_DIR/in-out_transfer.pl $% $'@'$'#' \
$ENCRYPTED_DIR $ENCRYPTED_DIR2' >> /var/spool/incron/root; \
	echo '$ENCRYPTED_DIR IN_CLOSE_WRITE $SCRIPTS_DIR/out-in_transfer.pl $% $'@'$'#' \
$ENCRYPTED_DIR2 $DECRYPTED_DIR' >> /var/spool/incron/root; \
	echo '$ENCRYPTED_DIR2 IN_CLOSE_WRITE $SCRIPTS_DIR/out-in_transfer2.pl $% $'@'$'#' \
$ENCRYPTED_DIR $DECRYPTED_DIR' >> /var/spool/incron/root"
	
	# The following three lines, stop the AUX_IMAGE container,
	# save its image, and then delete the container.
	#
	# NOTE: We required network access to setup the incron utility, however,
	# there is no other reason for the INIT_MODULE and VERIFICATION_MODULE containers
	# to have networks access. 
	# We therefore delete this container which was built with network access,
	# and then later (in the Aux_Mod_Setup function) use the saved image 
	# to create the container we need, with network access disabled.
	docker stop AUX_IMAGE 
	docker commit AUX_IMAGE $1
	docker rm AUX_IMAGE
  }

Enc_Mod_Setup ()
  {
	# This line creates the encryption container, from the previously saved image,
	# with the two interface directories, specified by the user, mounted 
	# in the container (-v), and with no network access (--net=none).
	docker run -d -i -t --net=none -v $1:$DECRYPTED_DIR -v $2:$ENCRYPTED_DIR --name=$3 $4
  }

CSP_Mod_Setup ()
  {
    # This line creates the CSP client container, with network access enabled, so 
	# that the CSP client can communicate with the CSP servers.
	docker run -d -i -t -v $1:$CSP_DIR --name=$2 ubuntu
	docker exec $2 apt-get update
  }

Aux_Mod_Setup ()
  {
	# This function is used to create the INIT and VERIFICATION containers,
	# with network access disabled
	docker run -d -i -t --net=none -v $1:$DECRYPTED_DIR -v $2:$ENCRYPTED_DIR -v $3:$ENCRYPTED_DIR2 --name=$4 $5
  }

# We start by creating the "Base" directory, and the six 
# shared directories.
mkdir ${BASE_DIR} ${USER_DIR} ${INIT_ENC1_INTERFACE} ${INIT_ENC2_INTERFACE} ${ENC1_VER_INTERFACE} ${ENC2_VER_INTERFACE} ${VER_CSP_INTERFACE}

# We create, and save, a template for the Encryption 
# application containers to be built.
Enc_Image_Setup ${ENC_IMAGE}

# We create, and save, a template for the INIT and
# VERFIFCATION containers to be built.
Aux_Image_Setup ${AUX_IMAGE}

# We build the INIT_MODULE container, with network acces disabled
# The Aux_Mod_Setup function takes in 5 parameters:
# - the names of the 3 interface directories through which 
# the INIT container interfaces with the user (USER_DIR)
# and with the two encryption containers (INIT_ENC1_INTERFACE 
# and INIT_ENC2_INTERFACE)
# - the name of the container
# - the name of the image used to build the INIT container
Aux_Mod_Setup ${USER_DIR} ${INIT_ENC1_INTERFACE} ${INIT_ENC2_INTERFACE} ${INIT_MODULE} ${AUX_IMAGE}

# We build the two Encryption containers, with no network 
# access.
# The Enc_Mod_Setup function takes in 4 parameters:
# - the names of the 2 interface directories through which 
# the encryption container receives data to be encrypted, and 
# delivers encrypted data.
# - the name of the container
# - the name of the image used to build the encryption container
Enc_Mod_Setup ${INIT_ENC1_INTERFACE} ${ENC1_VER_INTERFACE} ${ENC_MODULE} ${ENC_IMAGE}
Enc_Mod_Setup ${INIT_ENC2_INTERFACE} ${ENC2_VER_INTERFACE} ${ENC_MODULE2} ${ENC_IMAGE}

# We build the VERIFICATION_MODULE container, also with network access disabled
# The Aux_Mod_Setup function takes in 5 parameters:
# - the names of the 3 interface directories through which 
# the  container interfaces with the CSP client container
# (VER_CSP_INTERFACE), and with the two encryption 
# containers (ENC1_VER_INTERFACE and ENC2_VER_INTERFACE)
# - the name of the container
# - the name of the image used to build the VERFICATION container
Aux_Mod_Setup ${VER_CSP_INTERFACE} ${ENC1_VER_INTERFACE} ${ENC2_VER_INTERFACE} ${VERIFICATION_MODULE} ${AUX_IMAGE}

# Finally, we build the CSP module.
# The CSP_Mod_Setup function takes in 2 parameters:
# - the name of the interface directory through which 
# the CSP client container receives data from, or to be 
# synced to, the CSP
# - the name of the CSP client container
CSP_Mod_Setup ${VER_CSP_INTERFACE} ${CSP_MODULE}