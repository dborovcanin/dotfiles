#!/usr/bin/env bash
set -euo pipefail

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

# ---- pick emoji ----
# choice="$(rofi -dmenu -i -matching fuzzy -p "Emoji" <<'EOF'
choice="$(rofi -dmenu \
    -i -matching fuzzy -p "Emoji" \
    -theme-str 'window { width: 400px; } listview { lines: 15; } element-text { font: "JetBrainsMono Nerd Font 16, monospace 16"; }' <<'EOF'
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
🤗 hug
🤝 handshake

#health
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
🛌 person in bed
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

# birds
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

# reptiles / bugs
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

# clock
🕐 one o’clock
🕑 two o’clock
🕒 three o’clock
🕓 four o’clock
🕔 five o’clock
🕕 six o’clock
🕖 seven o’clock
🕗 eight o’clock
🕘 nine o’clock
🕙 ten o’clock
🕚 eleven o’clock
🕛 twelve o’clock
⏰ alarm clock
⏱️ stopwatch
⏲️ timer clock
🕰️ mantelpiece clock
⌚ watch

# sea
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

#flags
🚩 red flag
🏳 white flag
🏴 black flag
⚑ flag
⚐ flag outline

#custom
󰣇 arch
 gopher
EOF
)"

[ -z "$choice" ] && exit 0

emoji="${choice%% *}"

# copy to clipboard
copy_emoji "$emoji"

# notification
notify-send "Emoji copied" "$emoji"
