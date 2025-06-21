#!/bin/bash
# --------------------------------------------------
# Script d'installation paranoïaque pour machine bunker Linux (Debian/Qubes)
# Fonctionnalités : VPN, Tor, NoScript, sécurité, anonymat, cloisonnement
# --------------------------------------------------

# Vérifie que l'utilisateur est root
if [[ $EUID -ne 0 ]]; then
  echo "Ce script doit être exécuté en tant que root." >&2
  exit 1
fi

# Mise à jour du système
apt update && apt upgrade -y

# Installation des outils de base
apt install -y curl gnupg2 ufw fail2ban git wget tor macchanger apt-transport-https ca-certificates gnupg lsb-release

# --------------------------------------------------
# 1. Changement d'adresse MAC automatique
# --------------------------------------------------
echo "Changement aléatoire d'adresse MAC au démarrage..."
cat <<EOF > /etc/network/if-pre-up.d/macchanger
#!/bin/bash
macchanger -r eth0
EOF
chmod +x /etc/network/if-pre-up.d/macchanger

# --------------------------------------------------
# 2. Configuration du pare-feu (UFW)
# --------------------------------------------------
ufw default deny incoming
ufw default allow outgoing
ufw enable

# --------------------------------------------------
# 3. Configuration du service Tor
# --------------------------------------------------
systemctl enable tor
systemctl start tor

# --------------------------------------------------
# 4. Navigateur sécurisé (Tor Browser)
# --------------------------------------------------
mkdir -p /opt/tor-browser
cd /opt/tor-browser

TOR_VERSION=$(curl -s https://dist.torproject.org/torbrowser/ | grep linux64 | grep "en-US" | tail -n 1 | sed -E 's/.*href="(.*)">.*/\1/')
TOR_URL="https://dist.torproject.org/torbrowser/${TOR_VERSION}"
wget "$TOR_URL" -O tor.tar.xz

if [[ -f tor.tar.xz ]]; then
  tar -xf tor.tar.xz
  rm tor.tar.xz
  chown -R $SUDO_USER:$SUDO_USER /opt/tor-browser
fi

# --------------------------------------------------
# 5. Installation de NoScript, HTTPS Everywhere et extensions sur Firefox
# --------------------------------------------------
# (pour navigateur normal si besoin)

EXT_DIR="/usr/lib/firefox/browser/extensions"
mkdir -p "$EXT_DIR"

# NoScript
wget -O "$EXT_DIR/noscript.xpi" https://addons.mozilla.org/firefox/downloads/latest/noscript/addon-722/addon-722-latest.xpi

# HTTPS Everywhere
wget -O "$EXT_DIR/https-everywhere.xpi" https://addons.mozilla.org/firefox/downloads/latest/https-everywhere/addon-229918-latest.xpi

# uBlock Origin
wget -O "$EXT_DIR/ublock.xpi" https://addons.mozilla.org/firefox/downloads/latest/ublock-origin/addon-607454-latest.xpi

# --------------------------------------------------
# 6. Configuration DNS chiffré (Cloudflare DoH via dnscrypt-proxy)
# --------------------------------------------------
apt install -y dnscrypt-proxy
systemctl enable dnscrypt-proxy
systemctl start dnscrypt-proxy

# Remplacement des DNS système
rm -f /etc/resolv.conf
ln -s /run/dnscrypt-proxy/resolv.conf /etc/resolv.conf

# --------------------------------------------------
# 7. Installation de Mullvad VPN (optionnel)
# --------------------------------------------------
wget -qO - https://mullvad.net/download/app/deb/latest | dpkg -i - || true
apt install -f -y

# --------------------------------------------------
# 8. Sécurité supplémentaire : Fail2Ban
# --------------------------------------------------
systemctl enable fail2ban
systemctl start fail2ban

# --------------------------------------------------
# FIN
# --------------------------------------------------
echo -e "\nConfiguration paranoïaque terminée. Redémarre ta machine, puis lance Tor Browser depuis : /opt/tor-browser"
echo -e "\n⚠️ N'utilise jamais ce système pour des usages normaux. Garde-le purement pour tes activités sensibles."
echo -e "\n🔥 Tu es maintenant un fantôme numérique."
