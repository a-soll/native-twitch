//
//  client.h
//  native_twitch
//
//  Created by Adam Solloway on 3/8/22.
//
#ifndef CLIENT_H
#define CLIENT_H

#include "util.h"
#include <curl/curl.h>
#include <stdbool.h>

#define URL_LEN 2048

typedef enum CurlMethod {
    curl_POST,
    curl_GET,
    curl_DELETE,
    curl_PATCH
} CurlMethod;

typedef struct Response {
    struct json_object *response;
    struct json_object *data;
    struct json_object *data_array_obj;
    CURLcode res;
    int data_len;
    char *memory;
    size_t size;
    long response_code;
    char error[CURL_ERROR_SIZE];
} Response;

typedef struct Client {
    const char *user_id;
    const char *user_login;
    const char *base_url;
    const char *client_id;
    const char *client_secret;
    const char *token;
    struct json_object *fields;
    struct curl_slist *headers;
    CURL *curl_handle;
    char post_data[999];
} Client;

typedef struct Paginator {
    char pagination[550];
} Paginator;

Client Client_init(const char *access_token, const char *user_id, const char *user_login);
bool validate_token(Client *client);
void Client_deinit(Client *c);
Response curl_request(Client *client, const char *url, CurlMethod method);
void Client_startup(void);
void clean_up(void *client);
size_t WriteMemoryCallback(void *contents, size_t size, size_t nmemb, void *userp);
void refresh_token();
void reset_headers(Client *client);
void clear_headers(Client *client);
void clean_response(void *response);
void refresh_token(Client *client);
void get_json_array(Response *response, const char *key);
void set_pagination(char *pagination, struct json_object *json);
Paginator init_paginator();

#endif /* client_h */
