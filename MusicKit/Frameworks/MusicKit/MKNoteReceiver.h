/*
  $Id$
  Defined In: The MusicKit

  Description:
    During a MusicKit performance, MKInstrument objects realize MKNotes that
    are sent to them from MKPerformer objects.  The MKNoteReceiver class
    defines the MKNote-receiving mechanism used by MKInstruments; each
    MKNoteReceiver object acts as a MKNote input for an MKInstrument.  Closely
    related to MKNoteReceiver is the MKNoteSender class, which defines the
    MKNote-sending mechanism used by MKPerformers.  By separating these
    mechanisms into distinct classes, any MKInstrument can have multiple
    inputs and any MKPerformer, multiple outputs.
   
    A MKNoteReceiver is added to an MKInstrument through the latter's
    addNoteReceiver: method.  While an application can create MKNoteReceivers
    and add them to an MKInstrument, this is typically done by the MKInstrument itself
    when it's created.  You can retrieve the object to which a MKNoteReceiver has
    been added by invoking MKNoteReceiver's owner method.
   
    To send MKNotes from a MKNoteSender to a MKNoteReceiver, the two objects must be
    connected.  This is done through the connect: method:
   
    	[aNoteReceiver connect:aNoteSender]
   
    Every MKNoteReceiver and MKNoteSender contains a list of connections.  The
    connect: method adds either object to the other's list; in other
    words, the MKNoteReceiver is added to the MKNoteSender's list and the
    MKNoteSender is added to the MKNoteReceiver's list.  Both MKNoteReceiver and
    MKNoteSender implement connect: as well as disconnect: and disconnect,
    methods used to sever connections.  A MKNoteReceiver can be connected to
    any number of MKNoteSenders.  Connections can be established and severed
    during a performance.
   
    The MKNote-receiving mechanism is defined in the receiveNote: method.
    When a MKNoteReceiver receives the message receiveNote: it sends the
    message realizeNote:fromNoteReceiver: to its owner, with the received
    MKNote as the first argument and its own id as the second.  receiveNote:
    is automatically invoked when a connected MKNoteSender sends a MKNote.
    You can toggle a MKNoteReceiver's MKNote-forwarding capability through the
    squelch and unsquelch methods; a MKNoteReceiver ignores the MKNotes it
    receives while it's squelched.  A newly created MKNoteReceiver is
    unsquelched.
   
    CF:  MKNoteSender, MKInstrument

  Original Author: David A. Jaffe

  Copyright (c) 1988-1992, NeXT Computer, Inc.
  Portions Copyright (c) 1994 NeXT Computer, Inc. and reproduced under license from NeXT
  Portions Copyright (c) 1994 Stanford University
  Portions Copyright (c) 1999-2001, The MusicKit Project.
*/
@class MKInstrument;
@class MKNote;
@class MKNoteSender;

/*!
  @class MKNoteReceiver
  @abstract MKNoteReceiver is an auxilliary class that completes the
            implementation of MKInstrument.
  @discussion

MKNoteReceiver is an auxilliary class that completes the implementation of
MKInstrument.  Instances of MKNoteReceiver are owned by MKInstrument objects to
provide the following:

<ul>
<li>It's part of the link between a MKPerformer and an MKInstrument. 
MKNoteReceiver's <b>connect</b>: method connects a MKNoteReceiver to a
MKNoteSender, which is owned by a MKPerformer in much the same way that a
MKNoteReceiver is owned by an MKInstrument.  By connecting a MKNoteReceiver to a
MKNoteSender, their respective owners are said to be connected.   MKNoteSender
defines an equivalent <b>connect:</b> method - it doesn't matter which of the
two objects is the receiver and which is the argument when sending a
<b>connect:</b> message.</li>

<li>MKNoteReceiver's <b>receiveNote:</b> method defines the mechanism by
which an MKInstrument obtains MKNotes.  When a MKNoteReceiver receives the
<b>receiveNote:</b> message, it forwards the argument (a MKNote object) to its
owner by invoking the MKInstrument method<b> realizeNote:fromNoteReceiver:</b>. 
The <b>receiveNote:</b> method itself is sent when a connected MKNoteSender
receives a <b>sendNote:</b> message from its owner; you can also send
<b>receiveNote:</b> (or one of its five sister methods) directly to a
MKNoteReceiver from your application.  You can toggle a MKNoteReceiver's ability
to pass MKNotes to its owner through the <b>squelch</b> and <b>unsquelch</b>
methods; a MKNoteReceiver won't send <b>realizeNote:fromNoteReceiver:</b>
messages while it's squelched.</li>
</ul>
 
Unlike MKNoteSenders, which are generally expected to be created by the
MKPerformers that own them, MKNoteReceivers can be created either by their
owners or by your application.  For example, each MKSynthInstrument object
creates and adds to itself a single MKNoteReceiver.  MKScorefileWriter objects,
on the other hand, don't create any MKNoteReceivers; it's left to your
application to create and add them.  A MKNoteReceiver is created through the
<b>new</b> class method and added to an MKInstrument through the latter's
<b>addNoteReceiver:</b>.

A MKNoteReceiver can be owned by only one MKInstrument at a time; however, it
can be connected to any number of MKNoteSenders.  In addition, two different
MKNoteReceivers can be connected to the same MKNoteSender.  Thus the connections
between MKPerformers and MKInstruments can describe an arbitrarily complicated
network.    To retrieve the MKNoteReceivers that are owned by a particular
MKInstrument you invoke the MKInstrument's <b>noteReceiver</b> or
<b>noteReceivers</b> method. 

MKNoteReceivers are also created, owned, and used by MKMidi objects as part of
their assumption of the role of MKInstrument.
*/
#ifndef __MK_NoteReceiver_H___
#define __MK_NoteReceiver_H___

