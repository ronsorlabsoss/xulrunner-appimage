SESSION_ID := $(shell echo $$$$)-$(shell date +%s)

UBUNTU_DISTRO := xenial # also supported: bionic (trusty doesn't work: "GCC version too old: expected 4.9, got 4.8.3")
UBUNTU_MIRROR := http://us.archive.ubuntu.com/ubuntu/
TARGET_ARCH := amd64
HOST_ARCH := amd64
DEVROOT = build/devroot-$(TARGET_ARCH)-x-$(HOST_ARCH)/

UXP_APP := xulrunner
UXP_APP_PATH = $(DEVROOT)/root/build/application/$(UXP_APP)/app/$(UXP_APP)

DEBOOTSTRAP := debootstrap
MOZCONFIG_TPL := mozconfig.tpl
MOZCONFIG_FLAGS := -DAPPLICATION=$(UXP_APP)

HOST_PKG     := python python2.7 yasm autoconf2.13 build-essential zip unzip
TARGET_PKG   := libgtk2.0-dev libdbus-glib-1-dev libegl1-mesa-dev libasound2-dev \
		libxt-dev zlib1g-dev libssl-dev libsqlite3-dev libbz2-dev

UXP_TGZ := uxp/uxp-2019-06-12.tgz

APPIMAGETOOL := appimagetool
ifneq ($(TARGET_ARCH),$(HOST_ARCH))
  APPIMAGETOOL_ARGS = -runtime runtime-$(TARGET_ARCH)
endif

DESKTOP_TPL := app.desktop.tpl
APPRUN_TPL := AppRun.tpl

all: $(DEVROOT) $(DEVROOT)/opt/.stamp $(DEVROOT)/root/UXP-master/.mozconfig build/package.tar.bz2 build/$(UXP_APP).AppImage

$(DEVROOT):
	mkdir -p build
	$(DEBOOTSTRAP) --arch $(HOST_ARCH) $(UBUNTU_DISTRO) $(DEVROOT) || { rm -rf $(DEVROOT); exit 1; }
	cp /proc/cpuinfo /proc/meminfo $(DEVROOT)/proc

$(DEVROOT)/opt/:
	mkdir -p $(DEVROOT)/opt/

$(DEVROOT)/opt/mozconfig: $(DEVROOT)/opt/
	gpp $(MOZCONFIG_TPL) $(MOZCONFIG_FLAGS) > $@

$(DEVROOT)/opt/bootstrap.sh: $(DEVROOT)/opt/
	cp devroot-bootstrap.sh $@

$(DEVROOT)/opt/.stamp: $(DEVROOT)/opt/mozconfig $(DEVROOT)/opt/bootstrap.sh
	env TARGET_PACKAGES="$(TARGET_PKG)" HOST_PACKAGES="$(HOST_PKG)" DISTRO="$(UBUNTU_DISTRO)" IN_CHROOT=1 \
	    chroot $(DEVROOT) /opt/bootstrap.sh
	touch $(DEVROOT)/opt/.stamp

$(DEVROOT)/root/UXP-master/.stamp: $(DEVROOT)
	cd $(DEVROOT)/root; tar -xzf $(abspath $(UXP_TGZ))
	touch $(DEVROOT)/root/UXP-master/.stamp

$(DEVROOT)/root/UXP-master/.mozconfig: $(DEVROOT)/root/UXP-master/.stamp
	cp $(DEVROOT)/opt/mozconfig $(DEVROOT)/root/UXP-master/.mozconfig

$(UXP_APP_PATH): $(DEVROOT)/opt/.stamp $(DEVROOT)/root/UXP-master/.mozconfig
	chroot $(DEVROOT) bash -c "cd /root/UXP-master; ./mach build"

$(DEVROOT)/root/package.tar.bz2: $(UXP_APP_PATH)
ifeq ($(UXP_APP),xulrunner) # XulRunner doesn't support mach package for some reason; just do it ourselves
	chroot $(DEVROOT) bash -c "cd /root/build/dist/bin; tar -hcvjf /root/package.tar.bz2 ."
else
	chroot $(DEVROOT) bash -c "cd /root/UXP-master; ./mach package"
endif
	echo "Final tar-bzipped archive: $(DEVROOT)/root/package.tar.bz2"

build/package.tar.bz2: $(DEVROOT)/root/package.tar.bz2
	ln -s $(abspath $(DEVROOT)/root/package.tar.bz2) build/package.tar.bz2

build/$(UXP_APP).AppImage: build/package.tar.bz2 $(APPRUN_TPL) $(DESKTOP_TPL)
	{ mkdir /tmp/$(SESSION_ID) && tar -xj -C /tmp/$(SESSION_ID) -f build/package.tar.bz2 && \
	gpp $(DESKTOP_TPL) -DAPPLICATION=$(UXP_APP) > /tmp/$(SESSION_ID)/$(UXP_APP).desktop && \
	touch /tmp/$(SESSION_ID)/$(UXP_APP).png && \
	gpp $(APPRUN_TPL) -DAPPLICATION=$(UXP_APP) > /tmp/$(SESSION_ID)/AppRun && \
	chmod +x /tmp/$(SESSION_ID)/AppRun && \
	$(APPIMAGETOOL) /tmp/$(SESSION_ID) $(abspath $@); \
	rm -r /tmp/$(SESSION_ID); } || \
	{ rm -rf /tmp/$(SESSION_ID); exit 1; }

session-id:
	@echo $(SESSION_ID)

clean:
	rm -rf $(DEVROOT)/root/UXP-master $(DEVROOT)/root/build build/$(UXP_APP).AppImage build/package.tar.bz2

nuke: clean
	rm -rf $(DEVROOT)
