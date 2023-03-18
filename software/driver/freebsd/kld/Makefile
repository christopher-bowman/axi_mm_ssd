#
# Copyright (c) 2022 by Christopher R. Bowman. All rights reserved.
# contact: <my initials>@ChrisBowman.com
#

# Note: device_if.h bus_if.h and pci_if.h
# are all created by the build system but only
# if you add them to the SRCS dependencies

# SRCS=axi_2x7sd.c device_if.h bus_if.h ofw_bus_if.h
# KMOD=axi_2x7sd
SRCS=ssd.c device_if.h bus_if.h ofw_bus_if.h
KMOD=ssd

DTC=/usr/bin/dtc

artyz7_ssd_overlay.dtb: artyz7_ssd_overlay.dts
	${DTC} -I dts -O dtb -o artyz7_ssd_overlay.dtb artyz7_ssd_overlay.dts 

# note make sure your .dts file uses /include/ not #include
zynq-artyz7.dtb: zynq-7000.dtsi zynq-artyz7.dts
	${DTC} -@ -i . -I dts -O dtb -o zynq-artyz7.dtb zynq-artyz7.dts

load:
	kldload ./ssd.ko

unload:
	kldunload ssd.ko

program:
	~crb/bin/xbit2bin ../../../../hardware/axi_ssd.bit

stat:
	kldstat

.include <bsd.kmod.mk>
