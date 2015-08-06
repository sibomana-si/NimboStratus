#include "sisicrypt.h"

int main(int argc, char *argv[]){
	/* initialize cmdArgs */
	args.encrypt = 0;
	args.decrypt = 0;
	args.inFileName = NULL;
	args.key = NULL;
	args.iv = NULL;

	ProcessCmdLine(argc, argv);

	if (args.encrypt == 0 && args.decrypt == 0) {
		Usage();
	} else if (args.encrypt == 1){
		EncryptFile(args.inFileName, args.key, args.iv);
	} else {
		DecryptFile(args.inFileName, args.key, args.iv);		
	}
	exit(EXIT_SUCCESS);
}

void ProcessCmdLine(int argc, char *argv[]) {
	if (argc < 8 || argc > 8) Usage();

	int opt = 0;
	opt = getopt(argc, argv, optString);

	while (opt != -1) {
		switch(opt) {
				case 'e':
					if (args.decrypt == 1) Usage();
					args.encrypt = 1;
					break;

				case 'd':
					if (args.encrypt == 1) Usage();
					args.decrypt = 1;
					break;

				case 'f':
					args.inFileName = optarg;
					break;

				case 'k':
					args.key = optarg;
					break;

				case 'i':
					args.iv = optarg;
					break;

				case 'h':
					Usage();
					break;

				default:
					break;
		}
		opt = getopt(argc, argv, optString);
	}
}

void EncryptFile( char *fileName, char *key, char *iv ) {

	int status;
	char  buffer[BUFFERLENGTH];
	char *outFile;
	FILE *inFp = NULL, *outFp = NULL;

	outFile = calloc((strlen(fileName) + 4 + 1), 1);
	if (outFile == NULL) {
		Error("Failed to allocate memory for outFile!\n");
	}
	strcpy(outFile, fileName);
	strcat(outFile, ".enc");

	outFp = fopen(outFile, "w");
	if (outFp == NULL) {
		Error("failed to open output file for writing.");
	}

	inFp = fopen(fileName, "r");
	if (inFp == NULL) {
		Error("failed to open input file for reading!");
	}

	memset(buffer, 0, BUFFERLENGTH);

	/* functions to initialise crypto library and setup encryption context */

	while (fread(buffer, 1, 16, inFp) > 0) {
		// function(s) to encrypt data in buffer

		if(fwrite(buffer, 1, 16, outFp) != BUFFERLENGTH) {
			Error("There was an error in writing encrypted output to outFile!");
		}

		memset(buffer, 0, BUFFERLENGTH);
	}

	if (ferror(inFp)){
		Error("I/O error: Didn't complete reading from input file!\n");
	}

	/* function to destroy encryption context, and shutdown crypto library */		

	fclose(inFp);
	fclose(outFp);
	free(outFile);
}

void DecryptFile(char *fileName, char *key, char *iv) {
	int status;
	char  buffer[BUFFERLENGTH];
	char *outFile;
	FILE *inFp = NULL, *outFp = NULL;

	outFile = calloc((strlen(fileName) + 1 - 4), 1);
	if (outFile == NULL) {
		Error("Failed to allocate memory for outFile!\n");
	}
	strncpy(outFile, fileName, (strlen(fileName) - 4));

	outFp = fopen(outFile, "w");
	if (outFp == NULL) {
		Error("failed to open output file for writing.");
	}

	inFp = fopen(fileName, "r");
	if (inFp == NULL) {
		Error("failed to open input file for reading!");
	}

	memset(buffer, 0, BUFFERLENGTH);

	/* functions to initialise crypto library and setup encryption context */

	while (fread(buffer, 1, 16, inFp) > 0) {
		// function(s) to decrypt data in buffer
		
		if(fwrite(buffer, 1, 16, outFp) != BUFFERLENGTH) {
			Error("There was an error in writing decrypted output to outFile!");
		}

		memset(buffer, 0, BUFFERLENGTH);
	}

	if (ferror(inFp)){
		Error("I/O error: Didn't complete reading from input file!\n");
	}
	
	/* function to destroy encryption context, and shutdown crypto library */		

	fclose(inFp);
	fclose(outFp);
	free(outFile);
} 

void Usage(void) {
	printf("Usage:\nTo Encrypt file:\t sisicrypt -e -f <filename> -k <encryption key> -i <initialisation vector>\n");
	printf("To Decrypt file:\t sisicrypt -d -f <filename> -k <encryption key> -i <initialisation vector>\n");
	exit(EXIT_FAILURE);
}

void Error(char * errorMessage){
	fprintf(stderr, "%s\n", errorMessage);
	exit(EXIT_FAILURE);
}
