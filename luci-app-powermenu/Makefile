#
# Copyright (C) 2021 Helmi Amirudin <helmilaw@gmail.com>
# This is free software, licensed under the Apache License, Version 2.0
#

include $(TOPDIR)/rules.mk

LUCI_TITLE:=LuCI Power Menu to Shutdown/Reboot Your Router
LUCI_PKGARCH:=all
PKG_NAME:=luci-app-powermenu

define Package/$(PKG_NAME)
	$(call Package/luci/webtemplate)
	TITLE:=$(LUCI_TITLE)
endef

define Package/$(PKG_NAME)/description
	Simple turn off your router with this app.
endef

define Package/$(PKG_NAME)/install
	$(INSTALL_DIR) $(1)/usr/lib/lua/luci
	cp -pR ./luasrc/* $(1)/usr/lib/lua/luci
endef

define Package/$(PKG_NAME)/postinst
#!/bin/sh
	[ -d /tmp/luci-modulecache ] && rm -rf /tmp/luci-modulecache
	find /tmp -type f -name 'luci-indexcache.*' -exec rm -f {} \;
	chmod -R 755 /usr/lib/lua/luci/controller/*
	chmod -R 755 /usr/lib/lua/luci/view/*
exit 0
endef

include $(TOPDIR)/feeds/luci/luci.mk

$(eval $(call BuildPackage,$(PKG_NAME)))
