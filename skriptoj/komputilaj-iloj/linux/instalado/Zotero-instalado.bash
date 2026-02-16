# decompressing the archive takes time. It will take a moment before `sudo` 
password is demanded.

# https://doc.ubuntu-fr.org/zotero

downloaded-archive="Zotero-8.0.3_linux-x86_64.tar.xz"
tar -xf $downloaded-archive

sudo rm -rf /opt/zotero
sudo mv Zotero_linux-x86_64 /opt/zotero

sudo ln -sf /opt/zotero/set_launcher_icon /usr/local/bin/zotero-set-icon
sudo ln -sf /opt/zotero/zotero /usr/local/bin/zotero

/opt/zotero/set_launcher_icon

mkdir -p ~/.local/share/applications
ln -sf /opt/zotero/zotero.desktop ~/.local/share/applications/zotero.desktop


