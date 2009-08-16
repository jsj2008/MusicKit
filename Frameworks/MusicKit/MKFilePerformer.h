/*
  $Id$  
  Defined In: The MusicKit

  Description:
    A MKFilePerformer reads data from a file on the disk,
    fashions a MKNote object from the data, and then performs
    the MKNote.  An abstract superclass, MKFilePerformer
    provides common functionality and declares subclass responsibilities
    for the subclasses MKMidifilePerformer and MKScorefilePerformer.

    Note: In release 1.0, MKMidifilePerformer is not provided. Use a MKScore object
    to read a Midifile.

    A MKFilePerformer is associated with a file, either by the
    file's name or with a file pointer.  If you assoicate
    a MKFilePerformer with a file name (through the setFile:
    method) the object will take care of opening and closing
    the file for you:  the file is opened for reading when the
    MKFilePerformer receives the activate message and closed when
    it receives deactivate.

    The setStream: method associates a MKFilePerformer with a file
    pointer.  In this case, opening and closing the file
    is the responsibility of the application.  The MKFilePerformer's
    file pointer is set to NULL after each performance
    so you must send another setStream: message in order to replay the file.

    Note:  The argument to -setStream: is a NSData or NSMutableData.

    The MKFilePerformer class declares two methods as subclass responsibilities:
    nextNote and performNote:. nextNote must be subclassed to access the next line of information
    from the file and from it create either a MKNote object or a
    time value.  It returns the MKNote that it creates, or, in the case of a time value,
    it sets the instance variable fileTime to represent the current time in the file
    and returns nil.

    The MKNote created by nextNote is passed as the argument
    to performNote: which is responsible for performing any manipulations on the
    MKNote and then sending it by invoking sendNote:.
    The return value of performNote: is disregarded.

    Both nextNote and performNote: are invoked
    by the perform method, which, recall from the MKPerformer
    class, is itself never called directly but is sent by a MKConductor.
    perform also checks and incorporates the time limit
    and performance offset established by the timing window
    variables inherited from MKPerformer; nextNote and
    performNote: needn't access nor otherwise be concerned
    about these variables.

    Two other methods, initFile and finishFile, can
    be redefined by a MKFilePerformer subclass, although neither
    must be.  initializeFile is invoked
    when the object is activated and should perform any special
    initialization such as reading the file's header or magic number.
    If initializeFile returns nil, the MKFilePerformer is deactivated.
    The default returns the receiver.

    finishFile is invoked when the MKFilePerformer is deactivated
    and should perform any post-performance cleanup.  Its return
    value is disregarded.

    A MKFilePerformer reads and performs one MKNote at a time.  This
    allows efficient performance of arbitrarily large files.
    Compare this to the MKScore object which reads and processes the entire file
    before performing the first note.  However, unlike the MKScore object,
    the MKFilePerformer doesn't allow individual timing control over the
    different MKNote streams in the file; the timing window
    specifications inherited from MKPerformer are applied to the entire
    file.

    Any number of MKFilePerformers can perform the same file concurrently.

  Original Author: David A. Jaffe

  Copyright (c) 1988-1992, NeXT Computer, Inc.
  Portions Copyright (c) 1994 NeXT Computer, Inc. and reproduced under license from NeXT
  Portions Copyright (c) 1994 Stanford University.
  Portions Copyright (c) 1999-2001, The MusicKit Project.
*/
/*!
  @class MKFilePerformer
  @brief During a Music Kit performance, a MKFilePerformer reads and performs time-ordered
  music data from a file on the disk.  An abstract class, MKFilePerformer provides
  common functionality and declares subclass responsibilities for its one
  subclass, MKScorefilePerformer.

A MKFilePerformer is associated with a file either by the file's name or through
an NSMutableData instance.  If you associate a MKFilePerformer with a file name (through
the <b>setFile:</b> method) the object opens and closes the file for you:  The
file is opened for reading when the MKFilePerformer receives the <b>activate</b>
message and closed when it receives <b>deactivate</b>.  The <b>setFileStream:</b>
method associates a MKFilePerformer with an NSMutableData instance.  In this case, opening
and closing the file is the responsibility of the application.  The MKFilePerformer's
stream pointer is set to NULL after each performance so you must send another
<b>setFileStream:</b> message in order to replay the file.  Any number of MKFilePerformers
can perform the same file simultaneously.

The MKFilePerformer class declares two methods as subclass responsibilities: 
<b>nextNote</b> and <b>performNote:</b>.  A subclass implementation of<b>
nextNote</b> should be designed to read the next line of information in the file
and from it create either a MKNote object or a timeTag value (for the following
MKNote).  It returns the MKNote that it creates, or, in the case of a timeTag, it
sets the instance variable <b>fileTime</b> to represent the current time in the
file and returns <b>nil</b>.  <b>performNote:</b> should perform any desired
manipulations on the MKNote created by <b>nextNote</b> and then pass it as the
argument to <b>sendNote:</b> (sent to a MKNoteSender).  The value returned by
<b>performNote:</b> is ignored.

MKFilePerformer defines two timing variables, <b>firstTimeTag</b> and
<b>lastTimeTag</b>.  They represent the smallest and largest timeTag values that
are considered for performance:  MKNotes with timeTags that are less than
<b>firstTimeTag</b> are ignored; if <b>nextNote</b> creates a timeTag greater
than <b>lastTimeTag</b>, the MKFilePerformer is deactivated.

Creation of a MKFilePerformer's MKNoteSender(s) is a subclass responsibility.

  @see  MKScorefilePerformer, MKPerformer
*/
#ifndef __MK_FilePerformer_H___
#define __MK_FilePerformer_H___

