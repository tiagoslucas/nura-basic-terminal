/* irsend — drive the phone's IR LED (SPI6 MOSI, GPIO 20) as a raw
 * mark/space transmitter, bit-banging the carrier from userspace.
 *
 *   irsend [-v] [-f carrier_hz] [-d duty_pct] [-g gpio] MARK SPACE ... (µs)
 *   (-v prints the carrier frequency actually achieved)
 *
 * The caller must free GPIO 20 first (unbind the spi_qup controller);
 * the phone-ir wrapper does that. Needs root for SCHED_FIFO + gpiochip.
 */
#include <errno.h>
#include <fcntl.h>
#include <linux/gpio.h>
#include <sched.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/ioctl.h>
#include <sys/mman.h>
#include <time.h>
#include <unistd.h>

static inline uint64_t now_ns(void)
{
	struct timespec ts;
	clock_gettime(CLOCK_MONOTONIC, &ts);
	return (uint64_t)ts.tv_sec * 1000000000ull + ts.tv_nsec;
}

static int line_fd;
static unsigned long cycles, mark_ns;

static inline void led(int on)
{
	struct gpio_v2_line_values v = { .bits = on ? 1 : 0, .mask = 1 };
	ioctl(line_fd, GPIO_V2_LINE_SET_VALUES_IOCTL, &v);
}

static void spin_until(uint64_t t)
{
	while (now_ns() < t)
		;
}

static void mark(uint64_t us, uint64_t period_ns, uint64_t high_ns)
{
	uint64_t start = now_ns(), end = start + us * 1000ull, t = start;

	while (t < end) {
		led(1);
		cycles++;
		spin_until(t + high_ns);
		led(0);
		t += period_ns;
		spin_until(t < end ? t : end);
	}
	led(0);
	mark_ns += now_ns() - start;
}

int main(int argc, char **argv)
{
	int carrier = 38000, duty = 33, gpio = 20, opt, verbose = 0;
	struct gpio_v2_line_request req;
	int chip;

	while ((opt = getopt(argc, argv, "vf:d:g:")) != -1) {
		if (opt == 'v')
			verbose = 1;
		else if (opt == 'f')
			carrier = atoi(optarg);
		else if (opt == 'd')
			duty = atoi(optarg);
		else if (opt == 'g')
			gpio = atoi(optarg);
		else
			return 2;
	}
	if (optind >= argc) {
		fprintf(stderr, "usage: irsend [-f hz] [-d pct] [-g gpio] MARK SPACE ...\n");
		return 2;
	}

	chip = open("/dev/gpiochip0", O_RDWR);
	if (chip < 0) {
		perror("gpiochip0");
		return 1;
	}
	memset(&req, 0, sizeof(req));
	req.offsets[0] = gpio;
	req.num_lines = 1;
	strcpy(req.consumer, "irsend");
	req.config.flags = GPIO_V2_LINE_FLAG_OUTPUT;
	if (ioctl(chip, GPIO_V2_GET_LINE_IOCTL, &req) < 0) {
		perror("request gpio (is the SPI controller still bound?)");
		return 1;
	}
	line_fd = req.fd;
	close(chip);

	struct sched_param sp = { .sched_priority = 80 };
	sched_setscheduler(0, SCHED_FIFO, &sp);
	mlockall(MCL_CURRENT | MCL_FUTURE);

	uint64_t period = 1000000000ull / carrier;
	uint64_t high = period * duty / 100;
	int n = argc - optind;

	led(0);
	uint64_t t0 = now_ns();
	for (int i = 0; i < n; i++) {
		uint64_t us = strtoull(argv[optind + i], NULL, 10);
		if (i % 2 == 0) {
			mark(us, period, high);
		} else {
			led(0);
			spin_until(now_ns() + us * 1000ull);
		}
	}
	led(0);
	fprintf(stderr, "sent %d durations in %llu us\n", n,
		(unsigned long long)((now_ns() - t0) / 1000));
	if (verbose && mark_ns)
		fprintf(stderr, "carrier: %lu cycles in %lu us marked = %.0f Hz (asked %d)\n",
			cycles, mark_ns / 1000, cycles * 1e9 / mark_ns, carrier);
	return 0;
}
