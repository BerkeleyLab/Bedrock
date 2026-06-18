Zest is a dual LPC FMC mezzanine board with 8 ADCs and 2 DACs.

Full information about the Zest hardware is at: https://github.com/BerkeleyLab/Zest

### Using zest_setup.py

```
# -r resets the board, -f sets the local bus clock frequency
python zest_setup.py -a $IP -r -f 125.
```
