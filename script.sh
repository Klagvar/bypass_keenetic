#!/bin/sh

# 2023. Keenetic DNS bot /  Проект: bypass_keenetic / Автор: tas_unn
# GitHub: https://github.com/tas-unn/bypass_keenetic
# Данный бот предназначен для управления обхода блокировок на роутерах Keenetic
# Демо-бот: https://t.me/keenetic_dns_bot
#
# Файл: script.sh, Версия 2.2.0, последнее изменение: 24.09.2023, 22:32
# Доработал: NetworK (https://github.com/ziwork)

# оригинальный репозиторий (tas-unn), FORK by NetworK (ziwork)

repo="Klagvar"

# ip роутера
lanip=$(ip addr show br0 | grep -Po "(?<=inet ).*(?=/)" | awk '{print $1}')
ssredir="ss-redir"
localportsh=$(grep "localportsh" /opt/etc/bot_config.py | grep -Eo "[0-9]{1,5}")
#dnsporttor=$(grep "dnsporttor" /opt/etc/bot_config.py | grep -Eo "[0-9]{1,5}")
localporttor=$(grep "localporttor" /opt/etc/bot_config.py | grep -Eo "[0-9]{1,5}")
localportvmess=$(grep "localportvmess" /opt/etc/bot_config.py | grep -Eo "[0-9]{1,5}")
localporttrojan=$(grep "localporttrojan" /opt/etc/bot_config.py | grep -Eo "[0-9]{1,5}")
# Если доступен статус ndnproxy, подхватываем актуальные порты DoT/DoH, иначе читаем из конфига
if [ -f /tmp/ndnproxymain.stat ]; then
  dnsovertlsport=$(grep -Eo 'DoTPort: [0-9]+' /tmp/ndnproxymain.stat | awk '{print $2}')
  dnsoverhttpsport=$(grep -Eo 'DoHPort: [0-9]+' /tmp/ndnproxymain.stat | awk '{print $2}')
