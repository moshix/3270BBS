# TIMESHARING ASSEMBLER V1.0.1 Manual

## Overview

The TIMESHARING ASSEMBLER V1.0.1 provides a complete environment for writing, assembling, and executing IBM System/360 assembly language programs. It supports teh core S/360 instrction set and ASSIST I/O macros for simplified input/output operations. It's primarily a learning tool. And it's still experimeental, so report any issues to the developr. 

## Getting Started

Acces the assembler from the Extended Menu by selecting option **A** (or use shortcut M;A from the main menu).

### Basic Commands

| Command | Description |
|---------|-------------|
| `NEW` | Clear program memory and start fresh |
| `LOAD name` | Load a program from disk |
| `SAVE name` | Save current program to disk |
| `EDIT [name]` | Open program in ISPF editor |
| `LIST` | Display program source code |
| `RUN` | Assemble and execute program |
| `CHECK` | Syntax check and generate listing |
| `BYE` / `EXIT` | Return to menu |

### Debugging Commands

| Command | Description |
|---------|-------------|
| `REGS` | Display CPU registers |
| `DUMP addr [len]` | Dump memory contents |
| `SYMBOLS` | Display symbol table |

### File Management

| Command | Description |
|---------|-------------|
| `FILES` | List all available programs |
| `FLIST` | List your programs only |
| `BROWSE` | Open file browser |
| `ERASE name` | Delete a program file |
| `VIEW [name]` | View listing file |
| `EMAIL file` | Email listing to your email |

## Program Structure

A typical S/360 assembly program follows this structure:

```
PROGNAME CSECT                    Control section start
         USING PROGNAME,R15       Establish base register
*
* Your code here
*
         BCR   15,R14             Return to caller
*
* Data area
*
DATA     DS    ...                Data definitions
         END   PROGNAME           End of program
```

## Example: Simple Test Program

This minimal program demonstrates basic program structure:

```asm
*****************************************************************
*        HELLO WORLD - SIMPLE INTRODUCTION PROGRAM              *
*        S/360 ASSEMBLER FOR TSU TIMESHARING                    *
*        DEMONSTRATES BASIC OUTPUT AND PROGRAM STRUCTURE        *
*        COPYRIGHT 2025 MOSHIX - ALL RIGHTS RESERVED            *
*****************************************************************
HELLO    CSECT
         USING HELLO,R15
*
* REGISTER EQUATES
R0       EQU   0
R1       EQU   1
R2       EQU   2
R3       EQU   3
R4       EQU   4
R5       EQU   5
R6       EQU   6
R7       EQU   7
R8       EQU   8
R9       EQU   9
R10      EQU   10
R11      EQU   11
R12      EQU   12
R13      EQU   13
R14      EQU   14
R15      EQU   15
*
*-----------------------------------------------------------------
* END PROGRAM - BR R14 WITH R14=0 WILL HALT
*-----------------------------------------------------------------
         BR    R14
*
*-----------------------------------------------------------------
* DATA AREA
*-----------------------------------------------------------------
         DS    0F
NUM1     DC    F'25'
NUM2     DC    F'17'
RESULT   DS    F
*
* MESSAGES
BANNER1  DC    CL50'=================================================='
BANNER2  DC    CL50'        WELCOME TO S/360 ASSEMBLER!              '
BANNER3  DC    CL50'=================================================='
MSG1     DC    CL40' THIS IS YOUR FIRST ASSEMBLER PROGRAM  '
MSG2     DC    CL40' IT DEMONSTRATES:                      '
MSG3     DC    CL40'   - PRINTING AND ARITHMETIC           '
MATH1    DC    CL40' SIMPLE ARITHMETIC: 25 + 17 =          '
OUTMSG   DC    CL12' RESULT:    '
GOODBYE  DC    CL50' THANK YOU FOR TRYING THE ASSEMBLER! GOODBYE!'
BLANK    DC    CL1' '
*
* OUTPUT BUFFER FOR XDECO
OUTLINE  DS    CL12
*
         END   HELLO
```

