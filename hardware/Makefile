#
#	Copyright (c) 2023 by Christopher R. Bowman. All rights reserved.
# 	contact: <my initials>@ChrisBowman.com

#
#	This make file is intended to be run via gmake as that is what's 
#	natively available on the Linux systems that would run Vivado
#

OS:=$(shell uname)
ARCH:=$(shell uname -p)
#OS="Linux"

# default target is to build the bit file

bit: axi_ssd.bit

axi_ssd.bit: implementation/my_project/my_project.runs/impl_1/axi_ssd_top_wrapper.bit
	cp implementation/my_project/my_project.runs/impl_1/axi_ssd_top_wrapper.bit axi_ssd.bit

implementation/my_project/my_project.runs/impl_1/axi_ssd_top_wrapper.bit: source/verilog/* source/constraints/*
ifeq ($(OS), Linux)
	mkdir -p implementation
	(cd implementation && vivado -mode tcl -source ../scripts/project.tcl -tclargs --generate_bit)
else
	@echo "this part of the build must happen on a linux box with Vivado installed"
	exit 1
endif

# you can also just build the project so that you can run it in the Vivado GUI
project:
ifeq ($(OS), Linux)
	mkdir -p implementation
	(cd implementation && vivado -mode tcl -source ../scripts/project.tcl)
else
	@echo "this part of the build must happen on a linux box with Vivado installed"
	exit 1
endif
	
ip:
ifeq ($(OS), Linux)
	mkdir -p implementation/ip
	(cd implementation/ip && vivado -mode batch -source ../../scripts/create_ip.tcl)
else
	@echo "this part of the build must happen on a linux box with Vivado installed"
	exit 1
endif

program: axi_ssd.bit
ifeq ($(OS), FreeBSD)
ifeq ($(ARCH), armv7)
	~crb/bin/xbit2bin axi_ssd.bi
else
	@echo "Programming must happen on the target board"
	exit 1
endif
else
	@echo "Programming must happen on the target board"
	exit 1
endif
	
clean:
	rm -rf implementation
	rm -rf axi_ssd.bit

.PHONY: project bit clean program
