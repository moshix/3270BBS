# 🖥️ BASIC/3270BBS Manual

**Copyright © 2025-2026 by moshix. All rights reserved.**

Welcome to the 3270BBS BASIC Interpreter! This manual will guide you through writing and running BASIC programs on teh 3270BBS system.

---

## 🟦 Getting Started

### Entering BASIC
From the Extended Menu, press **B** to enter the BASIC interpreter. You'll see:

```
BASIC V1.0
TYPE HELP FOR COMMANDS, BYE TO EXIT
READY
>
```

### Basic Concepts
- Programs are made of **numbered lines** (e.g., `10`, `20`, `30`)
- Lines execute in numerical order
- Type a line number + code to add it to yuor program
- Type `RUN` to execute your program
- Type `BYE` to exit BASIC

---

## 🟩 Program Commands

| Command | Description |
|---------|-------------|
| `RUN` | Execute the program |
| `LIST` | Show all program lines |
| `LIST 10-50` | Show lines 10 through 50 |
| `NEW` | Clear the program from memory |
| `RENUM` | Renumber lines (10, 20, 30...) |
| `DELETE 10-50` | Delete lines 10 through 50 |

### File Commands

| Command | Description |
|---------|-------------|
| `SAVE "name"` | Save program to file |
| `LOAD "name"` | Load program from file |
| `EDIT "name"` | Edit file in full-screen editor |
| `EDIT` | Edit program in memory (no filename) |
| `ERASE "name"` | Delete program file |
| `FILES` | List your files and community programs |

**EDIT without a filename:** Opens the program currently in memory in the full-screen editor. This is useful when you've loaded a community program and want to modify it. When you save, it creates `UNTITLED.bas` in your directory.

### Community Programs

The system includes a collection of shared example programs that all users can access. These programs are stored in the `basic/community/` directory and have filenames starting with underscore (`_`).

**Using community programs:**
- `FILES` - Shows both your files and available community programs
- `LOAD "_example.bas"` - Load a community program
- Community programs are **read-only** - you cannot EDIT or ERASE them

**User file restrictions:**
- User filenames cannot contain underscores (`_`)
- This prevents confusion between user files and community files

### Other Commands

| Command | Description |
|---------|-------------|
| `HELP` | Show help information |
| `VARS` | List all variables |
| `CLEAR` | Clear the screen |
| `BYE` / `EXIT` / `QUIT` | Exit BASIC |

---

## 🟨 Statements

### PRINT - Display Output
```basic
10 PRINT "Hello, World!"
20 PRINT "Value is: "; X
30 PRINT A; " + "; B; " = "; A+B
```

### LET - Assign Variables
```basic
10 LET X = 10
20 LET NAME$ = "John"
30 X = X + 1          ' LET is optional
```
- Variables ending in `$` are strings
- Variables wihtout `$` are numbers

### INPUT - Get User Input
```basic
10 INPUT "Enter your name: ", NAME$
20 INPUT "Enter a number: ", N
30 PRINT "Hello, "; NAME$; "! Your number is "; N
```

### IF/THEN/ELSE - Conditional Execution
```basic
10 INPUT "Enter age: ", AGE
20 IF AGE >= 18 THEN PRINT "Adult" ELSE PRINT "Minor"
```
Comparision operators: `=`, `<>`, `<`, `>`, `<=`, `>=`

### GOTO - Jump to Line
```basic
10 PRINT "This loops forever!"
20 GOTO 10
```

### GOSUB/RETURN - Subroutines
```basic
10 PRINT "Main program"
20 GOSUB 100
30 PRINT "Back in main"
40 END
100 REM Subroutine
110 PRINT "In subroutine"
120 RETURN
```

### FOR/NEXT - Counting Loops
```basic
10 FOR I = 1 TO 10
20 PRINT I
30 NEXT I

' With STEP:
10 FOR I = 10 TO 0 STEP -1
20 PRINT I
30 NEXT I
```

### WHILE/WEND - Conditional Loops
```basic
10 X = 1
20 WHILE X <= 10
30 PRINT X
40 X = X + 1
50 WEND
```

### DIM - Declare Arrays
```basic
10 DIM SCORES(10)        ' 1D array
20 DIM GRID(5, 5)        ' 2D array
30 DIM NAMES$(20)        ' String array
40 SCORES(1) = 95
50 NAMES$(0) = "Alice"
```

### REM - Comments
```basic
10 REM This is a comment
20 ' This is also a comment
```

