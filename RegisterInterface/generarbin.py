from os import strerror

try:
    bf = open('file.bin', 'wb')

    data = bytearray(2)
    data[0] = 165 #0xA5
    data[1] = 2  #0x02 FILL RAM
    bf.write(data) 
  
    data = bytearray(4)
    i=j=0
    for k in range(4):
        for l in range(256):
            data[0] = i
            data[1] = j
            data[2] = k
            data[3] = l
            bf.write(data)

    data = bytearray(1)
    data[0] = 90 #0x5A
    bf.write(data) 

    bf.close()
except IOError as e:
    print('Se fue todo al carajo', strerr(e.errno))