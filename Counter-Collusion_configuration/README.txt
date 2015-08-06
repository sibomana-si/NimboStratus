/* This document serves as a short tutorial to setting up the
 * Counter-Collusion configuration for use.
 * It assumes that you have decided to use Dropbox as your Cloud 
 * Storage Provider, and aescrypt and ccrypt as the two encryption 
 * applications.
 * If you decide to use a different encryption application/
 * CSP, the steps regarding the installation of the encryption 
 * application/ CSP client may be different.
 * Also if you decide to use a different encryption application
 * you will need to modify the scripts, encrypt_script.pl and 
 * decrypt_script.pl, in the appropriate encryption container.
 * Specifically, the lines in the Encrypt function (Sub Encrypt) and 
 * Decrypt function (Sub Decrypt), that specify the syntax of the 
 * encryption function.
 * We also assume that you're setting up this configuration on a linux 
 * machine.
 */

/* STEP 1:
 * Begin by creating a directory for the files required for this 
 * configuration.
 */

	$ mkdir /tmp/counter-collusion_config_files
	$ cd /tmp/counter-collusion_config_files

/* STEP 2:
 * Then copy the files which we have provided (counter-collusion_config.sh,
 * and the directories enc_mod1 and enc_mod2) into this directory.
 * Also download the aescrypt encryption application 
 * (https://www.aescrypt.com/download/v3/linux/aescrypt-3.10.tgz),  
 * and the ccrypt encryption application 
 * (http://ccrypt.sourceforge.net/download/ccrypt-1.10.linux-x86_64.tar.gz)
 * into this directory.
 */

	$ cp <PATH TO DIRECTORY WHERE SCRIPTS ARE SAVED>/* /tmp/split-trust_config_files/
	$ wget https://www.aescrypt.com/download/v3/linux/aescrypt-3.10.tgz
	$ wget http://ccrypt.sourceforge.net/download/ccrypt-1.10.linux-x86_64.tar.gz
 
 
/* STEP 3:
 * Run the configuration setup script 
 */

	$ ./counter-collusion_config.sh

	
/* STEP 4:
 * Check that the three docker containers (automated-enc_module, automated-enc_module2,
 * and automated-csp_module) have been created and are running.
 */
 
	$ docker ps

	
/* STEP 5:
 * Transfer the encryption applications, and encrypt/decrypt scripts into the
 * encryption containers (automated-enc_module and automated-enc_module2)
 */

	$ cp aescrypt-3.10.tgz  enc_mod1/*   ~/framework_space/plain_dir/
	$ cp ccrypt-1.10.linux-x86_64.tar.gz  enc_mod2/*   ~/framework_space/enc1-enc2_dir/

	
/* STEP 6:
 * access the first encryption container 
 */

	$ docker start -i -a automated-enc_module

 < If you don't immediately get the command prompt, press the ENTER key>


/* STEP 7:
 * Transfer the encryption/decryption scripts to the scripts directory 
 * in this container.
 */
 
	# mv /decrypted/encrypt_script.pl /scripts/
	# mv /decrypted/decrypt_script.pl /scripts/


/* STEP 8:
 * Transfer the encryption application to the tmp directory 
 */

	# mv /decrypted/aescrypt-3.10.tgz /tmp/


/* STEP 9:
 * Install encryption application 
 */

	# tar -xzf aescrypt-3.10.tgz
	# cd aescrypt-3.10/src/
	# make
	# make install

/* STEP 10:
 * Download the keyfile, which contains the default password (randomly generated)
 * that will be used by the encryption application (aescrypt) for encryption/
 * decryption. This step assumes that you are going to setup this configuration on 
 * multiple devices, each synced to the same Dropbox account.
 * Since each time the setup script (counter-collusion_config.sh) is run on a new machine,
 * a different "keyfile" file will be generated, and we need all the machines to 
 * use the same keyfile for encryption/decryption, the user will have to copy the 
 * file "keyfile" from one of the machines and securely transfer it to the scripts
 * directory of the automated-enc_module container in the other machines that are
 * running this configuration.
 */ 

	# cp /scripts/keyfile /decrypted/

	
/* STEP 11:
 * Exit the encryption container.
 */

	# exit

	
