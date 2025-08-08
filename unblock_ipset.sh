#!/bin/sh
set -eu

# 2023. Keenetic DNS bot /  Проект: bypass_keenetic / Автор: tas_unn
# GitHub: https://github.com/tas-unn/bypass_keenetic
# Данный бот предназначен для управления обхода блокировок на роутерах Keenetic
# Демо-бот: https://t.me/keenetic_dns_bot
#
# Файл: unblock_ipset.sh, Версия 2.1.9, последнее изменение: 03.05.2023, 22:03
# Доработал: NetworK (https://github.com/ziwork)

cut_local() {
	grep -vE 'localhost|^0\.|^127\.|^10\.|^172\.16\.|^192\.168\.|^::|^fc..:|^fd..:|^fe..:'
}

# Ждём готовности локального DNS (dnsmasq). Если dig отсутствует, пробуем nslookup
until (
  (command -v dig >/dev/null 2>&1 && ADDRS=$(dig +time=2 +tries=1 +short google.com @127.0.0.1 -p 53) && [ -n "$ADDRS" ]) \
  || (command -v nslookup >/dev/null 2>&1 && nslookup -timeout=2 google.com 127.0.0.1 >/dev/null 2>&1)
); do sleep 3; done

# Atomic ipset rebuild helpers
prepare_tmp_set() {
  base_set="$1"
  tmp_set="${base_set}_new"
  ipset create "$tmp_set" hash:net -exist
}

add_to_set() {
  setname="$1"
  value="$2"
  ipset -exist add "$setname" "$value"
}

# Ensure base sets exist and prepare temporary ones
for s in unblocksh unblocktor unblockvmess unblocktroj; do
  ipset create "$s" hash:net -exist
  prepare_tmp_set "$s"
done

while read -r line || [ -n "$line" ]; do

  [ -z "$line" ] && continue
  [ "${line#?}" = "#" ] && continue

  cidr=$(echo "$line" | grep -Eo '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}/[0-9]{1,2}' | cut_local)

  if [ -n "$cidr" ]; then
    add_to_set unblocksh_new "$cidr"
    continue
  fi

  range=$(echo "$line" | grep -Eo '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}-[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' | cut_local)

  if [ -n "$range" ]; then
    add_to_set unblocksh_new "$range"
    continue
  fi

  addr=$(echo "$line" | grep -Eo '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' | cut_local)

  if [ -n "$addr" ]; then
    add_to_set unblocksh_new "$addr"
    continue
  fi

dig +short "$line" @127.0.0.1 -p 53 2>/dev/null | grep -Eo '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' | awk '{system("ipset -exist add unblocksh_new "$1)}'

done < /opt/etc/unblock/shadowsocks.txt


while read -r line || [ -n "$line" ]; do

  [ -z "$line" ] && continue
  [ "${line#?}" = "#" ] && continue

  cidr=$(echo "$line" | grep -Eo '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}/[0-9]{1,2}' | cut_local)

  if [ -n "$cidr" ]; then
    add_to_set unblocktor_new "$cidr"
    continue
  fi

  range=$(echo "$line" | grep -Eo '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}-[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' | cut_local)

  if [ -n "$range" ]; then
    add_to_set unblocktor_new "$range"
    continue
  fi

  addr=$(echo "$line" | grep -Eo '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' | cut_local)

  if [ -n "$addr" ]; then
    add_to_set unblocktor_new "$addr"
    continue
  fi

dig +short "$line" @127.0.0.1 -p 53 2>/dev/null | grep -Eo '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' | awk '{system("ipset -exist add unblocktor_new "$1)}'

done < /opt/etc/unblock/tor.txt


while read -r line || [ -n "$line" ]; do

  [ -z "$line" ] && continue
  [ "${line#?}" = "#" ] && continue

  cidr=$(echo "$line" | grep -Eo '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}/[0-9]{1,2}' | cut_local)

  if [ -n "$cidr" ]; then
    add_to_set unblockvmess_new "$cidr"
    continue
  fi

  range=$(echo "$line" | grep -Eo '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}-[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' | cut_local)

  if [ -n "$range" ]; then
    add_to_set unblockvmess_new "$range"
    continue
  fi

  addr=$(echo "$line" | grep -Eo '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' | cut_local)

  if [ -n "$addr" ]; then
    add_to_set unblockvmess_new "$addr"
    continue
  fi

