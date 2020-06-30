sysv_scripts := $(wildcard rc.*)
sysv_install := /etc/rc.d

sysd_scripts := $(wildcard rc-*)
sysd_install := /etc/systemd/system

errormessage := "access denied, (missing sudo?)"

all :
	echo "usage: sudo make <install|uninstall>"

test : $(sysv_install) $(sysd_install)
	test -w $(sysv_install) || (echo $(errormessage) 1>&2; exit 1)
	test -w $(sysd_install) || (echo $(errormessage) 1>&2; exit 1)

install : test
	for i in $(sysv_scripts); do cp -vf $$i $(sysv_install)/$$i; done
	for i in $(sysd_scripts); do cp -vf $$i $(sysd_install)/$$i; done
	for i in $(sysd_scripts); do systemctl enable $$i; done

uninstall : test
	for i in $(sysd_scripts); do systemctl disable $$i; done
	for i in $(sysd_scripts); do rm -vf $(sysd_install)/$$i; done
	for i in $(sysv_scripts); do rm -vf $(sysv_install)/$$i; done

.PHONY .SILENT : all test install uninstall