### END / STOP - End Program
```basic
100 END    ' Terminates program execution
```

### CLS - Clear Screen
```basic
10 CLS    ' Clears the screen
```

---

## 🟧 Math Functions

| Function | Description | Example |
|----------|-------------|---------|
| `ABS(x)` | Absolute value | `ABS(-5)` → `5` |
| `INT(x)` | Integer part (floor) | `INT(3.7)` → `3` |
| `SGN(x)` | Sign (-1, 0, or 1) | `SGN(-5)` → `-1` |
| `SQR(x)` | Square root | `SQR(16)` → `4` |
| `SIN(x)` | Sine (radians) | `SIN(3.14159/2)` → `1` |
| `COS(x)` | Cosine (radians) | `COS(0)` → `1` |
| `TAN(x)` | Tangent (radians) | `TAN(0)` → `0` |
| `ATAN(x)` | Arctangent (radians) | `ATAN(1)` → `0.785...` |
| `ASIN(x)` | Arcsine (radians), x must be -1 to 1 | `ASIN(1)` → `1.5707...` |
| `ACOS(x)` | Arccosine (radians), x must be -1 to 1 | `ACOS(0)` → `1.5707...` |
| `LOG(x)` | Natural logarithm | `LOG(2.718)` → `1` |
| `EXP(x)` | e raised to power | `EXP(1)` → `2.718...` |
| `RND(x)` | Random nubmer 0-1 | `RND(1)` → `0.xxxxx` |

### Trigonometric Conversion Functions

| Function | Description | Example |
|----------|-------------|---------|
| `PI()` | Returns the value of π | `PI()` → `3.14159...` |
| `RADIANS(deg)` | Convert degrees to radians | `RADIANS(180)` → `3.14159...` |
| `DEGREES(rad)` | Convert radians to degrees | `DEGREES(PI())` → `180` |

Example:
```basic
10 REM Trigonometry with degree/radian conversion
20 ANGLE = 45
30 RAD = RADIANS(ANGLE)
40 PRINT "Sin(45 degrees) = "; SIN(RAD)
50 PRINT "Asin result in degrees: "; DEGREES(ASIN(0.707))
60 END
```

---

## 🟪 String Functions

| Function | Description | Example |
|----------|-------------|---------|
| `LEN(s$)` | String length | `LEN("Hello")` → `5` |
| `LEFT$(s$,n)` | Left n characters | `LEFT$("Hello",2)` → `"He"` |
| `RIGHT$(s$,n)` | Right n characters | `RIGHT$("Hello",2)` → `"lo"` |
| `MID$(s$,p,n)` | Substring | `MID$("Hello",2,3)` → `"ell"` |
| `CHR$(n)` | Character from ASCII | `CHR$(65)` → `"A"` |
| `ASC(s$)` | ASCII from character | `ASC("A")` → `65` |
| `STR$(n)` | Number to string | `STR$(42)` → `"42"` |
| `VAL(s$)` | String to number | `VAL("42")` → `42` |
| `SPACE$(n)` | n spaces | `SPACE$(5)` → `"     "` |
| `UCASE$(s$)` | Uppercase | `UCASE$("hi")` → `"HI"` |
| `LCASE$(s$)` | Lowercase | `LCASE$("HI")` → `"hi"` |

---

## 🕐 Time Functions

| Function | Description | Example |
|----------|-------------|---------|
| `TIME$()` | Current time (HH:MM:SS) | `TIME$()` → `"14:30:45"` |
| `DATE$()` | Current date (YYYY-MM-DD) | `DATE$()` → `"2025-12-16"` |
| `TIMER()` | Seconds since midnight (with millisecond precision) | `TIMER()` → `52245.123` |
| `HOUR()` | Current hour (0-23) | `HOUR()` → `14` |
| `MINUTE()` | Current minute (0-59) | `MINUTE()` → `30` |
| `SECOND()` | Current second (0-59) | `SECOND()` → `45` |
| `YEAR()` | Current year | `YEAR()` → `2025` |
| `MONTH()` | Current month (1-12) | `MONTH()` → `12` |
| `DAY()` | Day of month (1-31) | `DAY()` → `16` |
| `SLEEP(n)` | Pause execution for n seconds | `SLEEP(1.5)` pauses 1.5 sec |

### SLEEP Function

The `SLEEP(n)` function pauses program execution for the specified number of seconds.

