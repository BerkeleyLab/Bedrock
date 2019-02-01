/* tap-vpi.c */

/* Larry Doolittle, LBNL */

#include <vpi_user.h>
#include <string.h>   /* strspn() */
#include <assert.h>
#include "ethernet_model.h"

/*
 * VPI (a.k.a. PLI 2) routines for connection to the Universal tun/tap
 * port to/from a Verilog program.
 *
 * $tap_io(out_octet, out_valid, in_octet, in_valid)
 *   in_octet is data received from the tap Ethernet port, sent
 *      to the Verilog program.
 *   out_octet provided by the Verilog program, will be sent to
 *      the tap Ethernet port, once out_valid is low for a cycle.
 *
 * Written according to standards, but so far only tested on
 * Linux with Icarus Verilog.
 */

static PLI_INT32 tap_io_compiletf(char*cd)
{
	vpiHandle sys = vpi_handle(vpiSysTfCall, 0);
	vpiHandle argv = vpi_iterate(vpiArgument, sys);
	vpiHandle arg;
	int i;

	(void) cd;  /* parameter is unused */
	/* Need four arguments */
	for (i=0; i<4; i++) {
		arg = vpi_scan(argv);
		assert(arg);
	}
	return 0;
}

static PLI_INT32 tap_io_calltf(char*cd)
{
	s_vpi_value value;
	int out_octet_val, out_valid_val, in_octet_val=0, in_valid_val=0, thinking_val;

	vpiHandle sys = vpi_handle(vpiSysTfCall, 0);
	vpiHandle argv = vpi_iterate(vpiArgument, sys);
	vpiHandle out_octet, out_valid, in_octet, in_valid, thinking;

	(void) cd;  /* parameter is unused */
	out_octet = vpi_scan(argv); assert(out_octet);
	out_valid = vpi_scan(argv); assert(out_valid);
	in_octet  = vpi_scan(argv); assert(in_octet);
	in_valid  = vpi_scan(argv); assert(in_valid);
	thinking  = vpi_scan(argv); assert(thinking);

	value.format = vpiIntVal;
	vpi_get_value(out_octet, &value);
	out_octet_val = value.value.integer;

	value.format = vpiIntVal;
	vpi_get_value(out_valid, &value);
	out_valid_val = value.value.integer;

	value.format = vpiIntVal;
	vpi_get_value(thinking, &value);
	thinking_val = value.value.integer;

	ethernet_model(out_octet_val, out_valid_val, &in_octet_val, &in_valid_val, thinking_val);

	value.format = vpiIntVal;
	value.value.integer = in_octet_val;
	vpi_put_value(in_octet, &value, 0, vpiNoDelay);

	value.format = vpiIntVal;
	value.value.integer = in_valid_val;
	vpi_put_value(in_valid, &value, 0, vpiNoDelay);

	return 0;
}

static void sys_tap_io_register(void)
{
	s_vpi_systf_data tf_data;

	tf_data.type      = vpiSysTask;
	tf_data.tfname    = "$tap_io";
	tf_data.calltf    = tap_io_calltf;
	tf_data.compiletf = tap_io_compiletf;
	tf_data.sizetf    = 0;
	tf_data.user_data = strdup("$tap_io");
	vpi_register_systf(&tf_data);
}

void (*vlog_startup_routines[])(void) = {
	sys_tap_io_register,
	0
};
