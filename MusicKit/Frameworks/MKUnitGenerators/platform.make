#******************************************************************************
#
#	Copyright (C)1998 by Eric Sunshine <sunshine@sunshineco.com>
#
# The contents of this file are copyrighted by Eric Sunshine.  You may use
# this file in your own projects provided that this copyright notice is
# retained verbatim.
#
#******************************************************************************
#------------------------------------------------------------------------------
# platform.make					      (1998-10-19, version 1.0)
#
#	A cross-platform compatibility makefile which allows a project to be
#	built for both OpenStep and Rhapsody without maintaining distinct
#	PB.project files and Makefiles for each platform.
#
#	Prior to Rhapsody DR2, system-supplied makefiles resided in a constant
#	location, in this case $(NEXT_ROOT)/NextDeveloper/Makefiles.  As of
#	DR2, however, the directory structure changed, so that on Mach,
#	makefiles now reside in /System/Developer/Makefiles, and on Windows
#	they reside in $(NEXT_ROOT)/Developer/Makefiles.
#
#	Apple hacked GNU's "make" utility under DR2 so that it automatically
#	defines the variable MAKEFILEPATH, which on Mach defaults to
#	/System/Developer/Makefiles, and on Microsoft Windows defaults to
#	$(NEXT_ROOT)/Developer/Makefiles.  In this manner, they are able to
#	refer to the system makefile directory without having to hardcode the
#	path into the local makefile as they did prior to DR2.
#
#	However, Apple's hack does not help the developer who must still
#	support pre-DR2 platforms which use the old directory structure, nor
#	did Apple provide a backward compatibility solution.  Consequently,
#	the developer is forced to maintain two sets of PB.project files and
#	Makefiles; one for OpenStep 4.x, and one for Rhapsody DR2 and later.
#
#	This file (platform.make) bridges the gap between the old directory
#	structure and the new by forcefully inserting itself into the make
#	process at the earliest possible time and adjusting the makefile path
#	dynamically to match either the old or the new directory structure.
#
#	To insert this file into the make process, follow these steps:
#
#	a) If the project is currently open in ProjectBuilder.app, close it.
#	b) Open the project's top-level PB.project file in a text editor.
#	c) Find the line which defines MAKEFILEDIR.  Its definition will be
#	   either $(NEXT_ROOT)/NextDeveloper/Makefiles/pb_makefiles or
#	   $(MAKEFILEPATH)/pb_makefiles depending upon whether it was
#	   generated by OpenStep 4.x or Rhapsody DR2.
#	d) Change the value of MAKEFILEDIR to "." (a single period).
#	e) Open the project's top-level Makefile in a text editor.
#	f) Find the line which defines MAKEFILEDIR.
#	g) Change the value of MAKEFILEDIR to . (a single period).
#	h) Place this file (platform.make) in the project's main directory.
#
#	The variable MAKEFILEDIR is normally used to locate the system makefile
#	directory from which platform.make is loaded as the very beginning of
#	the build process.  By changing the value of MAKEFILEDIR to ".", this
#	replacement platform.make gets loaded instead.
#
#	Once in control, this file determines the correct makefile path
#	dynamically, either $(NEXT_ROOT)/NextDeveloper/Makefiles/pb_makefiles
#	or $(MAKEFILEPATH)/pb_makefiles and sets it as the value of MAKEFILEDIR
#	so that later references to MAKEFILEDIR use the actual system
#	makefiles.  Finally, the real system platform.make is loaded, and
#	control returns to the caller.
#
#	To further facilitate cross-platform development, this file also
#	defines the following variables for pre-DR2 clients which are normally
#	only defined for DR2 and later clients.  These variables are typically
#	used by "install" targets where the installation location may vary from
#	platform to platform.
#
#	MAKEFILEPATH		Path to system makefiles
#	USER_APPS_DIR		$(HOME)/Apps [vs. $(HOME)/Applications) on DR2]
#	USER_LIBRARY_DIR	$(HOME)/Library
#	LOCAL_APPS_DIR		/LocalApps or $(NEXT_ROOT)/Local/Apps [Windows]
#	LOCAL_LIBRARY_DIR	/LocalLibrary or $(NEXT_ROOT)/Local/Library
#	SYSTEM_LIBRARY_DIR	/NextLibrary or $(NEXT_ROOT)/System/Library
#	LOCAL_DEVELOPER_DIR	/LocalDeveloper or $(NEXT_ROOT)/Local/Developer
#
# Please send comments to Eric Sunshine <sunshine@sunshineco.com>
# MIME, NeXT, and ASCII mail accepted.
#------------------------------------------------------------------------------
#------------------------------------------------------------------------------
# $Id$
# $Log$
# Revision 1.2  1999/07/28 17:50:53  leigh
# Used mkdealloc and now includes the SoundKit header
#
# Revision 1.1.1.1  1999/06/28 23:51:25  leigh
# MusicKit Frameworks
#
#------------------------------------------------------------------------------

ifndef MAKEFILEPATH
MAKEFILEPATH=$(NEXT_ROOT)/NextDeveloper/Makefiles
endif
MAKEFILEDIR=$(MAKEFILEPATH)/pb_makefiles

include $(MAKEFILEDIR)/platform.make

ifeq "NEXTSTEP" "$(OS)"

ifndef USER_APPS_DIR
USER_APPS_DIR=$(HOME)/Apps
endif
ifndef USER_LIBRARY_DIR
USER_LIBRARY_DIR=$(HOME)/Library
endif
ifndef LOCAL_APPS_DIR
LOCAL_APPS_DIR=/LocalApps
endif
ifndef LOCAL_LIBRARY_DIR
LOCAL_LIBRARY_DIR=/LocalLibrary
endif
ifndef LOCAL_DEVELOPER_DIR
LOCAL_DEVELOPER_DIR=/LocalDeveloper
endif
ifndef SYSTEM_LIBRARY_DIR
SYSTEM_LIBRARY_DIR=/NextLibrary
endif

else # Windows and PDO platforms

ifndef USER_APPS_DIR
USER_APPS_DIR=$(HOME)/Apps
endif
ifndef USER_LIBRARY_DIR
USER_LIBRARY_DIR=$(HOME)/Library
endif
ifndef LOCAL_APPS_DIR
LOCAL_APPS_DIR=$(NEXT_ROOT)/Local/Apps
endif
ifndef LOCAL_LIBRARY_DIR
LOCAL_LIBRARY_DIR=$(NEXT_ROOT)/Local/Library
endif
ifndef LOCAL_DEVELOPER_DIR
LOCAL_DEVELOPER_DIR=$(NEXT_ROOT)/Local/Developer
endif

endif
