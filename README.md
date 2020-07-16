# bootsync

Keep ESP synchronized on mirrored-disk systems

# Requirements

- UEFI

# Dependencies

- bash
- systemd
- efibootmgr
- rsync
- coreutils (ln)
- util-linux (mountpoint, findmnt)

# Installation

These scripts expect that the ESPs to be kept synchronized are mounted to directories named /boot.? where the question mark (?) is a single character that is unique to each ESP. The distinguishing character could, for example, correlate with the lettering of the corresponding SCSI disk device nodes that the ESPs are stored on (i.e. /dev/sda1 -> /boot.a, /dev/sdb1 -> /boot.b, etc.). Setting up such a correlation is just a recommendation. Only the pattern for the directory name matters. Where the /boot.? directories actually mount from is irrelevant to the scripts.

The /boot.? mount points are expected to be  available early in the system start up process. This is usually accomplished by listing the mounts in the /etc/fstab system configuration file. Your /etc/fstab file might contain lines like the following for example:

    PARTLABEL=boot.a /boot.a vfat umask=0077,shortname=lower,nofail 0 0
    PARTLABEL=boot.b /boot.b vfat umask=0077,shortname=lower,nofail 0 0

There should not exist a *directory* named /boot. Instead, these scripts will maintain a *symlink* named /boot that will be set to point to whichever ESP is currently being used on system start up. You can disable the rc-booklink systemd service and maintain the link yourself if you wish, but /boot must be a symlink, not a directory.

Once the mount points are configured as the scripts expect, the scripts can be copied into place and enabled. A makefile is provide to automate the installation process. To install the scripts using the makefile, run the following command while in the root of the git repository:

    $ sudo make install

# How it works

This software consists of two Bash scripts and two corresponding systemd services that call them on system start up. The scripts are quite short and simple. In the end, all the scripts do is call [rsync](https://en.wikipedia.org/wiki/Rsync) to copy the data from the active ESP to all other ESPs. The slightly complex part is in figuring out which is the ESP that the system is using and in performing a few safety checks to make sure a newer ESP (one containing a newer kernel) is not overwritten with the contents of an older ESP.

The Bash scripts are stored in /etc/rc.d. One is named rc.bootlink. It creates and updates the /boot symlink. The other is named rc.bootsync. It calls rsync after performing a few basic safety checks. The Bash scripts can be run manually with sudo. They do not take any parameters. In fact, I recommend running them manually once right after they are installed to be sure that they are working properly. I also recommend making a backup of your ESP before running them for the first time just to be safe.

# SELinux

To work with selinux, you will also need to compile and install the supplied bootsync.te rules. Commands similar to the following should get the job done:

```
$ cp -v bootsync.te /tmp
$ make -C /tmp -f /usr/share/selinux/devel/Makefile bootsync.pp
$ sudo semodule -X 300 -i /tmp/bootsync.pp
```

The following selinux context rule may also be helpful:

```
$ sudo semanage fcontext -a -t boot_t "/boot\.(a|b)(/.*)?"
```

I will attempt to integrate the above selinux configuration into the Makefile in a future revision of to this respository.

# Final notes

I use these scripts on Fedora systems (Workstation edition, not Silverblue) where I have my ESPs mounted to /boot.{a,b} and these partitions contain both the bootloader ([systemd-boot](https://www.freedesktop.org/wiki/Software/systemd/systemd-boot/)) and the kernel+initramfs. This configuration is recommended by the [Boot Loader Specification](https://systemd.io/BOOT_LOADER_SPECIFICATION/) which is part of the systemd project.

The GRUB bootloader is known to have problems with this configuration because it attempts to put a symlink below /boot. I have not tested these scripts with GRUB and I do not expect that they will work (properly) with GRUB. Feel free to try and get this to work with GRUB if you like, but my personal recommendation is to switch to using systemd-boot if possible. Please do not send pull requests to integrate GRUB compatibility features. I want to keep these scripts as simple as possible (no GRUB hacks please).

# Disclaimer

This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU Lesser General Public License for more details.
