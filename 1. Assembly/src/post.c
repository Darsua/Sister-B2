#include <time.h>
#include <stdio.h>
#include <unistd.h>

int write_timestamp(int fd) {
    if (fd < 0) return -1;
    time_t now = time(NULL);
    struct tm *t = localtime(&now);
    // Format: DD-MM-YYYY HH:MM:SS
    return dprintf(fd, " | %02d-%02d-%04d %02d:%02d:%02d\n",
                   t->tm_mday, t->tm_mon + 1, t->tm_year + 1900,
                   t->tm_hour, t->tm_min, t->tm_sec);
}