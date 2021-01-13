FROM docker.io/openstackhelm/libvirt:ubuntu_xenial-20190903
COPY libvirtd.conf /etc/libvirt/libvirtd.conf
COPY qemu.conf /etc/libvirt/qemu.conf
COPY libvirt.sh /tmp/libvirt.sh
RUN chmod +x /tmp/libvirt.sh
CMD /tmp/libvirt.sh