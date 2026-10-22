#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>

static uint8_t nibble(char c) {
    if (c >= '0' && c <= '9') return (uint8_t)(c - '0');
    if (c >= 'a' && c <= 'f') return (uint8_t)(c - 'a' + 10);
    if (c >= 'A' && c <= 'F') return (uint8_t)(c - 'A' + 10);
    return 0;
}

/* Same line-consuming, first-byte behavior as the pinned native reference reader. */
static int read_one(FILE *file, uint8_t *data) {
    char *line = NULL;
    size_t cap = 0;
    if (getline(&line, &cap, file) == -1) {
        free(line);
        return 0;
    }
    if (strlen(line) < 2) exit(2);
    *data = (uint8_t)((nibble(line[0]) << 4) | nibble(line[1]));
    free(line);
    return 1;
}

int main(int argc, char **argv) {
    FILE *file;
    if (argc != 3 || strlen(argv[2]) == 0 || !(file = fopen(argv[1], "r"))) return 2;
    for (size_t i = 0; i < strlen(argv[2]); i++) {
        uint8_t cmd;
        if (!read_one(file, &cmd)) return 1;
        printf("case%zu=%02x\n", i, cmd);
        if (cmd != nibble(argv[2][i])) return 1;
    }
    uint8_t extra;
    if (read_one(file, &extra)) return 1;
    fclose(file);
    return 0;
}
