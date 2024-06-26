#
# Xderm Mini GUI Software by Ryan Fauzi <https://github.com/ryanfauzi1/xderm-mini_GUI>
# LuCI Xderm Mini GUI App by Helmi Amirudin <https://www.helmiau.com>
#
# Copyright (C) 2021 Helmi Amirudin <helmilaw@gmail.com>
# This is free software, licensed under the Apache License, Version 2.0
#

include $(TOPDIR)/rules.mk

LUCI_TITLE:=LuCI Xderm Mini App
LUCI_PKGARCH:=all
LUCI_DEPENDS:=+bash +screen +coreutils +coreutils-base64 +coreutils-timeout +httping +v2ray-core \
	+corkscrew +procps-ng +procps-ng-ps +git +curl +sshpass +python3-pip +python3 +openssh-client \
	+openssl-util +php8 +php8-cgi +php8-mod-session +https-dns-proxy +badvpn +trojan

PKG_NAME:=luci-app-xderm-bin

define Package/$(PKG_NAME)
	$(call Package/luci/webtemplate)
	TITLE:=$(LUCI_TITLE)
	DEPENDS:=$(LUCI_DEPENDS)
endef

define Package/$(PKG_NAME)/description
	LuCI version of Xderm Mini GUI with xderm binaries.
endef

define Package/$(PKG_NAME)/install
	$(INSTALL_DIR) $(1)/usr/lib/lua/luci
	cp -pR ./luasrc/* $(1)/usr/lib/lua/luci
	$(INSTALL_DIR) $(1)/
	cp -pR ./root/* $(1)/
	chmod -R 755 /root/www/*
	chmod -R 755 /root/www/xderm/*
	chmod -R 755 /root/root/*
	chmod -R 755 /bin/xdrtool
	chmod -R 755 /bin/xderm_luci_install
endef

define Package/$(PKG_NAME)/postinst
#!/bin/sh
	[ -d /tmp/luci-modulecache ] && rm -rf /tmp/luci-modulecache
	find /tmp -type f -name 'luci-indexcache.*' -exec rm -f {} \;
	chmod -R 755 /usr/lib/lua/luci/controller/*
	chmod -R 755 /usr/lib/lua/luci/view/*
	chmod -R 755 /www/*
	chmod -R 755 /www/xderm/*
	chmod -R 755 /root/*
	chmod -R 755 /bin/xdrtool
	chmod -R 755 /bin/xderm_luci_install
	/etc/init.d/https-dns-proxy disable
	/etc/init.d/https-dns-proxy stop
	# Autofix download index.php, index.html
	if ! grep -q ".php=/usr/bin/php-cgi" /etc/config/uhttpd; then
		echo -e "  helmilog : system not using php-cgi, patching php config ..."
		logger "  helmilog : system not using php-cgi, patching php config..."
		uci set uhttpd.main.ubus_prefix='/ubus'
		uci set uhttpd.main.interpreter='.php=/usr/bin/php-cgi'
		uci set uhttpd.main.index_page='cgi-bin/luci'
		uci add_list uhttpd.main.index_page='index.html'
		uci add_list uhttpd.main.index_page='index.php'
		uci commit uhttpd
		echo -e "  helmilog : patching system with php configuration done ..."
		echo -e "  helmilog : restarting some apps ..."
		logger "  helmilog : patching system with php configuration done..."
		logger "  helmilog : restarting some apps..."
		/etc/init.d/uhttpd restart
	fi
	/usr/sbin/openvpn --mktun --dev tun0
	# Fix for xderm mini gui if trojan is not installed
	if [ ! -f /usr/bin/trojan ]; then
		ln -sf /usr/sbin/trojan /usr/bin/trojan
	fi
	[ -d /usr/lib/php8 ] && [ ! -d /usr/lib/php ] && ln -sf /usr/lib/php8 /usr/lib/php
exit 0
endef

define Package/$(PKG_NAME)/postrm
#!/bin/sh
	export NAMAPAKET="xderm"
	if [ -d /www/$NAMAPAKET ] && [ -f /www/$NAMAPAKET/limit.php ]; then
		rm -rf /www/$NAMAPAKET/img
		rm -rf /www/$NAMAPAKET/js
		rm -rf /www/$NAMAPAKET/log
		rm -rf /www/$NAMAPAKET/var
		rm -f /www/$NAMAPAKET/config.txt
		rm -f /www/$NAMAPAKET/header.php.xdrtool
		rm -f /www/$NAMAPAKET/index.html
		rm -f /www/$NAMAPAKET/index.php
		rm -f /www/$NAMAPAKET/login.php.xdrtool
		rm -f /www/$NAMAPAKET/xderm-mini
		rm -f /www/$NAMAPAKET/xdrtheme-blue-agus
		rm -f /bin/xdrtool
		rm -f /bin/xderm_luci_install
		rm -f /root/auth.txt
	fi
	if [ -d /www/$NAMAPAKET ] && [ ! -f /www/$NAMAPAKET/limit.php ]; then
		rm -rf /www/$NAMAPAKET
	fi
	unset NAMAPAKET
exit 0
endef

include $(TOPDIR)/feeds/luci/luci.mk

$(eval $(call BuildPackage,$(PKG_NAME)))