#import <Foundation/Foundation.h>

#import "MKPerformer.h"

@interface MKFilePerformer : MKPerformer
{
    /*! File name or nil if the file pointer is specifed directly. */
    NSString *filename;
    /*! The current time in the file (in beats). */
    double fileTime;
    /*! Pointer to the MKFilePerformer's file, either NSMutableData or NSData */
    id stream;
    /*! The smallest timeTag value considered for performance. */
    double firstTimeTag;
    /*! The greatest timeTag value considered for performance. */
    double lastTimeTag;
}
 
/*!
  @brief Initializes the object by setting <b>stream</b> and <b>filename</b> to NULL.

  You invoke this method when creating a new instance of MKFilePerformer.  
  A subclass implementation should send <b>[super init]</b>
  before performing its own initialization.  The return value is ignored.
  @return Returns an id.
*/
- init;

- copyWithZone:(NSZone *)zone;

/*!
  @brief Associates the object with the file named <i>aName</i>.

  The file is opened when the object is activated and closed when its deactivated.
  If the object is active, does nothing and returns <b>nil</b>,
  otherwise returns the object.
  @param  aName is a NSString instance.
  @return Returns an id.
*/
- setFile: (NSString *) aName;

/*!
  @brief Returns the object's file name, if any.
  @return Returns an NSString.
 */
- (NSString *) file; 

/*!
  @brief Sets the object's stream to <i>aStream</i>.

  The sender must open and close the stream himself.  If the object is active,
  this does nothing and returns <b>nil</b>, otherwise returns the
  object.
  @param  aStream is an id.
  @return Returns an id.
*/
- setStream: (id) aStream; // TODO either NSMutableData, or NSData

/*!
  @brief Returns the object's encoded stream object, or NULL if it isn't set.
  @return Returns an id.
*/
- (id) stream; // TODO either NSMutableData, or NSData

/*!
  @brief Prepares the object for a performance by opening the associated file
  (if necessary) and invoking <b>nextNote</b> until it returns an
  appropriate MKNote - one with a timeTag between <b>firstTimeTag</b>
  and <b>lastTimeTag</b>, inclusive.

  If an appropriate MKNote isn't found, the object is deactivated.
  You never invoke this method; its invoked by the <b>activate</b> method inherited from MKPerformer.
  @return Returns an id.
*/
- activateSelf;

/*!
  @brief Returns the file name extension that's recognized by the class.

  The default implementation returns nil.  A subclass may override this
  method to specify its own file extension.
  @return Returns an NSString.
*/
+ (NSString *) fileExtension;

