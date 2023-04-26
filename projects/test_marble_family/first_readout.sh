IP=$1
echo "first_readout $IP"
set -e
ping -c 2 $IP
export PYTHONPATH=../common:../../badger/tests
python3 -m testcase -a $IP -p 803 --stop --trx --si570
python3 -m peek_mailbox leep://$IP:803
tt=$(mktemp quick_XXXXXX)
python3 -m spi_test --ip $IP --udp 804 --otp --pages=1 --dump $tt
hexdump $tt | head -n 2
rm $tt