fi
dnsovertlsport=${dnsovertlsport:-$(grep "dnsovertlsport" /opt/etc/bot_config.py | grep -Eo "[0-9]{1,5}")}
dnsoverhttpsport=${dnsoverhttpsport:-$(grep "dnsoverhttpsport" /opt/etc/bot_config.py | grep -Eo "[0-9]{1,5}")}
keen_os_full=$(curl -s localhost:79/rci/show/version/title | tr -d \",)
keen_os_short=$(curl -s localhost:79/rci/show/version/title | tr -d \", | cut -b 1)

if [ "$1" = "-remove" ]; then
    echo "Начинаем удаление"
    # opkg remove curl mc tor tor-geoip bind-dig cron dnsmasq-full ipset iptables obfs4 shadowsocks-libev-ss-redir shadowsocks-libev-config
    opkg remove tor tor-geoip bind-dig cron dnsmasq-full ipset iptables obfs4 shadowsocks-libev-ss-redir shadowsocks-libev-config v2ray trojan
    echo "Пакеты удалены, удаляем папки, файлы и настройки"
    ipset flush testset
    ipset flush unblocktor
    ipset flush unblocksh
    ipset flush unblockvmess
    ipset flush unblocktroj
    #ipset flush unblockvpn
    if ls -d /opt/etc/unblock/vpn-*.txt >/dev/null 2>&1; then
     for vpn_file_names in /opt/etc/unblock/vpn-*; do
     vpn_file_name=$(echo "$vpn_file_names" | awk -F '/' '{print $5}' | sed 's/.txt//')
     # shellcheck disable=SC2116
     unblockvpn=$(echo unblock"$vpn_file_name")
     ipset flush "$unblockvpn"
     done
    fi

    chmod 777 /opt/root/get-pip.py || rm -Rfv /opt/root/get-pip.py
    chmod 777 /opt/etc/crontab || rm -Rfv /opt/etc/crontab
    chmod 777 /opt/etc/init.d/S22shadowsocks || rm -Rfv /opt/etc/init.d/S22shadowsocks
    chmod 777 /opt/etc/init.d/S22trojan || rm -Rfv /opt/etc/init.d/S22trojan
    chmod 777 /opt/etc/init.d/S24v2ray || rm -Rfv /opt/etc/init.d/S24v2ray
    chmod 777 /opt/etc/init.d/S35tor || rm -Rfv /opt/etc/init.d/S35tor
    chmod 777 /opt/etc/init.d/S56dnsmasq || rm -Rfv /opt/etc/init.d/S56dnsmasq
    chmod 777 /opt/etc/init.d/S99unblock || rm -Rfv /opt/etc/init.d/S99unblock
    chmod 777 /opt/etc/ndm/netfilter.d/100-redirect.sh || rm -rfv /opt/etc/ndm/netfilter.d/100-redirect.sh
    chmod 777 /opt/etc/ndm/ifstatechanged.d/100-unblock-vpn.sh || rm -rfv /opt/etc/ndm/ifstatechanged.d/100-unblock-vpn.sh
    chmod 777 /opt/etc/nmd/fs.d/100-ipset.sh || rm -rfv /opt/etc/nmd/fs.d/100-ipset.sh
    chmod 777 /opt/bin/unblock_dnsmasq.sh || rm -rfv /opt/bin/unblock_dnsmasq.sh
    chmod 777 /opt/bin/unblock_update.sh || rm -rfv /opt/bin/unblock_update.sh
    chmod 777 /opt/bin/unblock_ipset.sh || rm -rfv /opt/bin/unblock_ipset.sh
    chmod 777 /opt/etc/unblock.dnsmasq || rm -rfv /opt/etc/unblock.dnsmasq
    chmod 777 /opt/etc/dnsmasq.conf || rm -rfv /opt/etc/dnsmasq.conf
    chmod 777 /opt/tmp/tor || rm -Rfv /opt/tmp/tor
    # chmod 777 /opt/etc/unblock || rm -Rfv /opt/etc/unblock
    chmod 777 /opt/etc/tor || rm -Rfv /opt/etc/tor
    chmod 777 /opt/etc/v2ray || rm -Rfv /opt/etc/v2ray
    chmod 777 /opt/etc/trojan || rm -Rfv /opt/etc/trojan
    echo "Созданные папки, файлы и настройки удалены"
    echo "Если вы хотите полностью отключить DNS Override, перейдите в меню Сервис -> DNS Override -> DNS Override ВЫКЛ. После чего включится встроенный (штатный) DNS и роутер перезагрузится."
    #echo "Отключаем opkg dns-override"
    #ndmc -c 'no opkg dns-override'
    #sleep 3
    #echo "Сохраняем конфигурацию на роутере"
    #ndmc -c 'system configuration save'
    #sleep 3
    #echo "Перезагрузка роутера"
    #sleep 3
    #ndmc -c 'system reboot'
    exit 0
fi

if [ "$1" = "-install" ]; then
    echo "Начинаем установку"
    echo "Ваша версия KeenOS" "${keen_os_full}"
    opkg update
    # opkg install curl mc tor tor-geoip bind-dig cron dnsmasq-full ipset iptables obfs4 shadowsocks-libev-ss-redir shadowsocks-libev-config
    opkg install curl mc tor tor-geoip bind-dig cron dnsmasq-full ipset iptables obfs4 shadowsocks-libev-ss-redir shadowsocks-libev-config python3 python3-pip v2ray trojan
    curl -O https://bootstrap.pypa.io/get-pip.py
    sleep 3
    python get-pip.py
    pip install pyTelegramBotAPI telethon
    #pip install telethon
    #pip install pathlib
    #pip install --upgrade pip
    #pip install pytelegrambotapi
    #pip install paramiko
    echo "Установка пакетов завершена. Продолжаем установку"

    #ipset flush unblocktor
    #ipset flush unblocksh
    #ipset flush unblockvmess
    #ipset flush unblocktroj
    #ipset flush testset
    #ipset flush unblockvpn

    # есть поддержка множества hash:net или нет, если нет, то при этом вы потеряете возможность разблокировки по диапазону и CIDR
    set_type="hash:net"
    ipset create testset hash:net -exist > /dev/null 2>&1
    retVal=$?
    if [ $retVal -ne 0 ]; then
        set_type="hash:ip"
    fi

    echo "Переменные роутера найдены"
    # создания множеств IP-адресов unblock
    # rm -rf /opt/etc/ndm/fs.d/100-ipset.sh
    # chmod 777 /opt/etc/nmd/fs.d/100-ipset.sh || rm -rfv /opt/etc/nmd/fs.d/100-ipset.sh
    curl -o /opt/etc/ndm/fs.d/100-ipset.sh https://raw.githubusercontent.com/${repo}/bypass_keenetic/main/100-ipset.sh
    chmod 755 /opt/etc/ndm/fs.d/100-ipset.sh || chmod +x /opt/etc/ndm/fs.d/100-ipset.sh
    sed -i "s/hash:net/${set_type}/g" /opt/etc/ndm/fs.d/100-ipset.sh
    echo "Созданы файлы под множества"

    # chmod 777 /opt/tmp/tor || rm -Rfv /opt/tmp/tor
    # chmod 777 /opt/etc/tor/torrc || rm -Rfv /opt/etc/tor/torrc
    mkdir -p /opt/tmp/tor
    curl -o /opt/etc/tor/torrc https://raw.githubusercontent.com/${repo}/bypass_keenetic/main/torrc
    sed -i "s/hash:net/${set_type}/g" /opt/etc/tor/torrc
    echo "Установлены настройки Tor"

    # chmod 777 /opt/etc/shadowsocks.json || rm -Rfv /opt/etc/shadowsocks.json
    # chmod 777 /opt/etc/init.d/S22shadowsocks
    curl -o /opt/etc/shadowsocks.json https://raw.githubusercontent.com/${repo}/bypass_keenetic/main/shadowsocks.json
    echo "Установлены настройки Shadowsocks"
    sed -i "s/ss-local/${ssredir}/g" /opt/etc/init.d/S22shadowsocks
    chmod 0755 /opt/etc/shadowsocks.json || chmod 755 /opt/etc/init.d/S22shadowsocks || chmod +x /opt/etc/init.d/S22shadowsocks
    echo "Установлен параметр ss-redir для Shadowsocks"

    # chmod 777 /opt/etc/v2ray/config.json || rm -Rfv /opt/etc/v2ray/config.json
    curl -o /opt/etc/v2ray/config.json https://raw.githubusercontent.com/${repo}/bypass_keenetic/main/vmessconfig.json

    # chmod 777 /opt/etc/trojan/config.json || rm -Rfv /opt/etc/trojan/config.json
    curl -o /opt/etc/trojan/config.json https://raw.githubusercontent.com/${repo}/bypass_keenetic/main/trojanconfig.json
    chmod 755 /opt/etc/init.d/S24v2ray || chmod +x /opt/etc/init.d/S24v2ray
    sed -i 's|ARGS="-confdir /opt/etc/v2ray"|ARGS="run -c /opt/etc/v2ray/config.json"|g' /opt/etc/init.d/S24v2ray > /dev/null 2>&1

    # unblock folder and files
    mkdir -p /opt/etc/unblock
    touch /opt/etc/hosts || chmod 0755 /opt/etc/hosts
    touch /opt/etc/unblock/shadowsocks.txt || chmod 0755 /opt/etc/unblock/shadowsocks.txt
    touch /opt/etc/unblock/tor.txt || chmod 0755 /opt/etc/unblock/tor.txt
    touch /opt/etc/unblock/trojan.txt || chmod 0755 /opt/etc/unblock/trojan.txt
    touch /opt/etc/unblock/vmess.txt || chmod 0755 /opt/etc/unblock/vmess.txt
    touch /opt/etc/unblock/vpn.txt || chmod 0755 /opt/etc/unblock/vpn.txt
    echo "Созданы файлы под сайты и ip-адреса для обхода блокировок для SS, Tor, Trojan и v2ray, VPN"

    # Seed trojan.txt with repo list.txt if it's empty (so base masks for youtube/twitter/instagram are present)
    if [ ! -s /opt/etc/unblock/trojan.txt ]; then
      curl -fsSLo /opt/etc/unblock/trojan.txt https://raw.githubusercontent.com/${repo}/bypass_keenetic/main/list.txt || true
    fi

    # unblock_ipset.sh
    # chmod 777 /opt/bin/unblock_ipset.sh || rm -rfv /opt/bin/unblock_ipset.sh
    curl -o /opt/bin/unblock_ipset.sh https://raw.githubusercontent.com/${repo}/bypass_keenetic/main/unblock_ipset.sh
    chmod 755 /opt/bin/unblock_ipset.sh || chmod +x /opt/bin/unblock_ipset.sh
    sed -i "s/40500/${dnsovertlsport}/g" /opt/bin/unblock_ipset.sh || true
    echo "Установлен скрипт для заполнения множеств unblock IP-адресами заданного списка доменов"

    # unblock_dnsmasq.sh
    # chmod 777 /opt/bin/unblock_dnsmasq.sh || rm -rfv /opt/bin/unblock_dnsmasq.sh
    cat <<'EOF' > /opt/bin/unblock_dnsmasq.sh
#!/bin/sh

# 2023. Keenetic DNS bot /  Проект: bypass_keenetic / Автор: tas_unn
# GitHub: https://github.com/tas-unn/bypass_keenetic
# Данный бот предназначен для управления обхода блокировок на роутерах Keenetic
# Демо-бот: https://t.me/keenetic_dns_bot
#
# Файл: unblock.dnsmasq, Версия 2.2.0 (base-mask generation)
# Доработал: NetworK (https://github.com/ziwork) + Klagvar fork adjustments

cat /dev/null > /opt/etc/unblock.dnsmasq

#=======================================================================================
# Shadowsocks list → unblocksh
while read -r line || [ -n "$line" ]; do
  [ -z "$line" ] && continue
  [ "${line#?}" = "#" ] && continue
  echo "$line" | grep -Eq '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' && continue

  host="$line"
  if echo "$host" | grep -q '\*'; then
    host=$(echo "$host" | sed 's/^\*\.?//')
  fi
  echo "ipset=/$host/unblocksh" >> /opt/etc/unblock.dnsmasq
  echo "server=/$host/127.0.0.1#40500" >> /opt/etc/unblock.dnsmasq

done < /opt/etc/unblock/shadowsocks.txt
#=======================================================================================

# Tor list → unblocktor
while read -r line || [ -n "$line" ]; do
  [ -z "$line" ] && continue
  [ "${line#?}" = "#" ] && continue
  echo "$line" | grep -Eq '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' && continue

  host="$line"
  if echo "$host" | grep -q '\*'; then
    host=$(echo "$host" | sed 's/^\*\.?//')
  fi
  echo "ipset=/$host/unblocktor" >> /opt/etc/unblock.dnsmasq
  echo "server=/$host/127.0.0.1#40500" >> /opt/etc/unblock.dnsmasq

done < /opt/etc/unblock/tor.txt

# Vmess list → unblockvmess
while read -r line || [ -n "$line" ]; do
  [ -z "$line" ] && continue
  [ "${line#?}" = "#" ] && continue
  echo "$line" | grep -Eq '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' && continue

  host="$line"
  if echo "$host" | grep -q '\*'; then
    host=$(echo "$host" | sed 's/^\*\.?//')
  fi
  echo "ipset=/$host/unblockvmess" >> /opt/etc/unblock.dnsmasq
  echo "server=/$host/127.0.0.1#40500" >> /opt/etc/unblock.dnsmasq

done < /opt/etc/unblock/vmess.txt

# Trojan list → unblocktroj (with base-mask normalization for common YT/Twitter/Instagram CDNs)
while read -r line || [ -n "$line" ]; do
  [ -z "$line" ] && continue
  [ "${line#?}" = "#" ] && continue
  echo "$line" | grep -Eq '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' && continue

  host="$line"
  if echo "$host" | grep -q '\*'; then
    host=$(echo "$host" | sed 's/^\*\.?//')
  fi
  base=$(echo "$host" | awk -F. '{n=NF; if(n>=2){print $(n-1)"."$n}else{print $0}}')
  case "$base" in
    googlevideo.com|ytimg.com|twimg.com|cdninstagram.com)
      host="$base" ;;
  esac
  echo "ipset=/$host/unblocktroj" >> /opt/etc/unblock.dnsmasq
  echo "server=/$host/127.0.0.1#40500" >> /opt/etc/unblock.dnsmasq

done < /opt/etc/unblock/trojan.txt

# VPN-specific lists → unblockvpn-*
if ls -d /opt/etc/unblock/vpn-*.txt >/dev/null 2>&1; then
for vpn_file_names in /opt/etc/unblock/vpn-*; do
  vpn_file_name=$(echo "$vpn_file_names" | awk -F '/' '{print $5}' | sed 's/.txt//')
  unblockvpn=$(echo unblock"$vpn_file_name")
  cat "$vpn_file_names" | while read -r line || [ -n "$line" ]; do
    [ -z "$line" ] && continue
    [ "${line#?}" = "#" ] && continue
    echo "$line" | grep -Eq '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' && continue
    host="$line"
    if echo "$host" | grep -q '\*'; then
      host=$(echo "$host" | sed 's/^\*\.?//')
    fi
    echo "ipset=/$host/$unblockvpn" >> /opt/etc/unblock.dnsmasq
    echo "server=/$host/127.0.0.1#40500" >> /opt/etc/unblock.dnsmasq
  done
done
fi

#script0
#script1
#script2
#script3
#script4
#script5
#script6
#script7
#script8
#script9
EOF
    chmod 755 /opt/bin/unblock_dnsmasq.sh || chmod +x /opt/bin/unblock_dnsmasq.sh
    sed -i "s/40500/${dnsovertlsport}/g" /opt/bin/unblock_dnsmasq.sh || true
    /opt/bin/unblock_dnsmasq.sh
    # Add critical base masks for Trojan (YouTube/Twitter/Instagram) if not already present
    if ! grep -q '^ipset=/googlevideo.com/unblocktroj' /opt/etc/unblock.dnsmasq; then
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
    /opt/etc/init.d/S56dnsmasq restart || true
    echo "Установлен скрипт для формирования дополнительного конфигурационного файла dnsmasq из заданного списка доменов и его запуск"

    # unblock_update.sh
    # chmod 777 /opt/bin/unblock_update.sh || rm -rfv /opt/bin/unblock_update.sh
    curl -o /opt/bin/unblock_update.sh https://raw.githubusercontent.com/${repo}/bypass_keenetic/main/unblock_update.sh
    chmod 755 /opt/bin/unblock_update.sh || chmod +x /opt/bin/unblock_update.sh
    echo "Установлен скрипт ручного принудительного обновления системы после редактирования списка доменов"

    # s99unblock
    # chmod 777 /opt/etc/init.d/S99unblock || rm -Rfv /opt/etc/init.d/S99unblock
    curl -o /opt/etc/init.d/S99unblock https://raw.githubusercontent.com/${repo}/bypass_keenetic/main/S99unblock
    chmod 755 /opt/etc/init.d/S99unblock || chmod +x /opt/etc/init.d/S99unblock
    echo "Установлен cкрипт автоматического заполнения множества unblock при загрузке маршрутизатора"

    # 100-redirect.sh
    # chmod 777 /opt/etc/ndm/netfilter.d/100-redirect.sh || rm -rfv /opt/etc/ndm/netfilter.d/100-redirect.sh
    cat <<'EOF' > /opt/etc/ndm/netfilter.d/100-redirect.sh
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
fi

# Ensure no UDP redirect exists for Trojan (NAT mode doesn't proxy UDP)
while :; do
  rule_num=$(iptables -t nat -L PREROUTING --line-numbers | awk '/unblocktroj/ && /udp/ {print $1}' | tail -1)
  [ -z "$rule_num" ] && break
  iptables -t nat -D PREROUTING "$rule_num" || true
done


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
EOF
    chmod 755 /opt/etc/ndm/netfilter.d/100-redirect.sh || chmod +x /opt/etc/ndm/netfilter.d/100-redirect.sh
    sed -i "s/hash:net/${set_type}/g" /opt/etc/ndm/netfilter.d/100-redirect.sh
    sed -i "s/192.168.1.1/${lanip}/g" /opt/etc/ndm/netfilter.d/100-redirect.sh
    sed -i "s/1082/${localportsh}/g" /opt/etc/ndm/netfilter.d/100-redirect.sh
    sed -i "s/9141/${localporttor}/g" /opt/etc/ndm/netfilter.d/100-redirect.sh
    sed -i "s/10810/${localportvmess}/g" /opt/etc/ndm/netfilter.d/100-redirect.sh
    sed -i "s/10829/${localporttrojan}/g" /opt/etc/ndm/netfilter.d/100-redirect.sh
    echo "Установлено перенаправление пакетов с адресатами из unblock в: Tor, Shadowsocks, VPN, Trojan, v2ray"
    # Ensure no UDP redirect exists for Trojan right after install
    while iptables -t nat -C PREROUTING -i br0 -p udp -m set --match-set unblocktroj dst -j REDIRECT --to-ports ${localporttrojan} 2>/dev/null; do
      iptables -t nat -D PREROUTING -i br0 -p udp -m set --match-set unblocktroj dst -j REDIRECT --to-ports ${localporttrojan} || true
    done

    # VPN script
    # chmod 777 /opt/etc/ndm/ifstatechanged.d/100-unblock-vpn.sh || rm -rfv /opt/etc/ndm/ifstatechanged.d/100-unblock-vpn.sh
    if [ "${keen_os_short}" = "4" ]; then
      echo "VPN для KeenOS 4+";
      curl -s -o /opt/etc/ndm/ifstatechanged.d/100-unblock-vpn.sh https://raw.githubusercontent.com/${repo}/bypass_keenetic/main/100-unblock-vpn-v4.sh
    elif [ "${keen_os_short}" = "3" ]; then
      echo "VPN для KeenOS 3+";
      curl -s -o /opt/etc/ndm/ifstatechanged.d/100-unblock-vpn.sh https://raw.githubusercontent.com/${repo}/bypass_keenetic/main/100-unblock-vpn.sh
    else
      echo "Your really KeenOS ???";
      curl -s -o /opt/etc/ndm/ifstatechanged.d/100-unblock-vpn.sh https://raw.githubusercontent.com/${repo}/bypass_keenetic/main/100-unblock-vpn.sh
    fi
    #curl -o /opt/etc/ndm/ifstatechanged.d/100-unblock-vpn.sh https://raw.githubusercontent.com/${repo}/bypass_keenetic/main/100-unblock-vpn.sh
    chmod 755 /opt/etc/ndm/ifstatechanged.d/100-unblock-vpn.sh || chmod +x /opt/etc/ndm/ifstatechanged.d/100-unblock-vpn.sh
    echo "Установлен скрипт проверки подключения и остановки VPN"

    # dnsmasq.conf
    #rm -rf /opt/etc/dnsmasq.conf
    chmod 777 /opt/etc/dnsmasq.conf || rm -rfv /opt/etc/dnsmasq.conf
    cat <<'EOF' > /opt/etc/dnsmasq.conf
user=nobody
#pid-file=/var/run/opt-dnsmasq.pid
interface=br0
interface=br1
interface=lo

min-port=4096       # Specify lowest port available for DNS query transmission
cache-size=1536     # Specify the size of the cache in entries

#listen-address=::1
#listen-address=fe80::52ff:20ff:fe0f:cabe
listen-address=127.0.0.1
listen-address=192.168.1.1

#bind-dynamic
#except-interface=lo

bogus-priv          # Fake reverse lookups for RFC1918 private address ranges
no-negcache         # Do NOT cache failed search results
no-resolv           # Do NOT read resolv.conf
no-poll             # Do NOT poll resolv.conf file, reload only on SIGHUP
clear-on-reload     # Clear DNS cache when reloading dnsmasq
expand-hosts        # Expand simple names in /etc/hosts with domain-suffix
localise-queries    # Return answers to DNS queries from /etc/hosts and --interface-name and --dynamic-host which depend on the interface over which the query was received
domain-needed       # Tells dnsmasq to never forward A or AAAA queries for plain names, without dots or domain parts, to upstream nameservers
#filter-aaaa         # Prefer IPv4 by filtering AAAA (enable if your dnsmasq supports this option)
log-async           # Enable async. logging; optionally set queue length
stop-dns-rebind     # Reject (and log) addresses from upstream nameservers which are in the private ranges
rebind-localhost-ok # Exempt 127.0.0.0/8 and ::1 from rebinding checks
#rebind-domain-ok=/lan/onion/i2p/
rebind-domain-ok=/lan/local/onion/

# DNS over TLS-HTTPS /tmp/ndnproxymain.stat
# Порты DoT/DoH будут подставлены из script.sh при установке/обновлении
server=127.0.0.1#40500
server=127.0.0.1#40508
#server=127.0.0.1#40501
#server=127.0.0.1#40509

# Tor onion
#ipset=/onion/unblock4-tor,unblock6-tor
server=/onion/127.0.0.1#9053
server=/onion/::1#9053
ipset=/onion/unblocktor

# I2P
#address=/i2p/172.17.17.17

# SRV-hosts
#srv-host=_vlmcs._tcp.lan,rpi4.lan,1688,0,100 # KMS
#srv-host=_ntp._udp.lan,rpi4.lan,123,0,100    # NTP

#srv-host=_vlmcs._tcp.local,rpi4.local,1688,0,100 # KMS
#srv-host=_ntp._udp.local,rpi4.local,123,0,100    # NTP

# Samsung Tizen: Ott-Play over DNS
#server=/oll.tv/51.38.147.71

# OpenNIC DNS
# https://servers.opennicproject.org/
#server=/lib/2a05:dfc7:5::53
#server=/lib/185.121.177.177
#server=/lib/2a05:dfc7:5::5353
#server=/lib/169.239.202.202

conf-file=/opt/etc/unblock.dnsmasq
#conf-file=/opt/etc/unblock-tor.dnsmasq
#conf-file=/opt/etc/unblock-vpn.dnsmasq

# Локальный домен для автоматической подстановки в случае неполного доменного имени
domain=local,192.168.1.0/24
#address=/localhost/127.0.0.1/::1/
#address=/router.local/192.168.1.1

# Не использовать /etc/hosts
#no-hosts
EOF
    chmod 755 /opt/etc/dnsmasq.conf
    sed -i "s/192.168.1.1/${lanip}/g" /opt/etc/dnsmasq.conf
    sed -i "s/40500/${dnsovertlsport}/g" /opt/etc/dnsmasq.conf || true
    sed -i "s/40508/${dnsoverhttpsport}/g" /opt/etc/dnsmasq.conf || true
    echo "Установлена настройка dnsmasq и подключение дополнительного конфигурационного файла к dnsmasq"

    # cron file
    #rm -rf /opt/etc/crontab
    chmod 777 /opt/etc/crontab || rm -Rfv /opt/etc/crontab
    curl -o /opt/etc/crontab https://raw.githubusercontent.com/${repo}/bypass_keenetic/main/crontab
    chmod 600 /opt/etc/crontab
    echo "Установлено добавление задачи в cron для периодического обновления содержимого множества"
    /opt/bin/unblock_update.sh
    echo "Установлены все изначальные скрипты и скрипты разблокировок, выполнена основная настройка бота"

    #ndmc -c 'opkg dns-override'
    #sleep 3
    #ndmc -c 'system configuration save'
    #sleep 3
    #echo "Перезагрузка роутера"
    #ndmc -c 'system reboot'
    #sleep 5

    exit 0
fi

if [ "$1" = "-reinstall" ]; then
    curl -s -o /opt/root/script.sh https://raw.githubusercontent.com/Klagvar/bypass_keenetic/main/script.sh
    chmod 755 /opt/root/script.sh || chmod +x /opt/root/script.sh
    echo "Начинаем переустановку"
    #opkg update
    echo "Удаляем установленные пакеты и созданные файлы"
    /bin/sh /opt/root/script.sh -remove
    echo "Удаление завершено"
    echo "Выполняем установку"
    /bin/sh /opt/root/script.sh -install
    echo "Установка выполнена."
    exit 0
fi


if [ "$1" = "-update" ]; then
    echo "Начинаем обновление."
    opkg update > /dev/null 2>&1
    # opkg update
    echo "Ваша версия KeenOS" "${keen_os_full}."
    echo "Пакеты обновлены."

    /opt/etc/init.d/S22shadowsocks stop > /dev/null 2>&1
    /opt/etc/init.d/S24v2ray stop > /dev/null 2>&1
    /opt/etc/init.d/S22trojan stop > /dev/null 2>&1
    /opt/etc/init.d/S35tor stop > /dev/null 2>&1
    echo "Сервисы остановлены."

    now=$(date +"%Y.%m.%d.%H-%M")
    mkdir /opt/root/backup-"${now}"
    mv /opt/bin/unblock_ipset.sh /opt/root/backup-"${now}"/unblock_ipset.sh
    mv /opt/bin/unblock_dnsmasq.sh /opt/root/backup-"${now}"/unblock_dnsmasq.sh
    mv /opt/bin/unblock_update.sh /opt/root/backup-"${now}"/unblock_update.sh
    mv /opt/etc/dnsmasq.conf /opt/root/backup-"${now}"/dnsmasq.conf
    mv /opt/etc/ndm/fs.d/100-ipset.sh /opt/root/backup-"${now}"/100-ipset.sh
    mv /opt/etc/ndm/ifstatechanged.d/100-unblock-vpn.sh /opt/root/backup-"${now}"/100-unblock-vpn.sh
    mv /opt/etc/ndm/netfilter.d/100-redirect.sh /opt/root/backup-"${now}"/100-redirect.sh
    mv /opt/etc/bot.py /opt/root/backup-"${now}"/bot.py
    rm -R /opt/etc/ndm/ifstatechanged.d/100-unblock-vpn > /dev/null 2>&1
    chmod 755 /opt/root/backup-"${now}"/*
    echo "Бэкап создан."

    touch /opt/etc/hosts || chmod 0755 /opt/etc/hosts
    curl -s -o /opt/etc/ndm/fs.d/100-ipset.sh https://raw.githubusercontent.com/${repo}/bypass_keenetic/main/100-ipset.sh
    chmod 755 /opt/etc/ndm/fs.d/100-ipset.sh || chmod +x /opt/etc/ndm/fs.d/100-ipset.sh
    curl -s -o /opt/etc/ndm/netfilter.d/100-redirect.sh https://raw.githubusercontent.com/${repo}/bypass_keenetic/main/100-redirect.sh
    chmod 755 /opt/etc/ndm/netfilter.d/100-redirect.sh || chmod +x /opt/etc/ndm/netfilter.d/100-redirect.sh
    sed -i "s/hash:net/${set_type}/g" /opt/etc/ndm/netfilter.d/100-redirect.sh
    sed -i "s/192.168.1.1/${lanip}/g" /opt/etc/ndm/netfilter.d/100-redirect.sh
    sed -i "s/1082/${localportsh}/g" /opt/etc/ndm/netfilter.d/100-redirect.sh
    sed -i "s/9141/${localporttor}/g" /opt/etc/ndm/netfilter.d/100-redirect.sh
    sed -i "s/10810/${localportvmess}/g" /opt/etc/ndm/netfilter.d/100-redirect.sh
    sed -i "s/10829/${localporttrojan}/g" /opt/etc/ndm/netfilter.d/100-redirect.sh
    sed -i 's|ARGS="-confdir /opt/etc/v2ray"|ARGS="run -c /opt/etc/v2ray/config.json"|g' /opt/etc/init.d/S24v2ray > /dev/null 2>&1

    if [ "${keen_os_short}" = "4" ]; then
      echo "KeenOS 4+";
      curl -s -o /opt/etc/ndm/ifstatechanged.d/100-unblock-vpn.sh https://raw.githubusercontent.com/${repo}/bypass_keenetic/main/100-unblock-vpn-v4.sh
    elif [ "${keen_os_short}" = "3" ]; then
      echo "KeenOS 3+";
      curl -s -o /opt/etc/ndm/ifstatechanged.d/100-unblock-vpn.sh https://raw.githubusercontent.com/${repo}/bypass_keenetic/main/100-unblock-vpn.sh
    else
      echo "Your really KeenOS ???";
      curl -s -o /opt/etc/ndm/ifstatechanged.d/100-unblock-vpn.sh https://raw.githubusercontent.com/${repo}/bypass_keenetic/main/100-unblock-vpn.sh
    fi
    chmod 755 /opt/etc/ndm/ifstatechanged.d/100-unblock-vpn.sh || chmod +x /opt/etc/ndm/ifstatechanged.d/100-unblock-vpn.sh

    curl -s -o /opt/bin/unblock_ipset.sh https://raw.githubusercontent.com/${repo}/bypass_keenetic/main/unblock_ipset.sh
    curl -s -o /opt/bin/unblock_dnsmasq.sh https://raw.githubusercontent.com/${repo}/bypass_keenetic/main/unblock.dnsmasq
    curl -s -o /opt/bin/unblock_update.sh https://raw.githubusercontent.com/${repo}/bypass_keenetic/main/unblock_update.sh
    chmod 755 /opt/bin/unblock_*.sh || chmod +x /opt/bin/unblock_*.sh
    sed -i "s/40500/${dnsovertlsport}/g" /opt/bin/unblock_ipset.sh
    sed -i "s/40500/${dnsovertlsport}/g" /opt/bin/unblock_dnsmasq.sh
    # Rebuild dnsmasq rules and ensure base masks exist for key CDNs (YT/Twitter/Instagram)
    /opt/bin/unblock_dnsmasq.sh
    if ! grep -q '^ipset=/googlevideo.com/unblocktroj' /opt/etc/unblock.dnsmasq; then
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
    /opt/etc/init.d/S56dnsmasq restart || true
    # Seed trojan.txt on update too if empty
    if [ ! -s /opt/etc/unblock/trojan.txt ]; then
      curl -fsSLo /opt/etc/unblock/trojan.txt https://raw.githubusercontent.com/${repo}/bypass_keenetic/main/list.txt || true
    fi

    curl -s -o /opt/etc/dnsmasq.conf https://raw.githubusercontent.com/${repo}/bypass_keenetic/main/dnsmasq.conf
    chmod 755 /opt/etc/dnsmasq.conf
    sed -i "s/192.168.1.1/${lanip}/g" /opt/etc/dnsmasq.conf
    sed -i "s/40500/${dnsovertlsport}/g" /opt/etc/dnsmasq.conf
    sed -i "s/40508/${dnsoverhttpsport}/g" /opt/etc/dnsmasq.conf

    curl -s -o /opt/etc/bot.py https://raw.githubusercontent.com/${repo}/bypass_keenetic/main/bot.py
    chmod 755 /opt/etc/bot.py
    echo "Обновления скачены, права настроены."

    /opt/etc/init.d/S56dnsmasq restart > /dev/null 2>&1
    /opt/etc/init.d/S22shadowsocks start > /dev/null 2>&1
    /opt/etc/init.d/S24v2ray start > /dev/null 2>&1
    /opt/etc/init.d/S22trojan start > /dev/null 2>&1
    /opt/etc/init.d/S35tor start > /dev/null 2>&1

    bot_old_version=$(grep "ВЕРСИЯ" /opt/etc/bot_config.py | grep -Eo "[0-9].{1,}")
    bot_new_version=$(grep "ВЕРСИЯ" /opt/etc/bot.py | grep -Eo "[0-9].{1,}")

    echo "Версия бота" "${bot_old_version}" "обновлена до" "${bot_new_version}."
    sleep 2
    sed -i "s/${bot_old_version}/${bot_new_version}/g" /opt/etc/bot_config.py
    echo "Обновление выполнено. Сервисы перезапущены. Сейчас будет перезапущен бот (~15-30 сек)."
    sleep 7
    # shellcheck disable=SC2009
    # bot=$(ps | grep bot.py | awk '{print $1}' | head -1)
    bot_pid=$(ps | grep bot.py | awk '{print $1}')
    for bot in ${bot_pid}; do kill "${bot}"; done
    sleep 5
    python3 /opt/etc/bot.py &
    check_running=$(pidof python3 /opt/etc/bot.py)
    if [ -z "${check_running}" ]; then
      for bot in ${bot_pid}; do kill "${bot}"; done
      sleep 3
      python3 /opt/etc/bot.py &
    else
      echo "Бот запущен. Нажмите сюда: /start";
    fi

    exit 0
fi

if [ "$1" = "-reboot" ]; then
    ndmc -c 'opkg dns-override'
    sleep 3
    ndmc -c 'system configuration save'
    sleep 3
    echo "Перезагрузка роутера"
    ndmc -c 'system reboot'
fi

if [ "$1" = "-version" ]; then
    echo "Ваша версия KeenOS" "${keen_os_full}"
fi

if [ "$1" = "-help" ]; then
    echo "-install - use for install all needs for work"
    echo "-remove - use for remove all files script"
    echo "-update - use for get update files"
    echo "-reinstall - use for reinstall all files script"
fi

if [ -z "$1" ]; then
    #echo not found "$1".
    echo "-install - use for install all needs for work"
    echo "-remove - use for remove all files script"
    echo "-update - use for get update files"
    echo "-reinstall - use for reinstall all files script"
fi

#if [ -n "$1" ]; then
#    echo not found "$1".
#    echo "-install - use for install all needs for work"
#    echo "-remove - use for remove all files script"
#    echo "-update - use for get update files"
#    echo "-reinstall - use for reinstall all files script"
#else
#    echo "-install - use for install all needs for work"
#    echo "-remove - use for remove all files script"
#    echo "-update - use for get update files"
#    echo "-reinstall - use for reinstall all files script"
#fi