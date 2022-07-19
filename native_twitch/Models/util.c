//
//  util.c
//  native_twitch
//
//  Created by Adam Solloway on 3/8/22.
//
#include "util.h"
#include <curl/curl.h>
#include <stdarg.h>

const char *get_key(struct json_object *from, const char *key) {
    struct json_object *val;

    json_object_object_get_ex(from, key, &val);

    return json_object_get_string(val);
}

int replace_substr(char *dst, char *from, char *repl, char *with) {
    char *p = strstr(from, repl);
    int repl_index_in_from = p - from;
    int from_len = strlen(p) + repl_index_in_from;
    int repl_len = strlen(repl);
    int with_len = strlen(with);
    int new_len = (from_len - repl_len) + with_len;

    memcpy(dst, from, repl_index_in_from);
    memcpy(dst + repl_index_in_from, with, with_len);
    strcpy(dst + repl_index_in_from + with_len, p + repl_len);
    dst[new_len] = '\0';
    return new_len;
}

// abbreviate numbers in the thousands
// ex: 40382 -> 40.3K
int abbreviate_number(char *from, char *to) {
    int i;
    char digit;

    int size = strlen(from);
    from[size] = '\0';
    int delim = size - 3;

    for (i = 0; i < delim; i++) {
        to[i] = from[i];
    }

    digit = from[delim];
    to[i++] = '.';
    to[i++] = digit;
    to[i++] = 'K';
    to[i] = '\0';
    return i;
}

// formats string to provided array and returns length
int fmt_string(char *to, const char *s, ...) {
    va_list ap;
    int ret;

    va_start(ap, s);
    ret = vsprintf(to, s, ap);
    va_end(ap);
    to[ret] = '\0';

    return ret;
}

char *concat(char *dst, char *src, char term, size_t size) {
    char *tmp = NULL;
    tmp = memccpy(dst, src, term, size);
    return tmp;
}

void print_json(struct json_object *json) {
    printf("json: %s\n", json_object_to_json_string_ext(json, JSON_C_TO_STRING_PRETTY));
}
