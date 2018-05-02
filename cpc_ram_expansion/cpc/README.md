# ramtest


Memory test program for DK'Tronics compatible RAM expansions

Compile using Arnor BCPL

Create a disk image including

- minilib.b
- ramtest.b

Start BCPL

  |BCPL

Enter ramtest.bin when prompted for a file name

  GET "minilib.b"
  GET "ramtest.b"
  .

Exit to BASIC

RUN "ramtest.bin

