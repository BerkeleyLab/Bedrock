def bitn(num, n):
    return (num >> n) & 0x1


def prnd_951_sr_out(num=0x92):
    cn = (bitn(num, 8) ^ bitn(num, 4))  # +bitn(num,0))&0x1
    result = ((cn) + (num << 1)) & (2**9 - 1)
    out = result >> 8
    return [result, out]


def seq_start_width(seq, start, width):
    result = 0
    for i in range(width):
        loc = (start + i) % len(seq)
        result = result + (seq[loc] << (width - i - 1))
    return result


def outlast(seq, width):
    outseq = []
    start = 0
    cnt = 0
    result = seq_start_width(seq, start, width)
    outseq.append(result)
    cnt = cnt + 1
    start = (start + width) % len(seq)
    while start != 0:
        result = seq_start_width(seq, start, width)
        outseq.append(result)
        cnt = cnt + 1
        start = (start + width) % len(seq)
    return outseq


def prnd(seed, width):
    seq = []
    outseq = []
    num0 = seed
    counter = 1
    out = num0 >> 8
    seq.append(num0)
    outseq.append(out)
    [num, out] = prnd_951_sr_out(num0)
    counter = counter + 1
    while (num != num0):
        counter = counter + 1
        seq.append(num)
        outseq.append(out)
        [num, out] = prnd_951_sr_out(num)
    return outlast(outseq, width)


if __name__ == "__main__":
    outseq = prnd(seed=0x1ff, width=16)
    print(('\n'.join([format(i, '04x') for i in outseq])))
