echo "Removing Snap..."
while [ "$(snap list | wc -l)" -gt 0 ]; do
    for snap in $(snap list | awk 'NR>1 {print $1}'); do
        sudo snap remove --purge "$snap"
    done
done
sudo systemctl stop snapd
sudo systemctl disable snapd
sudo systemctl mask snapd
sudo apt purge snapd
rm -rf ~/snap
sudo rm -rf /snap /var/snap /var/lib/snapd
cat <<EOF | sudo tee /etc/apt/preferences.d/nosnap.pref
Package: snapd
Pin: release a=*
Pin-Priority: -10
EOF
sudo apt-get install -y gnome-software gnome-firmware

echo "Ïnstalling Flatpak and applications..."
sudo apt-get install -y flatpak
sudo flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
flatpak install -y flathub \
  app.zen_browser.zen \
  com.brave.Browser \
  com.github.ryonakano.reco \
  net.ankiweb.Anki \
  org.localsend.localsend_app \
  org.videolan.VLC \
  org.qbittorrent.qBittorrent \
  org.torproject.torbrowser-launcher

gsettings set org.gnome.desktop.interface enable-animations false
gsettings set org.freedesktop.Tracker3.Miner.Files crawling-interval -2
gsettings set org.freedesktop.Tracker3.Miner.Files enable-monitors false

sudo apt-get autoremove -y
