FROM alpine:3.12.0

LABEL maintainer "ferrari.marco@gmail.com"

# Install the necessary packages
RUN apk add --update \
  dnsmasq \
  wget \
  && rm -rf /var/cache/apk/*

ENV SYSLINUX_VERSION 6.04
ENV SYSLINUX_VERSION_SUFFIX -pre1
ENV SYSLINUX_FILE syslinux-"$SYSLINUX_VERSION""$SYSLINUX_VERSION_SUFFIX".tar.gz
ENV TEMP_SYSLINUX_PATH /tmp/syslinux-"$SYSLINUX_VERSION""$SYSLINUX_VERSION_SUFFIX"
WORKDIR /tmp
RUN \
  mkdir -p "$TEMP_SYSLINUX_PATH" \
  && wget -q https://www.kernel.org/pub/linux/utils/boot/syslinux/Testing/"$SYSLINUX_VERSION"/"$SYSLINUX_FILE" \
  && tar -xzf "$SYSLINUX_FILE" \
  && mkdir -p /var/lib/tftpboot/bios \
  && mkdir -p /var/lib/tftpboot/efi64 \
  && mkdir -p /var/lib/tftpboot/images \
  && mkdir -p /var/lib/tftpboot/pxelinux.cfg \
  && ln -s /var/lib/tftpboot/images /var/lib/tftpboot/bios \
  && ln -s /var/lib/tftpboot/pxelinux.cfg /var/lib/tftpboot/bios \
  && ln -s /var/lib/tftpboot/images /var/lib/tftpboot/efi64 \
  && ln -s /var/lib/tftpboot/pxelinux.cfg /var/lib/tftpboot/efi64 \
  && cp "$TEMP_SYSLINUX_PATH"/bios/core/pxelinux.0 /var/lib/tftpboot/bios \
  && cp "$TEMP_SYSLINUX_PATH"/bios/com32/libutil/libutil.c32 /var/lib/tftpboot/bios/ \
  && cp "$TEMP_SYSLINUX_PATH"/bios/com32/elflink/ldlinux/ldlinux.c32 /var/lib/tftpboot/bios/ \
  && cp "$TEMP_SYSLINUX_PATH"/bios/com32/menu/menu.c32 /var/lib/tftpboot/bios/ \
  && cp "$TEMP_SYSLINUX_PATH"/efi64/efi/syslinux.efi /var/lib/tftpboot/efi64/bootx64.efi \
  && cp "$TEMP_SYSLINUX_PATH"/efi64/com32/libutil/libutil.c32 /var/lib/tftpboot/efi64/ \
  && cp "$TEMP_SYSLINUX_PATH"/efi64/com32/elflink/ldlinux/ldlinux.e64 /var/lib/tftpboot/efi64/ \
  && cp "$TEMP_SYSLINUX_PATH"/efi64/com32/menu/menu.c32 /var/lib/tftpboot/efi64/ \
  && rm -rf "$TEMP_SYSLINUX_PATH" \
  && rm /tmp/"$SYSLINUX_FILE"
# Download and extract MemTest86+
ENV MEMTEST_VERSION 5.01
RUN wget -q http://www.memtest.org/download/"$MEMTEST_VERSION"/memtest86+-"$MEMTEST_VERSION".bin.gz \
  && gzip -d memtest86+-"$MEMTEST_VERSION".bin.gz \
  && mkdir -p /var/lib/tftpboot/memtest \
  && mv memtest86+-$MEMTEST_VERSION.bin /var/lib/tftpboot/memtest/memtest86+

# Configure PXE and TFTP
COPY tftpboot/ /var/lib/tftpboot

# Configure DNSMASQ
COPY etc/ /etc

# Start dnsmasq. It picks up default configuration from /etc/dnsmasq.conf and
# /etc/default/dnsmasq plus any command line switch
ENTRYPOINT ["dnsmasq", "--no-daemon"]
CMD ["--dhcp-range=192.168.56.2,proxy"]
