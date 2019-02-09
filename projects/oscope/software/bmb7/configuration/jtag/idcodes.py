#!/usr/bin/env python

# List of Xilinx parts [IDCODE, MASK, Description, IR length]
xilinx_idcodes = [

    # Xilinx System Ace
    (0x0A001093, 0x0FFFFFFF, 'Xilinx System Ace', 8),

    # Xilinx 95...XL series CPLDs
    (0x09602093, 0x0FFFFFFF, 'Xilinx XC9536XL CPLD', 8),
    (0x09604093, 0x0FFFFFFF, 'Xilinx XC9572XL CPLD', 8),
    (0x09608093, 0x0FFFFFFF, 'Xilinx XC95144XL CPLD', 8),
    (0x09616093, 0x0FFFFFFF, 'Xilinx XC95288XL CPLD', 8),

    # Xilinx Platform Flash
    (0x05044093, 0x0FFFFFFF, 'Xilinx Platform Flash 1Mbit', 16),
    (0x05045093, 0x0FFFFFFF, 'Xilinx Platform Flash 2Mbit', 16),
    (0x05046093, 0x0FFFFFFF, 'Xilinx Platform Flash 4Mbit', 16),
    (0x05057093, 0x0FFFFFFF, 'Xilinx Platform Flash 8Mbit', 16),
    (0x05058093, 0x0FFFFFFF, 'Xilinx Platform Flash 16Mbit', 16),
    (0x05059093, 0x0FFFFFFF, 'Xilinx Platform Flash 32Mbit', 16),

    # Xilinx Virtex 5

    (0x0286E093, 0x0FFFFFFF, 'Xilinx Virtex 5 LX30', 10),
    (0x02896093, 0x0FFFFFFF, 'Xilinx Virtex 5 LX50', 10),
    (0x028AE093, 0x0FFFFFFF, 'Xilinx Virtex 5 LX85', 10),
    (0x028D6093, 0x0FFFFFFF, 'Xilinx Virtex 5 LX110', 10),
    (0x028EC093, 0x0FFFFFFF, 'Xilinx Virtex 5 LX155', 10),
    (0x0290C093, 0x0FFFFFFF, 'Xilinx Virtex 5 LX220', 10),
    (0x0295C093, 0x0FFFFFFF, 'Xilinx Virtex 5 LX330', 10),

    (0x02A56093, 0x0FFFFFFF, 'Xilinx Virtex 5 LX20T', 10),
    (0x02A6E093, 0x0FFFFFFF, 'Xilinx Virtex 5 LX30T', 10),
    (0x02A96093, 0x0FFFFFFF, 'Xilinx Virtex 5 LX50T', 10),
    (0x02AAE093, 0x0FFFFFFF, 'Xilinx Virtex 5 LX85T', 10),
    (0x02AD6093, 0x0FFFFFFF, 'Xilinx Virtex 5 LX110T', 10),
    (0x02AEC093, 0x0FFFFFFF, 'Xilinx Virtex 5 LX155T', 10),
    (0x02B0C093, 0x0FFFFFFF, 'Xilinx Virtex 5 LX220T', 10),
    (0x02B5C093, 0x0FFFFFFF, 'Xilinx Virtex 5 LX330T', 10),

    (0x02E72093, 0x0FFFFFFF, 'Xilinx Virtex 5 SX35T', 10),
    (0x02E9A093, 0x0FFFFFFF, 'Xilinx Virtex 5 SX50T', 10),
    (0x02ECE093, 0x0FFFFFFF, 'Xilinx Virtex 5 SX95T', 10),
    (0x02F3E093, 0x0FFFFFFF, 'Xilinx Virtex 5 SX240T', 10),

    (0x03276093, 0x0FFFFFFF, 'Xilinx Virtex 5 FX30T', 10),
    (0x032C6093, 0x0FFFFFFF, 'Xilinx Virtex 5 FX70T', 10),
    (0x032D8093, 0x0FFFFFFF, 'Xilinx Virtex 5 FX100T', 10),
    (0x03300093, 0x0FFFFFFF, 'Xilinx Virtex 5 FX130T', 10),
    (0x03334093, 0x0FFFFFFF, 'Xilinx Virtex 5 FX200T', 10),

    (0x04502093, 0x0FFFFFFF, 'Xilinx Virtex 5 TX150T', 10),
    (0x0453E093, 0x0FFFFFFF, 'Xilinx Virtex 5 TX240T', 10),

    # Xilinx Spartan 6
    (0x04000093, 0x0FFFFFFF, 'Xilinx Spartan 6 LX4', 6),
    (0x04001093, 0x0FFFFFFF, 'Xilinx Spartan 6 LX9', 6),
    (0x04002093, 0x0FFFFFFF, 'Xilinx Spartan 6 LX16', 6),
    (0x04004093, 0x0FFFFFFF, 'Xilinx Spartan 6 LX25', 6),
    (0x04024093, 0x0FFFFFFF, 'Xilinx Spartan 6 LX25T', 6),
    (0x04008093, 0x0FFFFFFF, 'Xilinx Spartan 6 LX45', 6),
    (0x04028093, 0x0FFFFFFF, 'Xilinx Spartan 6 LX45T', 6),
    (0x0400E093, 0x0FFFFFFF, 'Xilinx Spartan 6 LX75', 6),
    (0x0402E093, 0x0FFFFFFF, 'Xilinx Spartan 6 LX75T', 6),
    (0x04011093, 0x0FFFFFFF, 'Xilinx Spartan 6 LX100', 6),
    (0x04031093, 0x0FFFFFFF, 'Xilinx Spartan 6 LX100T', 6),
    (0x0401D093, 0x0FFFFFFF, 'Xilinx Spartan 6 LX150', 6),
    (0x0403D093, 0x0FFFFFFF, 'Xilinx Spartan 6 LX150T', 6),

    # Xilinx Arctix 7

    (0x03631093, 0x0FFFFFFF, 'Xilinx Arctix 7 100T', 6),
    (0x03636093, 0x0FFFFFFF, 'Xilinx Arctix 7 200T', 6),

    # Xilinx Kintex 7

    (0x03647093, 0x0FFFFFFF, 'Xilinx Kintex 7 70T', 6),
    (0x0364C093, 0x0FFFFFFF, 'Xilinx Kintex 7 160T', 6),
    (0x03651093, 0x0FFFFFFF, 'Xilinx Kintex 7 325T', 6),
    (0x03647093, 0x0FFFFFFF, 'Xilinx Kintex 7 355T', 6),
    (0x03656093, 0x0FFFFFFF, 'Xilinx Kintex 7 410T', 6),
    (0x03752093, 0x0FFFFFFF, 'Xilinx Kintex 7 420T', 6),
    (0x03751093, 0x0FFFFFFF, 'Xilinx Kintex 7 480T', 6),
    
    # Xilinx Virtex 7

    (0x03671093, 0x0FFFFFFF, 'Xilinx Virtex 7 585T', 6),
    (0x03671093, 0x0FFF3FFF, 'Xilinx Virtex 7 2000T', 24),

    (0x03667093, 0x0FFFFFFF, 'Xilinx Virtex 7 X330T', 6),
    (0x03682093, 0x0FFFFFFF, 'Xilinx Virtex 7 X415T', 6),
    (0x03687093, 0x0FFFFFFF, 'Xilinx Virtex 7 X485T', 6),
    (0x03692093, 0x0FFFFFFF, 'Xilinx Virtex 7 X550T', 6),
    (0x03691093, 0x0FFFFFFF, 'Xilinx Virtex 7 X690T', 6),
    (0x03696093, 0x0FFFFFFF, 'Xilinx Virtex 7 X980T', 6),
    (0x036D5093, 0x0FFFFFFF, 'Xilinx Virtex 7 X1140T', 24),

    (0x036D9093, 0x0FFFFFFF, 'Xilinx Virtex 7 H580T', 22),
    (0x036DB093, 0x0FFFFFFF, 'Xilinx Virtex 7 H870T', 38)

]

# For future non-Xilinx additions
idcodes = xilinx_idcodes

#def xilinx_fpga_idcode_resolve_name(idcode):
#    for i in xilinx_part_list:
#        if (i[0] & i[1]) == (idcode & i[1]):
#            return i[2]
#    return 'UNKNOWN DEVICE'

#def idcode_resolve_name(idcode):
#    for i in idcode_list:
#        if (i[0] & i[1]) == (idcode & i[1]):
#            return i[2]
#    return 'UNKNOWN DEVICE'

#def idcode_resolve_irlen(idcode):
#    for i in idcode_list:
#        if (i[0] & i[1]) == (idcode & i[1]):
#            return i[3]
#    raise
