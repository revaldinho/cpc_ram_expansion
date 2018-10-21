#!/usr/bin/env python
'''
  lst2inline.py -f|--filename <filename> [-x|--notext][-c|--nocomments][-d|--decimal][-n|numbytes <int>][-h|--help] 
 
  Convert ASM80 assembler listing file to INLINE statements suitable for Arnor BCPL

Mandatory switches
 -f, --filename  <def file>  source filename in ASM80 listing format

Optional switches
 -x, --notext                write data bytes only and no assembler source or comments
 -c, --nocomments            write data bytes with assembler source and labels but no comments
 -n, --numbytes              number of data bytes per line in notext format (default is 6)
 -d, --decimal               write data bytes in decimal (default is hexadecimal)
 -h, --help                  write out this usage message
'''
import getopt, os, re, sys

def showUsageAndExit() :
    print __doc__
    sys.exit(2)

def lst2inline( filename, keeptext, keepcomment, numbytes, decimal ):

    codeline_re = re.compile("[0-9A-F]*\s*([0-9A-F][0-9A-F])? ([0-9A-F][0-9A-F])? ([0-9A-F][0-9A-F])? ([0-9A-F][0-9A-F])?\s*(\w*:)?\s*?(\w.*)?")
    
    print( "// %s" % ' '.join(sys.argv))
    with open(filename,"r") as f :
        code = []
        for l in f:
            (line, comment) = (l+";").split(';')[:2] 
            mobj = codeline_re.match(line)
            if mobj:
                if keeptext:
                    code = []
                code.extend( [(str(int(x,16)) if decimal else x) for x in mobj.group(1,2,3,4) if x ] )
            if keeptext:
                if decimal:
                    lineout = [ "%-23s" % ("" if len(code)==0 else ("INLINE %s" % ''.join(','.join(code)))) ] + ["// "]            
                else:
                    lineout = [ "%-27s" % ("" if len(code)==0 else ("INLINE #x%s" % ''.join(',#x'.join(code)))) ] + ["// "]            
                lineout.extend( [x.strip().upper() for x in mobj.group(5,6) if x ] )                
                if keepcomment and len(comment)>1:
                    lineout.append(" ; %s" % comment.rstrip().lower())
                print(''.join(lineout))
        if not keeptext:
            for i in range(0, len(code), numbytes ):
                if decimal:
                    print( ''.join("INLINE %s" % ','.join(code[i:min(i+numbytes,len(code))])))            
                else:
                    print( ''.join("INLINE #x%s" % ',#x'.join(code[i:min(i+numbytes,len(code))])))            
    f.close()

if __name__ == "__main__" :
    filename = ""
    keeptext = True
    keepcomment= True
    numbytes = 6
    decimal = False
    try:
        opts, args = getopt.getopt( sys.argv[1:], "f:n:dcxh", ["filename=","numbytes","decimal","nocomments","notext","help"])
    except getopt.GetoptError:
        showUsageAndExit()
    for opt, arg in opts:
        if opt in ( "-f", "--filename" ) :
            filename = arg
        elif opt in ( "-n", "--numbytes" ) :
            numbytes = int(arg,0)
        elif opt in ( "-x", "--notext" ) :
            keeptext = False
            keepcomment = False
        elif opt in ( "-c", "--nocomments" ) :
            keepcomment = False
        elif opt in ( "-d", "--decimal" ) :
            decimal = True
        elif opt in ( "-h","--help" ) :            
            showUsageAndExit()

    if ( filename == ""):
        showUsageAndExit()
    if ( not os.path.exists(filename) ) :
        print "ERROR: File %s doesn't exist" % filename
        sys.exit(2)

    lst2inline( filename, keeptext, keepcomment, numbytes, decimal)
        
