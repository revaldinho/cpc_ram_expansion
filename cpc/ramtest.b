MANIFEST $(
       BLKBOT = #x4000  
       BLKTOP = #x4FFF
       BLKSZ  = #X1000
       BANKMAN= #x7FFF
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

LET ramsel( bank, block ) BE $(
  OUT( BANKMAN, #xC0 | (bank<<3) | #x04 | (block&#x03) )
$) 

LET poke( adr, val ) BE $(
  // Get low byte val into A
  INLINE #xDD,#x7E,#x7E   // ld a, (ix+126)
  // Get ADR into DE
  INLINE #xDD,#x56,#x7D   // ld d, (ix+125)
  INLINE #xDD,#x5E,#x7C   // ld e, (ix+124)
  INLINE #x12             // ld (de),a
$)

LET peek( adr ) = VALOF $(
  LET v = 0
  INLINE #xDD,#x46,#x7F   // ld b, (ix+127)
  INLINE #xDD,#x4E,#x7E   // ld c, (ix+126)
  INLINE #x0A             // ld a, (bc)
  INLINE #xDD,#x77,#x76   // ld (ix+118),a
  RESULTIS v
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
            poke( BLKBOT, (bank*4)+block)
        $)
    $)

    FOR bank=0 TO 7 DO $(
        FOR block=0 TO 3 DO $(
            ramsel(bank,block)
            IF peek( BLKBOT) = (bank*4+block) DO $(
               ledger!((bank*4)+block+1) := 1
               ramblocks := ramblocks + 1
            $)
        $)
    $)

    RESULTIS ramblocks

$)

/* 
 * blocktest(block_abs)
 * 
 * RAM test of an absolute block number, is n=0..31 for a 512K expansion
 *
 */

LET blocktest(block_abs) = VALOF $(
    LET bank = (block_abs >> 2) & #x7
    LET block = block_abs & #x3
    LET fails = 0
    LET data = 0    
    LET BKG = "1234"  // put aside 4 bytes for data backgrounds

    BKG%1, BKG%2, BKG%3, BKG%4 := #x00, #x0F, #x33, #x55 

    writef("Testing bank %n, block %n ", bank,block)

    ramsel( bank, block)

    FOR bkg_num = 1 TO BKG%0 DO $(
        data := BKG%bkg_num
        FOR adr =BLKBOT TO BLKTOP DO $(
            poke( adr, data)
        $)
        wrch('.')
        FOR adr =BLKBOT TO BLKTOP DO $(
            UNLESS ( peek(adr) = data) DO fails := fails + 1
            poke( adr, ~(data))
        $)
        wrch('.')
        FOR adr =BLKBOT TO BLKTOP DO $(
            UNLESS ( peek(adr) EQV data ) DO fails := fails + 1
            poke( adr, data)
        $)
        wrch('.')
        FOR adr =BLKTOP TO BLKBOT BY -1 DO $(
            UNLESS (peek(adr) = data) DO fails := fails + 1
            poke( adr, ~(data))
        $)
        wrch('.')
        FOR adr =BLKTOP TO BLKBOT BY -1 DO $(
            UNLESS (peek(adr) EQV data) DO fails := fails + 1
        $)
        wrch('.')
    $)
    RESULTIS fails
$)

/* 
 * fullramtest()
 * 
 * RAM test of full RAM to check no interference between blocks
 *
 */

