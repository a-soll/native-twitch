//
//  chat.c
//  native_twitch
//
//  Created by Adam Solloway on 5/11/22.
//

#include "chat.h"
#include "util.h"
#include <twitchchat/twitchchat.h>

int get_word(char *str, int ind, char *word) {
    int i = 0;

    while (str[ind] != ' ' && str[ind] != '\0') {
        word[i] = str[ind];
        i++;
        ind++;
    }
    word[i] = '\0';
    return i;
}

void get_bttv_global(Client *client, struct hashmap_s *emote_map) {
    char *url = "https://api.betterttv.net/3/cached/emotes/global";
    Response response = curl_request(client, url, curl_GET);
    if (response.response != NULL) {
        response.data_len = json_object_array_length(response.response);
    }
    for (int i = 0; i < response.data_len; i++) {
        Emote *e = malloc(sizeof(Emote));
        response.data_array_obj = json_object_array_get_idx(response.response, i);
        e->name = get_key(response.data_array_obj, "code");
        e->id = get_key(response.data_array_obj, "id");
        char cdn[200];
        int len = fmt_string(cdn, "https://cdn.betterttv.net/emote/%s/1x", e->id);
        cdn[len] = '\0';
        memccpy(e->url_1x, cdn, '\0', len);
        e->url_1x[len] = '\0';
        if (0 != hashmap_put(emote_map, e->name, strlen(e->name), e)) {
            printf("Could not add %s\n", e->name);
        }
    }
    clean_response(&response);
}

void add_bttv_emote(struct json_object *json, int array_len, struct hashmap_s *emote_map) {
    struct json_object *data_array_obj;
    for (int i = 0; i < array_len; i++) {
        Emote *e = malloc(sizeof(Emote));
        data_array_obj = json_object_array_get_idx(json, i);
        e->name = get_key(data_array_obj, "code");
        e->id = get_key(data_array_obj, "id");
        char cdn[200];
        int len = fmt_string(cdn, "https://cdn.betterttv.net/emote/%s/1x", e->id);
        memccpy(e->url_1x, cdn, '\0', len);
        e->url_1x[len] = '\0';
        if (0 != hashmap_put(emote_map, e->name, strlen(e->name), e)) {
            printf("Could not add %s\n", e->name);
        }
    }
}

void get_bttv_channel_emotes(Client *client, const char *channel_id, struct hashmap_s *emote_map) {
    char url[URL_LEN];
    char *endpoint = "https://api.betterttv.net/3/cached/users/twitch/";
    fmt_string(url, "%s%s", endpoint, channel_id);
    Response response = curl_request(client, url, curl_GET);
    json_bool b = json_object_object_get_ex(response.response, "channelEmotes", &response.data);
    if (response.response != NULL && b) {
        response.data_len = json_object_array_length(response.data);
    }
    add_bttv_emote(response.data, response.data_len, emote_map);
    struct json_object *shared_emotes;
    json_object_object_get_ex(response.response, "sharedEmotes", &shared_emotes);
    add_bttv_emote(shared_emotes, json_object_array_length(shared_emotes), emote_map);
    clean_response(&response);
}

void get_ffz_channel_emotes(Client *client, const char *channel_id, struct hashmap_s *emote_map) {
    char url[URL_LEN];
    char *endpoint = "https://api.betterttv.net/3/cached/frankerfacez/users/twitch";
    fmt_string(url, "%s/%s", endpoint, channel_id);
    Response response = curl_request(client, url, curl_GET);
    if (response.response != NULL) {
        response.data_len = json_object_array_length(response.response);
    }
    for (int i = 0; i < response.data_len; i++) {
        Emote *e = malloc(sizeof(Emote));
        struct json_object *images;
        response.data_array_obj = json_object_array_get_idx(response.response, i);
        e->name = get_key(response.data_array_obj, "code");
        e->id = get_key(response.data_array_obj, "id");
        images = json_object_object_get(response.data_array_obj, "images");
        char *c = get_key(images, "1x");
        int len = strlen(c);
        memccpy(e->url_1x, c, '\0', len);
        e->url_1x[len] = '\0';
        if (0 != hashmap_put(emote_map, e->name, strlen(e->name), e)) {
            printf("Could not add %s\n", e->name);
        }
        json_object_put(images);
    }
    clean_response(&response);
}

