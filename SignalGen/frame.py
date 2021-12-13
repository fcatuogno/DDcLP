from time import sleep
import numpy as np

SOF             = b'\xA5'
CMD_RD_REG      = b'\x00'
CMD_WR_REG      = b'\x01'
CMD_WR_RAM      = b'\x02'
CMD_RD_RAM      = b'\x03'


EOF             = b'\x5A'
DONTCARE1       = b'\x00'
DONTCARE2       = b'\x00\x00'
DONTCARE4       = b'\x00\x00\x00\x00'
EMPTY4          = b'\x00\x00\x00\x00'
RAMSIZE = 1024

BANK8   = b'\x00'
BANK16  = b'\x01'
BANK32  = b'\x02'

ADDR_0  = b'\x00'
ADDR_1  = b'\x01'
ADDR_2  = b'\x02'
ADDR_3  = b'\x03'

def BurstRAM(port):
    i = 0
    port.write(SOF)
    port.write(CMD_WR_RAM)
    while i < RAMSIZE:
        port.write(i.to_bytes(4,'big'))
        # port.write(b'\xF3\xF3\xF3\xF3')
        i = i + 1
        #sleep(0.001)
    # port.write(EOF)
    #RW_Frame(port, CMD_WR_RAM, b'\x03',b'\xFF',b'\x00\x00\x03\xFF')

def rampa(port):
    i = 0
    port.write(SOF)
    port.write(CMD_WR_RAM)
    while i < RAMSIZE:
        port.write(i.to_bytes(4,'big'))
        i = i + 1
        #sleep(0.001)

def rampaInv(port):
    i = 1023
    port.write(SOF)
    port.write(CMD_WR_RAM)
    while i >= 0:
        port.write(i.to_bytes(4,'big'))
        i = i - 1

def triangular(port):
    i = 0
    j = 0
    port.write(SOF)
    port.write(CMD_WR_RAM)
    while j < RAMSIZE:
        port.write(i.to_bytes(4,'big'))
        j = j + 1
        if j<=RAMSIZE/2:
            i = i + 2
        else:
            i = i - 2


def senoidal(port):
    i = 0
    t = 0
    port.write(SOF)
    port.write(CMD_WR_RAM)
    while t < RAMSIZE:
        i = 511*np.sin(2*np.pi*t/1023)+512
        port.write(int(i).to_bytes(4,'big'))
        t = t + 1

def leerRAM(port):
    i = 0
    PARAM1 = b'\x00'
    PARAM2 = b'\x00'
    while i < RAMSIZE:
        PARAM = i.to_bytes(2, 'big')
        PARAM1 = PARAM[:1]
        PARAM2 = PARAM[1:2]
        RW_Frame(port, CMD_RD_RAM, PARAM1, PARAM2, b'\x00\x00\x00\x00')
        i = i + 1
        #sleep(0.001)
##################################################
#        port.write(SOF)
#        port.write(CMD_RD_RAM)
#        port.write(i.to_bytes(2,'big')) #p1 & p2
#        port.write(PARAM1) #Rellano para VAL
#        port.write(PARAM2)
#        port.write(PARAM1)
#        port.write(PARAM2)
#        i = i + 1
#        port.write(EOF)

def cleanRAM(port):
    i = 0
    port.write(SOF)
    port.write(CMD_WR_RAM)
    while i < RAMSIZE:
        port.write(EMPTY4)
        i = i + 1
    port.write(EOF)

def RW_Frame(port,CMD,PARAM1,PARAM2,DATA):

    port.write(SOF)
    port.write(CMD)
    port.write(PARAM1)
    port.write(PARAM2)
    port.write(DATA)
    port.write(EOF)
