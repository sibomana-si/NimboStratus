/* This document serves as a short tutorial to setting up the
 * Counter-CovertChannels configuration for use.
 * It assumes that you have decided to use Dropbox as your Cloud 
 * Storage Provider.
 * We also assume that you're setting up this configuration on a 
 * linux machine.
 * This configuration requires the use of two different encryption 
 * applications that encrypt deterministically, i.e. given the same
 * input file, encryption key, and initialization vector, the two
 * encryption applications produce the same ciphertext.
 * You can either search for, and download, two encryption applications
 * that achieve this, or build your encryption applications. We have
 * provided wrapper code (in the enc_wrapper directory), to facilitate
 * building your own encryption applications using standard crypto-
 * graphic libraries.
 * Remember to modify the scripts, encrypt_script.pl and 
 * decrypt_script.pl, in the directories enc_mod1 and enc_mod2.
 * Specifically, the lines in the Encrypt function (Sub Encrypt) and 
 * Decrypt function (Sub Decrypt), that specify the syntax of the 
 * encryption application.
 */

/* STEP 1:
 * Begin by creating a directory for the files required for this 
 * configuration.
 */

	$ mkdir /tmp/counter-covchannels_config_files
	$ cd /tmp/counter-covchannels_config_files

/* STEP 2:
 * Then copy the files which we have provided 
 * (counter-covertchannels_config.sh, and the directories 
 * init_module_scripts, ver_module_scripts, and enc_module_scripts)
 * into this directory.
 * Also copy the encryption applications that you are using into
 * this directory.
 */

	$ cp <PATH TO DIRECTORY WHERE SCRIPTS ARE LOCATED>/* /tmp/counter-covchannels_config_files/
	$ cp <PATH TO DIRECTORY WHERE ENCRYPTION APPLICATIONS ARE LOCATED>/* /tmp/counter-covchannels_config_files/
	
 
/* STEP 3:
 * Run the configuration setup script 
 */

	$ ./counter-covertchannels_config.sh

	
/* STEP 4:
 * Check that five docker containers (automated-init_module, 
 * automated-enc_module, automated-enc_module2, automated-ver_module,
 * and automated-csp_module) have been created, and are running.
 */
 
	$ docker ps

/* STEP 5:
 * Transfer the init_module scripts (in-out_transfer.pl,
 * out-in_transfer.pl, and out-in_transfer2.pl) to the scripts
 * directory in the automated-init_module container.
 */
 
	$ cp init_module_scripts/*   ~/framework_space/plain_dir/

	$ docker start -i -a automated-init_module
	
	<If you don't immediately get the command prompt, press the ENTER key>
	
	# mv /decrypted/* /scripts/
	# exit
	

	
/* STEP 6:
 * Transfer the ver_module scripts (in-out_transfer.pl,
 * out-in_transfer.pl, and out-in_transfer2.pl) to the scripts
 * directory in the automated-ver_module container.
 */
 
	$ cp ver_module_scripts/*   ~/framework_space/enc1-ver_dir/
	
	$ docker start -i -a automated-ver_module
	
	<If you don't immediately get the command prompt, press the ENTER key>
	
	# mv encrypted/* scripts/
	# exit

 
/* STEP 7:
 * Transfer the encryption applications, and encrypt/decrypt scripts into the
 * encryption containers (automated-enc_module and automated-enc_module2)
 */

	$ cp <PATH_TO_ENCRYPTION_APPLICATION1>  enc_module_scripts/enc_mod1/*   ~/framework_space/init-enc1_dir/
	$ cp <PATH_TO_ENCRYPTION_APPLICATION2>  enc_module_scripts/enc_mod2/*   ~/framework_space/init-enc2_dir/

	
/* STEP 8:
 * access the first encryption container 
 */

	$ docker start -i -a automated-enc_module

 <If you don't immediately get the command prompt, press the ENTER key>


/* STEP 9:
 * Transfer the encryption/decryption scripts to the scripts directory 
 * in this container.
 */
 
	# mv /decrypted/encrypt_script.pl /scripts/
	# mv /decrypted/decrypt_script.pl /scripts/


/* STEP 10:
 * Transfer the encryption application to the tmp directory 
 */

	# mv /decrypted/<ENCRYPTION APPLICATION1> /tmp/


/* STEP 11:
 * Install the encryption application. 
 */


/* STEP 12:
 * Download the keyfile, which contains the encryption key and IV (randomly generated)
 * that will be used by encryption application 1 for encryption/
 * decryption. This step assumes that you are going to setup this configuration on 
 * multiple devices, each synced to the same Dropbox account.
 * Since each time the setup script (counter-covertchannels_config.sh) is run on a new machine,
 * a different "keyfile" file will be generated, and we need all the machines to 
 * use the same keyfile for encryption/decryption, the user will have to copy the 
 * file "keyfile" from one of the machines and securely transfer it to the scripts
 * directory of the automated-enc_module container in the other machines that are
 * running this configuration.
 */ 

	# cp /scripts/keyfile /decrypted/

	
/* STEP 13:
 * Exit the encryption container.
 */

	# exit

	
