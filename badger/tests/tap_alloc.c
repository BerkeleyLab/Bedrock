#include <sys/socket.h>
#include <sys/ioctl.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <string.h>
#include <unistd.h>
#include <stdlib.h>
#include <stdio.h>
#include <errno.h>
#include "tap_alloc.h"

#ifdef __APPLE__
/*
 * OS X drive has no auto-allocate, so get name from environment.
 * The driver disables the 4-byte header by default, which what we want.
 * It does provide ioctls, though, so maybe this could be made explicit.
 */
int tap_alloc(char *dev)
{
	int fd;
	const char *ifName;
	char dName[40];

	ifName = getenv("VVP_NETWORK_NAME");
	if (ifName == NULL) ifName = "tap0";
	if ((strchr(ifName, '/') != NULL)
	 || (strchr(ifName, '.') != NULL)
	 || (strchr(ifName, '"') != NULL)
	 || (snprintf(dName, sizeof dName, "/dev/%s", ifName) >= (int)sizeof dName)) {
		fprintf(stderr, "VVP_NETWORK_NAME must be interface name only, e.g. \"tap0\"\n");
		return -1;
	}
	if( (fd = open(dName, O_RDWR)) < 0 ) {
		fprintf(stderr, "Can't open \"%s\": %s\n", dName, strerror(errno));
		printf("Maybe you want to: chmod 666 %s && ifconfig %s <ip_address> up\n", dName, ifName);
		return -1;
	}
	strcpy(dev, dName);
	return fd;
}
#else
#include <linux/if.h>
#include <linux/if_tun.h>

int tap_alloc(char *dev)
{
	struct ifreq ifr;
	int fd, err;

	if( (fd = open("/dev/net/tun", O_RDWR)) < 0 ){
		perror("tun-open");
		printf("Maybe you want to: tunctl -u $USER && ifconfig tap0 <ip_address> up\n");
		printf("or: printf \"tuntap add mode tap user $USER\\n link set tap0 up\\n address add 192.168.7.1 dev tap0\\n route add 192.168.7.0/24 dev tap0\\n\" | sudo ip -batch -\n");

		return -1;
	}

	memset(&ifr, 0, sizeof(ifr));

	/* Flags: IFF_TUN   - TUN device (no Ethernet headers)
	 *        IFF_TAP   - TAP device
	 *
	 *        IFF_NO_PI - Do not provide packet information
	 */
	ifr.ifr_flags = IFF_TAP | IFF_NO_PI;
	if( *dev ) {
		strncpy(ifr.ifr_name, dev, IFNAMSIZ-1);
		ifr.ifr_name[IFNAMSIZ-1] = '\0';  /* work around strncpy stupidity */
	}

	if( (err = ioctl(fd, TUNSETIFF, (void *) &ifr)) < 0 ){
		perror("tun-ioctl");
		printf("Maybe you want to: tunctl -u $USER && ifconfig tap0 <ip_address> up\n");
		printf("or: printf \"tuntap add mode tap user $USER\\n link set tap0 up\\n address add 192.168.7.1 dev tap0\\n route add 192.168.7.0/24 dev tap0\\n\" | sudo ip -batch -\n");
		close(fd);
		return err;
	}
	strcpy(dev, ifr.ifr_name);
	return fd;
}
#endif
