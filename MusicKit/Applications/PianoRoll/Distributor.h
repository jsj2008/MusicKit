
/* Generated by Interface Builder */

#import <Foundation/NSObject.h>
#import "Document.h"

@interface Distributor:NSObject
{
    IBOutlet NSWindow * infoPanel;
    id helpPanel;
    id openPanel;
    id savePanel;
    id tadList;
    NSMutableArray *docList;	
    PlayScore *scorePlayer;
}

- init;
- setTadList:theList;
- (void)closeDoc:sender;
- (void)openDoc:sender;
- (void)saveDocAs:sender;
- (void)saveDoc:sender;
- (void)showHelp:sender;
- (void)showInfo:sender;
- (void)newDoc:sender;
- (void)play:sender;
- (void)stopPlay:sender;
- (Document *) findCurrent;

@end