#!/bin/tcsh


if ( -e ramtest.dsk ) rm -rf ramtest.dsk


iDSK ramtest.dsk -n

foreach l ( ramtest.b testlib.b minilib.b )
   if ( -e $l ) iDSK ramtest.dsk -i $l
end


