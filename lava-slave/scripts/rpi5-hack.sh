rpi5_hack() {
	echo "DEBUG: RPI5 hack start"
	export
	find /var/lib/lava/dispatcher/ | grep raspberrypi5  | grep initrd |
	while read rdpath
	do
		TFTPHOME=/var/lib/lava/dispatcher/tmp/
		echo "DEBUG: found rdpath=$rdpath"
		BASETFTP=$(dirname $rdpath | sed 's,/initrd,,')
		echo "DEBUG: BASETFTP=$BASETFTP"

		dtbpath=$(find $BASETFTP -iname *.dtb)
		echo "DEBUG: DTB is $dtbpath"

		INITRD=$(find $BASETFTP -iname initramfs*)
		echo "DEBUG: INITRD=$INITRD"
		REL_INITRD=$(echo $INITRD | sed "s,$TFTPHOME,,")
		echo "DEBUG: REL_INITRD=$REL_INITRD"

		IMAGE=$(find $BASETFTP -iname Image)
		echo "DEBUG: IMAGE=$IMAGE"
		REL_IMAGE=$(echo $IMAGE | sed "s,$TFTPHOME,,")
		echo "DEBUG: REL_IMAGE=$REL_IMAGE"
		# firmware truncate too long filename
		cp $INITRD $TFTPHOME/

		NBDPORT=0
		TMPF=$(mktemp)
		ss -tlpn |grep nbd-server > "$TMPF"
		while read line
		do
			echo "DEBUG: check $line"
			PID=$(echo $line | grep -o "pid=[0-9]*" | cut -d= -f2)
			echo "DEBUG: PID=$PID"
			ps aux |grep $PID |grep -q raspberrypi5
			if [ $? -ne 0 ];then
				echo "DEBUG: not raspberrypi5 NBD"
				continue
			fi
			NBDPORT=$(echo $line | grep -o "0.0.0.0:[0-9][0-9]*" | cut -d: -f2)
			echo "NBDPORT=$NBDPORT"
		done < $TMPF
		rm "$TMPF"
		if [ $NBDPORT -eq 0 ];then
			echo "ERROR: FAIL to find NBD PORT"
			exit 1
		fi

		echo "
		enable_uart=1
		kernel $REL_IMAGE
		initramfs $(basename $REL_INITRD)
		" > $TFTPHOME/config.txt
		cat $TFTPHOME/config.txt
		cp $dtbpath $TFTPHOME/bcm2712-rpi-5-b.dtb
		# without cmdline, firmware override cmdline
		echo "console=ttyAMA10,115200n8 rw nbd.server=192.168.66.1 nbd.port=$NBDPORT root=/dev/ram0 ramdisk_size=16384 rootdelay=7 ip=dhcp verbose earlyprintk systemd.log_color=false rw systemd.mask=systemd-network-generator.service" > $TFTPHOME/cmdline.txt
	done
}