## Example: Hello World with Input/Output

This program demonstrates user input, string handling, and arithmetic:

```asm
*****************************************************************
*        HELLO WORLD - SIMPLE INTRODUCTION PROGRAM              *
*        S/360 ASSEMBLER FOR TSU TIMESHARING                    *
*        DEMONSTRATES INPUT, OUTPUT, AND STRING HANDLING        *
*        COPYRIGHT 2025 MOSHIX - ALL RIGHTS RESERVED            *
*****************************************************************
HELLO    CSECT
         USING HELLO,R15
*
* REGISTER EQUATES
R0       EQU   0
R1       EQU   1
R2       EQU   2
R3       EQU   3
R4       EQU   4
R5       EQU   5
R6       EQU   6
R7       EQU   7
R8       EQU   8
R9       EQU   9
R10      EQU   10
R11      EQU   11
R12      EQU   12
R13      EQU   13
R14      EQU   14
R15      EQU   15
*
*-----------------------------------------------------------------
* PRINT WELCOME MESSAGES
*-----------------------------------------------------------------
         XPRNT BANNER1,50
         XPRNT BANNER2,50
         XPRNT BANNER3,50
         XPRNT BLANK,1
         XPRNT MSG1,40
         XPRNT MSG2,40
         XPRNT MSG3,40
         XPRNT MSG4,40
         XPRNT BLANK,1
         XPRNT BANNER3,50
*
*-----------------------------------------------------------------
* ASK FOR USER'S NAME AND GREET THEM
*-----------------------------------------------------------------
         XPRNT BLANK,1
         XPRNT ASKNAME,30
*
* READ USER INPUT INTO INBUF
         XREAD INBUF,20
*
* NOW BUILD THE GREETING: "HELLO, " + NAME
* THE GREETING BUFFER ALREADY HAS "HELLO, " AT THE START
* WE NEED TO COPY THE NAME FROM INBUF TO GREET+7
*
* USE MVC TO COPY THE NAME (UP TO 20 CHARS)
* MVC GREET+8(20),INBUF COPIES INBUF TO POSITION 8 IN GREET
* (POSITION 8 BECAUSE GREET HAS CARRIAGE CONTROL CHAR + "HELLO, ")
         MVC   GREET+8(20),INBUF
*
* PRINT THE PERSONALIZED GREETING
         XPRNT GREET,30
         XPRNT BLANK,1
*
*-----------------------------------------------------------------
* DEMONSTRATE SIMPLE ARITHMETIC
*-----------------------------------------------------------------
         XPRNT MATH1,40
*
* LOAD FIRST NUMBER INTO R2
         L     R2,NUM1
* ADD SECOND NUMBER
         A     R2,NUM2
* STORE RESULT
         ST    R2,RESULT
*
* CONVERT RESULT TO DECIMAL AND PRINT
         XDECO R2,OUTLINE
         XPRNT OUTMSG,12
         XPRNT OUTLINE,12
*
*-----------------------------------------------------------------
* SAY GOODBYE
*-----------------------------------------------------------------
         XPRNT BLANK,1
         XPRNT GOODBYE,50
*
*-----------------------------------------------------------------
* END PROGRAM - BR R14 WITH R14=0 WILL HALT
*-----------------------------------------------------------------
         BR    R14
*
*-----------------------------------------------------------------
* DATA AREA
*-----------------------------------------------------------------
         DS    0F
NUM1     DC    F'25'
NUM2     DC    F'17'
RESULT   DS    F
*
* INPUT BUFFER FOR NAME (20 CHARS MAX)
INBUF    DS    CL20
*
* GREETING MESSAGE - SPACE (CC) + "HELLO, " FOLLOWED BY SPACE FOR NAME
GREET    DC    CL30' HELLO, '
*
* MESSAGES
BANNER1  DC    CL50'=================================================='
BANNER2  DC    CL50'        WELCOME TO S/360 ASSEMBLER!              '
BANNER3  DC    CL50'=================================================='
MSG1     DC    CL40' THIS IS YOUR FIRST ASSEMBLER PROGRAM  '
MSG2     DC    CL40' IT DEMONSTRATES:                      '
MSG3     DC    CL40'   - INPUT/OUTPUT WITH XREAD/XPRNT     '
MSG4     DC    CL40'   - STRING HANDLING WITH MVC          '
ASKNAME  DC    CL30' WHAT IS YOUR NAME? '
MATH1    DC    CL40' SIMPLE ARITHMETIC: 25 + 17 =          '
OUTMSG   DC    CL12' RESULT:    '
GOODBYE  DC    CL50' THANK YOU FOR TRYING THE ASSEMBLER! GOODBYE!'
BLANK    DC    CL1' '
*
* OUTPUT BUFFER FOR XDECO
OUTLINE  DS    CL12
*
         END   HELLO
```

