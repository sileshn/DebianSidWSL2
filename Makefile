OUT_ZIP=DebianSidWSL2.zip
LNCR_EXE=Debian.exe

DLR=curl
DLR_FLAGS=-L
LNCR_ZIP_URL=https://github.com/yuk7/wsldl/releases/download/22020900/icons.zip
LNCR_ZIP_EXE=Debian.exe

all: $(OUT_ZIP)

zip: $(OUT_ZIP)
$(OUT_ZIP): ziproot
	@echo -e '\e[1;31mBuilding $(OUT_ZIP)\e[m'
	cd ziproot; bsdtar -a -cf ../$(OUT_ZIP) *

ziproot: Launcher.exe rootfs.tar.gz
	@echo -e '\e[1;31mBuilding ziproot...\e[m'
	mkdir ziproot
	cp Launcher.exe ziproot/${LNCR_EXE}
	cp rootfs.tar.gz ziproot/

exe: Launcher.exe
Launcher.exe: icons.zip
	@echo -e '\e[1;31mExtracting Launcher.exe...\e[m'
	unzip icons.zip $(LNCR_ZIP_EXE)
	mv $(LNCR_ZIP_EXE) Launcher.exe

icons.zip:
	@echo -e '\e[1;31mDownloading icons.zip...\e[m'
	$(DLR) $(DLR_FLAGS) $(LNCR_ZIP_URL) -o icons.zip

rootfs.tar.gz: rootfs
	@echo -e '\e[1;31mBuilding rootfs.tar.gz...\e[m'
	cd rootfs; sudo bsdtar -zcpf ../rootfs.tar.gz `sudo ls`
	sudo chown `id -un` rootfs.tar.gz

rootfs: base.tar
	@echo -e '\e[1;31mBuilding rootfs...\e[m'
	mkdir rootfs
	sudo bsdtar -zxpf base.tar -C rootfs
	@echo "# This file was automatically generated by WSL. To stop automatic generation of this file, remove this line." | sudo tee rootfs/etc/resolv.conf > /dev/null
	sudo cp wsl.conf rootfs/etc/wsl.conf
	sudo cp bash_profile rootfs/root/.bash_profile
	sudo chmod +x rootfs

base.tar:
	@echo -e '\e[1;31mExporting base.tar using docker...\e[m'
	docker run --name debiansidwsl --net=host --platform linux/amd64 debian:sid /bin/bash -c "echo 'debconf debconf/frontend select Noninteractive' | debconf-set-selections; apt-get update; apt-get install -y -q apt-utils; apt-get full-upgrade -y -q; apt-get install -y -q apt-transport-https iproute2 aria2 bash-completion build-essential ca-certificates curl dialog figlet htop iputils-ping lolcat locales lsof nano software-properties-common sudo tree vim; sed -i 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/g' /etc/locale.gen && locale-gen; sudo sh -c 'echo :WSLInterop:M::MZ::/init:PF > /usr/lib/binfmt.d/WSLInterop.conf'; apt-get autoremove -y; apt-get clean;"
	docker export --output=base.tar debiansidwsl
	docker rm -f debiansidwsl

clean:
	@echo -e '\e[1;31mCleaning files...\e[m'
	-rm ${OUT_ZIP}
	-rm -r ziproot
	-rm Launcher.exe
	-rm icons.zip
	-rm rootfs.tar.gz
	-sudo rm -r rootfs
	-rm base.tar
	-docker rmi -f debian:sid
