/*-
 * SPDX-License-Identifier: BSD-2-Clause-FreeBSD
 *
 * Copyright (c) 2022 Milan Obuch
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS'' AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED.  IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE LIABLE
 * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
 * OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 * LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
 * OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
 * SUCH DAMAGE.
 *
 * $FreeBSD$
 */

/*
 * Simple driver for dual seven segment display with multiplex in hardware
 *
 */

/*
 * KLD ssd
 * Copyright (c) 2022 Christopher R. Bowman
 * All rghts reserved
 */

#include <sys/cdefs.h>
__FBSDID("$FreeBSD$");

#include <sys/param.h>
#include <sys/systm.h>
#include <sys/conf.h>
#include <sys/kernel.h>
#include <sys/malloc.h>
#include <sys/module.h>
#include <sys/bus.h>
#include <machine/bus.h>
#include <sys/rman.h>
#include <sys/sysctl.h>
#include <machine/resource.h>
#include <machine/cpu.h>
#include <sys/timeet.h>
#include <sys/systm.h>  /* uprintf */

#include <dev/fdt/fdt_common.h>
#include <dev/ofw/openfirm.h>
#include <dev/ofw/ofw_bus.h>
#include <dev/ofw/ofw_bus_subr.h>

#define AXI_MM_SSD_LOCK(sc)		mtx_lock(&(sc)->sc_mtx)
#define	AXI_MM_SSD_UNLOCK(sc)		mtx_unlock(&(sc)->sc_mtx)
#define AXI_MM_SSD_LOCK_INIT(sc) \
	mtx_init(&(sc)->sc_mtx, device_get_nameunit((sc)->dev),	\
	    "axi2x7sd", MTX_DEF)
#define AXI_MM_SSD_LOCK_DESTROY(_sc)	mtx_destroy(&_sc->sc_mtx);

#define WR4(sc, off, val)	bus_write_4((sc)->mem_res, (off), (val))
#define RD4(sc, off)		bus_read_4((sc)->mem_res, (off))

/* Hardware driver registers */

#define	AXI_MM_SSD_SGN		0x0000		/* Signature register */
#define	AXI_MM_SSD_SR1		0x0004		/* Segment register 1 */
#define	AXI_MM_SSD_SR2		0x0008		/* Segment register 2 */
#define	AXI_MM_SSD_DUMMY	0x000c		/* unused register */

static devclass_t ssd_devclass;

struct ssd_softc {
	device_t	dev;
	struct mtx	sc_mtx;
	struct resource *mem_res;	/* register base address */
};

static int
axi_mm_ssd_proc0(SYSCTL_HANDLER_ARGS)
{
	int error;
static	int32_t value0 = 1;
	struct ssd_softc *sc;

	sc = (struct ssd_softc *)arg1;

	AXI_MM_SSD_LOCK(sc);

	value0 = RD4(sc, AXI_MM_SSD_SR2);

	AXI_MM_SSD_UNLOCK(sc);

	error = sysctl_handle_int(oidp, &value0, sizeof(value0), req);
	if (error != 0 || req->newptr == NULL)
		return (error);

	WR4(sc, AXI_MM_SSD_SR2, value0);

	return (0);
}

static int
axi_mm_ssd_proc1(SYSCTL_HANDLER_ARGS)
{
	int error;
static	int32_t value1 = 0x10;
	struct ssd_softc *sc;

	sc = (struct ssd_softc *)arg1;

	AXI_MM_SSD_LOCK(sc);

	value1 = RD4(sc, AXI_MM_SSD_SR1);

	AXI_MM_SSD_UNLOCK(sc);

	error = sysctl_handle_int(oidp, &value1, sizeof(value1), req);
	if (error != 0 || req->newptr == NULL)
		return (error);

	WR4(sc, AXI_MM_SSD_SR1, value1);

	return (0);
}