#import <Foundation/NSObject.h>

@interface MKNoteReceiver: NSObject
{
    NSMutableArray *noteSenders;      /*! @var noteSenders Array of connected MKNoteSenders. */
    BOOL isSquelched;                 /*! @var isSquelched YES if the object is currently squelched. */
    MKInstrument *owner;              /*! @var owner MKInstrument that owns MKNoteReceiver. */

@private
    void *_myData;
}
 
/*!
  @method owner
  @result Returns an id.
  @discussion Returns the MKInstrument (or MKMidi object) that owns the
              MKNoteReceiver.
              
              See also: - <b>addNoteReceiver:</b> (MKInstrument, MKMidi)
*/
- owner; 

/*!
  @method init
  @result Returns <b>self</b>.
  @discussion Initializes a MKNoteReceiver that was created through
              <b>allocFromZone:</b>. 
              Subclass should send [super init] when overriding this method.
*/
- init;

/*!
  @method dealloc
  @abstract Disconnects and frees the receiver.
 */
- (void) dealloc; 

/*!
  @method disconnect:
  @param  aNoteSender is an MKNoteSender instance.
  @result Returns <b>self</b>.
  @discussion Severs the connection between the MKNoteReceiver and
              <i>aNoteSender</i>; if the MKNoteSender isn't connected, this does
              nothing.
              
              See also: - <b>disconnect</b>, - <b>connect:</b>, - <b>isConnected:</b>, - <b>connections</b> 
*/
- disconnect: (MKNoteSender *) aNoteSender; 

/*!
  @method disconnect
  @result Returns <b>self</b>.
  @discussion Severs the connections between the MKNoteReceiver and all the
              MKNoteSenders it's connected to.
              
              See also: - <b>disconnect:</b>, - <b>connect:</b>, - <b>isConnected:</b>, - <b>connections</b> 
*/
- disconnect; 

/*!
  @method isConnected:
  @param  aNoteSender is an MKNoteSender instance.
  @result Returns a BOOL.
  @discussion Returns YES if <i>aNoteSender</i> is connected to the
              MKNoteReceiver, otherwise returns NO.
              
              See also: - <b>connect</b>, - <b>disconnect</b>, - <b>connections</b>, - <b>connectionCount</b>,  
*/
- (BOOL) isConnected: (MKNoteSender *) aNoteSender; 

/*!
  @method connect:
  @param  aNoteSender is an MKNoteSender instance.
  @result Returns <b>self</b>.
  @discussion Connects <i>aNoteSender</i> to the MKNoteReceiver; if the argument
              isn't a MKNoteSender, the connection isn't made.
              
              See also: - <b>disconnect:</b>, - <b>isConnected</b>, - <b>connections</b>
*/
- connect: (MKNoteSender *) aNoteSender; 

/*!
  @method squelch
  @result Returns <b>self</b>.
  @discussion Disables the MKNoteReceiver's ability to send <b>realizeNote:fromMKNoteReceiver:</b>
              messages to its owner.
              
              See also: - <b>isSquelched</b>, - <b>unsquelch</b>
*/
- squelch; 

/*!
  @method unsquelch
  @result Returns <b>self</b>.
  @discussion Enables the MKNoteReceiver's ability to send <b>realizeNote:fromMKNoteReceiver:</b>
              messages to its owner, undoing the effect of a previous <b>squelch</b> message.
              
              See also: - <b>isSquelched</b>, - <b>squelch</b>
*/
- unsquelch; 

