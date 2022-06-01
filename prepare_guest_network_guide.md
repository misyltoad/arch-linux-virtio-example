Run this in the VM to get the network to work:

```
GUEST_DEV=enp0s8
sudo ip addr add 192.168.10.2/24 dev "${GUEST_DEV}"
sudo ip link set "${GUEST_DEV}" up
sudo ip route add default via 192.168.10.1
echo "nameserver 8.8.8.8" | sudo tee /etc/resolv.conf
```
