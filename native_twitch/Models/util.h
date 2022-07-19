//
//  util.h
//  native_twitch
//
//  Created by Adam Solloway on 3/8/22.
//
#ifndef UTIL_H
#define UTIL_H

#include <json-c/json.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

const char *get_key(struct json_object *from, const char *key);
int abbreviate_number(char *from, char *to);
//void get_json_array(Response *response, const char *key);
int fmt_string(char *to, const char *s, ...);
char *concat(char *dst, char *src, char term, size_t size);
// reset size and memory
void clean_up(void *client);
void print_json(struct json_object *json);
int replace_substr(char *dst, char *from, char *repl, char *with);

#endif /* util_h */