/* STEP 14:
 * Move keyfile to the counter-covchannels_config_files directory (and immediately transfer it 
 * to the other machines that the user wants to keep in sync.)
 * Make sure to delete it afterwards, so there's no copy of it in an unsecure location.
 */
 
	$ mv ~/framework_space/init-enc1_dir/keyfile /tmp/counter-covchannels_config_files/enc_mod1_keyfile


/* STEP 15:
 * access the second encryption container 
 */

	$ docker start -i -a automated-enc_module2

 <If you don't immediately get the command prompt, press the ENTER key>


/* STEP 16:
 * Transfer the encryption/decryption scripts to the scripts directory 
 * in this container.
 */
 
	# mv /decrypted/encrypt_script.pl /scripts/
	# mv /decrypted/decrypt_script.pl /scripts/


/* STEP 17:
 * Transfer the encryption application to the tmp directory 
 */

	# mv /decrypted/<ENCRYPTION APPLICATION2> /tmp/


/* STEP 18:
 * Install the encryption application 
 */

	
/* STEP 19:
 * Download the keyfile generated for this container (This assumes you are setting up
 * this configuration on several machines, that will be synced to the same Dropbox
 * account.
 */ 

	# cp /scripts/keyfile /decrypted/


/* STEP 20:
 * Exit the encryption container.
 */

	# exit

	
/* STEP 21:
 * Move keyfile to the counter-covchannels_config_files directory (and immediately 
 * transfer it to the other machines that the user wants to keep in sync.)
 * Make sure to delete it afterwards, so there's no copy of it in an unsecure location.
 */
 
	$ mv ~/framework_space/init-enc2_dir/keyfile /tmp/counter-covchannels_config_files/enc_mod2_keyfile

	
/* STEP 22:
 * Access the CSP container.
 */

	$ docker start -i -a automated-csp_module

	<If you don't immediately get the command prompt, press the ENTER key>
	
	 
/* STEP 23:
 * Install the Dropbox client application.
 */

	# apt-get install wget
	# wget -O - "https://www.dropbox.com/download?plat=lnx.x86_64" | tar xzf -
	# .dropbox-dist/dropboxd
	

/* STEP 24:
 * At this point you are required to copy a link generated by the Dropbox client,
 * to your browser, and to log in to your dropbox account.
 * Once you have completed the login step, the Dropbox installation is complete, and
 * starts synchronizing the Dropbox folder on your machine with your Dropbox account.
 */
 

/* STEP 25:
 * Stop the Dropbox client 
 */
 
	<CTRL-C (simultaneously press the Ctrl and C buttons to stop the dropbox client)>

	
/* STEP 26:
 * Create a symbolic link in the Dropbox directory, that points to
 * the directory "/csp" in this container. Then exit the container.
 */
 
	# ln -s /csp/ /Dropbox/  
	# exit

	
/* STEP 27:
 * Restart the three containers(automated-enc_module, automated-enc_module2,
 * and automated-csp_module) in the background.
 */

	$ docker start automated-enc_module
	$ docker start automated-enc_module2
	$ docker start automated-csp_module

	
/* STEP 28:
 * Start the incron filesystem monitoring tool, in the init, verification, and
 * encryption containers. 
 */

	$ docker exec automated-init_module incrond
	$ docker exec automated-ver_module incrond
	$ docker exec automated-enc_module incrond
	$ docker exec automated-enc_module2 incrond

	
/* STEP 29:
 * Start the Dropbox client 
 */
	
	$ docker exec automated-csp_module .dropbox-dist/dropboxd

/* You will again be required to authenticate yourself to your
 * Dropbox account, by copying a link generated by the Dropbox client,
 * to your browser, and logging in to the Dropbox account.
 * Once you have completed the login step, enter CTRL - C on the keyboard
 * to get back the command prompt. 
 * At this point you are ready to start syncing files to
 * your dropbox account, by sending/retrieving files to/from
 * the directory 
 * <PATH TO USER'S HOME_DIRECTORY>/framework_space/plain_dir/
 */
 
 
/* USING MULTIPLE MACHINES TO SYNC DATA */ 
 
/* If you are setting up this configuration on two or more machines that 
 * you would like to keep synced with your csp (dropbox) account, the
 * setup procedure on machine 2, 3, ..., is the same as above, 
 * with the following exceptions:
 *
 * - In STEP 2, in addition to copying the scripts, also copy the two
 *	 files, enc_mod1_keyfile, and enc_mod2_keyfile (obtained from the 
 *   configuration setup on the first machine), 
 *   to the directory /tmp/counter-covchannels_config_files/
 *
 * - In STEP 7, in addition to copying the scripts, also copy the
 *   the "keyfile" files retrieved from the first machine. i.e.
 * 	
 *		$ cp enc_mod1_keyfile  ~/framework_space/init-enc1_dir/keyfile
 *  	$ cp enc_mod2_keyfile  ~/framework_space/init-enc2_dir/keyfile
 *
 *
 * - In STEP 9 and STEP 16, in addition to the scripts, move the file "keyfile" 
 *   to the scripts directory:
 *
 *  	$ mv /decrypted/keyfile /scripts/
 * 
 * - SKIP STEP 12, 14, 19 and 21.
 */