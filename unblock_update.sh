#!/bin/sh
set -eu

# Атомарное обновление ipset: создаём временные наборы, наполняем, затем swap
create_temp_set() {
  base_set="$1"
  temp_set="${base_set}_new"
  ipset create "$temp_set" hash:net -exist
}

fill_set_from_file() {
  target_set="$1"
  file_path="$2"
  grep -v '^$' "$file_path" | while read -r line || [ -n "$line" ]; do
    [ -z "$line" ] && continue
    [ "${line#?}" = "#" ] && continue
    # CIDR
    cidr=$(echo "$line" | grep -Eo '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}/[0-9]{1,2}')
    if [ -n "$cidr" ]; then ipset -exist add "$target_set" "$cidr"; continue; fi
    # RANGE
    range=$(echo "$line" | grep -Eo '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}-[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}')
    if [ -n "$range" ]; then ipset -exist add "$target_set" "$range"; continue; fi
    # SINGLE IP
    addr=$(echo "$line" | grep -Eo '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}')
    if [ -n "$addr" ]; then ipset -exist add "$target_set" "$addr"; fi
  done
}

swap_sets() {
  base_set="$1"
  temp_set="${base_set}_new"
  ipset swap "$base_set" "$temp_set" 2>/dev/null || true
  ipset destroy "$temp_set" 2>/dev/null || true
}

# Убедимся, что базовые наборы существуют
for s in unblocksh unblocktor unblockvmess unblocktroj; do
  ipset create "$s" hash:net -exist
done

if ls -d /opt/etc/unblock/vpn-*.txt >/dev/null 2>&1; then
  for vpn_file_names in /opt/etc/unblock/vpn-*; do
    vpn_file_name=$(echo "$vpn_file_names" | awk -F '/' '{print $5}' | sed 's/.txt//')
    unblockvpn=$(echo unblock"$vpn_file_name")
    ipset create "$unblockvpn" hash:net -exist
  done
fi

/opt/bin/unblock_dnsmasq.sh
# Ensure critical base masks for YT/Twitter/Instagram exist
if ! grep -q '^ipset=/googlevideo.com/unblocktroj' /opt/etc/unblock.dnsmasq 2>/dev/null; then
cat >>/opt/etc/unblock.dnsmasq <<'EOF'
ipset=/googlevideo.com/unblocktroj
server=/googlevideo.com/127.0.0.1#40500
ipset=/ytimg.com/unblocktroj
server=/ytimg.com/127.0.0.1#40500
ipset=/twimg.com/unblocktroj
server=/twimg.com/127.0.0.1#40500
ipset=/cdninstagram.com/unblocktroj
server=/cdninstagram.com/127.0.0.1#40500
EOF
fi
/opt/etc/init.d/S56dnsmasq restart

# Пересобираем наборы атомарно из файлов доменов/адресов через резолв в отдельном процессе
/opt/bin/unblock_ipset.sh &