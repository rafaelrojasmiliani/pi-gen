#!/bin/bash -e

main() {

    if [ -f "${ROOTFS_DIR}/etc/avahi/avahi-daemon.conf" ]; then
        cat >"${ROOTFS_DIR}/etc/avahi/avahi-daemon.conf" <<EOL
[server]
host-name=${AVAHI_HOST_NAME}
use-ipv4=yes
use-ipv6=yes
ratelimit-interval-usec=1000000
ratelimit-burst=1000

[wide-area]
enable-wide-area=yes

[publish]
publish-hinfo=no
publish-workstation=no

[reflector]
enable-reflector=yes

[rlimits]
EOL
    fi

    if ${WLAN_HAS_STATIC_IP}; then
        sed -i '/interface wlan0/,$d' "${ROOTFS_DIR}/etc/dhcpcd.conf"
        sed -i '/^# PI_GEN WLAN BEGIN/,/^# PI_GEN WLAN END/{d}' \
            "${ROOTFS_DIR}/etc/dhcpcd.conf"
        cat >>"${ROOTFS_DIR}/etc/dhcpcd.conf" <<EOL
# PI_GEN WLAN BEGIN
interface wlan0
static ip_address=${WLAN_STATIC_IP}
static routers=${WLAN_STATIC_IP_GATEWAY}
# PI_GEN WLAN END
EOL
    fi

    if ${ETH_HAS_STATIC_IP}; then
        sed -i '/interface eth0/,$d' "${ROOTFS_DIR}/etc/dhcpcd.conf"
        sed -i '/^# PI_GEN ETH0 BEGIN/,/^# PI_GEN ETH0 END/{d}' \
            "${ROOTFS_DIR}/etc/dhcpcd.conf"
        cat >>"${ROOTFS_DIR}/etc/dhcpcd.conf" <<EOL
# PI_GEN ETH0 BEGIN
interface eth0
static ip_address=${ETH_STATIC_IP}
static routers=${ETH_STATIC_IP_GATEWAY}
# PI_GEN ETH0 END
EOL
    fi

    # cat >> "${ROOTFS_DIR}/etc/dhcp/dhcpd.conf" << EOL
    # option domain-name "example.org";
    # option domain-name-servers ns1.example.org, ns2.example.org;
    # default-lease-time 600;
    # max-lease-time 7200;
    # ddns-update-style none;

    # subnet 192.168.1.0 netmask 255.255.255.0 {
    #         option routers                  192.168.10.1;
    #         option subnet-mask              255.255.255.0;
    #         option domain-search            "example.org";
    #         option domain-name-servers      192.168.1.1;
    #         range   192.168.1.2   192.168.1.2;
    # }
    # EOL

}

main
