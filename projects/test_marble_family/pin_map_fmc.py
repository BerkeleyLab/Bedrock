# Such a short program, python isn't a bad choice
for fmc in [1, 2]:
    for ix in range(34):
        print("FMC%d_LA_%d_P   FMC%d_LA_P[%d]" % (fmc, ix, fmc, ix))
        print("FMC%d_LA_%d_N   FMC%d_LA_N[%d]" % (fmc, ix, fmc, ix))
