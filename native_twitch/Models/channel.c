//
//  c_file.c
//  native_twitch
//
//  Created by Adam Solloway on 3/8/22.
//
#include "channel.h"
#include "string.h"
#include "util.h"
#include <json-c/json.h>
#include <string.h>

void pop_name(Channel *chan, const char *user_name) {
    int len = strlen(user_name);
    memcpy(chan->user_name, user_name, len);
    chan->user_name[len] = '\0';
}

void pop_login(Channel *chan, const char *login) {
    int len = strlen(login);
    memcpy(chan->user_login, login, len);
    chan->user_login[len] = '\0';
}

void Channel_init(Channel *c) {
    c->endpoint = "channels";
    c->viewer_count[0] = ' ';
    c->viewer_count[1] = '\0';
}

void Channel_deinit(Channel *c) {
    // free(c->user_id);
    // free(c->started_at);
    // free(c->title);
}

void get_channel_stream(Client *client, Channel *channel) {
    char *base_url = "https://api.twitch.tv/helix/streams?user_login=";
    char url[2048];
    fmt_string(url, "%s%s", base_url, channel->user_login);
    Response response = curl_request(client, url, curl_GET);
    get_json_array(&response, "data");
    for (int i = 0; i < response.data_len; i++) {
        struct json_object *data_array_object;
        data_array_object = json_object_array_get_idx(response.data, i);
        char *viewer_count = get_key(data_array_object, "viewer_count");
        int len = strlen(viewer_count);
        if (len > 3) {
            abbreviate_number(viewer_count, channel->viewer_count);
        } else {
            memccpy(channel->viewer_count, viewer_count, '\0', sizeof(channel->viewer_count));
            channel->viewer_count[len] = '\0';
        }
    }
    // json_object_put(response.response);
    clean_response(&response);
}

void get_profile_url(Client *client, Channel *channel) {
    struct json_object *data_array_object;
    char url[2048];
    char *base_url = "https://api.twitch.tv/helix/users?id=";
    int len = fmt_string(url, "%s%s", base_url, channel->user_id);
    url[len] = '\0';
    Response response = curl_request(client, url, curl_GET);
    get_json_array(&response, "data");
    for (int i = 0; i < response.data_len; i++) {
        data_array_object = json_object_array_get_idx(response.data, i);
        memccpy(channel->profile_image_url, get_key(data_array_object, "profile_image_url"), '\0', sizeof(channel->profile_image_url));
    }
    // json_object_put(response.response);
    clean_response(&response);
}

int get_followed_channels(Client *client, Channel **follows, int count) {
    Response response;
    char url[URL_LEN];
    fmt_string(url, "%s/streams/followed?user_id=42045317", client->base_url);
    response = curl_request(client, url, curl_GET);
    get_json_array(&response, "data");
    *follows = calloc(response.data_len, sizeof(Channel));

    for (int i = 0; i < response.data_len; i++) {
        Channel chan;
        Channel_init(&chan);
        struct json_object *data_array_object = json_object_array_get_idx(response.data, i);
        memcpy(chan.id, get_key(data_array_object, "id"), sizeof(chan.id));
        memcpy(chan.user_id, get_key(data_array_object, "user_id"), sizeof(chan.user_id));
        memcpy(chan.user_name, get_key(data_array_object, "user_name"), sizeof(chan.user_name));
        memcpy(chan.user_login, get_key(data_array_object, "user_login"), sizeof(chan.user_login));
        memcpy(chan.game_id, get_key(data_array_object, "game_id"), sizeof(chan.game_id));
        memcpy(chan.game_name, get_key(data_array_object, "game_name"), sizeof(chan.game_name));
        (*follows)[i] = chan;
    }
    clean_response(&response);
    return response.data_len;
}

void channel_init_from_json(Channel *channel, struct json_object *json) {
    memccpy(channel->id, get_key(json, "id"), '\0', sizeof(channel->id));
    memccpy(channel->user_id, get_key(json, "user_id"), '\0', sizeof(channel->user_id));
    memccpy(channel->user_login, get_key(json, "user_login"), '\0', sizeof(channel->user_login));
    memccpy(channel->user_name, get_key(json, "user_name"), '\0', sizeof(channel->user_login));
    memccpy(channel->game_id, get_key(json, "game_id"), '\0', sizeof(channel->game_id));
    memccpy(channel->game_name, get_key(json, "game_name"), '\0', sizeof(channel->game_name));
    memccpy(channel->title, get_key(json, "title"), '\0', sizeof(channel->title));
    memccpy(channel->viewer_count, get_key(json, "viewer_count"), '\0', sizeof(channel->viewer_count));
    memccpy(channel->started_at, get_key(json, "started_at"), '\0', sizeof(channel->started_at));
    memccpy(channel->broadcaster_language, get_key(json, "language"), '\0', sizeof(channel->broadcaster_language));
    replace_substr(channel->thumbnail_url, get_key(json, "thumbnail_url"), "{width}x{height}", "344x194");
}
