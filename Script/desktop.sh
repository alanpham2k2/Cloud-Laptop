echo "Deleting default GNOME apps..."
sudo dnf purge gedit

echo "Ïnstalling Flatpak and applications..."
sudo dnf install -y flatpak
sudo flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
flatpak install -y flathub \
  app.zen_browser.zen \
  com.brave.Browser \
  com.github.ryonakano.reco \
  net.ankiweb.Anki \
  org.localsend.localsend_app \
  org.videolan.VLC \
  org.qbittorrent.qBittorrent \
  org.torproject.torbrowser-launcher \
  io.gitlab.librewolf-community \
  org.adishatz.Screenshot
  
flatpak override --user --reset com.github.ryonakano.reco
flatpak override --user --device=dri com.github.ryonakano.reco
