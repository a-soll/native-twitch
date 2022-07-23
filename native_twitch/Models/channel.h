//
//  c_file.h
//  native_twitch
//
//  Created by Adam Solloway on 3/8/22.
//

#ifndef channel_h
#define channel_h

#include <stdio.h>
#include "client.h"
#include <stdbool.h>

#define USER_NAME_MAX 25

typedef struct Channel {
    const char *endpoint;
    char broadcaster_language[5];
    char user_id[35];
    char user_name[USER_NAME_MAX];
    char game_id[10];
    char id[25];
    char game_name[50];
    bool is_live;
    char started_at[25];
    char title[500];
    char thumbnail_url[2048]; // 344x194
    char user_login[25];
    char profile_url[2048];
    char viewer_count[15];
    char profile_image_url[2048];
} Channel;

void Channel_init(Channel *c);
void Channel_deinit(Channel *c);
void pop_name(Channel *chan, const char *name);
void print_id(Channel *channel);
void pp(Channel channel);
void get_channel_stream(Client *client, Channel *channel);
void get_profile_url(Client *client, Channel *channel);
int get_followed_channels(Client *client, Channel **follows, int count);
void channel_init_from_json(Channel *channel, struct json_object *json);
void pop_login(Channel *chan, const char *login);

#endif /* c_file_h */
