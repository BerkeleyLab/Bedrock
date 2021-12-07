import socket
import struct
import time

from multiprocessing import Process
from functools import reduce

import numpy as np
from matplotlib import pyplot as plt

from litex import RemoteClient

# np.set_printoptions(threshold=sys.maxsize)


def trigger_hardware(n_points):
    wb = RemoteClient()
    wb.open()
    assert n_points <= 1024 * 1024
    fifo_size = wb.regs.data_pipe_fifo_size.read()
    print(f"Fifo size was set to {fifo_size}")
    if n_points != fifo_size:
        print(f"Setting fifo size to {n_points}")
        wb.regs.data_pipe_fifo_size.write(n_points)
        print(f"fifo size set to {wb.regs.data_pipe_fifo_size.read()}")

    print(wb.regs.data_pipe_fifo_read.write(0))
    print(wb.regs.data_pipe_fifo_load.write(1))
    triggered_at = time.time()
    print(wb.regs.data_pipe_fifo_load.read())
    while wb.regs.data_pipe_fifo_full.read() != 1:
        pass
    full_at = time.time()
    print(f"triggered at {triggered_at}")
    print(f"full at {full_at}. Now sending read command")
    wb.regs.data_pipe_fifo_read.write(1)


def recvall(sock, n_points=1024 * 1024):
    BUFF_SIZE = n_points * 8 * 2   # 1M points from 8 ADCs each 2 bytes wide
    yet_to_rx = BUFF_SIZE
    data = []
    total_len = 0
    packet_cnt = 0
    while True:
        if yet_to_rx > 1464:
            ask = 1472
        else:
            ask = yet_to_rx + 8
        part, _ = sock.recvfrom(ask)
        data.append(part)
        total_len += len(part) - 8
        yet_to_rx -= len(part) - 8
        if total_len >= BUFF_SIZE:
            # either 0 or end of data
            break
        packet_cnt += 1

    print(f'time-rx-complete {time.time()}\npackets-received {len(data)}\nbytes-received {total_len}')
    return data


def capture(ip, port, plot_n, n_points, to_file="dump.bin"):
    sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    sock.bind((ip, port))
    sock.setsockopt(socket.SOL_SOCKET, socket.SO_RCVBUF, 1024 * 1024 * 16)
    print(sock.getsockopt(socket.SOL_SOCKET, socket.SO_RCVBUF))
    data = recvall(sock, n_points)
    ids = [struct.unpack(f'>{2}I', p[:8])[1] for p in data]

    # Checking no packets went missing
    print("checking no packets gone missing")
    for i, j in zip(ids[:-1], ids[1:]):
        if i + 1 != j:
            print(i, j)
            print("ERROR: Missing packets")

    print("splicing ..")
    D = reduce(lambda x, y: x+y, [p[8:] for p in data])
    x = len(D)//2

    print("unpacking ..")
    D = struct.unpack(f'>{x}h', D)
    D = np.array(D, np.dtype(np.int16))
    D = np.reshape(D, (-1, 8))

    print("plotting ..")
    if plot_n != 0:
        for i in range(8):
            plt.plot(D[:, i][:plot_n])
        plt.show()

    print(f"dumping to {to_file} ..")
    if to_file is not None:
        D.tofile(to_file)


def main():
    import argparse
    parser = argparse.ArgumentParser(description="Capture buffer from zest")
    parser.add_argument("--ip", default="192.168.1.114", help="capture host ip")
    parser.add_argument("--port", default=7778, help="capture host port")
    parser.add_argument("--plot-n", default=0, type=int,
                        help="make a plot of the first N points of all channels")
    parser.add_argument("--fifo-size", default=1024*1024, type=int,
                        help="Number of ADC channel data points to store (8x"
                        "get stored as there are 8 ADC channels in zest)")
    parser.add_argument("--to-file", default="dump.bin", help="dump data to file")
    parser.add_argument("--from-file", default="", help="plot data from file; No capture in this case")
    cmd_args = parser.parse_args()
    if cmd_args.from_file != "":
        D = np.fromfile(cmd_args.from_file, dtype=np.int16)
        D = np.reshape(D, (-1, 8))
        print(D)
        print(cmd_args.plot_n)
        for i in range(8):
            plt.plot(D[:, i][:int(cmd_args.plot_n)])
        plt.show()
    else:
        fifo_size = cmd_args.fifo_size
        p = Process(target=capture,
                    args=(cmd_args.ip,
                          cmd_args.port,
                          cmd_args.plot_n,
                          cmd_args.fifo_size,),
                    kwargs={"to_file" : cmd_args.to_file})
        p.start()
        trigger_hardware(fifo_size)
        p.join()


if __name__ == "__main__":
    main()