/*!
  @method isSquelched
  @result Returns a BOOL.
  @discussion Returns YES if the MKNoteReceiver is squelched, otherwise returns
              NO.  A squelched MKNoteReceiver won't invoke its owner's
              <b>realizeNote:fromNoteReceiver:</b> method.
              
              See also: - <b>squelch</b>, - <b>unsquelch</b>
*/
- (BOOL) isSquelched; 

/*!
  @method copyFromZone:
  @param  zone is a NSZone *.
  @result Returns an id.
  @discussion Creates and returns a new MKNoteReceiver with the same
              connections as the receiver.
              This is the same as <b>copy</b>, but the new object is allocated
              from <i>zone</i>.
              
              See also: - <b>copy</b>
*/
- copyWithZone: (NSZone *) zone; 

/*!
  @method connectionCount
  @result Returns an unsigned int.
  @discussion Returns the number of MKNoteSenders that are connected to the
              MKNoteReceiver.
              
              See also: - <b>connect:</b>,<b></b> -
              <b>disconnect:</b>,<b></b>- <b>isConnected</b>,<b> </b> -
              <b>connections</b>
*/
- (unsigned) connectionCount;

/*!
  @method connections
  @result Returns a NSArray instance.
  @discussion Creates and returns a NSArray of the MKNoteSenders that are
              connected to the MKNoteReceiver. 
              
              See also: - <b>connect:</b>,<b> </b>- <b>disconnect:</b>,<b></b> - <b>isConnected</b>
*/
- (NSArray *) connections;

/*!
  @method receiveNote:
  @param  aNote is an MKNote instance.
  @result Returns the receiver, or nil if the receiver is squelched.
  @discussion Sends the message <b>realizeNote:</b><i>aNote</i>
              <b>fromMKNoteReceiver:self</b> to the MKNoteReceiver's owner thereby causing <i>aNote</i>
              to be realized by the receiver's owner.  If the MKNoteReceiver is squelched, the message isn't sent.
              This method is invoked automatically as the MKNoteReceiver's connected MKNoteSenders receive
              <b>sendNote:</b> messages; you can also invoke this method directly, although typically 
              <b>receiveNote:</b> is sent as part of a MKNoteSender's <b>sendNote:</b> method.
              
              See also: - <b>receiveAndFreeNote:</b>, - <b>receiveNote:withDelay:</b>, - <b>receiveNote:atTime:</b>
*/
- receiveNote: (MKNote *) aNote; 

/*!
  @method receiveNote:atTime:
  @param  aNote is an MKNote instance.
  @param  time is a double.
  @result Returns <b>self</b>.
  @discussion Enqueues, with the MKConductor object described below, a request for
              <b>receiveNote:</b><i>aNote</i> to be sent to <b>self</b> at time
              <i>beatsSinceStart</i>, measured in beats from the beginning of the
              MKConductor's performance.  If <i>beatsSinceStart</i> has already
              passed, the enqueued message is sent immediately.  Returns
              <b>self</b>.
              
              The request is enqueued with<i></i> the object that's returned by
              <b>[</b><i>aNote</i> <b>conductor]</b>.  If the MKNote was received from
              a MKNoteSender, this is the MKConductor of the MKPerformer that originally
              sent <i>aNote</i> into the performance.  If you invoke this method (or any
              of the <b>receiveNote:</b> methods that enqueue a message request) directly,
              or if MKMidi is the originator of the MKNote, then the defaultConductor is used.
              
              See also: - <b>receiveNote:</b>,<b></b>-<b>  receiveNote:withDelay:</b>
*/
- receiveNote: (MKNote *) aNote atTime: (double) time;

/*!
  @method receiveNote:withDelay:
  @param  aNote is an MKNote instance.
  @param  delayTime is a double.
  @result Returns <b>self</b>.
  @discussion Enqueues, with the appropriate MKConductor, a request for
              <b>receiveNote:</b><i>aNote</i> to be sent to <b>self</b> after
              <i>delayTime</i>, measured in beats from the time this message
              is received.  See <b>receiveNote:atTime:</b> for a description
              of the MKConductor that's used.  Returns <b>self</b>.
              
              See also: - <b>receiveNote:</b>,<b></b>-<b>  receiveNote:atTime:</b>
*/
- receiveNote: (MKNote *) aNote withDelay: (double) delayTime; 

/* 
    You never send this message directly.  
    Should be invoked with NXWriteRootObject(). 
    Archives isSquelched and object name, if any. 
    Also optionally archives elements of MKNoteSender NSArray and owner using 
    NXWriteObjectReference(). 
*/
- (void) encodeWithCoder: (NSCoder *) aCoder;

/* 
    You never send this message directly.  
    Should be invoked via NXReadObject(). 
    See write:. 
*/
- (id) initWithCoder: (NSCoder *) aDecoder;

@end

#endif
