/* Generated by the NeXT Project Builder 
   NOTE: Do NOT change this file -- Project Builder maintains it.
*/

#import "ExampApp.h"

void main(int argc, char *argv[]) {

    [ExampApp new];
    if ([NXApp loadNibSection:"QC.nib" owner:NXApp withNames:NO])
	    [NXApp run];
	    
    [NXApp free];
    exit(0);
}