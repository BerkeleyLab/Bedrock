/* udp-vpi.c */

/* Larry Doolittle, LBNL */

#include <vpi_user.h>
#include <sys/ioctl.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <arpa/inet.h>
#include <sys/stat.h>
#include <string.h>   /* strspn() */
#include <stdlib.h>   /* exit() */
#include <stdio.h>    /* snprintf() */
#include <unistd.h>   /* read() and write() */
#include <time.h>     /* nanosleep() */
#include <fcntl.h>
#include <assert.h>
#include <errno.h>
#include <stdint.h>

#include "udp_model.h"
unsigned short udp_port;
int badger_client;

/*
 * VPI (a.k.a. PLI 2) routines for connection to a UDP
 * port to/from a Verilog program.
 *
 * $udp_init(udp_port, badger_client);
 *   badger_client: Selects between badger-client interface (1)
                    as described in badger/clients.eps and
                    raw bytes+strobe interface (0).
 * $udp_in(in_octet, in_valid, in_count, thinking);
 *   in_octet: data received from the UDP port, sent
 *             to the Verilog program.
 * $udp_out(out_octet, out_end);
 *   out_octet: provided by the Verilog program; will be sent to
 *              the UDP port once out_valid is low for a cycle.
 *
 * Written according to standards, but so far only tested on
 * Linux with Icarus Verilog.
 */

static PLI_INT32 udp_in_compiletf(char*cd)
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

static PLI_INT32 udp_in_calltf(char*cd)
{
	s_vpi_value value;
	int in_octet_val=0, in_valid_val=0, in_count_val, thinking_val;

	vpiHandle sys = vpi_handle(vpiSysTfCall, 0);
	vpiHandle argv = vpi_iterate(vpiArgument, sys);
	vpiHandle in_octet, in_valid, in_count, thinking;
	(void) cd;  /* parameter is unused */

	in_octet  = vpi_scan(argv); assert(in_octet);
	in_valid  = vpi_scan(argv); assert(in_valid);
	in_count  = vpi_scan(argv); assert(in_count);
	thinking  = vpi_scan(argv); assert(thinking);

	value.format = vpiIntVal;
	vpi_get_value(thinking, &value);
	thinking_val = value.value.integer;

	udp_receiver(&in_octet_val, &in_valid_val, &in_count_val, thinking_val);

	value.format = vpiIntVal;
	value.value.integer = in_octet_val;
	vpi_put_value(in_octet, &value, 0, vpiNoDelay);

	value.format = vpiIntVal;
	value.value.integer = in_valid_val;
	vpi_put_value(in_valid, &value, 0, vpiNoDelay);

	value.format = vpiIntVal;
	value.value.integer = in_count_val;
	vpi_put_value(in_count, &value, 0, vpiNoDelay);

	return 0;
}

static PLI_INT32 udp_out_compiletf(char*cd)
{
	vpiHandle sys = vpi_handle(vpiSysTfCall, 0);
	vpiHandle argv = vpi_iterate(vpiArgument, sys);
	vpiHandle arg;
	int i;

	(void) cd;  /* parameter is unused */
	/* Need two arguments */
	for (i=0; i<2; i++) {
		arg = vpi_scan(argv);
		assert(arg);
	}
	return 0;
}

static PLI_INT32 udp_out_calltf(char*cd)
{
	s_vpi_value value;
	int out_octet_val, out_end_val;

	vpiHandle sys = vpi_handle(vpiSysTfCall, 0);
	vpiHandle argv = vpi_iterate(vpiArgument, sys);
	vpiHandle out_octet, out_end;
	(void) cd;  /* parameter is unused */

	out_octet = vpi_scan(argv); assert(out_octet);
	out_end   = vpi_scan(argv); assert(out_end);

	value.format = vpiIntVal;
	vpi_get_value(out_octet, &value);
	out_octet_val = value.value.integer;

	value.format = vpiIntVal;
	vpi_get_value(out_end, &value);
	out_end_val = value.value.integer;

	udp_sender(out_octet_val, out_end_val);
	return 0;
}


static PLI_INT32 udp_init_compiletf(char*cd)
{
	vpiHandle sys = vpi_handle(vpiSysTfCall, 0);
	vpiHandle argv = vpi_iterate(vpiArgument, sys);
	vpiHandle arg;
	int i;
	(void) cd;  /* parameter is unused */

	/* Need two arguments */
	for (i=0; i<2; i++) {
		arg = vpi_scan(argv);
		assert(arg);
	}
	return 0;
}

static PLI_INT32 udp_init_calltf(char*cd)
{
	s_vpi_value value;
	vpiHandle sys = vpi_handle(vpiSysTfCall, 0);
	vpiHandle argv = vpi_iterate(vpiArgument, sys);
	vpiHandle port_num = vpi_scan(argv); assert(port_num);
	vpiHandle is_badger = vpi_scan(argv); assert(is_badger);
	(void) cd;  /* parameter is unused */
	value.format = vpiIntVal;
	vpi_get_value(port_num, &value);
	udp_port = value.value.integer;
	vpi_get_value(is_badger, &value);
	badger_client = value.value.integer;
	return 0;
}

static void sys_udp_init_register(void)
{
	s_vpi_systf_data tf_data;

	tf_data.type      = vpiSysTask;
	tf_data.tfname    = "$udp_init";
	tf_data.calltf    = udp_init_calltf;
	tf_data.compiletf = udp_init_compiletf;
	tf_data.sizetf    = 0;
	tf_data.user_data = strdup("$udp_init");
	vpi_register_systf(&tf_data);
}

static void sys_udp_in_register(void)
{
	s_vpi_systf_data tf_data;

	tf_data.type      = vpiSysTask;
	tf_data.tfname    = "$udp_in";
	tf_data.calltf    = udp_in_calltf;
	tf_data.compiletf = udp_in_compiletf;
	tf_data.sizetf    = 0;
	tf_data.user_data = strdup("$udp_in");
	vpi_register_systf(&tf_data);
}

static void sys_udp_out_register(void)
{
	s_vpi_systf_data tf_data;

	tf_data.type      = vpiSysTask;
	tf_data.tfname    = "$udp_out";
	tf_data.calltf    = udp_out_calltf;
	tf_data.compiletf = udp_out_compiletf;
	tf_data.sizetf    = 0;
	tf_data.user_data = strdup("$udp_out");
	vpi_register_systf(&tf_data);
}

void (*vlog_startup_routines[])(void) = {
	sys_udp_init_register,
	sys_udp_in_register,
	sys_udp_out_register,
	0
};
