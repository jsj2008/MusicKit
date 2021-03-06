#
#   $Id$
#   Defined In: The MusicKit
#
#  Description:
#    SndKit Makefile for GNUstep
#
#  Original Author: Stephen Brandon <stephen@brandonitconsulting.co.uk>
#
#  21 April 2001, Copyright (c) 2001 Stephen Brandon.
#
#  Permission is granted to use and modify this code for commercial and non-commercial
#  purposes so long as the author attribution and this copyright message remains intact
#  and accompanies all derived code.

# See the public CVS logs for the modification history via http://www.musickit.org

# Install into the local root by default
# GNUSTEP_INSTALLATION_DOMAIN = LOCAL

include $(GNUSTEP_MAKEFILES)/common.make

# For use in rpm generation:
PACKAGE_NAME = SndKit
VERSION = 5.6.0

srcdir = .

SK_COMPILE_MP3_ENCODER = yes

# The framework or library to be compiled
ifeq (mingw32, $(GNUSTEP_TARGET_OS))
  LIBRARY_NAME = libSndKit
  MY_NAME = $(LIBRARY_NAME)
  # Extra DLL exports file
  $(LIBRARY_NAME)_DLL_DEF = $(LIBRARY_NAME).def
  ADDITIONAL_LDFLAGS += -Wl,--output-def,$(LIBRARY_NAME).def
else
  FRAMEWORK_NAME = SndKit
  MY_NAME=$(FRAMEWORK_NAME)
endif

# The framework resource files and directories
$(MY_NAME)_RESOURCE_FILES = 

$(MY_NAME)_RESOURCE_DIRS = 

# The Bundle Objective-C source files to be compiled
$(MY_NAME)_OBJC_FILES = \
         Snd.m \
         SndAudioBuffer.m \
         SndAudioBufferQueue.m \
         SndAudioFader.m \
         SndAudioProcessor.m \
         SndAudioProcessorChain.m \
         SndAudioProcessorDelay.m \
         SndAudioProcessorDistortion.m \
         SndAudioProcessorFlanger.m \
         SndAudioProcessorInspector.m \
         SndAudioProcessorMP3Encoder.m \
         SndAudioProcessorNoiseGate.m \
         SndAudioProcessorRecorder.m \
         SndAudioProcessorReverb.m \
         SndAudioProcessorToneGenerator.m \
         SndBreakpoint.m \
         SndConvert.m \
         SndDisplayData.m \
         SndDisplayDataList.m \
         SndEditing.m \
         SndEnvelope.m \
         SndError.m \
         SndOnDisk.m \
	 SndFileIO.m \
         SndFunctions.m \
         SndMeter.m \
	 SndMuLaw.m \
         SndMP3.m \
	 SndPasteboard.m \
         SndPerformance.m \
         SndPlayer.m \
         SndPlaying.m \
         SndResample.m \
         SndStreamArchitectureView.m \
         SndStreamClient.m \
         SndStreamManager.m \
         SndStreamMixer.m \
         SndStreamRecorder.m \
         SndStreamInput.m \
         SndStretchableScroller.m \
         SndTable.m \
         SndView.m \
         SndReverbAllpassFilter.m \
         SndReverbCombFilter.m \
         Sndfilterkit.m

$(MY_NAME)_C_FILES = \
         SndEndianFunctions.c \
         vDSP.c

# The framework installed header files
$(MY_NAME)_HEADER_FILES = \
         Snd.h \
         SndAudioBuffer.h \
         SndAudioBufferQueue.h \
         SndAudioFader.h \
         SndAudioProcessor.h \
         SndAudioProcessorChain.h \
         SndAudioProcessorDelay.h \
         SndAudioProcessorDistortion.h \
         SndAudioProcessorFlanger.h \
         SndAudioProcessorInspector.h \
         SndAudioProcessorMP3Encoder.h \
         SndAudioProcessorNoiseGate.h \
         SndAudioProcessorRecorder.h \
         SndAudioProcessorReverb.h \
         SndAudioProcessorToneGenerator.h \
         SndBreakpoint.h \
         SndDisplayData.h \
         SndDisplayDataList.h \
         SndEndianFunctions.h \
         SndEnvelope.h \
         SndError.h \
         SndOnDisk.h \
         SndFormat.h \
         SndFunctions.h \
         SndKitConfig.h \
         SndKit.h \
         SndMuLaw.h \
         SndMeter.h \
         SndMP3.h \
	 SndPasteboard.h \
         SndPerformance.h \
         SndPlayer.h \
         SndResample.h \
         SndStreamArchitectureView.h \
         SndStreamClient.h \
         SndStreamManager.h \
         SndStreamMixer.h \
         SndStreamRecorder.h \
         SndStreamInput.h \
         SndTable.h \
         SndView.h\
         Sndfilterkit.h \
         Sndlargefilter.h \
         Sndsmallfilter.h \
	 vDSP.h

$(MY_NAME)_HEADER_FILES_INSTALL_DIR = SndKit

# Extra DLL exports file
# $(MY_NAME)_DLL_DEF = $(MY_NAME).def

-include GNUmakefile.preamble

ifeq (mingw32, $(GNUSTEP_TARGET_OS))
  include $(GNUSTEP_MAKEFILES)/library.make
else
  include $(GNUSTEP_MAKEFILES)/framework.make
endif

-include GNUmakefile.postamble
