/*//////////////////////////////////////////////////////////////////////////////
  //
  // $Id$
  // recsnd - SndKit commandline recording tool example using streaming 
  //          architecture.
  //
  // Original Author: SKoT McDonald <skot@tomandandy.com>  Sept 4 2001
  //
  //////////////////////////////////////////////////////////////////////////////*/

#import <Foundation/Foundation.h>
#import <SndKit/SndKit.h>
#include <unistd.h>

static char* versionString   = "5.5.3"; 
static char* versionDate     = "April 2007";  
static char* defaultFilename = "temp.wav";
static BOOL  bSilent         = FALSE;

#define RECSND_NO_ERROR     (0)
#define BAD_DURATION (-1)

/*//////////////////////////////////////////////////////////////////////////////
  //  showHelp
  //////////////////////////////////////////////////////////////////////////////*/

void showHelp(void)
{
    printf("recsnd -  A command line SndKit recording tool.\n");
    printf("Author:   SKoT McDonald <skot@tomandandy.com>\n");
    printf("Use:      recsnd [options] <filename>\n");
    printf("Options:  -h    show this help page\n"); 
    printf("          -v    show version\n"); 
    printf("          -d N  record duration in seconds (N is positive real)\n");
    printf("          -s    silent mode (no output)\n");
    printf("\n");
}

/*//////////////////////////////////////////////////////////////////////////////
  //  showVersion
  //////////////////////////////////////////////////////////////////////////////*/

void showVersion(void)
{
    printf("recsnd  version: %s date: %s\n",versionString, versionDate);
}

/*//////////////////////////////////////////////////////////////////////////////
  //  doRecord
  //////////////////////////////////////////////////////////////////////////////*/

void doRecord(const char* recordFilename, double recordDuration)
{
    NSAutoreleasePool *pool     = [[NSAutoreleasePool alloc] init];
    SndStreamRecorder *recorder = [[SndStreamRecorder alloc] init];
    NSString *fileName = [[NSFileManager defaultManager] stringWithFileSystemRepresentation: recordFilename
										     length: strlen(recordFilename)];
        
    [recorder startRecordingToFile: fileName];
    
    if (recordDuration >= 0.0) {
	while (recordDuration > 0.0) {
	    printf(".");
	    fflush(stdout);
	    if (recordDuration > 1.0) {
		[NSThread sleepUntilDate: [NSDate dateWithTimeIntervalSinceNow: 1]];
		recordDuration -= 1.0;
	    }
	    else {
		[NSThread sleepUntilDate: [NSDate dateWithTimeIntervalSinceNow: recordDuration]];
		recordDuration = 0.0;
	    }
	}
    }
    else {
	printf("Press return key to stop recording...\n");
	getchar();
    }
    
    [recorder stopRecordingWait: TRUE disconnectFromStream: TRUE];
    
    if (!bSilent) 
        printf("Done.\n");
    
    [pool release];
}

/*//////////////////////////////////////////////////////////////////////////////
  //  main
  //////////////////////////////////////////////////////////////////////////////*/

int main (int argc, const char * argv[])
{
    int    i;
    const char* recordFilename = NULL;
    double recordDuration = -1;
    
    if (argc == 1) {
	printf("Use: recsnd [options] <filename>\n");
	printf("Type recsnd -h for more help.\n");
	return RECSND_NO_ERROR;
    }
    
    // Process the arguments
    
    for (i = 1; i < argc; i++) {
	if (argv[i][0] == '-') {
	    switch (argv[i][1]) {
		case 'h': showHelp();    return RECSND_NO_ERROR; break;
		case 'v': showVersion(); return RECSND_NO_ERROR; break;
		case 's': bSilent = TRUE; break;
		case 'd':
		    i++;
		    if (i >= argc) {
			fprintf(stderr,"No record duration specified after -d option! Aborting.\n");
			return BAD_DURATION;
		    }
		    else {
			recordDuration = atof(argv[i]);
			if (recordDuration < 0.0) {
			    fprintf(stderr,"Record durations must be positive! Aborting.\n");
			    return BAD_DURATION;
			}
		    }
		    break;
		default:
		    fprintf(stderr,"Ignoring unknown option '%s'.\n",argv[i]);
	    }
	}
	else if (recordFilename == NULL) {
	    recordFilename = argv[i];
	}
	else {
	    fprintf(stderr,"Ignoring superfluous filename: %s\n",argv[i]);
	}
    }
    
    // One last check that the filename is correct...
    
    if (recordFilename == NULL) {
	recordFilename = defaultFilename;
    }
    
    // Record!
    
    doRecord(recordFilename, recordDuration);
    
    return 0;  
}
