#!/bin/bash
## snapshot.csh  <snapshot_name> 
##
## Create a new snapshot directory and copy this hardcoded list of files inside
##

## Files to copy
files='../src/cpld_ram512k_v110.v ../xc9572/cpld_ram512k_v110.rpt ../xc9572/cpld_ram512k_v110.syr ../xc9572/cpld_ram512k_v110.tim ../xc9572/cpld_ram512k_v110_xc9536-10-PC44.jed'

snapshot_name=$1
if [ -d $snapshot_name ] ; then
    echo "WARNING: directory $snapshot_name already exists, overwrite ? 
(Y/N)"
    read YESNO
    shopt -s nocasematch    
    case "$YESNO" in 
    "Y" ) echo "ok" ;;
    *) return 1;;
    esac
    rm -rf $snapshot_name
fi
mkdir $snapshot_name


for i in $files ; do
   cp $i $snapshot_name
done

