#!/usr/bin/env python

from configuration.jtag import *
import spi, time
from datetime import datetime, timedelta
try:
    import ntplib  # see below, optional source of current time,
    # used when writing images in case local computer is messed up.
except:
    pass

KINTEX_IMAGE_TABLE_ADDRESS = 24 * spi.SECTOR_SIZE
KINTEX_IMAGE_TABLE_ENTRY_SIZE = 56

class interface():
    def __init__(self, prom):
        self.__target = prom

    def erase_table(self):
        self.__target.sector_erase(KINTEX_IMAGE_TABLE_ADDRESS)

    def get_images(self):

        data = self.__target.read_data(KINTEX_IMAGE_TABLE_ADDRESS, spi.SECTOR_SIZE)

        offset = 0

        result = list()

        while (offset < spi.SECTOR_SIZE - KINTEX_IMAGE_TABLE_ENTRY_SIZE):
            
            entry = data[offset : offset + KINTEX_IMAGE_TABLE_ENTRY_SIZE]

            length = 0
            for i in range(0, 4):
                length += int(entry[0+i]) * 2**(24-i*8)

            # End of table
            if length == 0xFFFFFFFF:
                break

            sha256 = entry[4:36]

            address = 0
            for i in range(0, 4):
                address += int(entry[36+i]) * 2**(24-i*8)

            build_date = 0
            for i in range(0, 8):
                build_date += int(entry[40+i]) * 2**(56-i*8)

            storage_date = 0
            for i in range(0, 8):
                storage_date += int(entry[48+i]) * 2**(56-i*8)

            result.append({
                    'sha256' : sha256,
                    'address' : address,
                    'length' : length,
                    'build_date' : build_date,
                    'storage_date' : storage_date
                    })

            offset += KINTEX_IMAGE_TABLE_ENTRY_SIZE

        return result

    def erase_image(self, identifier):
        
        images = self.get_images()

        for i in images:
            if i['sha256'] == identifier:
                print 'Erasing image'
                images.remove(i)
                self.save_image_table(images)
                return
        
        print 'Image not found'

    def save_image_table(self, images):

        # Initialise table to blank state
        table = bytearray()

        for i in images:

            length = i['length']
            address = i['address']
            build_date = i['build_date']
            storage_date = i['storage_date']

            x = bytearray()

            x.append((length >> 24) & 0xFF)
            x.append((length >> 16) & 0xFF)
            x.append((length >> 8) & 0xFF)
            x.append((length) & 0xFF)

            x += bytearray(i['sha256'])
            
            x.append((address >> 24) & 0xFF)
            x.append((address >> 16) & 0xFF)
            x.append((address >> 8) & 0xFF)
            x.append((address) & 0xFF)

            x.append((build_date >> 56) & 0xFF)
            x.append((build_date >> 48) & 0xFF)
            x.append((build_date >> 40) & 0xFF)
            x.append((build_date >> 32) & 0xFF)
            x.append((build_date >> 24) & 0xFF)
            x.append((build_date >> 16) & 0xFF)
            x.append((build_date >> 8) & 0xFF)
            x.append((build_date) & 0xFF)

            x.append((storage_date >> 56) & 0xFF)
            x.append((storage_date >> 48) & 0xFF)
            x.append((storage_date >> 40) & 0xFF)
            x.append((storage_date >> 32) & 0xFF)
            x.append((storage_date >> 24) & 0xFF)
            x.append((storage_date >> 16) & 0xFF)
            x.append((storage_date >> 8) & 0xFF)
            x.append((storage_date) & 0xFF)

            for j in x:
                print hex(j),
            print

            table += x

        # Append 0xFF block to end of last page or add extra page
        if len(table) % 256 == 0:
            table += bytearray([0xFF]) * 256
        else:
            table += bytearray([0xFF]) * (256 - len(table) % 256)

        # Compare the current data with the previous to see if we have to erase
        pd = self.__target.read_data(KINTEX_IMAGE_TABLE_ADDRESS, len(table))
        
        for i in range(0, len(table)):
            if ( table[i] != pd[i] ):
                if ( pd[i] != 0xFF ):
                    # Erase the previous table
                    print 'Erasing old file table'
                    self.erase_table()
                    break

        print 'Updating file table'
        for i in range(0, len(table) / 256):
            self.__target.page_program(table[i * 256 : (i+1) * 256], i * 256 + KINTEX_IMAGE_TABLE_ADDRESS)

        # Verify
        pd = self.__target.read_data(KINTEX_IMAGE_TABLE_ADDRESS, len(table))
        for i in range(0, len(pd)):
            if ( table[i] != pd[i] ):
                print
                raise SPI_Base_Exception('Image table update byte', str(i), 'failed')

    def add_image(self, name):
        
        # Start by assuming a completely empty Kintex space
        available_sectors = [[25, 500]]

        # Right now we presume everything is on a block boundary for simplicity
        images = self.get_images()

        # Parse the bitstream
        parser = xilinx_bitfile_parser.bitfile(name)
        
        # Each image should only overlap with a single available block
        for i in images:

            if i['sha256'] == parser.hash():
                if i['length'] == parser.length() / 8:
                    print 'Matching image already stored in PROM'
                    return

            for j in available_sectors:

                position = i['address'] / spi.SECTOR_SIZE
                length = i['length'] / spi.SECTOR_SIZE
                if ( length % spi.SECTOR_SIZE != 0 ):
                    length += 1

                if ( (position >= j[0]) and (position < j[1]) ):
                    if ( position == j[0] ):
                        if ( position + length == j[1] ):
                            # Whole block - remove
                            available_sectors.remove(j)
                        else:
                            # Front of block is used
                            j[0] = position + length
                    else:
                        if ( position + length == j[1] ):
                            # Back of block is used
                            j[1] = position
                        else:
                            # Middle of block is used - split
                            new_entry = [position+length, j[1]]
                            j[1] = position
                            available_sectors.append(new_entry)
                
                    break

        length = parser.length() / (8 * spi.SECTOR_SIZE)
        if ( (parser.length() / 8) % spi.SECTOR_SIZE != 0 ):
            length += 1
    
        print 'Sectors needed:',length

        location = 0
        for i in available_sectors:
            if ( (i[1] - i[0]) >= length ):
                location = i[0]
                break

        if location == 0:
            raise spi.SPI_Base_Exception('Insufficient contiguous sectors available on device')
        
        print 'Writing image starting at sector', location

        self.__target.program_bitfile(name, location)

        # Get the current date & time from NTP
        # Otherwise use local
        storage_date = 0
        
        try:
            c = ntplib.NTPClient()
            response = c.request('0.pool.ntp.org', version=3)
            storage_date = int(response.tx_time)
        except ntplib.NTPException:
            print 'Timeout on NTP request, using local clock instead'
            storage_date = int(time.time())

        build_date = int(time.mktime(datetime.strptime(parser.build_date() + ' ' + parser.build_time(), '%Y/%m/%d %H:%M:%S').timetuple()))

        print 'Storage timestamp:', storage_date
        print 'Build timestamp:', build_date

        print 'Adding entry to image table'

        images.append({
                'sha256' : parser.hash(),
                'address' : location * spi.SECTOR_SIZE,
                'length' : parser.length() / 8,
                'build_date' : build_date,
                'storage_date' : storage_date
                })

        self.save_image_table(images)