- **Range:** 0.1 to 255 seconds
- **Fractions:** Supports decimal values (e.g., `SLEEP(0.5)` for half a second)
- **CPU-friendly:** Does not consume CPU cycles during the wait
- **Returns:** 0 (can be ignored)

Example:
```basic
10 REM Countdown Timer
20 FOR I = 10 TO 0 STEP -1
30 PRINT I
40 X = SLEEP(1)
50 NEXT I
60 PRINT "BLAST OFF!"
70 END
```

---

## 🟥 3270BBS Data Access

Access live BBS data direcly from BASIC!

### $ChatMessage(n) - Chat Messages
```basic
10 PRINT $ChatMessage(0)    ' Most recent
20 PRINT $ChatMessage(-1)   ' Second most recent
```
Returns: `"username: message"`

### $Mail(n) - Your Mail Messages
```basic
10 PRINT $Mail(0)           ' Most recent mail
20 PRINT $Mail(-1)          ' Second most recent
```
Returns: `"From: sender - subject"`

### $UserList(n) - Online Users
```basic
10 PRINT $UserList(0)       ' First online user
20 PRINT $UserList(1)       ' Second online user
```
Returns: username string

### $UserInfo$ - Your Username
```basic
10 PRINT "You are: "; $UserInfo$
```
Returns: your username

### $Conference(n) - Conference Posts
```basic
10 PRINT $Conference(0)     ' Most recent post
20 PRINT $Conference(-1)    ' Second most recent
```
Returns: `"title by author"`

---

## 🟫 Example Programs

### Example 1: Sine Wave Graph
This program draws a sine curve usign asterisks:

```basic
10 REM Sine Wave Graph
20 FOR I = 0 TO 20
30 X = I * 0.3
40 Y = SIN(X)
50 S = INT((Y + 1) * 20)
60 PRINT SPACE$(S); "*"
70 NEXT I
80 END
```

Output:
```
                    *
                         *
                              *
                                *
                                  *
                                *
                              *
                         *
                    *
               *
          *
     *
  *
 *
  *
     *
          *
               *
                    *
                         *
                              *
```

### Example 2: Display Last 3 Chat Messages
This program retrieves and displays teh three most recent chat messages from the BBS:

```basic
10 REM Display Last 3 Chat Messages
20 PRINT "=============================="
30 PRINT "   RECENT CHAT MESSAGES"
40 PRINT "=============================="
50 PRINT
60 FOR I = 0 TO -2 STEP -1
70 MSG$ = $ChatMessage(I)
80 IF MSG$ <> "" THEN PRINT MSG$
90 NEXT I
100 PRINT
110 PRINT "=============================="
120 END
```

### Example 3: Who's Online
```basic
10 REM List Online Users
20 PRINT "Online Users:"
30 PRINT "-------------"
40 FOR I = 0 TO 9
50 U$ = $UserList(I)
60 IF U$ <> "" THEN PRINT I+1; ". "; U$
70 NEXT I
80 END
```

### Example 4: Personal Dashboard
```basic
10 REM Personal Dashboard
20 PRINT "==============================="
30 PRINT "  WELCOME, "; $UserInfo$
40 PRINT "==============================="
50 PRINT
60 PRINT "Your latest mail:"
70 PRINT "  "; $Mail(0)
80 PRINT
90 PRINT "Latest chat:"
100 PRINT "  "; $ChatMessage(0)
110 PRINT
120 PRINT "Latest conference post:"
130 PRINT "  "; $Conference(0)
140 END
```

### Example 5: Digital Clock (Time Functions)
This program displays the current date and time using all time functions:

```basic
10 REM Digital Clock Display
20 PRINT "================================"
30 PRINT "    CURRENT DATE AND TIME"
40 PRINT "================================"
50 PRINT
60 PRINT "  Date: "; DATE$()
70 PRINT "  Time: "; TIME$()
80 PRINT
90 PRINT "  Year:   "; YEAR()
100 PRINT "  Month:  "; MONTH()
110 PRINT "  Day:    "; DAY()
120 PRINT "  Hour:   "; HOUR()
130 PRINT "  Minute: "; MINUTE()
140 PRINT "  Second: "; SECOND()
150 PRINT
160 PRINT "  Seconds since midnight: "; TIMER()
170 END
```

### Example 6: Orbital Mechanics Plot (24x80 terminal)
This program plots an elliptical orbit around a central body using ASCII graphics. Fits within the 24x80 Model 2 terminal display:

