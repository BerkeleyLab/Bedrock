from litex import RemoteClient
wb = RemoteClient()
wb.open()
print(wb.regs.data_pipe_fifo_read.write(0))
print(wb.regs.data_pipe_fifo_load.write(1))
print(wb.regs.data_pipe_fifo_load.read())
while True:
    x = wb.regs.data_pipe_fifo_full.read()
    print(x)
    if x == 1:
        break
    pass

print("read", wb.regs.data_pipe_fifo_read.write(1))
wb.close()