/*!
  @brief Returns an NSArray of NSStrings holding file extensions that
  are recognized by the class.

  The default implementation returns an NSArray whose single element
  NSString is given the value returned by the <b>fileExtension</b> method.
  A subclass may override this method to specify its own file extensions.
  @return Returns an NSArray.
*/
+ (NSArray *) fileExtensions;

/*!
  @brief Gets the next MKNote from the object's file by invoking
  <b>nextNote</b>, passes it as the argument to <b>performNote:</b>,
  then sets the value of <i>nextPerform</i>.

  You never invoke this method; it's invoked by the object's MKConductor.
  The return value is ignored.
  @return Returns an id.
*/
- perform; 

/*!
  @brief A subclass responsibility expected to manipulate and send
  <i>aNote</i>, which was presumably just read from a file.

  You never invoke this method; it's invoked automatically by the <b>perform</b>
  method.  The return type is ignored.
  @param  aNote is an MKNote instance.
  @return Returns an id.
*/
- performNote: (MKNote *) aNote; 

/*!
  @brief A subclass responsibility expected to fashion a MKNote or timeTag from the file.

  It should return the MKNote or <b>nil</b> if the next file
  entry is a timeTag.  In the latter case, <i>fileTime</i> should be
  updated.  You never invoke this method; it's invoked automatically
  by the <b>perform</b> method.
  @return Returns an MKNote instance.
*/
- (MKNote *) nextNote; 

/*!
  @brief A subclass can implement this method to perform file initialization.

  If <b>nil</b> is returned, the object is deactivated.  You never
  invoke this method; it's invoked automatically by
  <b>activateSelf</b>.  The default implementation does nothing and
  returns the object.
  @return Returns an id.
*/
- initializeFile;

/*!
  @brief Invokes <b>finishFile</b>, closes the object's file (if it was set
  through <b>setFile:</b>), and sets the <b>stream</b> instance variable to nil.

  You never invoke this method; its invoked automatically when the object is deactivated.
*/
- (void) deactivate; 

/*!
  @brief A subclass can implement this method for post-performance file
  operations.

  You shouldn't close the stream pointer as part of this method.
  You never invoke this method; it's invoked automatically by
  <b>deactivateSelf</b>.  The default implementation does nothing. 
  The return value is ignored.
  @return Returns an id.
*/
- finishFile; 

/*!
  @brief Sets the smallest timeTag considered for performance to <i>aTimeTag</i>.

  Returns the object.  If the object is active, does
  nothing and returns <b>nil</b>.
  @param  aTimeTag is a double.
  @return Returns an id.
*/
- setFirstTimeTag: (double) aTimeTag;

/*!
  @brief Sets the largest timeTag considered for performance to <i>aTimeTag</i>.

  Returns the object.  If the object is active, does
  nothing and returns <b>nil</b>.
  @param  aTimeTag is a double.
  @return Returns an id.
*/
- setLastTimeTag: (double) aTimeTag; 

/*!
  @brief Returns the object's <b>firstTimeTag</b> value.
  @return Returns a double.  
*/
- (double) firstTimeTag; 

/*!
  @brief Returns the object's <b>lastTimeTag</b> value.
  @return Returns a double.
*/
- (double) lastTimeTag;

/*!
  @brief You never invoke this method directly; to archive a MKFilePerformer,
  call the <b>NSArchiver</b> <b>archiveRoot</b> method.

  An archived MKFilePerformer maintains its <i>filename</i>, <i>firstTimeTag</i>,
  and <i>lastTimeTag</i> instance variables (as well as the instance
  variables defined in MKPerformer).
  @param  aCoder is an NSCoder instance.
*/
- (void) encodeWithCoder: (NSCoder *) aCoder;

/*!
  @brief You never invoke this method directly; to read an archived
  MKFilePerformer, call the <b>NSUnarchiver</b> methods.
  @param  aDecoder is an NSCoder instance.
  @return Returns an id.
*/
- (id) initWithCoder: (NSCoder *) aDecoder;

@end

#endif
