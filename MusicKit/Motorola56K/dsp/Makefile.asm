# Make file for assembly language directories smsrc, apsrc, ugsrc, umsrc.
# 
# The local Makefile which includes this one must define the following:
#
# NAME = <local directory name, e.g. "smsrc", "apsrc", "ugsrc", or "umsrc">
# SRCS = <all source files, e.g. "foo.asm bar.asm test/foo.asm test/tbar.asm">
#
# 04/12/89/jos - Added Makefile to installsrc
#
include ../Makefile.config

# install flags
IFLAGS = -q -c

INSTALL_FILES = $(SRCS)

all:  $(OTHER_ALL)

INSTALLSRC_SRCS = Makefile $(INSTALL_FILES)

typ_installsrc:: $(SOURCE_DIR)/$(NAME) $(SOURCE_DIR)/$(NAME)/test
	tar cf - $(INSTALLSRC_SRCS) | (cd $(SOURCE_DIR)/$(NAME); tar xfp -)
	(cd $(SOURCE_DIR)/$(NAME); chmod 644 $(INSTALLSRC_SRCS))

installhdrs::
	echo "No headers in asm source" > /dev/null

installsrc:: typ_installsrc $(OTHER_INSTALLSRC)

typ_install:: $(DSP_INSTALL_ROOT)/$(NAME)
	tar cf - $(INSTALL_FILES) | (cd $(DSP_INSTALL_ROOT)/$(NAME); \
		tar xfp -)
	(cd $(DSP_INSTALL_ROOT)/$(NAME); chmod 644 $(INSTALL_FILES))

install ccrma_install:: typ_install $(OTHER_INSTALLS)

# To get this, set MANPAGES and add install_man_pages to OTHER_INSTALLS
install_man_pages: $(MANPAGES) $(MAN_DIR)/$(NAME)
	tar cf - $(MANPAGES) | (cd $(MAN_DIR)/$(NAME); tar xfp -)
	(cd $(MAN_DIR)/$(NAME); chmod 644 $(MANPAGES))
	
local_install:: $(OTHER_LOCAL_INSTALLS)

clean::  lean

lean:
	/bin/rm -f *.lod *.lst *.dsp *.img *.o test_* $(OTHER_LEANS)

