# silly exercise of programmable-brightness LEDS in lb_marble_slave.v
IP=192.168.19.10
while true; do
    for x1 in 0 10 40 127 215 245 255 245 215 127 40 10; do
        x2=$((255-$x1))
        echo $x1 $x2
        python3 bedrock/badger/lbus_access.py -a $IP reg 327682=$x1 326783=$x2
        sleep 0.1
    done
done
