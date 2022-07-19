//
//  client.c
//  native_twitch
//
//  Created by Adam Solloway on 3/8/22.
//

#include "client.h"
#include "videoplayer.h"

Client Client_init(const char *access_token, const char *user_id, const char *user_login) {
    Client c;
    c.base_url = "https://api.twitch.tv/helix";
    c.client_id = "gp762nuuoqcoxypju8c569th9wz7q5";
    c.token = access_token;
    c.user_id = user_id;
    c.user_login = user_login;
    c.headers = NULL;
    c.curl_handle = NULL;

    char header[URL_LEN];
    c.headers = curl_slist_append(c.headers, "Content-Type: application/json");
    c.headers = curl_slist_append(c.headers, "Accept: application/json");
    fmt_string(header, "Authorization: Bearer %s", c.token);
    c.headers = curl_slist_append(c.headers, header);

    fmt_string(header, "Client-Id: %s", c.client_id);
    c.headers = curl_slist_append(c.headers, header);
    return c;
}

void Client_deinit(Client *c) {
    json_object_put(c->fields);
    curl_slist_free_all(c->headers);
}

bool validate_token(Client *client) {
    bool ret = false;
    const char *url = "https://id.twitch.tv/oauth2/validate";
    Response response = curl_request(client, url, curl_GET);
    if (response.response_code == 200) {
        client->user_login = get_key(response.response, "login");
        client->user_id = get_key(response.response, "user_id");
        ret = true;
    }
    clean_response(&response);
    return ret;
}

Response curl_request(Client *client, const char *url, CurlMethod method) {
    Response response;
    response.memory = malloc(1);
    response.size = 0;
    client->curl_handle = curl_easy_init();
    response.error[0] = 0;
    response.data_len = 0;

    switch (method) {
    case curl_GET:
        curl_easy_setopt(client->curl_handle, CURLOPT_CUSTOMREQUEST, "GET");
        break;
    case curl_POST:
        curl_easy_setopt(client->curl_handle, CURLOPT_CUSTOMREQUEST, "POST");
        curl_easy_setopt(client->curl_handle, CURLOPT_POSTFIELDS, client->post_data);
        break;
    case curl_DELETE:
        curl_easy_setopt(client->curl_handle, CURLOPT_CUSTOMREQUEST, "POST");
        curl_easy_setopt(client->curl_handle, CURLOPT_POSTFIELDS, client->post_data);
        break;
    case curl_PATCH:
        curl_easy_setopt(client->curl_handle, CURLOPT_CUSTOMREQUEST, "POST");
        curl_easy_setopt(client->curl_handle, CURLOPT_POSTFIELDS, client->post_data);
        break;
    default:
        curl_easy_setopt(client->curl_handle, CURLOPT_CUSTOMREQUEST, "GET");
    }

    curl_easy_setopt(client->curl_handle, CURLOPT_URL, url);
    curl_easy_setopt(client->curl_handle, CURLOPT_SSL_VERIFYPEER, 0);
    curl_easy_setopt(client->curl_handle, CURLOPT_HTTPHEADER, client->headers);
    curl_easy_setopt(client->curl_handle, CURLOPT_WRITEFUNCTION, WriteMemoryCallback);
    curl_easy_setopt(client->curl_handle, CURLOPT_WRITEDATA, (void *)&response);
    curl_easy_setopt(client->curl_handle, CURLOPT_ERRORBUFFER, response.error);
    curl_easy_setopt(client->curl_handle, CURLOPT_NOSIGNAL, 1L);

    // curl_easy_setopt(client->curl_handle, CURLOPT_VERBOSE, client->curl_handle);

    response.res = curl_easy_perform(client->curl_handle);
    if (response.res == CURLE_OK) {
        curl_easy_getinfo(client->curl_handle, CURLINFO_RESPONSE_CODE, &response.response_code);
    }
    response.response = json_tokener_parse(response.memory);
    curl_easy_cleanup(client->curl_handle);
    return response;
}

void clean_response(void *response) {
    struct Response *res = (struct Response *)response;
    json_object_put(res->response);
    free(res->memory);
}

void clean_up(void *client) {
    struct Client *mem = (struct Client *)client;
    if (mem->curl_handle != NULL) {
        curl_easy_cleanup(mem->curl_handle);
    }
}

size_t WriteMemoryCallback(void *contents, size_t size, size_t nmemb, void *userp) {
    size_t realsize = size * nmemb;
    struct Response *mem = (struct Response *)userp;

    char *ptr = realloc(mem->memory, mem->size + realsize + 1);
    if (ptr == NULL) {
        printf("error: not enough memory\n");
        return 0;
    }
    mem->memory = ptr;
    memcpy(&(mem->memory[mem->size]), contents, realsize);
    mem->size += realsize;
    mem->memory[mem->size] = 0;
    return realsize;
}

void reset_headers(Client *client) {
    clear_headers(client);
    char header[100];

    fmt_string(header, "Authorization: Bearer %s", client->token);
    client->headers = curl_slist_append(client->headers, header);

    fmt_string(header, "client-Id: %s", client->client_id);
    client->headers = curl_slist_append(client->headers, header);
}

void clear_headers(Client *client) {
    curl_slist_free_all(client->headers);
    client->headers = NULL;
}

void get_json_array(Response *response, const char *key) {
    if (response->response != NULL) {
        json_object_object_get_ex(response->response, key, &response->data);
        if (response->data != NULL) {
            response->data_len = json_object_array_length(response->data);
        }
    }
}

void set_pagination(char *pagination, struct json_object *json) {
    struct json_object *pagination_json;
    json_object_object_get_ex(json, "pagination", &pagination_json);
    memccpy(pagination, get_key(pagination_json, "cursor"), '\0', 65);
}

Paginator init_paginator() {
    Paginator paginator;
    paginator.pagination[0] = '\0';
    return paginator;
}
