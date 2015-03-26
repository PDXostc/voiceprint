PROJECT = JLRPOCX012.Voiceprint
INSTALL_FILES = images js icon.png index.html
WRT_FILES = DNA_common css icon.png index.html images setup config.xml js manifest.json README.md
VERSION := 0.0.1
PACKAGE = $(PROJECT)-$(VERSION)

SEND := ~/send

ifndef TIZEN_IP
TIZEN_IP=TizenVTC
endif

dev: clean dev-common
	zip -r $(PROJECT).wgt $(WRT_FILES)

wgtPkg: common
	zip -r $(PROJECT).wgt $(WRT_FILES)
	
config:
	scp setup/weston.ini root@$(TIZEN_IP):/etc/xdg/weston/

$(PROJECT).wgt : dev

wgt:
	zip -r $(PROJECT).wgt $(WRT_FILES)

kill.xwalk:
	ssh root@$(TIZEN_IP) "pkill xwalk"

kill.feb1:
	ssh app@$(TIZEN_IP) "pkgcmd -k JLRPOCX012.Voiceprint"

run: install
	ssh app@$(TIZEN_IP) "export DBUS_SESSION_BUS_ADDRESS='unix:path=/run/user/5000/dbus/user_bus_socket' && xwalkctl  2>&1 | egrep -e 'Voiceprint' | awk '{print $1}' | xargs --no-run-if-empty xwalk-launcher -d"

run.feb1: install.feb1
	ssh app@$(TIZEN_IP) "app_launcher -s JLRPOCX012.Voiceprint -d "

install.feb1: deploy
ifndef OBS
	-ssh app@$(TIZEN_IP) "pkgcmd -u -n JLRPOCX012 -q"
	ssh app@$(TIZEN_IP) "pkgcmd -i -t wgt -p /home/app/JLRPOCX012.Voiceprint.wgt -q"
endif

install: deploy
ifndef OBS
	ssh app@$(TIZEN_IP) "export DBUS_SESSION_BUS_ADDRESS='unix:path=/run/user/5000/dbus/user_bus_socket' && xwalkctl  2>&1 | egrep -e 'Voiceprint' | awk '{print $1}' | xargs --no-run-if-empty xwalkctl -u"
	ssh app@$(TIZEN_IP) "export DBUS_SESSION_BUS_ADDRESS='unix:path=/run/user/5000/dbus/user_bus_socket' && xwalkctl -i /home/app/JLRPOCX012.Voiceprint.wgt"
endif

$(PROJECT).wgt : wgt

deploy: dev
ifndef OBS
	scp $(PROJECT).wgt app@$(TIZEN_IP):/home/app
endif

all:
	@echo "Nothing to build"

clean:
	-rm -f $(PROJECT).wgt
	-rm -rf DNA_common


boxcheck: tizen-release
	ssh root@$(TIZEN_IP) "cat /etc/tizen-release" | diff tizen-release - ; if [ $$? -ne 0 ] ; then tput setaf 1 ; echo "tizen-release version not correct"; tput sgr0 ;exit 1 ; fi

install_obs: 
	mkdir -p ${DESTDIR}/opt/usr/apps/.preinstallWidgets
	cp -r JLRPOCX012.Voiceprint.wgt ${DESTDIR}/opt/usr/apps/.preinstallWidgets/

common: /opt/usr/apps/common-apps
	cp -r /opt/usr/apps/common-apps DNA_common

/opt/usr/apps/common-apps:
	@echo "Please install Common Assets"
	exit 1

dev-common: ../common-app
	cp -rf ../common-app ./DNA_common
	rm -rf DNA_common/.git

../common-app:
	#@echo "Please checkout Common Assets"
	#exit 1
	git clone  git@github.com:PDXostc/common-app.git ../common-app
