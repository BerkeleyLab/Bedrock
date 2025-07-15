/* Strip header off of a Xilinx .bit file, to make
 * something that corresponds to the raw Altera .rbf file,
 * suitable for checksum and download with usrper.
 * Or, with -s option, coerce timestamp to one given.
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include <unistd.h>
#include <limits.h>

typedef unsigned int uint32;
/* utilities involved in reading the Xilinx .bit file.
 * File format documented by Alan Nishioka <alann@accom.com>
 */

static int xget_char(FILE *o)
{
	int c;
	if ((c = getchar()) == EOF) exit(1);
	if (o) fputc(c, o);
	return c;
}

static uint32 get_long(FILE *o)
{
	uint32 l;
	l = xget_char(o);
	l = xget_char(o) | l<<8;
	l = xget_char(o) | l<<8;
	l = xget_char(o) | l<<8;
	return l;
}

static int get_short(FILE *o)
{
	int c, l;
	if ((c = getchar()) == EOF) return -1;
	l = c;
	if (o) fputc(c, o);
	if ((c = getchar()) == EOF) return -1;
	l = l<<8 | c;
	if (o) fputc(c, o);
	return l;
}

static void find_key(int key, FILE *o)
{
	int c;
	if ((c = getchar()) != key) {
		fprintf(stderr, "find_key found 0x%.2x instead of 0x%.2x\n", (unsigned)c, (unsigned)key);
		exit(1);
	}
	if (o) fputc(c, o);
}

static void emit_string(const char *str, FILE *o)
{
	if (!o) return;
	int l = strlen(str)+1;  /* include the trailing 0 */
	if (l > SHRT_MAX) {
		fprintf(stderr,"emit_string: str too long\n");
		exit(1);
	}
	fputc((l>>8) & 0xff, o);
	putc(l & 0xff, o);
	for (int ix=0; ix<l; ix++) fputc(str[ix], o);
}

static void print_string(const char *name, FILE *o, const char *subst_string)
{
	int i, c, len;
	char *str;
	if ((len = get_short(NULL)) < 0) {
		fprintf(stderr,"print_string got EOF instead of length\n");
		exit(1);
	}
	str = malloc(len+1);
	if (str == NULL) {
		perror("print_string malloc");
		exit(1);
	}
	for (i=0; i<len; i++) {
		if ((c = getchar()) == EOF) {
			fprintf(stderr,"print_string found EOF in string of length %d\n", len);
			exit(1);
		}
		str[i] = c;
	}
	str[len] = '\0';
	printf("%s%s\n", name, str);
	emit_string(subst_string ? subst_string : str, o);
}

static int load_main(const char *stime, const char *outfile_name)
{
	FILE *o = NULL;
	int i, c, len;
	char odatem[12], otimem[10];
	const char *odate=NULL, *otime=NULL;
	if (stime != NULL) {
		time_t itime = atoi(stime);
		struct tm *tm1 = gmtime(&itime);
		printf("supplied time %s %ld\n", stime, itime);
		size_t rc1 = strftime(odatem, sizeof(odatem), "%Y/%m/%d", tm1);
		size_t rc2 = strftime(otimem, sizeof(otimem), "%H:%M:%S", tm1);
		if (rc1 && rc2) {
			odate = odatem;
			otime = otimem;
			printf("result strings %s %s\n", odate, otime);
		}
	}
	if (outfile_name) o=fopen(outfile_name,"w");
	if ((len = get_short(o)) < 0) exit(1);
	for (i=0; i<len; i++) {
		if ((c = getchar()) == EOF) exit(1);
		if (o) fputc(c, o);
	}
	find_key(0x00, o);
	find_key(0x01, o);
	find_key(0x61, o);
	print_string("design: ", o, NULL);
	find_key(0x62, o);
	print_string("part:   ", o, NULL);
	find_key(0x63, o);
	print_string("date:   ", o, odate);
	find_key(0x64, o);
	print_string("time:   ", o, otime);
	find_key(0x65, o);
	len = get_long(o);
	printf("length: %d\n", len);
	if (o) {
		for (i=0; i<len; i++) {
			fputc(getchar(),o);
		}
		if (fclose(o)) {
			perror("fclose");
			unlink(outfile_name);
		} else {
			printf("wrote:  %s\n",outfile_name);
		}
	}
	return 0;
}

int main(int argc, char *argv[])
{
	char *outfile;
	char *stime=NULL;
	if (argc > 1 && argv[1][0] == '-' && argv[1][1] != 's') {
		printf("Usage: %s [-s timestamp] [outfile] < xilinx_bitfile\n", argv[0]);
		printf("    maybe %s -s $(git log -1 --pretty=%%ct)\n", argv[0]);
		exit(1);
	}
	if (argc > 1 && (strcmp(argv[1], "-s")==0)) {
		if (argc > 2) {
			stime = argv[2];
			argc -= 2;
			argv += 2;
		}
	}
	outfile = argv[1];  /* argument will be NULL if no file specified */
	load_main(stime, outfile);
	return 0;
}
