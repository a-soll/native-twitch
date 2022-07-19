//
//  videoplayer.h
//  native_twitch
//
//  Created by Adam Solloway on 3/17/22.
//

#ifndef videoplayer_h
#define videoplayer_h

#include <json-c/json.h>
#include "channel.h"
#include "client.h"

typedef struct VideoToken {
    const char *value;
    const char *signature;
    char *encoded_value;
} VideoToken;

typedef struct Resolution {
    char name[25];
    char resolution[15];
    char link[URL_LEN];
} Resolution;

typedef struct Video {
    VideoToken token;
    const char *token_url;
    const char *vod;
    const char *channel;
    Resolution *resolution_list;
} Video;

void get_stream_url(Client *client, Channel *channel, Video *player, bool is_vod);
void get_video_token(Client *client, Video *player, Channel *channel);
Video init_video_player();
void token_encode(VideoToken *token);
void parse_links(Video *video, char *data);

#endif /* videoplayer_h */