dig +short "$line" @127.0.0.1 -p 53 2>/dev/null | grep -Eo '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' | awk '{system("ipset -exist add unblockvmess_new "$1)}'

done < /opt/etc/unblock/vmess.txt


while read -r line || [ -n "$line" ]; do

  [ -z "$line" ] && continue
  [ "${line#?}" = "#" ] && continue

  cidr=$(echo "$line" | grep -Eo '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}/[0-9]{1,2}' | cut_local)

  if [ -n "$cidr" ]; then
    ipset -exist add unblocktroj "$cidr"
    continue
  fi

  range=$(echo "$line" | grep -Eo '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}-[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' | cut_local)

  if [ -n "$range" ]; then
    ipset -exist add unblocktroj "$range"
    continue
  fi

  addr=$(echo "$line" | grep -Eo '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' | cut_local)

  if [ -n "$addr" ]; then
    add_to_set unblocktroj_new "$addr"
    continue
  fi

dig +short "$line" @127.0.0.1 -p 53 2>/dev/null | grep -Eo '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' | awk '{system("ipset -exist add unblocktroj_new "$1)}'

done < /opt/etc/unblock/trojan.txt

if ls -d /opt/etc/unblock/vpn-*.txt >/dev/null 2>&1; then
for vpn_file_names in /opt/etc/unblock/vpn-*; do
vpn_file_name=$(echo "$vpn_file_names" | awk -F '/' '{print $5}' | sed 's/.txt//')
unblockvpn=$(echo unblock"$vpn_file_name")
if [ -n '$(ipset list | grep "unblockvpn-")' ] ; then  ipset create "$unblockvpn" hash:net -exist; fi
cat "$vpn_file_names" | while read -r line || [ -n "$line" ]; do
  [ -z "$line" ] && continue
  [ "${line#?}" = "#" ] && continue

  cidr=$(echo "$line" | grep -Eo '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}/[0-9]{1,2}' | cut_local)
  if [ -n "$cidr" ]; then
    ipset -exist add "$unblockvpn" "$cidr"
    continue
  fi

  range=$(echo "$line" | grep -Eo '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}-[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' | cut_local)
  if [ -n "$range" ]; then
    ipset -exist add "$unblockvpn" "$range"
    continue
  fi

  addr=$(echo "$line" | grep -Eo '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' | cut_local)
  if [ -n "$addr" ]; then
    ipset -exist add "$unblockvpn" "$addr"
    continue
  fi

  dig +short "$line" @127.0.0.1 -p 53 2>/dev/null | grep -Eo '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' | awk -v unblockvpn="$unblockvpn" '{system("ipset -exist add " unblockvpn " " $1)}'
done
done
fi

# Atomically swap base sets to newly built ones
for s in unblocksh unblocktor unblockvmess unblocktroj; do
  ipset swap "$s" "${s}_new" 2>/dev/null || true
  ipset destroy "${s}_new" 2>/dev/null || true
done

# unblockvpn - множество
# vpn1.txt - название файла со списком обхода

#while read -r line || [ -n "$line" ]; do
#  [ -z "$line" ] && continue
#  [ "${line#?}" = "#" ] && continue
#
#  cidr=$(echo "$line" | grep -Eo '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}/[0-9]{1,2}' | cut_local)
#  if [ -n "$cidr" ]; then
#    ipset -exist add unblockvpn "$cidr"
#    continue
#  fi
#
#  range=$(echo "$line" | grep -Eo '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}-[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' | cut_local)
#  if [ -n "$range" ]; then
#    ipset -exist add unblockvpn "$range"
#    continue
#  fi
#
#  addr=$(echo "$line" | grep -Eo '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' | cut_local)
#  if [ -n "$addr" ]; then
#    ipset -exist add unblockvpn "$addr"
#    continue
#  fi
#
#  dig +short "$line" @localhost -p 40500 | grep -Eo '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' | awk '{system("ipset -exist add unblockvpn "$1)}'
#done < /opt/etc/unblock/vpn.txt