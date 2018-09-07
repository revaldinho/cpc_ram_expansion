MANIFEST $(
  BLKBOT = #x4000  
  BLKTOP = #x4FFF
  BLKSZ  = #X1000
  BANKMAN= #x7FFF
  VERBOSE = 1      
  MAXFAILS= 4
  BLK1 = #x4000
  BLK3 = #xC000
  TESTLEN = #x000F
  RAM=0
  BKGS = 4   
$)

STATIC $(
  ledger  = 0
$)

LET out( adr, val ) BE $(
  INLINE #xDD,#x7E,#x7E   // ld a, (ix+126) - low byte of val
  INLINE #xDD,#x46,#x7D   // ld b, (ix+125) - adr
  INLINE #xDD,#x4E,#x7C   // ld c, (ix+124)
  INLINE #xED, #x79       // out (c), a
$)


LET exp_ramsel( mode, bank, block) BE $(
  // Choosing mode >3 + a block number can access eff. modes 4-7
  // e.g.  ramsel(4,4,0) -> addresses bank 4, block 0 using mode 4
  //       ramsel(4,4,3) -> addresses bank 4, block 3 using mode 7
  //       ramsel(3,4,x) -> select bank4 mode 3, block number ignored (and can be omitted)
  //       ramsel(0,x,x) -> select base RAM, bank and block number ignored (and can be omitted)
  TEST (mode>3) THEN 
       out( BANKMAN, #xC0 | ((bank&#x07)<<3) | #x04 | (block&#x03) )
  ELSE
       out( BANKMAN, #xC0 | ((bank&#x07)<<3) | (mode&#x03))
$)

AND base_ramsel() BE $(
    exp_ramsel(0,0,0)
$)

AND ramsel( bank, block ) BE $(
  // legacy proc
  exp_ramsel(4, bank, block)
$) 


/*
 * rollcall()
 *
 * Simple check to identify which blocks are present and set
 * up entries in the ledger array
 *
 */
LET rollcall() = VALOF $(
    LET bank, block,ramblocks = 0,0,0

    FOR bank=0 TO 7 DO $(
        FOR block=0 TO 3 DO $(
            ramsel(bank,block)
            RAM%BLKBOT:=(bank<<2)+block
        $)
    $)

    FOR bank=0 TO 7 DO $(
        FOR block=0 TO 3 DO $(
            ramsel(bank,block)
            IF RAM%BLKBOT = ((bank<<2)+block) DO $(
               ledger!((bank<<2)+block+1) := 1
               ramblocks := ramblocks + 1
            $)
        $)
    $)
    RESULTIS ramblocks

$)


LET block_fill( start, len, data) BE $(
    LET adr,end=0,0
    end := start+len-1
    FOR adr = start TO end DO $(
        RAM%adr := data
    $)
$)

LET memcpy( src, dest, len ) BE $(
    LET s,end=0,0
    LET d = dest
    end := src+len-1
    FOR s = src TO end DO $(
        RAM%d := RAM%s
        d := d+1
    $)
$)

LET block_check( start, len, data, verbose) =VALOF $(
    LET adr,end, fails=0,0,0
    end := start+len-1
    FOR adr = start TO end DO $(
        UNLESS RAM%adr=data THEN $(
          fails:=fails+1
          IF (verbose) THEN writef("Error: adr %X4 Exp. %X2 Act. %X2 *n", adr, data, RAM%adr)
        $)
    $)
    RESULTIS fails
$)

LET rw_march( start,end,wr_val, rd_val, verbose ) = VALOF $(
    LET fails,adr,up=0,0,0
    LET incr = 0

    incr := (end < start) -> -1, 1;
    IF ( verbose>1 ) THEN writes("*n  March %s", (incr>0)-> "Up","Down")
        
    adr :=start
    WHILE adr ~= end DO $(
        TEST RAM%adr = rd_val THEN $(
            IF (verbose & ( adr & #x1F = 0)) THEN writes (".")
        $) ELSE $(
            fails := fails+1
            IF (verbose & (fails<=MAXFAILS)) THEN 
               writef("*nFail @ adr=%X4 expected= %X2 actual= %X2 *n", adr, rd_val, RAM%adr)             
        $)       
        RAM%adr := wr_val
        adr := adr + incr
    $)
    RESULTIS fails
$)

LET blk_9n_ramtest ( base, len, backgrounds, verbose) = VALOF $(
    // Simple 9N test, return 0 for success, or number of mismatches
    LET fails, memtop = 0,0
    LET bkg = VEC 4
    LET data, notdata = ?,?
    LET maxbkg = 3

    bkg!0 := #x00
    bkg!1 := #xAA
    bkg!2 := #xCC
    bkg!3 := #xF0

    UNLESS backgrounds > 3 DO maxbkg:=backgrounds

    memtop := base+len-1
    FOR i=0 TO maxbkg DO $(
        data := (bkg!i) & #xFF
        notdata := (~(bkg!i)) & #xFF    
        block_fill(base,len, data)  // 1N 
        fails := rw_march(base,memtop,notdata,data, verbose) // 2N 
        fails := fails + rw_march(base,memtop,data,notdata, verbose) // 2N
        fails := fails + rw_march(memtop,base,notdata,data, verbose) // 2N
        fails := fails + rw_march(memtop,base,data,notdata, verbose) // 2N
    $)
    IF ( verbose>0 ) THEN newline()
    RESULTIS fails
$)


LET exp_ramtest (mode, ledger, blk_fails, base_fails, verbose ) = VALOF $(    
    // RAM Test suitable for modes 1,3,4-7, return 0 for success or number of fails
    LET bank, blk, abs_blk = ?, ?, ?
    LET start_blk = 0
    LET blk_adr   = 0

    base_ramsel()

    TEST ( mode < 4 ) THEN $(
       start_blk:=3 
       blk_adr := BLK3
    $) ELSE $(
       start_blk:=0
       blk_adr := BLK1
    $)

    block_fill(blk_adr,TESTLEN,#x00)
    
    FOR bank=0 TO 7 DO $(
        writef("Checking bank %D *n", bank)
        FOR blk=start_blk TO 3 DO $( 
            abs_blk := bank*4 + blk
            TEST (ledger!abs_blk) THEN $(
               writef("  Block %D  ", blk)
               exp_ramsel( 8, bank, blk)
               blk_fails!abs_blk := blk_9n_ramtest(blk_adr, TESTLEN, BKGS, verbose)
               writef("  Checking base RAM*n")
               base_ramsel()
               base_fails!abs_blk := block_check(blk_adr,TESTLEN,#x00, verbose)
               IF ( base_fails!abs_blk >0 ) THEN block_fill(blk_adr,TESTLEN,#x00)
               writef("*n*n  Exp. fails: %D  Base fails: %D *n",  blk_fails!abs_blk, base_fails!abs_blk)
            $) ELSE $(
               base_fails!abs_blk :=0
               blk_fails!abs_blk :=0
               writef("*n  Blk %D Absent", blk)
            $)
        $)
    $)
    RESULTIS  (base_fails!abs_blk +  blk_fails!abs_blk)
$)

LET start() BE $(
    LET ledger_space = VEC 32 
    LET test_results = VEC 32
    LET fails = 0
    LET total_ram_kb = 0
    LET ramblocks = 0
    LET t = 0
    LET c47_blk_fails = VEC 32
    LET c47_base_fails = VEC 32
    LET tmp_blk, abs_blk, bank = 0,0,0
    
    ledger := ledger_space

    t := starttest(2)

    writes("*pR A M T E S T V 2 - (c) Revaldinho 2018*n")
    writes("*nMemory Test for DK'Tronics Compatible RAM Expansions*n")

    FOR i=1 TO 32 DO ledger!i := 0

    writes("*nRunning simple check to find RAM blocks ... ")
    ramblocks := rollcall()
    writef("Found %n RAM blocks*n", ramblocks)

    writes("*nMode C4-7 memory test*n")
    writes("=====================*n")
    exp_ramtest (8, ledger,c47_blk_fails,c47_base_fails, VERBOSE )

    writes("*p*n          ** E X P A N S I O N  **  R A M T E S T  **  S U M M A R Y  ** *n")    
    tmp_blk := 0
    FOR i=0 TO 32 DO IF ledger!i THEN tmp_blk:= tmp_blk+1
    writef("*nFound %D  expansion RAM blocks, Total RAM: 64K + %D K = %D K Bytes", tmp_blk, tmp_blk*16, (tmp_blk*16)+64)
    writes("*n*nExpansion memory test:*n*n")    
    writes("Bank   |   0    |   1    |   2    |   3    |   4    |   5    |   6    |   7    *n")
    writes("Blk|Mde|Exp/Base|Exp/Base|Exp/Base|Exp/Base|Exp/Base|Exp/Base|Exp/Base|Exp/Base*n")
    writes("---+---+--------+--------+--------+--------+--------+--------+--------+--------*n")
    FOR blk=3 TO 0 BY -1 DO $(
        writef("  %D |  %D ", blk, blk+4)
        FOR bank=0 TO 7 DO $( 
            abs_blk := bank*4 + blk
            TEST (ledger!abs_blk) THEN $(
                writes((c47_blk_fails!abs_blk)->"|BAD/","| OK/")
                writes((c47_base_fails!abs_blk)->"BAD ","OK  ")  
            $) ELSE writes("| Absent ")
        $)
        newline()
    $)
    writes("---+---+--------+--------+--------+--------+--------+--------+--------+--------*n")



    TEST fails = 0 THEN writes("**** P A S S *****n") 
    ELSE writes("**** F A I L *****n")
    endtest(t)    

$)
