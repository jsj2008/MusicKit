#
# Generated by the NeXT Project Builder.
#
# NOTE: Do NOT change this file -- Project Builder maintains it.
#
# Put all of your customizations in files called Makefile.preamble
# and Makefile.postamble (both optional), and Makefile will include them.
#

NAME = edsnd

PROJECTVERSION = 2.8
PROJECT_TYPE = Application
NEXTSTEP_APPICON = sndapp.tiff
ICONSECTIONS =	-sectcreate __ICON app sndapp.tiff

English_RESOURCES = edsnd.nib Envelope.nib FFT.nib snddoc.nib\
                    Stopwatch.nib

LANGUAGES = English

GLOBAL_RESOURCES = sndapp.tiff

CLASSES = Animator.m EdsndApp.m EdSoundView.m Envelope.m\
          EnvelopeView.m FFT.m FFTView.m ScrollingSound.m\
          SoundDocument.m SpectrumView.m Stopwatch.m UpPanel.m

HFILES = Animator.h EdsndApp.h EdSoundView.h Envelope.h EnvelopeView.h\
         FFT.h FFTView.h ScrollingSound.h SoundDocument.h\
         SpectrumView.h Stopwatch.h UpPanel.h

MFILES = edsnd_main.m fft.m SNDindirect.m

CFILES = fft_net.c

PSWFILES = PWenv.psw PWfft.psw PWSpectrum.psw


MAKEFILEDIR = /System/Developer/Makefiles/pb_makefiles
CODE_GEN_STYLE = DYNAMIC
MAKEFILE = app.make
NEXTSTEP_INSTALLDIR = $(HOME)/Apps
WINDOWS_INSTALLDIR = $(HOME)/Apps
PDO_UNIX_INSTALLDIR = $(HOME)/Apps
LIBS = -lMedia_s -lNeXT_s
DEBUG_LIBS = $(LIBS)
PROF_LIBS = $(LIBS)




NEXTSTEP_OBJCPLUS_COMPILER = /usr/bin/cc
WINDOWS_OBJCPLUS_COMPILER = $(DEVDIR)/gcc
PDO_UNIX_OBJCPLUS_COMPILER = $(NEXTDEV_BIN)/gcc
NEXTSTEP_JAVA_COMPILER = /usr/bin/javac
WINDOWS_JAVA_COMPILER = $(JDKBINDIR)/javac.exe
PDO_UNIX_JAVA_COMPILER = $(JDKBINDIR)/javac

include $(MAKEFILEDIR)/platform.make

-include Makefile.preamble

include $(MAKEFILEDIR)/$(MAKEFILE)

-include Makefile.postamble

-include Makefile.dependencies
