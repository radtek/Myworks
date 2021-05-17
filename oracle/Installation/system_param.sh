#!/bin/bash
SYSCTLL=`cat /etc/sysctl.conf | grep -v '#' | wc -l`

if [ $SYSCTLL == '0' ]; then
echo "Adding system parameters..."

SHMS=`grep MemTotal /proc/meminfo | awk '{print $2*1024*0.7}'`
SHMMAX=`printf %0.f $SHMS`
SHMMNI=4096

cat << EOF >> /etc/sysctl.conf
fs.aio-max-nr = 1048576
fs.file-max = 6815744
kernel.sem = 250 32000 100 128
net.ipv4.ip_local_port_range = 9000 65500
net.core.rmem_default = 262144
net.core.rmem_max = 4194304
net.core.wmem_default = 262144
net.core.wmem_max = 1048586
kernel.sysrq=1
kernel.randomize_va_space=0
vm.min_free_kbytes=524288
kernel.shmmni = $SHMMNI
kernel.shmmax = $SHMMAX
kernel.shmall = $[$SHMMAX/$SHMMNI]
EOF

ERRORMSG=`sysctl -p 2>&1`
	if [ $? -eq 0 ]; then
		echo "sysctl.conf add some values.. OK"
	else
		echo $ERRORMSG 1>&2
	fi

else 
	echo "sysctl.conf has some values.. "
fi

PAM=`cat /etc/pam.d/login | grep -E 'session.*required.*pam_limits.so'`
if [ $? -eq 1 ]; then
echo "Insert session pam limit option.. OK"

cat << EOF >> /etc/pam.d/login

session    required     pam_limits.so
EOF
else 
echo "pam alerady has limit option.. "
fi

ORAUSER=`grep 1001 /etc/passwd | awk -F : '{print $1 }'`
echo "Check limits.conf file..."
grep $ORAUSER /etc/security/limits.conf | grep -v '#' | grep -E 'hard.*nofile'\|'soft.*stack'
if [ $? -eq 1 ]; then
cat << EOF >> /etc/security/limits.conf
$ORAUSER    hard    nofile          65536
$ORAUSER    soft    stack           10240
EOF
echo "Inserted stack/nofile set... OK"
else
if grep $ORAUSER /etc/security/limits.conf | grep -v '#' | grep -E 'hard.*nofile'; then
    echo ""
else
echo "$ORAUSER    hard    nofile          65536" >> /etc/security/limits.conf
echo "Inserted nofile set... OK"
fi
if grep $ORAUSER /etc/security/limits.conf | grep -v '#' | grep -E 'soft.*stack'; then
    echo ""
else
echo "$ORAUSER    soft    stack           10240" >> /etc/security/limits.conf
echo "Inserted stack set... OK"
fi
fi

IPCOPT=`grep RemoveIPC /etc/systemd/logind.conf | grep -v '#'`
if [ $? -eq 1 ]; then
cat << EOF >> /etc/systemd/logind.conf


### ORACLE Environment ## DO NOT DELETE IPC OPTION #######
RemoveIPC=no
EOF
echo "Inserted RemoveIPC option.. OK"
else 
	echo "Already Setted : $IPCOPT"
fi

AHP=`grep AnonHugePages /proc/meminfo | awk '{print $2}'`
if [ $AHP == '0' ]; then
	echo "AnonHugePages not setted.. OK"
else
GRUBCL=`grep transparent_hugepage=never /etc/default/grub | wc -l`
if [ $GRUBCL == '0' ]; then 
sed -i 's/quiet\"/quiet transparent_hugepage=never\"/' /etc/default/grub
	if [ $? -eq 0 ]; then
		if [ -d /sys/firmware/efi ]; then
			`grub2-mkconfig -o /boot/efi/EFI/redhat/grub.cfg`
		else
			`grub2-mkconfig -o /boot/grub2/grub.cfg`
		fi
		if [ $? -eq 0 ]; then
			echo "mkconfig Done! .. OK"
		else 
			echo "mkconfig failed!"
		fi
	else 
		echo "replace string tansparent_hugepage=never failed!"
	fi
fi
echo "grub.cfg already setted!"
    if [ -d /sys/firmware/efi ]; then
        cat /boot/efi/EFI/redhat/grub.cfg | grep transparent_hugepage
    else
        cat /boot/grub2/grub.cfg | grep transparent_hugepage
    fi
fi
