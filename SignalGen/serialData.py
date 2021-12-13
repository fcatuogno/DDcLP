import serial as s
from frame import *

# [SOF=0xA5] [CMD] [PARAM1] [PARAM2] [VAL#0] [VAL#1] [VAL#2] [VAL#3] [EOF=0x5A]

port = s.Serial(port='COM7',baudrate=921600,bytesize=8,parity='N',stopbits=1)
                    #LSB         MSB
DUTY            = b'\x00\x02\x00\x00'
PRESCALER_A     = b'\x00\x00\x00\x01'
SEL             = b'\x01\x00\x00\x00'
PRESCALER_RAM   = b'\x00\x00\x44\x01'

#rampa(port)
rampaInv(port)
#triangular(port)
#senoidal(port)
#BurstRAM(port)
#cleanRAM(port)
#leerRAM(port)

sleep(1)

RW_Frame(port, CMD_WR_REG, BANK16, ADDR_0, DUTY)
RW_Frame(port, CMD_WR_REG, BANK32, ADDR_0, PRESCALER_A)
RW_Frame(port, CMD_WR_REG, BANK32, ADDR_1, PRESCALER_RAM)
RW_Frame(port, CMD_WR_REG, BANK8, ADDR_0, SEL)

RW_Frame(port, CMD_RD_REG, BANK16, ADDR_0, DUTY)
RW_Frame(port, CMD_RD_REG, BANK32, ADDR_0, PRESCALER_A)
RW_Frame(port, CMD_RD_REG, BANK8, ADDR_0, SEL)
RW_Frame(port, CMD_RD_REG, BANK32, ADDR_1, PRESCALER_RAM)


# RW_Frame(port, CMD_RD_RAM, b'\x01',b'\xFE',b'\x00\x00\x0B\xFA')
# RW_Frame(port, CMD_RD_RAM, b'\x00',b'\x1D',b'\x00\x00\x0B\xFA')
# RW_Frame(port, CMD_RD_RAM, b'\x03',b'\xFE',b'\x00\x00\x0B\xFA')
# RW_Frame(port, CMD_RD_RAM, b'\x03',b'\xFF',b'\x00\x00\x0B\xFA')

port.close()