static void
axi_mm_ssd_sysctl_init(struct ssd_softc *sc)
{
	struct sysctl_ctx_list *ctx;
	struct sysctl_oid *tree_node;
	struct sysctl_oid_list *tree;

	/*
	 * Add per-position sysctl tree/handlers.
	 */
	ctx = device_get_sysctl_ctx(sc->dev);
	tree_node = device_get_sysctl_tree(sc->dev);
	tree = SYSCTL_CHILDREN(tree_node);

	SYSCTL_ADD_PROC(ctx, tree, OID_AUTO, "ones",
	    CTLFLAG_RW | CTLTYPE_UINT, sc, 0,
	    axi_mm_ssd_proc0, "IU", "ones position segments");

	SYSCTL_ADD_PROC(ctx, tree, OID_AUTO, "tens",
	    CTLFLAG_RW | CTLTYPE_UINT, sc, 0,
	    axi_mm_ssd_proc1, "IU", "tens position segments");
}



static int
ssd_probe(device_t dev)
{


//	device_printf(dev, "probe of ssd\n");
	if (!ofw_bus_status_okay(dev))
		return (ENXIO);

	if (!ofw_bus_is_compatible(dev, "crb,ssd-1.0")){
#ifdef PROBEDEBUG
		phandle_t node;
		if ((node = ofw_bus_get_node(dev)) == -1)
			return (ENXIO);
		size_t len;
		if ((len = OF_getproplen(node, "compatible")) <= 0)
			return (ENXIO);
#define	OFW_COMPAT_LEN	255
		char compat[OFW_COMPAT_LEN];
		bzero(compat, OFW_COMPAT_LEN);

		if (OF_getprop(node, "compatible", compat, OFW_COMPAT_LEN) < 0)
			return (ENXIO);

		int l;
		char *my_compat;
		my_compat = compat;
		while (len > 0) {
			device_printf(dev, "compat string: %s\n", my_compat);

			/* Slide to the next sub-string. */
			l = strlen(my_compat) + 1;
			my_compat += l;
			len -= l;
		}
#endif
		return (ENXIO);
	}
		
	//device_printf(dev, "matched ssd\n");
	device_set_desc(dev, "AXI MM seven segment display");
	return (BUS_PROBE_DEFAULT);
}

static int
ssd_detach(device_t dev)
{
	struct ssd_softc *sc = device_get_softc(dev);

	if (sc->mem_res != NULL) {
		/* Release memory resource. */
		bus_release_resource(dev, SYS_RES_MEMORY,
				     rman_get_rid(sc->mem_res), sc->mem_res);
	}

	AXI_MM_SSD_LOCK_DESTROY(sc);

	return (0);
}

static int
ssd_attach(device_t dev)
{
	struct ssd_softc *sc;

	device_printf(dev, "attaching ssd\n");
	sc = device_get_softc(dev);
	sc->dev = dev;

	int rid;

	AXI_MM_SSD_LOCK_INIT(sc);

	/* Allocate memory. */
	rid = 0;
	sc->mem_res = bus_alloc_resource_any(dev,
		     SYS_RES_MEMORY, &rid, RF_ACTIVE);
	if (sc->mem_res == NULL) {
		device_printf(dev, "Can't allocate memory for device\n");
		ssd_detach(dev);
		return (ENOMEM);
	}
#define MAGIC_SIGNATURE 0xFEEDFACE
#ifdef CHECKMAGIC
int32_t value = RD4(sc, AXI_MM_SSD_SGN);
	if (value != MAGIC_SIGNATURE) {
		device_printf(dev, "MAGIC_SIGNATURE 0xFEEDFACE not found! value = %x\n", value);
		ssd_detach(dev);
		return (ENXIO);
	}
#endif
	axi_mm_ssd_sysctl_init(sc);
	device_printf(dev, "ssd attached\n");

	return (0);

}

static device_method_t ssd_methods[] = {
	  /* Device interface */
	  DEVMETHOD(device_probe,	ssd_probe),
	  DEVMETHOD(device_attach,	ssd_attach),
	  DEVMETHOD(device_suspend,	bus_generic_suspend),
	  DEVMETHOD(device_resume,	bus_generic_resume),
	  DEVMETHOD(device_shutdown,	bus_generic_shutdown),
	  {0, 0}
};
 
static driver_t ssd_driver = {
	  "ssd",
	  ssd_methods,
	  sizeof(struct ssd_softc)
};
 
DRIVER_MODULE(ssd, simplebus, ssd_driver, ssd_devclass, 0, 0);
