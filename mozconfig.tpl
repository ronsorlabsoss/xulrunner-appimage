mk_add_options AUTOCLOBBER=1
mk_add_options MOZ_OBJDIR=/root/build

ac_add_options --enable-application=APPLICATION

ac_add_options --enable-optimize="-O2"
ac_add_options --enable-default-toolkit=cairo-gtk2
ac_add_options --enable-jemalloc
#ifndef NO_STRIP
ac_add_options --enable-strip
#endif
ac_add_options --with-pthreads

#ifdef DEBUG
ac_add_options --enable-debug-symbols
#endif

ac_add_options --disable-tests
#ifndef NO_EME
ac_add_options --enable-eme
#else
ac_add_options --disable-eme
#endif

ac_add_options --disable-parental-controls
ac_add_options --disable-accessibility
#ifndef NO_WEBRTC
ac_add_options --enable-webrtc
#else
ac_add_options --disable-webrtc
#endif

ac_add_options --disable-dbus
ac_add_options --disable-gamepad
ac_add_options --disable-necko-wifi
ac_add_options --disable-updater
ac_add_options --disable-gconf
ac_add_options --disable-safe-browsing
ac_add_options --enable-alsa
ac_add_options --disable-pulseaudio