## Example Listing (CHECK Command Output)

When you run teh `CHECK` command, the assembler produces a listing file showing object code, addresses, and source. Here is a sample from the N-Queens solver:

```
  TIMESHARING S/360 ASSEMBLER v1.0.1 - NQUEENS
  Generated: 2026-01-17 13:02:12


LOC  OBJECT CODE    ADDR1 ADDR2  STMT   SOURCE STATEMENT                 NQUEENS 
------------------------------------------------------------------------------
                                    1  ***********************************
                                    2  *        N-QUEENS SOLVER - ITERATIV
                                    3  *        S/360 ASSEMBLER FOR ASSIST
                                    4  *        FINDS ALL SOLUTIONS FOR N 
                                    5  *        COPYRIGHT 2025 MOSHIX - AL
                                    6  ***********************************
00000                               7  NQUEENS  CSECT
                                    8           USING NQUEENS,R15
                                    9  *
                                   10  * REGISTER USAGE:
                                   11  *   R2  = N (BOARD SIZE)
                                   12  *   R3  = CURRENT ROW
                                   13  *   R4  = CURRENT COLUMN / WORK
                                   14  *   R5  = LOOP COUNTER K
                                   15  *   R6  = SAFE FLAG (1=SAFE, 0=UNSA
                                   16  *   R7  = SOLUTION COUNT
                                   17  *   R8  = SHOWN COUNT
                                   18  *   R9  = WORK REGISTER
                                   19  *   R10 = WORK REGISTER
                                   20  *   R11 = BASE FOR Q ARRAY
                                   21  *   R12 = TEMP
                                   22  *   R14 = RETURN ADDRESS
                                   23  *   R15 = BASE REGISTER
                                   24  *
                                   25  *----------------------------------
                                   26  * DISPLAY TITLE
                                   27  *----------------------------------
00000                              28           XPRNT TITLE1,40
00004                              29           XPRNT TITLE2,40
00008                              30           XPRNT TITLE3,40
0000C                              31           XPRNT BLANK,1
                                   32  *
                                   33  *----------------------------------
                                   34  * GET BOARD SIZE FROM USER
                                   35  *----------------------------------
00010                              36  GETSIZE  XPRNT PROMPT,30
00014                              37           XREAD INBUF,80
00018                              38           XDECI R2,INBUF
0001C 5920 0000                    39           C     R2,=F'4'
00020 4740 F030      00030         40           BL    TOOSMALL
00024 5920 0000                    41           C     R2,=F'9'
00028 4720 F038      00038         42           BH    TOOBIG
0002C 47F0 F040      00040         43           B     SIZEOK
                                   44  *
00030                              45  TOOSMALL XPRNT MINERR,35
00034 47F0 F010      00010         46           B     GETSIZE
00038                              47  TOOBIG   XPRNT MAXERR,35
0003C 47F0 F010      00010         48           B     GETSIZE
                                   49  *
                                   50  *----------------------------------
                                   51  * INITIALIZE
                                   52  *----------------------------------
00040 5020 0000                    53  SIZEOK   ST    R2,N              SA
00044 1B77                         54           SR    R7,R7             SO
00046 1B88                         55           SR    R8,R8             SH
00048 41B0 F1E4      001E4         56           LA    R11,QUEENS        BA
```

