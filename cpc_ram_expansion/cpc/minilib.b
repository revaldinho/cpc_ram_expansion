// (c)  Copyright:  Martin Richards  30 April 2014
//
// Reduced BCPLLIB to use with Amstrad CPC BCPL system with rdch/wrch remapped to
// System calls. Rev. Oct 2017
//
// Include parts of the ARNOR ALIBHDR1 file

option s-,b-,l-,o #x8000

MANIFEST $( bytesperword =2 ; endstream = -1 $)

STATIC $( randomseed = 0; lfsr = 0 $)

LET presskeytoexit() BE $(
  writes("Press any key to exit*n")
  rdch()
$)

AND mode(m) BE $(
  inline 221, 126, 126 // ld a, (ix+d)
  inline 205, #x0E, #xBC // call 0xbc0e [SCN_SET_MODE]
$)

AND time() = scaledtime(0)

AND scaledtime(d) = VALOF $(
  // Get time and divide it by provided power of two to allow timing of longer events
  LET t=0                                                     
  inline #xCD,#x0D,#xBD // call KM_TIME_PLEASE -> 4 byte result DE:HL 
  inline #xDD,#x7E,#x7E // ld a,(ix+126)       get divider (power of two)
  inline #xFE,#x00      // cp 0
  inline #x28,#x09      // jr z, exit          exit (no scaling) if d==0
  inline #x47           // ld b,a
                        // loop:
  inline #xCB,#x3B      // SRL e               divide lower 3 bytes of DE/HL
  inline #xCB,#x1C      // RR h
  inline #xCB,#x1D      // RR l
  inline #x10,#xF8      // DJNZ loop
                        // exit:
  inline #xDD,#x75,#x76 // ld (ix+118), l      store result in variable 't'
  inline #xDD,#x74,#x77 // ld (ix+119), h
  RESULTIS t
$)

AND resettime() BE $(
  inline #x11,0,0      // ld de,00
  inline #x21,0,0      // ld hl,00
  inline 205,#x10,#xBD // call 0xBD10 [KL_SET_TIME] 
$)

// Benchmark top and tail routines
AND starttest(m) = VALOF $(
  mode(m)
  resettime()
  RESULTIS 0
$)

AND endtest(t) BE $(
  LET t2,frac,sec = 0,0,0
  t2 := scaledtime(2)         // ask for time in 75th of sec.
  sec := (t2-t)/75            // seconds
  frac := (t2 - sec*75)*4/3   // convert remainder to 100ths 
  writef("Time elapsed = %N.", sec)
  writez(frac,2)
  writes("s*n")
  presskeytoexit()
$)

AND wrch(c) BE
$(
  inline 221,126,126
  inline 205,#x5A,#xBB
$)

AND rdch() = VALOF
$(
  let key = 0
  inline 205,#x18,#xBB    // call wait key
  inline 221,119,120      // store it in key
  RESULTIS key
$)

AND newline() BE $(
    wrch(10)
    wrch(13)
    $)
 
AND newpage() BE wrch('*p')

AND writed(num,d) BE
$(
  LET temp = VEC 20
  AND ptr, n = 0, num
  IF num <0 THEN d, n:= d-1, -n
  temp!ptr, n, ptr := n REM 10, n/10, ptr+1 REPEATUNTIL n=0
  FOR j = ptr+1 TO d DO wrch(' ')
  IF num < 0 THEN wrch('-')
  FOR j = ptr-1 TO 0 BY -1 DO wrch(temp!j+'0')
$)

AND writez(n, d) BE writedz(n, d, TRUE,  n<0)

AND writedz(n, d, zeroes, neg) BE
$( 
  LET t = VEC 10
  LET i = 0
  LET k = n

  IF neg DO $( d := d - 1; k := -n $)

  $( t!i := k REM 10
    k   := k/10
    i   := i + 1
  $) REPEATWHILE k

  IF neg & zeroes DO wrch('-')
  FOR j = i+1 TO d DO wrch(zeroes -> '0', '*s')
  IF neg & ~zeroes DO wrch('-')
  FOR j = i-1 TO 0 BY -1 DO wrch(t!j+'0')
$)

AND writen(n) BE writed(n, 0)

AND writehex(n, d) BE 
$( IF d>1 DO writehex(n>>4, d-1)
  wrch((n&15)!TABLE '0','1','2','3','4','5','6','7',
                    '8','9','A','B','C','D','E','F')
$)


AND writebin(n, d) BE
$( IF d > 1 DO writebin(n>>1, d-1)
  wrch((n&1)+'0')
$)

AND writes(s) BE
$( // UNLESS 0 < s < rootnode!rtn_memsize DO s := "##Bad string##"
   FOR i = 1 TO s%0 DO wrch(s%i)
$)

AND writet(s, d) BE
$( writes(s)
  FOR i = 1 TO d-s%0 DO wrch('*s')
$)

AND writeu(n, d) BE
$( LET m = (n>>1)/5
  IF m DO $( writed(m, d-1); d := 1 $)
  writed(n-m*10, d)
$)

// Simpler writef from an ancient blib distribution

AND writef (format, a, b, c, d, e, f, g, h, i, j, k) BE
$( LET t = @ a

   FOR p = 1 TO format%0 DO
   $( LET k = format%p

      TEST k='%'
           THEN $( LET f, arg, n = 0, t!0, 0
                   LET type      = ?
                   p    := p + 1
                   type := capitalch(format%p)
                   SWITCHON type INTO
                   $( DEFAULT: wrch(type); ENDCASE

                      CASE 'S': f := writes  ; GOTO l
                      CASE 'T': f := writet  ; GOTO m
                      CASE 'C': f := wrch    ; GOTO l
                      //CASE 'O': f := writeoct; GOTO m
                      CASE 'X': f := writehex; GOTO m
                      CASE 'I': f := writed  ; GOTO m
                      CASE 'N': f := writen  ; GOTO l
                      CASE 'U': f := writeu  ; GOTO m

                      m: p := p + 1
                         n := format%p
                         n := '0' <= n <= '9' -> n-'0', 10+n-'A'

                      l: f(arg, n)

                      CASE '$': t := t + 1
                   $)
                $)
           ELSE wrch(k)
    $)
$)

AND capitalch(ch) = 'a' <= ch <= 'z' -> ch + 'A' - 'a', ch

AND compch(ch1, ch2) = capitalch(ch1) - capitalch(ch2)

