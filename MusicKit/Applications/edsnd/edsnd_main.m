/* Generated by the NeXT Project Builder 
   NOTE: Do NOT change this file -- Project Builder maintains it.
*/

#import "EdsndApp.h"

void main(int argc, char *argv[]) {

    [EdsndApp new];
    if ([NXApp loadNibSection:"edsnd.nib" owner:NXApp withNames:NO])
	    [NXApp run];
	    
    [NXApp free];
    exit(0);
}
