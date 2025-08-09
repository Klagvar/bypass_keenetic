#!/bin/sh

# 2023. Keenetic DNS bot /  Проект: bypass_keenetic / Автор: tas_unn
# GitHub: https://github.com/tas-unn/bypass_keenetic
# Данный бот предназначен для управления обхода блокировок на роутерах Keenetic
#
# Файл: 100-redirect.sh, Версия 2.2.0
# Доработал: NetworK (https://github.com/ziwork) и Gemini
# Это исправленная версия для повышения стабильности.

[ "$type" = "ip6tables" ] && exit 0
[ "$table" != "mangle" ] && [ "$table" != "nat" ] && exit 0

set -eu

# --- Конфигурация портов ---
# Порты для перенаправления трафика для разных прокси.
# Убедитесь, что они совпадают с настройками соответствующих сервисов.
SS_REDIR_PORT="1082"
TOR_REDIR_PORT="9141"
VMESS_REDIR_PORT="10810"
TROJAN_REDIR_PORT="10829"
# -------------------------

local_ip=$(ip -4 addr show br0 | grep -oP '(?<=inet\s)\d+(\.\d+){3}')

# -------- DNS health-check & DNAT control --------
# Эта функция проверяет, готов ли локальный DNS-сервер (dnsmasq),
# чтобы избежать "чёрных дыр" в интернете, если dnsmasq упал.
dns_ready() {
  if ! pidof dnsmasq >/dev/null 2>&1; then
    return 1
  fi
  # Проверяем резолв через локальный dnsmasq
  if command -v dig >/dev/null 2>&1; then
    dig +time=2 +tries=1 +short google.com @127.0.0.1 -p 53 >/dev/null 2>&1 && return 0
  fi
  if command -v nslookup >/dev/null 2>&1; then
    nslookup -timeout=2 google.com 127.0.0.1 >/dev/null 2>&1 && return 0
  fi
  return 1
}

# Функция управляет правилом DNAT для DNS-запросов.
# Оно включается только если dns_ready, иначе — выключается для восстановления доступа в интернет.
ensure_dns_dnat() {
  if dns_ready; then
    for protocol in udp tcp; do
      if ! iptables-save -t nat | grep -q -- "-A PREROUTING -i br0 -p $protocol -m $protocol --dport 53 -j DNAT --to-destination $local_ip"; then
        iptables -I PREROUTING -w -t nat -i br0 -p "$protocol" --dport 53 -j DNAT --to "$local_ip"
      fi
    done
  else
    # DNS не готов → удаляем правила, чтобы не блокировать интернет.
    for protocol in udp tcp; do
      while iptables -C PREROUTING -t nat -i br0 -p "$protocol" --dport 53 -j DNAT --to "$local_ip" >/dev/null 2>&1; do
        iptables -D PREROUTING -w -t nat -i br0 -p "$protocol" --dport 53 -j DNAT --to "$local_ip" || true
      done
      # Также удаляем более общее правило, если оно есть
      while iptables -C PREROUTING -t nat -p "$protocol" --dport 53 -j DNAT --to "$local_ip" >/dev/null 2>&1; do
        iptables -D PREROUTING -w -t nat -p "$protocol" --dport 53 -j DNAT --to "$local_ip" || true
      done
    done
  fi
}

# Применяем проверку DNS при каждом запуске скрипта
ensure_dns_dnat


# --- Правила перенаправления для прокси ---

# Shadowsocks
if [ -z "$(iptables-save 2>/dev/null | grep unblocksh)" ]; then
    ipset create unblocksh hash:net -exist 2>/dev/null
    iptables -I PREROUTING -w -t nat -i br0 -p tcp -m set --match-set unblocksh dst -j REDIRECT --to-port "$SS_REDIR_PORT"
    iptables -I PREROUTING -w -t nat -i br0 -p udp -m set --match-set unblocksh dst -j REDIRECT --to-port "$SS_REDIR_PORT"
fi

# Tor
if [ -z "$(iptables-save 2>/dev/null | grep unblocktor)" ]; then
    ipset create unblocktor hash:net -exist 2>/dev/null
    iptables -I PREROUTING -w -t nat -i br0 -p tcp -m set --match-set unblocktor dst -j REDIRECT --to-port "$TOR_REDIR_PORT"
    iptables -I PREROUTING -w -t nat -i br0 -p udp -m set --match-set unblocktor dst -j REDIRECT --to-port "$TOR_REDIR_PORT"
