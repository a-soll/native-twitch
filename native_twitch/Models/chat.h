//
//  chat.h
//  native_twitch
//
//  Created by Adam Solloway on 5/11/22.
//

#ifndef chat_h
#define chat_h

#include "client.h"
#include "hashmap.h"
#include <twitchchat/twitchchat.h>

#define MAX_WORDS 250

typedef struct MsgFragment {
    char content[URL_LEN]; // url len because replacing emote word with link
    bool is_emote;
} MsgFragment;

MsgFragment msg_frag[MAX_WORDS];

typedef struct Emote {
    const char *name;
    char url_1x[200];
    // const char *url_2x;
    // const char *url_3x;
    const char *id;
    int start;
    int end;
} Emote;

void populate_emote(Emote *emote);
void get_bttv_global(Client *client, struct hashmap_s *emote_map);
void get_bttv_channel_emotes(Client *client, const char *channel_id, struct hashmap_s *emote_map);
void get_ffz_channel_emotes(Client *client, const char *channel_id, struct hashmap_s *emote_map);
void get_channel_emotes(Client *client, const char *channel_id, struct hashmap_s *emote_map);
void get_global_emotes(Client *client, struct hashmap_s *emote_map);
struct hashmap_s init_emote_map(const unsigned initial_size);
Emote *get_emote(const char *word, struct hashmap_s *emote_map);
const char *message_to_html(Message *message, struct hashmap_s *emote_map);
Emote *parse_emote(Message *message, struct hashmap_s *emote_map);
int get_word(char *str, int ind, char word[]);
int build_message(Irc *irc, MsgFragment *dmsg, struct hashmap_s *emote_map);
void add_bttv_emote(struct json_object *json, int array_len, struct hashmap_s *emote_map);

#endif /* chat_h */
