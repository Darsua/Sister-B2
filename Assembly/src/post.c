#include <time.h>
#include <stdio.h>

int post_timestamp() {
    // Append the current timestamp to posts.txt
    FILE *file = fopen("posts.txt", "a");
    if (file == NULL) return -1; // Error opening file
    
    time_t now = time(NULL);
    // Convert to local time format
    struct tm *t = localtime(&now);
    // Format: DD-MM-YYYY HH:MM:SS
    fprintf(file, "%02d-%02d-%04d %02d:%02d:%02d\n",
            t->tm_mday, t->tm_mon + 1, t->tm_year + 1900,
            t->tm_hour, t->tm_min, t->tm_sec);
    fclose(file);
    
    return 0; // Success
}