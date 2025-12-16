# 🖥️ 3270BBS BASIC Interpreter Manual

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
| `FILES` | List your saved programs |

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
| `ATAN(x)` | Arctangent | `ATAN(1)` → `0.785...` |
| `LOG(x)` | Natural logarithm | `LOG(2.718)` → `1` |
| `EXP(x)` | e raised to power | `EXP(1)` → `2.718...` |
| `RND(x)` | Random nubmer 0-1 | `RND(1)` → `0.xxxxx` |

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
COMMANDS:  RUN LIST NEW SAVE LOAD FILES RENUM DELETE HELP VARS BYE

STATEMENTS: PRINT INPUT LET IF/THEN/ELSE GOTO GOSUB/RETURN
            FOR/NEXT WHILE/WEND DIM REM END

MATH:      ABS INT SGN SQR SIN COS TAN ATAN LOG EXP RND

STRING:    LEN LEFT$ RIGHT$ MID$ CHR$ ASC STR$ VAL SPACE$ UCASE$ LCASE$

BBS DATA:  $ChatMessage(n) $Mail(n) $UserList(n) $UserInfo$ $Conference(n)
```

---

*3270BBS BASIC Interpreter v1.0 - Happy coding!* 🚀