LET fullramtest() = VALOF $(
    LET bank = 0
    LET block = 0
    LET subblock = 0
    LET fails = 0
    
    LET BKG = #x55

    FOR block = 0 TO 31 DO $(
        IF ledger!(block+1) DO $(
           bank := (block >> 2)&#x7
           subblock := block & #x3
           ramsel(bank, subblock)
           FOR adr =BLKBOT TO BLKTOP DO poke( adr, BKG)
        $)    
        wrch('.')           
    $)
    newline()

    FOR block = 0 TO 31 DO $(
        IF ledger!(block+1) DO $(
           bank := (block >> 2)&#x7
           subblock := block & #x3
           ramsel(bank,subblock)
           FOR adr =BLKBOT TO BLKTOP DO $(
               UNLESS (peek(adr) = BKG) DO fails := fails + 1
               poke( adr, ~(BKG))
           $)
        $)
        wrch('.')           
    $)
    newline()

    //writef("Fails %n*n", fails)
    FOR block = 0 TO 31 DO $(
        IF ledger!(block+1) DO $(
           bank := (block >> 2)&#x7
           subblock := block & #x3
           ramsel(bank,subblock)
           FOR adr =BLKBOT TO BLKTOP DO $(
               UNLESS (peek(adr) EQV (BKG)) DO fails := fails + 1
               poke( adr, BKG)
           $)
        $)
        wrch('.')
    $)
    newline()
    //writef("Fails %n*n", fails)
    FOR block = 31 TO 0 BY -1 $(
        IF ledger!(block+1) DO $(
           bank := (block >> 2)&#x7
           subblock := block & #x3
           ramsel(bank,subblock)
           FOR adr =BLKTOP TO BLKBOT BY -1 DO $(
               UNLESS (peek(adr) = BKG) DO fails := fails + 1
               poke( adr, ~(BKG))
           $)
        $)
        wrch('.')
    $)
    newline()

    //writef("Fails %n*n", fails)
    FOR block = 31 TO 0 BY -1 $(
        IF ledger!(block+1) DO $(
           bank := (block >> 2)&#x7
           subblock := block & #x3
           ramsel(bank,subblock)
           FOR adr =BLKTOP TO BLKBOT BY -1 DO $(
               UNLESS (peek(adr) EQV (BKG)) DO fails := fails + 1
               poke( adr, BKG)
           $)
        $)
        wrch('.')
    $)
    newline()

    RESULTIS fails

$)

LET display(test_results) BE $(
    LET bank = 0
    writes("Block       0         1         2         3    *n")
    writes("Bank  +---------+---------+---------+---------+*n")
    FOR i=0 TO 31 DO $(
        IF (i& #x3) = 0 DO writef("    %n |", (i>>2)&#x7)
        TEST ledger!(i+1) THEN $(
           TEST test_results!(i+1) THEN writes("  PASS   |")
           ELSE writes("  FAIL   |")
        $)
        ELSE writes(" absent  |")
        IF (i& #x3) = 3 DO $(
           writes("*n")
           //writes("      +---------+---------+---------+---------+*n")
        $)
    $)
    writes("      +---------+---------+---------+---------+*n")
$)

LET start() BE $(
    LET ledger_space = VEC 32 
    LET test_results = VEC 32
    LET fails = 0
    LET total_ram_kb = 0
    LET ramblocks = 0
    LET t = 0
    ledger := ledger_space

    t := starttest(2)

    writes("*pR A M T E S T - (c) Revaldinho 2018*n")
    writes("*nMemory Test for DK'Tronics Compatible RAM Expansions*n")

    FOR i=1 TO 32 DO ledger!i := 0

    writes("*nRunning simple check to find RAM blocks ... ")
    ramblocks := rollcall()
    writef("Found %n RAM blocks*n", ramblocks)

    writes("*nRunning block by block RAM test*n")
    FOR i=1 TO 32 DO $(
        IF ledger!i DO $(
             total_ram_kb := total_ram_kb + 16
             fails := blocktest(i-1)
             
             TEST fails > 0 THEN $(
                 writes(" FAIL*n")
                 test_results!i := 0
             $) ELSE $(
                 writes(" PASS*n")
                 test_results!i := 1
             $)
        $)
    $)

    writef("*n*nS U M M A R Y*n*n")
    writef("Found %n KBytes Extension RAM*n*n", total_ram_kb)
    display(test_results)

    writes("*nRunning full RAM area test, all addresses*n")
    fails := fullramtest()
    
    TEST fails = 0 THEN writes("**** P A S S *****n") 
    ELSE writes("**** F A I L *****n")
    endtest(t)    

$)