The listing shows:
- **LOC**: Location (hex address) in the program
- **OBJECT CODE**: Machine code generated
- **ADDR1/ADDR2**: Resolved addresses for operands
- **STMT**: Statement number
- **SOURCE STATEMENT**: Original source code

## Supported Instructions

### RR Format (Register-Register)

| Mnemonic | Operation |
|----------|-----------|
| `LR R1,R2` | Load Register |
| `LTR R1,R2` | Load and Test Register |
| `LCR R1,R2` | Load Complement Register |
| `LNR R1,R2` | Load Negative Register |
| `LPR R1,R2` | Load Positive Register |
| `AR R1,R2` | Add Register |
| `SR R1,R2` | Subtract Register |
| `MR R1,R2` | Multiply Register (R1 must be even) |
| `DR R1,R2` | Divide Register (R1 must be even) |
| `CR R1,R2` | Compare Register |
| `NR R1,R2` | AND Register |
| `OR R1,R2` | OR Register |
| `XR R1,R2` | XOR Register |
| `BALR R1,R2` | Branch and Link Register |
| `BCR M,R2` | Branch on Condition Register |
| `BCTR R1,R2` | Branch on Count Register |

### RX Format (Register-Storage)

| Mnemonic | Operation |
|----------|-----------|
| `L R1,D(X,B)` | Load |
| `ST R1,D(X,B)` | Store |
| `LA R1,D(X,B)` | Load Address |
| `LH R1,D(X,B)` | Load Halfword |
| `STH R1,D(X,B)` | Store Halfword |
| `IC R1,D(X,B)` | Insert Character |
| `STC R1,D(X,B)` | Store Character |
| `A R1,D(X,B)` | Add |
| `S R1,D(X,B)` | Subtract |
| `M R1,D(X,B)` | Multiply |
| `D R1,D(X,B)` | Divide |
| `C R1,D(X,B)` | Compare |
| `N R1,D(X,B)` | AND |
| `O R1,D(X,B)` | OR |
| `X R1,D(X,B)` | XOR |
| `BC M,D(X,B)` | Branch on Condition |
| `BAL R1,D(X,B)` | Branch and Link |
| `BCT R1,D(X,B)` | Branch on Count |

### RS Format (Register-Storage)

| Mnemonic | Operation |
|----------|-----------|
| `LM R1,R3,D(B)` | Load Multiple |
| `STM R1,R3,D(B)` | Store Multiple |
| `SLA R1,D(B)` | Shift Left Arithmetic |
| `SRA R1,D(B)` | Shift Right Arithmetic |
| `SLL R1,D(B)` | Shift Left Logical |
| `SRL R1,D(B)` | Shift Right Logical |
| `BXH R1,R3,D(B)` | Branch on Index High |
| `BXLE R1,R3,D(B)` | Branch on Index Low or Equal |

### SI Format (Storage-Immediate)

| Mnemonic | Operation |
|----------|-----------|
| `MVI D(B),I` | Move Immediate |
| `CLI D(B),I` | Compare Logical Immediate |
| `NI D(B),I` | AND Immediate |
| `OI D(B),I` | OR Immediate |
| `XI D(B),I` | XOR Immediate |
| `TM D(B),I` | Test Under Mask |

### SS Format (Storage-Storage)

| Mnemonic | Operation |
|----------|-----------|
| `MVC D1(L,B1),D2(B2)` | Move Characters |
| `CLC D1(L,B1),D2(B2)` | Compare Logical Characters |
| `NC D1(L,B1),D2(B2)` | AND Characters |
| `OC D1(L,B1),D2(B2)` | OR Characters |
| `XC D1(L,B1),D2(B2)` | XOR Characters |
| `PACK D1(L1,B1),D2(L2,B2)` | Pack |
| `UNPK D1(L1,B1),D2(L2,B2)` | Unpack |
| `TR D1(L,B1),D2(B2)` | Translate |
| `ED D1(L,B1),D2(B2)` | Edit (format packed decimal) |
| `EDMK D1(L,B1),D2(B2)` | Edit and Mark |

