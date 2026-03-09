
# Skripto por aŭtomatigi la purigon de la dosierujo "Téléchargements" kaj agordi cron

# 1. Kreu la skripton **clean_downloads.sh**

path="$HOME/opt/clean_downloads.sh"
touch $path
cat << 'EOF' > "$path"
#!/bin/bash
find "$HOME/Téléchargements" -type f -mtime +30 -delete
EOF
chmod +x "$path"

# 2. Aldonu la cron-taskon se ĝi ne jam ekzistas

CRONLINE="0 2 * * * /home/ron/opt/clean_downloads.sh"
( crontab -l 2>/dev/null | grep -Fv "$path" ; echo "$CRONLINE" ) | crontab -

# 3. Malfermu la redaktiston de crontab por kontrolo/modifo manbaze

crontab -l # NE uzas -e, kiu estas redaktado-reĝimo, kaj ne montras ekzistantajn liniojn!

