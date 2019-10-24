# tap0 used by Verilog simulations
# This script must be run as root, and may or may not be specific to LBNL's CI server
ip -batch - <<EOT
tuntap add mode tap
link set tap0 up
address add 192.168.7.1 dev tap0
route add 192.168.7.0/24 dev tap0
EOT