```basic
10 REM Orbital Mechanics Plotter
20 REM Fits 24x80 Model 2 Terminal
30 DIM SCR$(18)
40 W = 70: H = 16
50 CX = 35: CY = 8
60 A = 28: B = 7
70 E = 0.6
80 REM Initialize screen buffer
90 FOR Y = 0 TO H-1
100 SCR$(Y) = SPACE$(W)
110 NEXT Y
120 REM Plot elliptical orbit path
130 FOR T = 0 TO 62
140 AN = T * 0.1
150 R = (A * (1 - E*E)) / (1 + E * COS(AN))
160 PX = INT(CX + R * COS(AN) * 0.5)
170 PY = INT(CY + R * SIN(AN) * 0.25)
180 IF PX >= 0 AND PX < W AND PY >= 0 AND PY < H THEN GOSUB 400
190 NEXT T
200 REM Place Sun at focus
210 PX = CX - INT(A * E * 0.5): PY = CY
220 CH$ = "@": GOSUB 400
230 REM Place satellite
240 AN = 0.8: R = (A * (1 - E*E)) / (1 + E * COS(AN))
250 PX = INT(CX + R * COS(AN) * 0.5)
260 PY = INT(CY + R * SIN(AN) * 0.25)
270 CH$ = "*": GOSUB 400
280 REM Print the display
290 PRINT "ORBITAL MECHANICS - ELLIPTICAL ORBIT"
300 PRINT "Eccentricity: "; E; "  Semi-major: "; A
310 FOR Y = 0 TO H-1
320 PRINT SCR$(Y)
330 NEXT Y
340 PRINT "@ = Sun (focus)  * = Satellite  . = Orbit path"
350 END
400 REM Subroutine: Plot character at PX,PY
410 IF CH$ = "" THEN CH$ = "."
420 L$ = SCR$(PY)
430 IF PX = 0 THEN SCR$(PY) = CH$ + MID$(L$, 2)
440 IF PX > 0 AND PX < W-1 THEN SCR$(PY) = LEFT$(L$, PX) + CH$ + MID$(L$, PX+2)
450 IF PX = W-1 THEN SCR$(PY) = LEFT$(L$, PX) + CH$
460 CH$ = "."
470 RETURN
```

Output:
```
ORBITAL MECHANICS - ELLIPTICAL ORBIT
Eccentricity: 0.6  Semi-major: 28
                         ...........
                    ...              ....
                 ..                      ...
               .                            ..
             .                                .
            .                                  .
           .         @                     *    .
            .                                  .
             .                                .
               .                            ..
                 ..                      ...
                    ...              ....
                         ...........
@ = Sun (focus)  * = Satellite  . = Orbit path
```

---

## ⌨️ Keyboard Controls

| Key | Action |
|-----|--------|
| **Enter** | Execute comand / Submit input |
| **Clear** | Clear screen, show new READY prompt |
| **PA1** / **PA2** | Break/stop running program |

---

## 💡 Tips

1. **Line Numbers**: Use increments of 10 (10, 20, 30...) so you can insert lines latter
2. **RENUM**: If you run out of space beetween lines, use `RENUM` to renumber
3. **Save Often**: Use `SAVE "myprogram"` to save your work
4. **Debug**: Use `PRINT` statments to check variable values
5. **Variables**: String variables must end wiht `$` (e.g., `NAME$`)

---

## ❓ Quick Reference Card

```
COMMANDS:  RUN LIST NEW SAVE LOAD EDIT ERASE FILES RENUM DELETE HELP VARS BYE

STATEMENTS: PRINT INPUT LET IF/THEN/ELSE GOTO GOSUB/RETURN
            FOR/NEXT WHILE/WEND DIM REM END CLS

MATH:      ABS INT SGN SQR SIN COS TAN ATAN ASIN ACOS LOG EXP RND
           PI() RADIANS(deg) DEGREES(rad)

STRING:    LEN LEFT$ RIGHT$ MID$ CHR$ ASC STR$ VAL SPACE$ UCASE$ LCASE$

TIME:      TIME$() DATE$() TIMER() HOUR() MINUTE() SECOND()
           YEAR() MONTH() DAY() SLEEP(n)

BBS DATA:  $ChatMessage(n) $Mail(n) $UserList(n) $UserInfo$ $Conference(n)
```

---

*3270BBS BASIC Interpreter v1.6 - Happy coding!* 🚀