### Extended Branch Mnemonics

| Mnemonic | Meaning | Mask |
|----------|---------|------|
| `B addr` | Branch Always | 15 |
| `BR R2` | Branch Always (Register) | 15 |
| `BE addr` | Branch if Equal | 8 |
| `BNE addr` | Branch if Not Equal | 7 |
| `BH addr` | Branch if High | 2 |
| `BL addr` | Branch if Low | 4 |
| `BNH addr` | Branch if Not High | 13 |
| `BNL addr` | Branch if Not Low | 11 |
| `BP addr` | Branch if Plus | 2 |
| `BM addr` | Branch if Minus | 4 |
| `BZ addr` | Branch if Zero | 8 |
| `BNZ addr` | Branch if Not Zero | 7 |
| `BO addr` | Branch if Overflow | 1 |
| `NOP addr` | No Operation | 0 |

## Assembler Directives

| Directive | Description |
|-----------|-------------|
| `START [addr]` | Start assembly at address |
| `END [entry]` | End assembly, optional entry point |
| `CSECT` | Define control section |
| `USING symbol,Rn` | Establish base register |
| `DROP Rn` | Drop base register |
| `EQU expr` | Define symbol value |
| `DC type'value'` | Define constant |
| `DS type` | Define storage |
| `ORG expr` | Set location counter |
| `LTORG` | Generate literal pool |

### DC (Define Constant) Types

| Type | Description | Alignment | Default Length |
|------|-------------|-----------|----------------|
| `F` | Fullword (32-bit signed) | 4 | 4 |
| `H` | Halfword (16-bit signed) | 2 | 2 |
| `A` | Address | 4 | 4 |
| `C` | Character | 1 | varies |
| `X` | Hexadecimal | 1 | varies |
| `P` | Packed decimal | 1 | varies |

Examples:
```
NUMBER   DC    F'123'         Fullword constant
HALF     DC    H'-5'          Halfword constant
ADDR     DC    A(LOOP)        Address constant
MESSAGE  DC    CL10'HELLO'    Character constant, 10 bytes
HEXVAL   DC    X'FF00'        Hex constant
```

### DS (Define Storage) Types

Same types as DC, but reserves uninitialized storage.

```
COUNTER  DS    F              Reserve fullword
BUFFER   DS    CL80           Reserve 80-byte buffer
         DS    0F             Align to fullword boundary
```

## ASSIST I/O Macros

The interpreter supports ASSIST macros for simplified I/O:

### XREAD - Read Input

```
         XREAD buffer,length
```

Reads a line of input into the specified buffer.
- **buffer**: Address of input area
- **length**: Maximum characters to read (default: 80)
- Sets CC=0 on success, CC=1 on EOF

### XPRNT - Print Output

```
         XPRNT buffer,length
```

Prints a line of output.
- **buffer**: Address of output area
- **length**: Number of characters to print (default: 133)
- First byte is carriage control: ' '=single, '0'=double, '1'=page

### XDECI - Decimal Input

```
         XDECI Rn,buffer
```

Converts decimal string to binary in register.
- **Rn**: Target register
- **buffer**: Address of decimal string
- R1 set to address after number
- Sets CC based on value (0=zero, 1=negative, 2=positive, 3=error)

### XDECO - Decimal Output

```
         XDECO Rn,buffer
```

Converts binary register to 12-character decimal string.
- **Rn**: Source register
- **buffer**: Address to store result (12 bytes)

### XDUMP - Memory Dump

```
         XDUMP address,length
```

Displays memory contents in hex and character format.
- **address**: Starting address
- **length**: Number of bytes to dump (default: 64)

### XHEXI - Hexadecimal Input

```
         XHEXI Rn,buffer
```

Converts hex string to binary in register.

### XHEXO - Hexadecimal Output

```
         XHEXO Rn,buffer
```

