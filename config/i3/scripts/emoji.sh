#!/usr/bin/env bash
set -euo pipefail

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
☕ coffee
🍺 beer
🍕 pizza
🍔 burger
🍎 apple
🥑 avocado
🍌 banana
🎂 cake
🍰 dessert
🎁 gift
📌 pin
📍 location
📎 paperclip
📅 calendar
📁 folder
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

#custom
󰣇 arch
 gopher
EOF
)"

[ -z "$choice" ] && exit 0

emoji="${choice%% *}"

# copy to clipboard
printf "%s" "$emoji" | xclip -selection clipboard
printf "%s" "$emoji" | xclip -selection primary

# notification
notify-send "Emoji copied" "$emoji"