#!/usr/bin/env bash
set -euo pipefail

# The emoji picker, drawn by config/rofi/menu.rasi.
#
# Return copies the emoji to the clipboard; the name and the category behind
# each one are matched but never shown, so "cat", "animal" and "🐱" all find
# the same row.

here=$(dirname "$(realpath "${BASH_SOURCE[0]}")")

# theme:begin emoji
key_color="#d5c4a1"
font="JetBrainsMonoNL NFP 16"
# theme:end

# nf-md-emoticon_happy_outline, spelled as a code point like the icons in power.sh.
icon=$'\U000F01F5'

copy_emoji() {
    local emoji="$1"

    if [[ -n "${WAYLAND_DISPLAY:-}" || -n "${SWAYSOCK:-}" ]]; then
        if command -v wl-copy >/dev/null 2>&1; then
            printf "%s" "$emoji" | wl-copy --trim-newline
            printf "%s" "$emoji" | wl-copy --trim-newline --primary || true
            return
        fi
    fi

    if command -v xclip >/dev/null 2>&1; then
        printf "%s" "$emoji" | xclip -selection clipboard
        printf "%s" "$emoji" | xclip -selection primary
        return
    fi

    printf "emoji.sh: no supported clipboard tool found\n" >&2
    exit 1
}

# The list below is "emoji name..." under a "# category" heading. Every row
# leaves rofi as "emoji  name<tab>name category": the first column is shown,
# the second is only matched, which is what makes a category searchable
# without a heading taking up a row of its own.
entries() {
    awk '
        /^[[:space:]]*$/ { next }
        /^#/ {
            category = substr($0, 2)
            gsub(/^[[:space:]]+|[[:space:]]+$/, "", category)
            next
        }
        {
            name = substr($0, index($0, " ") + 1)
            printf "%s  %s\t%s %s\n", $1, name, name, category
        }
    ' <<'EOF'
# smileys faces
😀 grinning
😁 smile eyes
😂 joy
🤣 rofl
😃 happy
😄 happy2
😅 sweat smile
😆 laugh
😉 wink
😊 blush
🙂 slight smile
🙃 upside down
😋 yum
😎 cool sunglasses
🤓 nerd
😍 heart eyes
😘 kiss
😗 kiss2
😙 kiss smile
😚 closed eye kiss
🤗 hug
🤔 thinking question
🤨 suspicious
😐 neutral
😑 expressionless
😶 no mouth
😏 smirk
😒 unamused
🙄 eye roll
😬 grimace
😮 surprised
😯 surprised2
😲 shocked
😳 flushed
🥺 pleading
🫡 salute
😢 cry
😭 sob
😤 frustrated
😠 angry
😡 rage
🤯 mind blown
😱 scream
😨 fear
😰 anxious
😥 relief
😓 sweat
🤝 handshake

# health
🥶 cold face
🧊 ice
❄️ snowflake
🌬️ wind face
🤧 sneezing face
🤒 face with thermometer
🤕 face with head-bandage
😷 face with medical mask
🤢 nauseated face
🤮 face vomiting
😵 dizzy face
🩺 stethoscope
💊 pill
🌡️ thermometer

# animals
🐶 dog
🐕 dog2
🐩 poodle
🐺 wolf
🦊 fox
🐱 cat
🐈 cat2
🦁 lion
🐯 tiger
🐅 tiger2
🐆 leopard
🐴 horse
🫎 moose
🦌 deer
🐮 cow
🐷 pig
🐽 pig nose
🐭 mouse
🐹 hamster
🐰 rabbit
🦝 raccoon
🐻 bear
🐻‍❄️ polar bear
🐼 panda
🐨 koala
🐸 frog
🐵 monkey
🙈 monkey see no evil
🙉 monkey hear no evil
🙊 monkey speak no evil
🦍 gorilla
🦧 orangutan
🐾 paw prints

# birds animals
🐔 chicken
🐓 rooster
🐣 chick
🐤 baby chick
🐦 bird
🐧 penguin
🦆 duck
🦅 eagle
🦉 owl
🦜 parrot

# reptiles bugs animals
🐍 snake
🐢 turtle
🦎 lizard
🐊 crocodile
🐉 dragon
🐲 dragon face
🐛 bug
🦋 butterfly
🐌 snail
🐞 ladybug
🦗 cricket
🕷 spider
🦂 scorpion

# sea animals
🐳 whale
🐋 whale2
🐬 dolphin
🦈 shark
🐙 octopus
🦑 squid
🦀 crab
🦞 lobster
🐠 fish
🐟 fish2
🐡 blowfish

# arrows
➡️ right arrow
⬅️ left arrow
⬆️ up arrow
⬇️ down arrow
↗️ up-right arrow
↘️ down-right arrow
↙️ down-left arrow
↖️ up-left arrow
↔️ left-right arrow
↕️ up-down arrow
➜ rightwards arrow
➝ right arrow
➞ rightwards arrow
🔙 back arrow
🔝 top arrow
🔚 end arrow
🔜 soon arrow

