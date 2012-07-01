BUILDDIR = $(CURDIR)/build
C74SUPPORT = ../../../c74support
MAX_INCLUDES = $(C74SUPPORT)/max-includes
OBJECT_LIST = o.atomize o.change o.collect o.cond o.dict o.difference o.explode o.expr o.flatten o.if \
o.intersection o.mappatch o.message o.pack o.pak o.prepend o.print o.printbytes o.route o.select o.union \
o.unless o.var o.when
MAC_OBJECTS = $(foreach OBJ, $(OBJECT_LIST), $(BUILDDIR)/$(OBJ).mxo)
WIN_OBJECTS = $(foreach OBJ, $(OBJECT_LIST), $(BUILDDIR)/$(OBJ).mxe)
ifeq (win, $(findstring win, $(MAKECMDGOALS)))
	CC = $(WIN_CC)
	CFLAGS = $(WIN_CFLAGS)
	INCLUDES = $(WIN_INCLUDES)
	LIBS = $(WIN_LIBS)
	LDFLAGS = $(WIN_LDFLAGS)
	OBJECTS = $(WIN_OBJECTS)
else 
	OBJECTS = $(MAC_OBJECTS)
endif
VPATH = $(OBJECT_LIST)

VERSION = $(shell perl -p -e 'if(/\#define\s+ODOT_VERSION\s+\"(.*)\"/){print $$1; last;}' odot_version.h)
OS = $(shell perl -e 'print $$^O')
RELEASEDIR = odot-$(strip $(OS))-$(strip $(VERSION))
ARCHIVE = odot-$(strip $(OS)).tgz
VERSION_FILE = current-$(strip $(OS))-version

RELEASE_OBJECTS_DIR = $(RELEASEDIR)/objects

PATCHES_FOR_RELEASE = $(addprefix patches/, help demos abstractions deprecated overview)
TEXTFILES_FOR_RELEASE = README_ODOT.txt

SERVER_PATH = /home/www-data/berkeley.edu-cnmat.www/maxdl/files/odot/

WIN_CC = gcc
WIN_CFLAGS = -DWIN_VERSION -DWIN_EXT_VERSION -U__STRICT_ANSI__ -U__ANSI_SOURCE -std=c99
WIN_INCLUDES = -I$(MAX_INCLUDES) -Ilibo -Ilibomax
WIN_LIBS = -Llibomax -lomax -L$(MAX_INCLUDES) -lMaxAPI -Llibo -lo
WIN_LDFLAGS = -shared -static-libgcc

ifeq ($(strip $(CNMAT_MAX_INSTALL_DIR)),)
	INSTALLDIR = ~/odot
else
	INSTALLDIR = $(CNMAT_MAX_INSTALL_DIR)/odot
endif

all: debug
	xcodebuild -scheme "Build all" -configuration Release -project odot.xcodeproj build

release: $(ARCHIVE)

win: $(OBJECTS)

win-release: $(ARCHIVE)

win-install: install

win-upload: upload

$(BUILDDIR)/commonsyms.o: 
	$(CC) $(CFLAGS) $(INCLUDES) -c -o $(BUILDDIR)/commonsyms.o $(MAX_INCLUDES)/common/commonsyms.c

$(BUILDDIR)/%.mxe: %.c $(BUILDDIR) $(BUILDDIR)/commonsyms.o
	$(CC) $(CFLAGS) $(INCLUDES) -c -o $(BUILDDIR)/$*.o $<
	$(CC) $(LDFLAGS) -o $(BUILDDIR)/$*.mxe $(BUILDDIR)/$*.o $(BUILDDIR)/commonsyms.o $(LIBS) 

$(BUILDDIR)/%.mxo:
	xcodebuild -target $* -configuration Release -project odot.xcodeproj build

$(BUILDDIR):
	@[ -d $(BUILDDIR) ] || mkdir -p $(BUILDDIR)

$(RELEASEDIR): $(BUILDDIR)
	@[ -d $(RELEASEDIR) ] || mkdir -p $(RELEASEDIR)

$(INSTALLDIR):
	@[ -d $(INSTALLDIR) ] || mkdir -p $(INSTALLDIR)

$(RELEASE_OBJECTS_DIR): $(RELEASEDIR)
	@[ -d $(RELEASE_OBJECTS_DIR) ] || mkdir -p $(RELEASE_OBJECTS_DIR)

$(ARCHIVE): $(OBJECTS) $(RELEASEDIR) $(RELEASE_PATCHES_DIR) $(RELEASE_OBJECTS_DIR)
	@echo copying objects
	@cp -r $(OBJECTS) $(RELEASE_OBJECTS_DIR)
	@echo copying patches
	@rsync -avq --exclude=*/.* $(PATCHES_FOR_RELEASE) $(RELEASEDIR)
	@echo copying extra files
	@cp $(TEXTFILES_FOR_RELEASE) $(RELEASEDIR)
	@echo compressing
	@tar zcf $(RELEASEDIR).tgz $(RELEASEDIR)
	@cp $(RELEASEDIR).tgz $(ARCHIVE)
	@echo $(VERSION) > $(VERSION_FILE)
	@echo done

install: $(ARCHIVE) $(INSTALLDIR)
	cp -r $(RELEASEDIR)/* $(INSTALLDIR)

upload: $(ARCHIVE)
	scp $(RELEASEDIR).tgz $(ARCHIVE) $(VERSION_FILE) cnmat.berkeley.edu:/$(SERVER_PATH)

.PHONY: clean
clean: 
	rm -rf $(BUILDDIR)
	rm -rf $(RELEASEDIR)
	rm -rf $(ARCHIVE)
#./package.pl clean
#	for d in $(OBJECT_LIST); do (cd $$d; $(MAKE) clean); done
#xcodebuild -project odot.xcodeproj clean

# package: 
# 	./package.pl

# archive:
# 	./package.pl archive

# DOCUMENTS:
# 	$(foreach t, $(TEXTFILES), cp $(t) $(BUILDDIR))

# .PHONY: install
# install:
# 	./package.pl install $(CNMAT_MAX_INSTALL_DIR)

# release:
# 	rm -f build/$(ARCHIVE)
# 	cd build && tar -zcf $(ARCHIVE) *
# 	@read -p "Username: " UN; \
# 	scp build/$(ARCHIVE) $$UN@cnmat.berkeley.edu:$(SERVER_PATH)

# unstable:
# 	rm -f build/$(UNSTABLE)
# 	cd build && tar -zcvf $(UNSTABLE) *
# 	@read -p "Username: " UN;\
# 	scp build/$(UNSTABLE) $$UN@cnmat.berkeley.edu:$(SERVER_PATH)

# win-release:
# 	rm -f build/$(WIN-RELEASE)
# 	cd build && tar -zcvf $(WIN-RELEASE) *
# 	@read 0p "Username: " UN;\
# 	scp build/$(WIN-RELEASE) $$UN@cnmat.berkeley.edu:$(SERVER_PATH)
