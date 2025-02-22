#include <stdio.h>
#include <unistd.h>
/*
 * To build:
 * gcc myapp.c -o myapp
 * To run:
 * ./myapp
 * Output:
 * Hello, OTA update!
 */

int main() {
    while (1) {
        printf("Hello, OTA update!\n");
        sleep(600); // in seconds
    }
    return 0;
}