# clock time
🕐 one o'clock
🕑 two o'clock
🕒 three o'clock
🕓 four o'clock
🕔 five o'clock
🕕 six o'clock
🕖 seven o'clock
🕗 eight o'clock
🕘 nine o'clock
🕙 ten o'clock
🕚 eleven o'clock
🕛 twelve o'clock
⏰ alarm clock
⏱️ stopwatch
⏲️ timer clock
🕰️ mantelpiece clock
⌚ watch

# spooky
👻 ghost
🧛 vampire
🧛‍♂️ man vampire
🧛‍♀️ woman vampire
🧟 zombie
🧟‍♂️ man zombie
🧟‍♀️ woman zombie
🧙 mage
🧙‍♂️ man mage
🧙‍♀️ woman mage
🧹 broom
🕸️ spider web
🕷️ spider
🦇 bat
💀 skull
🎃 jack-o-lantern
🪦 headstone
🩸 drop of blood
🌕 full moon
🌑 new moon
🌫️ fog
🕯️ candle
🔮 crystal ball

# weapons
🔪 kitchen knife
🗡️ dagger
⚔️ crossed swords
🏹 bow and arrow
🛡️ shield
🪓 axe
🔨 hammer
⛏️ pick
🪚 saw
🔱 trident emblem
💣 bomb
🔫 gun
🪖 military helmet
🎖️ military medal
🏅 medal
🥇 gold medal
🚁 helicopter
✈️ airplane
🛩️ small airplane
🚢 warship ship
⛴️ ferry ship
🚨 siren
📯 horn
🚧 barricade
🏴‍☠️ pirate flag
☠️ skull and crossbones
💥 collision explosion
🧨 firecracker

# symbols
✅ check checkbox
✔ checkmark
☑ checked box
❌ cross x
✖ heavy x
🛑 stop sign
⛔ no entry stop
❓ question
❔ question outline
❕ exclamation
❗ exclamation mark
⚠ warning
🚫 forbidden
💯 hundred
🔴 red
🟢 green
🟡 yellow
🔵 blue
⚫ black circle
⚪ white circle

# hands
👍 thumbs up like
👎 thumbs down
👊 fist bump
✊ raised fist
🤛 left fist
🤜 right fist
👏 clap
🙌 celebrate
👐 open hands
🤲 palms up
🙏 pray thanks
👋 wave hello
🤚 raised hand
✋ stop hand
🖐 hand
👌 ok
🤌 italian hand
🤏 pinch
🤟 rock
🤘 metal
🤙 call me
💪 muscle workout strong
🦾 mechanical arm
🖕 middle finger
👉 right pointing finger
👈 left pointing finger

# people
👨 man
👩 woman
🧑 person
👦 boy
👧 girl
👶 baby
👴 old man
👵 old woman
🧔 beard man
👨‍💻 programmer
👩‍💻 programmer woman
👨‍🔧 mechanic
👩‍🔧 mechanic woman
👨‍🍳 cook
👩‍🍳 cook woman
👨‍🚀 astronaut
👩‍🚀 astronaut woman
🤦 facepalm
🤦‍♂️ man facepalm
🤦‍♀️ woman facepalm
👮 police
🕵 detective
🥷 ninja
🏃 running
🚶 walking
🧍 standing
🧎 kneeling
🧘 meditation yoga
🏋 workout lifting
🤸 gymnastics
🤼 wrestling
🤽 water polo
🏊 swimming
🛀 bath
🛌 sleep bed
💃 dance
🕺 dance man

# food
☕ coffee
🍺 beer
🍕 pizza
🍔 burger
🍎 apple
🥑 avocado
🍌 banana
🎂 cake
🍰 dessert
🥕 carrot
🍆 eggplant
🥬 lettuce

# objects
💡 idea
🔥 fire
⭐ star
✨ sparkles
🌙 moon
☀ sun
🌧 rain
❄ snow
⚡ lightning
🎁 gift
📌 pin
📍 location
📎 paperclip
📅 calendar
📁 folder
🧣 scarf
🧦 socks
🧤 gloves
🥊 glove
📂 open folder
🗂 files
📝 note
✏ pencil
🖊 pen
📖 book
💻 laptop
🖥 desktop
🖱 mouse
⌨ keyboard
📱 phone
☎ telephone
📡 antenna
🔒 lock
🔓 unlock
🔑 key
💾 save disk
🔋 battery
💬 message
🗨 speech bubble
📢 announcement
📣 megaphone
📬 mailbox
🪢 rope
🪝 hook
🔗 chain

# flags
🚩 red flag
🏳 white flag
🏴 black flag
⚑ flag
⚐ flag outline

# custom
󰣇 arch
 gopher
EOF
}

selection=$(entries | rofi -dmenu -matching fuzzy -i \
    -p "$icon" \
    -display-columns 1 -display-column-separator '\t' \
    -mesg "<span foreground=\"$key_color\">Return</span> copy  ·  a name or a category matches" \
    -theme "$here/../config/rofi/menu.rasi" \
    -theme-str "window {width: 28em;}
                listview {lines: 12; spacing: 2px;}
                element {padding: 3px 12px;}
                element-text {font: \"$font\";}")

[ -z "$selection" ] && exit 0

# rofi prints the whole row, hidden column and all; the emoji is what stands
# before the two spaces the row was built with.
emoji=${selection%% *}

copy_emoji "$emoji"

notify-send "Emoji copied" "$emoji"
