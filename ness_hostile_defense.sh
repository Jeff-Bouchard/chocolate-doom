#!/bin/bash
# ness_hostile_defense.sh
# Aggressive node defense: Dynamic Overlay-Only Mode + hostile countermeasures
# Requires: ufw, ipfs, nmap, python3, overlays up (skywire0/ygg0/tor/i2p)

# --- CONFIG ---
OVERLAYS=(skywire0 ygg0 tun0 i2p0)
PUBLIC_IFACE=eth0
BLACKLIST_JSON="/var/lib/ness/blacklist.json"
ZIPBOMB="/var/lib/ness/zipbomb.zip"
COOLDOWN=900 # seconds

# --- FUNCTIONS ---
function overlays_up() {
    for iface in "${OVERLAYS[@]}"; do
        ip link show "$iface" 2>/dev/null | grep -q 'state UP' && return 0
    done
    return 1
}

function clearnet_block() {
    echo "[!] Blocking clearnet access on $PUBLIC_IFACE, overlay-only mode!"
    ufw deny in on $PUBLIC_IFACE
    for iface in "${OVERLAYS[@]}"; do
        ufw allow in on $iface
    done
}

function clearnet_restore() {
    echo "[+] Restoring clearnet access on $PUBLIC_IFACE."
    ufw delete deny in on $PUBLIC_IFACE
}

function ban_ip() {
    local ip="$1"
    ufw insert 1 deny from "$ip" to any
}

function zipbomb_response() {
    # Serve ZIPBOMB via web server's error handler or CGI
    # (Manual integration required)
    echo "[!] Would serve zipbomb to $1"
}

function slowloris_response() {
    # Simulate slowloris by holding connection open
    # (Manual integration required)
    echo "[!] Would slowloris $1"
}

function retaliatory_scan() {
    local ip="$1"
    echo "[!] Scanning $ip for intelligence..."
    nmap -F "$ip" -oN "/var/lib/ness/scans/$ip.txt" &
}

function update_blacklist_json() {
    python3 /var/lib/ness/update_blacklist.py "$BLACKLIST_JSON"
}

function publish_ipfs() {
    local cid=$(ipfs add -Q "$BLACKLIST_JSON")
    echo "[!] IPFS CID: $cid"
    echo "$cid" > /var/lib/ness/latest_cid.txt
}

# --- MAIN LOOP ---
mkdir -p /var/lib/ness/scans
mkdir -p /var/lib/ness

while true; do
    overlays_up
    if [ $? -eq 0 ]; then
        clearnet_block
        # Monitor for new attackers (parse logs, banmoron output, etc)
        # For each new attacker IP:
        #   ban_ip $ip
        #   zipbomb_response $ip
        #   slowloris_response $ip
        #   retaliatory_scan $ip
        #   update_blacklist_json
        #   publish_ipfs
    else
        clearnet_restore
    fi
    sleep $COOLDOWN
    # (Add logic to restore clearnet after cooldown if overlays go down)
done
