/* MidiEcho is an example of a Music Kit performance where the interactive
   response time needs to be as fast as possible, even if at the expense of 
   a bit of timing indeterminacy. Therefore, the Conductor is clocked and 
   Midi is untimed (i.e. no delays are introduced in the Midi object). 
   The Conductor is also set to not 'finishWhenEmpty'. This ensures the 
   performance will continue, whether or not the Conductor has 
   any objective-c messages to send, until the user decides to terminate the 
   performance. The Midi object is set to not 'useInputTimeStamps' because
   we are not interested in the exact time the MIDI entered the computer, as
   we would be if we were recording the MIDI (See MidiRecord).
 */

#import "EchoFilter.h"
#import "MidiEcho.h"

@implementation MidiEcho

NSString *dev = @"midi0"; /* Serial port A on NeXT hardware--the default. */
static float delay = .1;

static void handleMKError(char *msg)
{
    if (!NSRunAlertPanel(@"MidiEcho", [NSString stringWithCString:msg], @"OK", @"Quit", nil, NULL))
	[NSApp terminate:NSApp];
}

- (void)showInfoPanel:sender
{
    [NSBundle loadNibNamed:@"Info.nib" owner:self];
    [infoPanel orderFront:sender]; 
}

- (void)go:sender
{
    if ([MKConductor inPerformance])  
    	return;

    MKSetErrorProc(handleMKError); /* Intercept Music Kit errors. */
       
    /* Get Midi object for the specified midi device */
    midi = [Midi midiOnDevice:dev];

    if (!midi) {
	NSRunAlertPanel(@"MidiEcho", @"No driver present for specified device.", @"OK", nil, nil);
	[sender setState:0];
	return;
    }

    /* The driver's time stamps are not useful in this application */
    [midi setUseInputTimeStamps:NO]; 

    /* Open it for input and output */
    [midi open];

    /* We use a NoteFilter subclass to make the echoes. */
    myFilter = [[EchoFilter alloc] init];
    [myFilter setDelay:delay];

    /* Connect up the Midi NoteSender for channel 1 to the NoteReceiver of the NoteFilter */
    [[midi channelNoteSender:1] connect:[myFilter noteReceiver]];

    /* Connect each of the NoteFilter's outputs to the corresponding input of Midi. */
    [myFilter connectAcross:midi];

    /* No delay in sending out midi out events */      
    [midi setOutputTimed:NO];     

    /* Boost priority of performance. */ 
    [MKConductor setThreadPriority:1.0];

    /* Tell Conductor not to quit when there are no more scheduled messages.
       We are often in the 'empty' state, waiting for the next MIDI message.
       */
    [MKConductor setFinishWhenEmpty:NO];   

    /* Start up Midi */
    [midi run];

    /* Start the Conductor  */
    [MKConductor startPerformance]; 
}

- (void)setMidiDev:sender
{
    if ([[sender selectedCell] tag])
	dev = @"midi1";
    else
	dev = @"midi0";
    if ([MKConductor inPerformance]) { /* Already started? */
	[MKConductor finishPerformance];
	[midi close];
	[midi autorelease];    
	[myFilter autorelease];
	[self go:self]; /* Start us up again. */
    } 
}

- (void)setDelayFrom:sender
  /* This is invoked from the text field. Sets the delay used by the NoteFilter
   */
{
    delay = [sender floatValue];
    [myFilter setDelay:delay]; 
}

@end