/* STEP 12:
 * Move keyfile to the counter-collusion_config_files directory (and immediately transfer it 
 * to the other machines that the user wants to keep in sync.)
 * Make sure to delete it afterwards, so there's no copy of it in an unsecure location.
 */
 
	$ mv ~/framework_space/plain_dir/keyfile /tmp/counter-collusion_config_files/enc_mod1_keyfile


/* STEP 13:
 * access the second encryption container 
 */

	$ docker start -i -a automated-enc_module2

 < If you don't immediately get the command prompt, press the ENTER key>


/* STEP 14:
 * Transfer the encryption/decryption scripts to the scripts directory 
 * in this container.
 */
 
	# mv /decrypted/encrypt_script.pl /scripts/
	# mv /decrypted/decrypt_script.pl /scripts/


/* STEP 15:
 * Transfer the encryption application to the tmp directory 
 */

	# mv /decrypted/ccrypt-1.10.linux-x86_64.tar.gz /tmp/


/* STEP 16:
 * Install encryption application 
 */

	# tar -xzf ccrypt-1.10.linux-x86_64.tar.gz
	# cd ccrypt-1.10/
	# ./configure
	# make
	# make install

	
/* STEP 17:
 * Download the keyfile generated for this container (This assumes you are setting up
 * this configuration on several machines, that will be synced to the same Dropbox
 * account.
 */ 

	# cp /scripts/keyfile /decrypted/


/* STEP 18:
 * Exit the encryption container.
 */

	# exit

	
/* STEP 19:
 * Move keyfile to the counter-collusion_config_files directory (and immediately 
 * transfer it to the other machines that the user wants to keep in sync.)
 * Make sure to delete it afterwards, so there's no copy of it in an unsecure location.
 */
 
	$ mv ~/framework_space/enc1-enc2_dir/keyfile /tmp/counter-collusion_config_files/enc_mod2_keyfile

	
/* STEP 20:
 * Access the CSP container.
 */

	$ docker start -i -a automated-csp_module

	< If you don't immediately get the command prompt, press the ENTER key>
	
	 
/* STEP 21:
 * Install the Dropbox client application.
 */

	# apt-get install wget
	# wget -O - "https://www.dropbox.com/download?plat=lnx.x86_64" | tar xzf -
	# .dropbox-dist/dropboxd
	

/* STEP 22:
 * At this point you are required to copy a link generated by the Dropbox client,
 * to your browser, and to log in to your dropbox account.
 * Once you have completed the login step, the Dropbox installation is complete, and
 * starts synchronizing the Dropbox folder on your machine with your Dropbox account.
 */
 

/* STEP 23:
 * Stop the Dropbox client 
 */
 
	<CTRL-C (simultaneously press the Ctrl and C buttons to stop the dropbox client)>

	
/* STEP 24:
 * Create a symbolic link in the Dropbox directory, that points to
 * the directory "/csp" in this container. Then exit the container.
 */
 
	# ln -s /csp/ /Dropbox/  
	# exit

	
/* STEP 25:
 * Restart the three containers(automated-enc_module, automated-enc_module2,
 * and automated-csp_module) in the background.
 */

	$ docker start automated-enc_module
	$ docker start automated-enc_module2
	$ docker start automated-csp_module

	
/* STEP 26:
 * Start the incron filesystem monitoring tool, in the two encryption containers. 
 */

	$ docker exec automated-enc_module incrond
	$ docker exec automated-enc_module2 incrond

	
/* STEP 27:
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
 *   to the directory /tmp/counter-collusion_config_files/
 *
 * - In STEP 5, in addition to copying the scripts, also copy the
 *   the "keyfile" files retrieved from the first machine. i.e.
 * 	
 *	$ cp enc_mod1_keyfile  ~/framework_space/plain_dir/keyfile
 *  $ cp enc_mod2_keyfile  ~/framework_space/enc1-enc2_dir/keyfile
 *
 *
 * - In STEP 7 and STEP 14, in addition to the scripts, move the file "keyfile" 
 *   to the scripts directory:
 *
 *  $ mv /decrypted/keyfile /scripts/
 * 
 * - SKIP STEP 10 and STEP 12.
 */