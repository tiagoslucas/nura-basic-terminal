/* synthtouch - synthetic multitouch touchscreen via uinput, for testing
 * phone-gestures without touching the real screen. Mimics the Goodix:
 * protocol B (slots + tracking ids), ABS ranges 0-4095.
 *
 * Usage: synthtouch x0 y0 x1 y1 [duration_ms]   -- drag
 *        synthtouch dtap x y                    -- double tap
 * Raw units for x/y.
 */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <fcntl.h>
#include <sys/ioctl.h>
#include <linux/input.h>
#include <linux/uinput.h>

static void emit(int fd, int type, int code, int val)
{
    struct input_event ev;
    memset(&ev, 0, sizeof(ev));
    ev.type = type;
    ev.code = code;
    ev.value = val;
    if (write(fd, &ev, sizeof(ev)) != sizeof(ev)) {
        perror("write");
        exit(1);
    }
}

static void syn(int fd)
{
    emit(fd, EV_SYN, SYN_REPORT, 0);
}

static void set_abs(int fd, int code, int min, int max)
{
    struct uinput_abs_setup s;
    memset(&s, 0, sizeof(s));
    s.code = code;
    s.absinfo.minimum = min;
    s.absinfo.maximum = max;
    if (ioctl(fd, UI_ABS_SETUP, &s) < 0) {
        perror("UI_ABS_SETUP");
        exit(1);
    }
    ioctl(fd, UI_SET_ABSBIT, code);
}

int main(int argc, char **argv)
{
    int dtap = argc == 4 && strcmp(argv[1], "dtap") == 0;
    if (argc < 6 && !dtap) {
        fprintf(stderr, "usage: %s x0 y0 x1 y1 [duration_ms] | %s dtap x y\n",
                argv[0], argv[0]);
        return 1;
    }
    int x0 = dtap ? atoi(argv[2]) : atoi(argv[1]);
    int y0 = dtap ? atoi(argv[3]) : atoi(argv[2]);
    int x1 = dtap ? x0 : atoi(argv[3]);
    int y1 = dtap ? y0 : atoi(argv[4]);
    int dur_ms = dtap ? 400 : (argc > 6 ? atoi(argv[5]) : 400);

    int fd = open("/dev/uinput", O_WRONLY | O_NONBLOCK);
    if (fd < 0) {
        perror("/dev/uinput");
        return 1;
    }

    ioctl(fd, UI_SET_EVBIT, EV_ABS);
    ioctl(fd, UI_SET_EVBIT, EV_KEY);
    ioctl(fd, UI_SET_KEYBIT, BTN_TOUCH);
    set_abs(fd, ABS_X, 0, 4095);
    set_abs(fd, ABS_Y, 0, 4095);
    set_abs(fd, ABS_MT_SLOT, 0, 9);
    set_abs(fd, ABS_MT_TRACKING_ID, 0, 65535);
    set_abs(fd, ABS_MT_POSITION_X, 0, 4095);
    set_abs(fd, ABS_MT_POSITION_Y, 0, 4095);

    struct uinput_setup setup;
    memset(&setup, 0, sizeof(setup));
    strcpy(setup.name, "Synth Touchscreen");
    setup.id.bustype = BUS_USB;
    if (ioctl(fd, UI_DEV_SETUP, &setup) < 0) {
        perror("UI_DEV_SETUP");
        return 1;
    }
    if (ioctl(fd, UI_DEV_CREATE) < 0) {
        perror("UI_DEV_CREATE");
        return 1;
    }
    /* let the daemon's find loop / libinput see the device first */
    sleep(1);

    if (dtap) {
        /* two quick taps in place */
        for (int i = 0; i < 2; i++) {
            emit(fd, EV_ABS, ABS_MT_SLOT, 0);
            emit(fd, EV_ABS, ABS_MT_TRACKING_ID, 45);
            emit(fd, EV_ABS, ABS_MT_POSITION_X, x0);
            emit(fd, EV_ABS, ABS_MT_POSITION_Y, y0);
            emit(fd, EV_KEY, BTN_TOUCH, 1);
            syn(fd);
            usleep(80000);
            emit(fd, EV_ABS, ABS_MT_TRACKING_ID, -1);
            emit(fd, EV_KEY, BTN_TOUCH, 0);
            syn(fd);
            if (i == 0)
                usleep(150000);
        }
        sleep(1);
        ioctl(fd, UI_DEV_DESTROY);
        close(fd);
        return 0;
    }

    /* touch down */
    emit(fd, EV_ABS, ABS_MT_SLOT, 0);
    emit(fd, EV_ABS, ABS_MT_TRACKING_ID, 45);
    emit(fd, EV_ABS, ABS_MT_POSITION_X, x0);
    emit(fd, EV_ABS, ABS_MT_POSITION_Y, y0);
    emit(fd, EV_KEY, BTN_TOUCH, 1);
    syn(fd);

    /* drag */
    int steps = 20;
    for (int i = 1; i <= steps; i++) {
        int x = x0 + (x1 - x0) * i / steps;
        int y = y0 + (y1 - y0) * i / steps;
        emit(fd, EV_ABS, ABS_MT_POSITION_X, x);
        emit(fd, EV_ABS, ABS_MT_POSITION_Y, y);
        syn(fd);
        usleep(dur_ms * 1000 / steps);
    }

    /* lift */
    emit(fd, EV_ABS, ABS_MT_TRACKING_ID, -1);
    emit(fd, EV_KEY, BTN_TOUCH, 0);
    syn(fd);

    sleep(1);
    ioctl(fd, UI_DEV_DESTROY);
    close(fd);
    return 0;
}
