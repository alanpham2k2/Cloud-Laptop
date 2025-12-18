echo "Ïnstalling Flatpak..."
sudo apt-get install -y flatpak

echo "Installing Flatpak applications..."
flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
flatpak install -y flathub \
  app.zen_browser.zen \
  com.github.ryonakano.reco \
  net.ankiweb.Anki \
  org.localsend.localsend_app \
  org.videolan.VLC \
  org.qbittorrent.qBittorrent \
  org.torproject.torbrowser-launcher

