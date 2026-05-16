shared_script "@vk_Antiloader/modul/antidump.lua"

fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'f17_Squitgame'
author 'F17 Team'
version '1.0.0'
description 'F17 Squid Game - Den Xanh Den Do'

shared_scripts {
    'config/config.lua'
}

VoKy_AntiLoader {
    'client/client.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/server.lua'
}

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/app.js',
    'html/assets/*.css',
    'html/assets/*.js',
    'html/sounds/*.mp3',
    'stream/squidgame_doll.ydr'
}

server_exports {
    'StartMiniGame'
}

dependencies {
    'qb-core',
    'f17notify'
}

optional_dependencies {
    'ox_inventory',
    'f17_level',
    'f17_daotrentroi'
}
