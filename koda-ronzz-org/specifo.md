# Specifo de koda.ronzz.org

## loko

- instalaĵloko : `/var/www/koda-ronzz-org`

## temo

- [kodo.ronzz-org temo](https://github.com/Ron-RONZZ-org/kodo-ronzz-org-temo)

## disvolviĝo

- temo : `sudo ln -s ~/dokumento/kodo-ronzz-org-temo/temo-koda-ease /var/www/koda-ronzz-org/content/themes/koda-ease`

## rapidaj mendoj

```bash
su - ghost-admin

cd /var/www/koda-ronzz-org

copilot --banner
```

Ĝisdatigo de la temo "Ease"

```bash
sudo rm -r /tmp/ease-theme-update
git clone https://github.com/Ron-RONZZ-org/koda-ronzz-org.git /tmp/ease-theme-update
sudo mv /var/www/koda-ronzz-org/content/themes/ease /var/www/koda-ronzz-org/content/themes/ease.old
sudo cp -r /tmp/ease-theme-update/content/themes/ease /var/www/koda-ronzz-org/content/themes/
sudo chown -R ghost:ghost /var/www/koda-ronzz-org/content/themes/ease
ghost restart
```