NAME = myapp
VERSION = 1.0.0

.PHONY: myapp debian

all: myapp debian

# build the app
myapp: 
	@echo "++ Building myapp"
	gcc myapp.c -o myapp

# Debian Packaging
DEB_BLD_DIR = debian_build/$(NAME)_$(VERSION)
debian:
	@echo "++ Building Debian package"
	rm -rf debian_build
	mkdir -p $(DEB_BLD_DIR)
	mkdir -p $(DEB_BLD_DIR)/usr/bin
	cp myapp $(DEB_BLD_DIR)/usr/bin
	mkdir -p $(DEB_BLD_DIR)/etc/systemd/system
	cp debian/myapp.service $(DEB_BLD_DIR)/etc/systemd/system
	mkdir -p $(DEB_BLD_DIR)/DEBIAN
	cp debian/postinst $(DEB_BLD_DIR)/DEBIAN
	cp debian/prerm $(DEB_BLD_DIR)/DEBIAN
	cp debian/postrm $(DEB_BLD_DIR)/DEBIAN
	cp debian/control $(DEB_BLD_DIR)/DEBIAN
	dpkg-deb --build --root-owner-group $(DEB_BLD_DIR)