Converts register to 8-character hex string.

## MVS/z/OS Linkage Macros

These macros provide compatibility with standard MVS/z/OS linkage conventions:

### WTO - Write To Operator

WTO supports two formats:

**Inline Message Format:**
```
         WTO   'message text'
```
Writes a message to the operator console, prefixed with "WTO:".

**Execute Form (MF=E):**
```
         WTO   MF=(E,addr)
```
Uses a pre-built parameter list at the specified address. This allows dynamic message content by modifying the message area before calling WTO.

**Parameter List Format for MF=(E,addr):**
```asm
MSGAREA  DC    H'40'               Length (including 4-byte header)
         DC    H'0'                MCS flags (must be zeros)
         DC    CL36'Message text'  The actual message (EBCDIC)
```

The length field (first halfword) should be the total parameter list length including the 4-byte header.

Example (Inline):
```asm
         WTO   'PROGRAM STARTING'
         WTO   'PROCESSING COMPLETE'
```

Example (Execute Form - for dynamic messages):
```asm
* Build message at runtime
         MVC   MSG+4(10),COUNTER   Insert counter value
         WTO   MF=(E,MSG)
*
MSG      DC    H'24',H'0',CL20'Count: XXXXXXXXXX'
```

### SAVE - Save Registers

```
         SAVE  (r1,r2)
         SAVE  (14,12)        Standard linkage
```

Saves registers r1 through r2 to the save area pointed to by R13 at offset 12.
- Equivalent to: `STM r1,r2,12(R13)`
- Standard linkage convention uses `SAVE (14,12)` to save R14, R15, R0-R12
- Registers wrap around: (14,12) means registers 14, 15, 0, 1, 2, ... 12

Example:
```asm
MYPROG   CSECT
         SAVE  (14,12)        Save caller's registers
         BASR  R12,0          Establish base
         USING *,R12
```

### RETURN - Return to Caller

```
         RETURN (r1,r2)
         RETURN (14,12),RC=0       Return with return code 0
         RETURN (14,12),RC=(15)    Return with current R15 value
```

Restores registers r1 through r2 from the save area, sets return code, and returns to caller.
- Equivalent to: `LM r1,r2,12(R13)` followed by `BR R14`
- **RC=n**: Sets R15 to the specified return code value
- **RC=(15)**: Keeps the current R15 value as the return code
- In the interpreter, RETURN halts program execution

Example:
```asm
         L     R13,SAVEAREA+4    Restore caller's R13
         RETURN (14,12),RC=0     Restore registers, return code 0
```

### ED - Edit Instruction

The ED instruction formats packed decimal data for printing using a pattern.

```
         ED    PATTERN(L),SOURCE
```

**Pattern Characters:**
- First byte = Fill character (usually X'40' = space)
- X'20' = Digit Select - replaced with source digit or fill char
- X'21' = Significance Starter - turns on significance, shows digit
- X'22' = Field Separator - resets significance
- Other bytes = Message characters (kept if significant, else fill)

**Example:**
```asm
         CVD   R2,DW           Convert binary to packed decimal
         MVC   ZN,EDMASK       Load edit mask
         ED    ZN,DW+6         Edit packed decimal to printable
*
DW       DS    D               Doubleword work area
ZN       DS    CL4             Zone decimal result
EDMASK   DC    X'40202120'     Fill=' ', digit, digit, sig+digit
```

**Condition Code:**
- CC=0: Result is zero
- CC=1: Result is negative
- CC=2: Result is positive

### YREGS - Define Register Equates

```
         YREGS
```

Expands to register equates R0-R15 for all 16 general purpose registers.
- Equivalent to defining: `R0 EQU 0`, `R1 EQU 1`, ... `R15 EQU 15`
- Place near the end of your program, before the `END` statement
- Standard IBM macro for convenience

Example:
```asm
MYPROG   CSECT
         USING MYPROG,R12
         LR    R12,R15
         ...
         BR    R14
         YREGS
         END   MYPROG
```

## Register Conventions

