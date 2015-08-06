#ifndef SISICRYPT_H

	#include <stdio.h>
	#include <stdlib.h>
	#include <unistd.h>
	#include <string.h>
	#include <path to crytpo library header file>

	#define SISICRYPT_H
	
	typedef struct {
		int encrypt;		/* -e option */
		int decrypt;		/* -d option */
		char *inFileName;	/* -f option */
		char *key;			/* -k option */
		char *iv;			/* -i option */
	} cmdArgs;

	cmdArgs args;
	static const char *optString = "edf:k:i:h";
	int BUFFERLENGTH = 16;

	void Usage(void);
	void ProcessCmdLine(int argc, char *argv[]);
	void EncryptFile(char *fileName, char *key, char *iv);
	void DecryptFile(char *fileName, char *key, char *iv);
	void Error(char * errorMessage);

#endif
