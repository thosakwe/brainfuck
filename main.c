// Mostly copied from:
// https://gist.github.com/maxcountryman/1699708

#include <errno.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>

unsigned char tape[255] = {0};
unsigned char* ptr = tape;

int printUsage() {
    fprintf(stderr, "usage: brainfuck <filename>\n");
    return 1;
}

void interpret(char* input) {
    char current_char;
    size_t i;
    size_t loop;
    clock_t start = clock();

    for (i = 0; input[i] != 0; i++) {
        current_char = input[i];
        if (current_char == '>') {
            ++ptr;
        } else if (current_char == '<') {
            --ptr;
        } else if (current_char == '+') {
            ++*ptr;
        } else if (current_char == '-') {
            --*ptr;
        } else if (current_char == '.' ) {
            putchar(*ptr);
        } else if (current_char == ',') {
            *ptr = getchar();
        } else if (current_char == '[') {
            continue;
        } else if (current_char == ']' && *ptr) {
            loop = 1;
            while (loop > 0) {
                current_char = input[--i];
                if (current_char == '[') {
                    loop--;
                } else if (current_char == ']') {
                    loop++;
                }
            }
        }
    }

    clock_t end = clock();
    float ms = (float) (end - start);
    printf("\nElapsed time: %.0f ms\n", ms);
}

int main(int argc, char** argv) {
    char *buf;
    FILE *file;
    long int len, read;

    if (argc <= 1) {
        fprintf(stderr, "fatal error: no input file\n\n");
        return printUsage();
    }

    if (!(file = fopen(argv[1], "r"))) {
        fprintf(stderr, "Could not read input file.");
        fputs(strerror(errno), stderr);
        return 1;
    }

    fseek(file, 0, SEEK_END);
    len = ftell(file);
    buf = (char*) malloc(len);
    fseek(file, 0, SEEK_SET);
    read = fread(buf, 1, len, file);
    fclose(file);

    if (read != len) {
        fprintf(stderr, "Could not read input file.");
        fputs(strerror(errno), stderr);
        return 1;
    }

    interpret(buf);
    return 0;
}