void get_global_emotes(Client *client, struct hashmap_s *emote_map) {
    char *endpoint = "/chat/emotes/global";
    size_t size = strlen(client->base_url) + strlen(endpoint);
    char url[URL_LEN];

    fmt_string(url, "%s%s", client->base_url, endpoint);
    Response response = curl_request(client, url, curl_GET);
    response.data = json_object_object_get(response.response, "data");
    if (response.response != NULL) {
        response.data_len = json_object_array_length(response.data);
    }

    for (int i = 0; i < response.data_len; i++) {
        Emote *e = malloc(sizeof(Emote));
        struct json_object *images;
        response.data_array_obj = json_object_array_get_idx(response.data, i);
        e->name = get_key(response.data_array_obj, "name");
        e->id = get_key(response.data_array_obj, "id");
        images = json_object_object_get(response.data_array_obj, "images");
        char *c = get_key(images, "url_1x");
        int len = strlen(c);
        c[len] = '\0';
        memcpy(e->url_1x, c, strlen(c));
        e->url_1x[len] = '\0';
        if (0 != hashmap_put(emote_map, e->name, strlen(e->name), e)) {
            printf("Could not add %s\n", e->name);
        }
        json_object_put(images);
    }
    clean_response(&response);
}

void get_channel_emotes(Client *client, const char *channel_id, struct hashmap_s *emote_map) {
    char url[URL_LEN];
    char *endpoint = "/chat/emotes?broadcaster_id=";
    struct json_object *images;

    fmt_string(url, "%s%s%s", client->base_url, endpoint, channel_id);
    Response response = curl_request(client, url, curl_GET);
    response.data = json_object_object_get(response.response, "data");
    if (response.response != NULL) {
        response.data_len = json_object_array_length(response.data);
    }
    for (int i = 0; i < response.data_len; i++) {
        Emote *e = malloc(sizeof(Emote));
        response.data_array_obj = json_object_array_get_idx(response.data, i);
        e->name = get_key(response.data_array_obj, "name");
        e->id = get_key(response.data_array_obj, "id");
        images = json_object_object_get(response.data_array_obj, "images");
        char *c = get_key(images, "url_1x");
        int len = strlen(c);
        c[len] = '\0';
        memcpy(e->url_1x, c, strlen(c));
        e->url_1x[len] = '\0';
        if (0 != hashmap_put(emote_map, e->name, strlen(e->name), e)) {
            printf("Could not add %s\n", e->name);
        }
    }
    clean_response(&response);
}

struct hashmap_s init_emote_map(const unsigned initial_size) {
    struct hashmap_s emote_map;
    if (0 != hashmap_create(initial_size, &emote_map)) {
        return emote_map;
    }
    return emote_map;
}

Emote *get_emote(const char *word, struct hashmap_s *emote_map) {
    Emote *emote = hashmap_get(emote_map, word, strlen(word));
    return emote;
}

int build_message(Irc *irc, MsgFragment *dmsg, struct hashmap_s *emote_map) {
    int i = 0;
    int j = 0;
    int x = 0;
    char *p = NULL;

    while (i <= irc->message.size) {
        Emote *e = NULL;
        char word[irc->message.size + 1];
        int len = get_word(irc->message.message, i, word);
        if (len == 0) {
            i++;
            continue;
        }
        i += len;
        if ((e = get_emote(word, emote_map)) != NULL) {
            x = 0;
            p = NULL;
            memccpy(dmsg[j].content, e->url_1x, '\0', URL_LEN);
            dmsg[j].is_emote = true;
            j++;
        } else {
            x += len;
            dmsg[j].is_emote = false;
            p = memccpy(dmsg[j].content, word, '\0', URL_LEN);
            j++;
            x++;
        }
        i++;
    }
    j++;
    return j;
}

Emote *parse_emote(Message *message, struct hashmap_s *emote_map) {
    Emote *e;
    int i = 0;
    int j = 0;
    char word[MESSAGE_LEN];

    while (message->message[i] != '\0') {
        if (message->message[i] != ' ') {
            word[j] = message->message[i];
            j++;
        }
        if (message->message[i] == ' ' || message->message[i + 1] == '\0') {
            word[j] = '\0';
            e = get_emote(word, emote_map);
            if (e) {
                printf("%s\n", e->name);
                printf("%s\n", e->id);
                printf("%s\n", e->url_1x);
            }
            j = 0;
        }
        i++;
    }
    return e;
}
