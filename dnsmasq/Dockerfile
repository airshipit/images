ARG FROM=docker.io/ubuntu:bionic
FROM ${FROM} AS builder
ARG DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y efibootmgr gcc git make genisoimage xz-utils grub2-common grub-efi-amd64 grub-efi-amd64-bin shim shim-signed dosfstools mtools liblzma-dev
WORKDIR /tmp
RUN git clone http://git.ipxe.org/ipxe.git && \
      cd ipxe && \
      git checkout 3fe683ebab29afacf224e6b0921f6329bebcdca7 && \
      cd src && \
      sed -i -e "s/#undef.*NET_PROTO_IPV6/#define NET_PROTO_IPV6/g" config/general.h && \
      make bin/undionly.kpxe bin-x86_64-efi/ipxe.efi bin-x86_64-efi/snponly.efi

RUN if [ $(uname -m) = "x86_64" ]; then \
      dd bs=1024 count=3200 if=/dev/zero of=esp.img && \
      mkfs.msdos -F 12 -n 'ESP_IMAGE' ./esp.img && \
      mmd -i esp.img EFI && \
      mmd -i esp.img EFI/BOOT && \
      mkdir -p /boot/efi && \
      grub-mkimage -C xz -O x86_64-efi -p /boot/grub -o /tmp/grubx64.efi boot linux search normal configfile part_gpt btrfs ext2 fat iso9660 loopback test keystatus gfxmenu regexp probe efi_gop efi_uga all_video gfxterm font scsi echo read ls cat png jpeg halt reboot && \
      mcopy -i esp.img -v /tmp/grubx64.efi ::EFI/BOOT && \
      mdir -i esp.img ::EFI/BOOT; \
    else \
      touch /tmp/esp.img; \
    fi

FROM ${FROM}

LABEL org.opencontainers.image.authors='airship-discuss@lists.airshipit.org, irc://#airshipit@freenode' \
      org.opencontainers.image.url='https://airshipit.org' \
      org.opencontainers.image.documentation='https://airship-images.readthedocs.org' \
      org.opencontainers.image.source='https://opendev.org/airship/images' \
      org.opencontainers.image.vendor='The Airship Authors' \
      org.opencontainers.image.licenses='Apache-2.0'

RUN set -xe \
    && export DEBIAN_FRONTEND=noninteractive \
    && apt-get update -qq && apt-get -y dist-upgrade \
    && apt-get install -y dnsmasq \
    && apt-get autoremove -y --purge \
    && apt-get clean \
    && rm -rf /var/lib/apt-get/lists/*

RUN mkdir -p /tftpboot
COPY --from=builder /tmp/ipxe/src/bin/undionly.kpxe /tftpboot
COPY --from=builder /tmp/ipxe/src/bin-x86_64-efi/snponly.efi /tftpboot
COPY --from=builder /tmp/ipxe/src/bin-x86_64-efi/ipxe.efi /tftpboot
COPY --from=builder /tmp/esp.img /tmp/uefi_esp.img

CMD ["/bin/bash"]