fi

# Vmess
if [ -z "$(iptables-save 2>/dev/null | grep unblockvmess)" ]; then
    ipset create unblockvmess hash:net -exist 2>/dev/null
    iptables -I PREROUTING -w -t nat -i br0 -p tcp -m set --match-set unblockvmess dst -j REDIRECT --to-port "$VMESS_REDIR_PORT"
    iptables -I PREROUTING -w -t nat -i br0 -p udp -m set --match-set unblockvmess dst -j REDIRECT --to-port "$VMESS_REDIR_PORT"
fi

# Trojan
if [ -z "$(iptables-save 2>/dev/null | grep unblocktroj)" ]; then
    ipset create unblocktroj hash:net -exist 2>/dev/null
    iptables -I PREROUTING -w -t nat -i br0 -p tcp -m set --match-set unblocktroj dst -j REDIRECT --to-port "$TROJAN_REDIR_PORT"
    iptables -I PREROUTING -w -t nat -i br0 -p udp -m set --match-set unblocktroj dst -j REDIRECT --to-port "$TROJAN_REDIR_PORT"
fi


# --- Правила маркировки для VPN-клиентов Keenetic ---
TAG="100-redirect.sh"
if ls -d /opt/etc/unblock/vpn-*.txt >/dev/null 2>&1; then
    for vpn_file_name in /opt/etc/unblock/vpn*; do
        vpn_unblock_name=$(echo "$vpn_file_name" | awk -F '/' '{print $5}' | sed 's/.txt//')
        unblockvpn=$(echo "unblock$vpn_unblock_name")
        vpn_type=$(echo "$unblockvpn" | sed 's/-/ /g' | awk '{print $NF}')
        vpn_link_up=$(curl -s "localhost:79/rci/show/interface/$vpn_type/link" | tr -d '"')

        if [ "$vpn_link_up" = "up" ]; then
            vpn_type_lower=$(echo "$vpn_type" | tr '[:upper:]' '[:lower:]')
            get_vpn_fwmark_id=$(grep "$vpn_type_lower" /opt/etc/iproute2/rt_tables | awk '{print $1}')

            if [ -n "${get_vpn_fwmark_id}" ]; then
                vpn_table_id=$get_vpn_fwmark_id
            else
                continue
            fi
            vpn_mark_id=$(printf "0x%x" "$vpn_table_id")

            if ! iptables-save -t mangle | grep -q "$unblockvpn"; then
                info_vpn_rule="ipset: $unblockvpn, mark_id: $vpn_mark_id"
                logger -t "$TAG" "$info_vpn_rule"

                ipset create "$unblockvpn" hash:net -exist 2>/dev/null

                fastnat=$(curl -s "localhost:79/rci/show/version" | grep ppe)
                software=$(curl -s "localhost:79/rci/show/rc/ppe" | grep software -C1 | head -1 | awk '{print $2}' | tr -d ',')
                hardware=$(curl -s "localhost:79/rci/show/rc/ppe" | grep hardware -C1 | head -1 | awk '{print $2}' | tr -d ',')

                if [ -z "$fastnat" ] && [ "$software" = "false" ] && [ "$hardware" = "false" ]; then
                    logger -t "$TAG" "VPN: fastnat/swnat/hwnat ВЫКЛЮЧЕНЫ, применяем MARK"
                    # С отключенными ускорителями
                    iptables -A PREROUTING -w -t mangle -i br0 -p tcp -m set --match-set "$unblockvpn" dst -j MARK --set-mark "$vpn_mark_id"
                    iptables -A PREROUTING -w -t mangle -i br0 -p udp -m set --match-set "$unblockvpn" dst -j MARK --set-mark "$vpn_mark_id"
                else
                    logger -t "$TAG" "VPN: fastnat/swnat/hwnat ВКЛЮЧЕНЫ, применяем CONNMARK"
                    # С включенными ускорителями
                    iptables -A PREROUTING -w -t mangle -i br0 -m conntrack --ctstate NEW -m set --match-set "$unblockvpn" dst -j CONNMARK --set-mark "$vpn_mark_id"
                    iptables -A PREROUTING -w -t mangle -i br0 -j CONNMARK --restore-mark
                fi
            fi # iptables check
        fi # link check
    done
fi # file check

exit 0