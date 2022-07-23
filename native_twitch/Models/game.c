#include "game.h"

// example box art url: https://static-cdn.jtvnw.net/ttv-boxart/1678360288_IGDB-{width}x{height}.jpg
// placeholder https://static-cdn.jtvnw.net/ttv-static/404_boxart.jpg
void init_game(Game *game, struct json_obect *json) {
    char *name = get_key(json, "name");
    char *id = get_key(json, "id");
    strcpy(game->name, name);
    strcpy(game->id, id);
    const char *box_url = get_key(json, "box_art_url");
    replace_substr(game->box_art_url, box_url, "{width}x{height}", "188x251");
}

int get_top_games(Client *client, Game **games, Paginator *iterator, int items) {
    Game *g;
    int ret = 0;
    int game_index = items;
    const char *base_url = "https://api.twitch.tv/helix/games/top?first=100";
    int base_len = strlen(base_url);
    char url[2048];

    if (iterator->pagination[0] == '\0') {
        memccpy(url, base_url, '\0', strlen(base_url));
        url[base_len] = '\0';
    } else {
        int len = fmt_string(url, "%s&after=%s", base_url, iterator->pagination);
        url[len] = '\0';
    }
    Response response = curl_request(client, url, curl_GET);
    get_json_array(&response, "data");
    if (*games == NULL) {
        g = malloc(sizeof(Game) * response.data_len);
    } else {
        g = realloc(*games, sizeof(Game) * (items + response.data_len));
    }
    ret = response.data_len;
    for (int i = 0; i < response.data_len; i++) {
        Game game;
        struct json_object *data_array_object;
        data_array_object = json_object_array_get_idx(response.data, i);
        init_game(&game, data_array_object);
        g[game_index] = game;
        game_index++;
    }
    set_pagination(iterator->pagination, response.response);
    *games = g;
    clean_response(&response);
    return ret;
}

int get_game_streams(Client *client, Game *game, Channel **channels, Paginator *iterator, int items) {
    Channel *c;
    char *base_url = "https://api.twitch.tv/helix/streams?first=100";
    int base_len = strlen(base_url);
    char url[2048];
    int chan_index = items;

    if (iterator->pagination[0] == '\0') {
        int len = fmt_string(url, "%s&game_id=%s", base_url, game->id);
        url[len] = '\0';
    } else {
        int len = fmt_string(url, "%s&after=%s&game_id=%s", base_url, iterator->pagination, game->id);
        url[len] = '\0';
    }
    Response response = curl_request(client, url, curl_GET);
    get_json_array(&response, "data");
    if (*channels == NULL) {
        c = malloc(sizeof(Channel) * response.data_len);
    } else {
        c = realloc(*channels, sizeof(Channel) * (items + response.data_len));
    }
    int ret = response.data_len;
    for (int i = 0; i < response.data_len; i++) {
        Channel chan;
        struct json_object *data_array_object;
        data_array_object = json_object_array_get_idx(response.data, i);
        channel_init_from_json(&chan, data_array_object);
        c[chan_index] = chan;
        chan_index++;
    }
    set_pagination(iterator->pagination, response.response);
    *channels = c;
    clean_response(&response);
    return ret;
}