| Register | Common Usage |
|----------|--------------|
| R0 | Work register (cannot be base/index) |
| R1 | Parameter passing, work |
| R2-R11 | General purpose |
| R12 | Base register (common) |
| R13 | Save area pointer |
| R14 | Return address |
| R15 | Entry point / return code |

## Condition Codes

| CC | Meaning |
|----|---------|
| 0 | Equal / Zero |
| 1 | Low / Negative / First operand low |
| 2 | High / Positive / First operand high |
| 3 | Overflow / Mixed |

## Interrupt Handling

If a program is interrupted with PA1 or PA2, or if a runtime error occurs, the assembler displays a register dump showing:

- **GPR 0-F**: General Purpose Registers (16 registers in hexadecimal)
- **FPR 0,2,4,6**: Floating Point Registers
- **PSW**: Program Status Word showing condition code, program mask, and address
- **AT**: Current instruction mnemonic, length (ILC), and source line number

Example register dump:
```
GPR 0-3:  00000000 00000005 00000004 00000003
GPR 4-7:  00000002 00000001 00000000 FFFFFFFF
GPR 8-B:  00000000 00000010 000001E4 00000000
GPR C-F:  00000000 0000FF00 00000000 00000000
FPR 0,2,4,6: 0.0000E+00 0.0000E+00 0.0000E+00 0.0000E+00
PSW: 00000000 20000068  24M.......  CC=2 MASK=0 ADDR=000068
AT: BNL LEN=4 LINE=89
```

## Execution Limits

- Maximum iterations: 100,000 (adjusted for macro delays)
- Maximum runtime: 60 seconds (adjusted for macro delays)
- Memory size: 1MB
- Each macro call pauses for 0.10 seconds and extends limits by 15% iterations, 20% time

## ISPF Editor Integration

Use `EDIT` command or `HI ASM` in the ISPF editor for syntax highlighting:

- **Labels**: White
- **Mnemonics**: Yellow
- **Registers**: Cyan/Turquoise
- **Macros**: Red
- **Literals**: Pink
- **Comments**: Blue
- **Default**: Green

## File Organization

Programs are stored in:
- `assembler/community/` - Shared programs (read-only, prefixed with `_`)
- `assembler/username/` - Your personal programs

File extension: `.asm`
Listing files: `.list`

**Note**: You cannot save programs with a `_` prefix in your private area (reserved for community files).

## Tips

1. Always establish addressability with USING
2. Use meaningful labels (max 8 characters for traditional compatibility)
3. Align data appropriately (DS 0F for fullwords)
4. Use extended branch mnemonics for clarity
5. Comment your code generously with asterisk (*) lines
6. Use CHECK command to validate before RUN
7. Use XDUMP to debug memory contents
8. First byte of XPRNT output is carriage control (use space for single spacing)

## Error Messages

| Message | Meaning |
|---------|---------|
| ?NO PROGRAM | No source loaded |
| ASSEMBLY ERRORS | Syntax or semantic errors found |
| RUNTIME ERROR | Error during execution |
| ?BREAK - PROGRAM INTERRUPTED | Program interrupted by PA1/PA2 |
| MAXIMUM ITERATIONS EXCEEDED | Possible infinite loop |
| UNDEFINED SYMBOL | Symbol not defined |
| SUBSCRIPT OUT OF RANGE | Array index invalid |
| DIVIDE BY ZERO | Division operation error |

## References

- [IBM System/360 Principles of Operation (A22-6821-0)](https://bitsavers.trailing-edge.com/pdf/ibm/360/princOps/A22-6821-0_360PrincOps.pdf) - Complete instruction set reference
- [ASSIST Introductory Assembler User's Manual](https://faculty.cs.niu.edu/~byrnes/csci360/ho/asusergd.shtml#part1s4) - Original ASSIST documentation by John R. Mashey, Pennsylvania State University
- IBM High Level Assembler Language Reference

---

*Copyright 2025 by moshix - TIMESHARING ASSEMBLER V1.0.1*
