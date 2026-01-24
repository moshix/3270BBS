# 🖥️ TIMESHARING BASIC/3270BBS Manual

**Copyright © 2025-2026 by moshix. All rights reserved.**

Welcome to the BASIC/3270BBS interpreter and compiler! This manual will guide you through writing and running BASIC programs on the 3270BBS system.

As of version 2.3.0 of BASIC/3270BBS, programs can be traditional line numbered (e.g. 100 PRINT "Hello, world") or without line numbers and use labels instead, in which case every program must start with a START: label. 
  
---

##  Getting Started

### Entering BASIC
From the Extended Menu, press **B** to enter BASIC/3270BBS . You'll see:

```
      TIMESHARING BASIC/3270BBS V2.8.0
TYPE HELP FOR COMMANDS, BYE TO EXIT
READY
>
```

### Command Line BASIC
- Programs are made of **numbered lines** (e.g., `10`, `20`, `30`)
- Lines execute in numerical order
- Type a line number + code to add it to yuor program
- Type `RUN` to execute your program
- Type `BYE` to exit BASIC

---

##  Program Commands

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
| `BROWSE` | Open file browser to select and edit files |
| `ERASE "name"` | Delete program file (.bas or .list) |
| `FILES` | List your files and community programs |
| `FILES pattern` | List files matching wildcard pattern (* and ?) |
| `FILES /W` | Wide format: two columns, no timestamps |
| `FILES /U user` | List shared files from another user |
| `FILES /C` | List only community files |
| `FLIST` | List only your files (no community files) |
| `FLIST pattern` | List your files matching wildcard pattern |
| `LOAD "user/%file"` | Load a shared file from another user |

**Wildcard Patterns:** FILES and FLIST support MS-DOS style wildcards:
- `*` matches zero or more characters
- `?` matches exactly one character

Examples:
```
FILES *.bas          All .bas files
FILES test*          Files starting with "test"
FILES *game*         Files containing "game"
FILES ?.bas          Single-character .bas files (a.bas, x.bas)
FILES test?.bas      test0.bas, test1.bas, testa.bas, etc.
FLIST *.list         Your .list files only
FILES *.bas /W       Wide format with wildcard filter
```

**EDIT without a filename:** Opens the program currently in memory in the full-screen editor. This is useful when you've loaded a community program and want to modify it. When you save, it creates `UNTITLED.bas` in your directory.

**BROWSE:** Opens an interactive file browser that displays all your files and community programs. You can:
- Navigate with F7 (page up) and F8 (page down)
- Type U/C to switch between User and Community files
- Type N/D to sort by Name or Date
- Type any character on a file line to select and open it in the editor
- Type D on a file line to delete it (with confirmation)
- Press F3 to return to BASIC without selecting a file

### Syntax Checking Commands

| Command | Description |
|---------|-------------|
| `CHECK` | Syntax check program in memory, generate listing file |
| `VIEW name.list` | View the listing file without clearing program |
| `EMAIL name.list` | Email the listing as a PDF to your email address |

#### CHECK Command

The `CHECK` command performs a syntax analysis of the program currently in memory without executing it. It generates a z/OS COBOL-style listing file in your directory named after the program (e.g., `myprogram.list`). If the program hasn't been saved yet, it uses `UNNAMED.list`.

**What CHECK does:**
- Validates syntax of each line
- Identifies syntax errors without running the program
- Detects potential problems and issues warnings
- Builds a variable cross-reference (where each variable is defined and used)
- Creates a data dictionary (all variables and arrays)
- Calculates program statistics

**Warnings Detected:**
- **Loop without SLEEP:** FOR/NEXT, WHILE/WEND, or backward GOTO jumps without a `SLEEP` statement may trigger the loop detector or execution time termination
- **Overly complex lines:** Lines with 3+ statements separated by colons are flagged as complex
- **Very long lines:** Lines exceeding 120 characters are flagged for simplification
- **Insufficient comments:** Programs with less than 1 REM statement per 10 lines of code receive a program-level warning

**Example usage:**
```basic
10 REM MY PROGRAM
20 LET X = 10
30 PRINT "Value is: "; X
40 END
CHECK
```

Output:
```
CHECKING PROGRAM...
NO ERRORS OR WARNINGS FOUND
LISTING SAVED TO myprogram.list
USE VIEW myprogram.list TO SEE FULL LISTING
```

#### VIEW Command

The `VIEW` command opens `.list` files in the editor for viewing. Unlike `LOAD` or `EDIT`, it does **not** clear the program from memory.

**Restrictions:**
- Only works with `.list` extension files
- Opens in read-only mode
- Program in memory is preserved

**Example:**
```
VIEW myprogram.list
```

#### EMAIL Command

The `EMAIL` command sends a `.list` file as a PDF attachment to your registered email address. It uses the same email controls and daily limits as other BBS email features.

**Requirements:**
- Must have an email address set in your profile
- Daily email limit applies (admin bypass available)
- SendGrid must be configured on the server

**The PDF includes:**
- Professional header with BBS name and date
- Full listing content in fixed-width Courier font
- Syntax highlighting for errors (red) and warnings (orange)
- Section headers highlighted for cross-reference, data dictionary etc.

**Example:**
```
EMAIL myprogram.list
```

Output:
```
GENERATING PDF...
SENDING EMAIL TO user@example.com...
EMAIL SENT SUCCESSFULLY
LISTING myprogram.list EMAILED TO user@example.com
```

**Error Messages:**
- `?NO EMAIL ADDRESS IN YOUR PROFILE` - Set email in profile settings
- `?DAILY EMAIL LIMIT REACHED` - Wait until tomorrow
- `?FILE NOT FOUND` - Run CHECK first to generate the listing

#### Listing File Format

The `.list` file is formatted like a mainframe z/OS COBOL compiler listing:

```
================================================================================
                    3270BBS TIMESHARING BASIC COMPILER LISTING
================================================================================
 DATE: 25 DEC 2025 14:30:45  USER: MOSHIX
 SOURCE: (IN MEMORY)
================================================================================

                              S O U R C E   L I S T I N G
--------------------------------------------------------------------------------
  LINE  STMT  SOURCE TEXT
--------------------------------------------------------------------------------
    10     1  REM MY PROGRAM
    20     2  LET X = 10
    30     3  PRINT "Value is: "; X

================================================================================
                       E R R O R   A N D   W A R N I N G   S U M M A R Y
================================================================================

  ERRORS:
  LINE   MESSAGE
  ----   -------
  (NO ERRORS)

  WARNINGS:
  LINE   MESSAGE
  ----   -------
  (NO WARNINGS)

 TOTAL ERRORS: 0    TOTAL WARNINGS: 0

================================================================================
                       V A R I A B L E   C R O S S - R E F E R E N C E
================================================================================
  VARIABLE      TYPE      DEFINED       REFERENCED
--------------------------------------------------------------------------------
  X             NUMERIC   20            30

================================================================================
                            D A T A   D I C T I O N A R Y
================================================================================
  NAME          TYPE        DIM SIZE    DESCRIPTION
--------------------------------------------------------------------------------
  X             NUMERIC     -           Simple variable

================================================================================
                           P R O G R A M   S T A T I S T I C S
================================================================================
  SOURCE LINES:              3
  STATEMENTS:                3
  TOTAL SIZE:               54 bytes
  ARRAYS DEFINED:            0
  ARRAY MEMORY:              0 elements allocated

================================================================================
                            E N D   O F   L I S T I N G
================================================================================
```

### Community Programs

The system includes a collection of shared example programs that all users can access. These programs are stored in the `basic/community/` directory and have filenames starting with underscore (`_`).

**Using community programs:**
- `FILES` - Shows both your files and available community programs
- `FILES /W` - Wide format with two columns (no timestamps, saves screen space)
- `LOAD "_example.bas"` - Load a community program
- Community programs are **read-only** - you cannot EDIT or ERASE them

### Shared User Files

Users can share programs with each other by naming files with a `%` prefix. These files are visible to other users but remain read-only.

**Creating shared files:**
- Save your program with a `%` prefix: `SAVE "%myprogram.bas"`
- Only you can modify, save, or erase your own `%` files

**Accessing other users' shared files:**
- `FILES /U moshix` - List shared files from user moshix
- `LOAD "moshix/%example.bas"` - Load a shared file from moshix
- Shared files are **read-only** - you can load them but not modify the original

**File naming conventions:**
- `_filename` - Community files (in basic/community/, read-only)
- `%filename` - Shared user files (visible to others, owner can modify)
- `filename` - Private user files (only visible to you)

**User file restrictions:**
- User filenames cannot contain underscores (`_`)
- This prevents confusion between user files and community files

### Other Commands

| Command | Description |
|---------|-------------|
| `HELP` | Show help information |
| `VARS` | List all variables |
| `CLEAR` | Clear teh screen |
| `BYE` / `EXIT` / `QUIT` | Exit BASIC |

---

##  Statements

### PRINT - Display Output
```basic
10 PRINT "Hello, World!"
20 PRINT "Value is: "; X
30 PRINT A; " + "; B; " = "; A+B
```

#### COLOR Attribute
You can add color to your output using the optional `COLOR` attribute at the end of a PRINT statement:

```basic
PRINT expression [; expression ...] [COLOR colorname [modifier]]
```

**Colors available:**
| Color | Description |
|-------|-------------|
| `WHITE` | White text |
| `RED` | Red text |
| `YELLOW` | Yellow text |
| `PINK` | Pink/magenta text |
| `GREEN` | Green text |
| `BLUE` | Blue text |
| `TURQUOISE` | Turquoise/cyan text (default) |

**Modifiers (optional):**
| Modifier | Description |
|----------|-------------|
| `BLINK` | Blinking text |
| `REVERSEVIDEO` | Inverted colors (text becomes background) |

**Examples (label-based):**
```basic
START:
    PRINT "ALERT!" COLOR RED
    PRINT "Success: "; RESULT$ COLOR GREEN
    PRINT "WARNING!" COLOR YELLOW BLINK
    PRINT "Selected item" COLOR WHITE REVERSEVIDEO
    PRINT "Status: "; S; " - "; MSG$ COLOR PINK
    END
```

**Notes:**
- The `COLOR` attribute must appear at the end of the PRINT statement
- Without `COLOR`, text defaults to turquoise (standard 3270 terminal color)
- Colors and modifiers are rendered using 3270 terminal extended attributes
- Not all terminal emulators support all colors or highlighting modes

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

BASIC supports both single-line and multi-line IF statements.

#### Single-Line IF
```basic
10 INPUT "Enter age: ", AGE
20 IF AGE >= 18 THEN PRINT "Adult" ELSE PRINT "Minor"
```

#### Multi-Line Block IF
For more complex logic, use block IF with ELSEIF and END IF:
```basic
10 INPUT "Enter score: ", SCORE
20 IF SCORE >= 90 THEN
30   PRINT "Grade: A"
40 ELSEIF SCORE >= 80 THEN
50   PRINT "Grade: B"
60 ELSEIF SCORE >= 70 THEN
70   PRINT "Grade: C"
80 ELSE
90   PRINT "Grade: F"
100 END IF
110 PRINT "Done!"
```

**Block IF Rules:**
- `IF condition THEN` on its own line starts a block
- `ELSEIF condition THEN` provides additional conditions (optional)
- `ELSE` on its own line handles the fallback case (optional)
- `END IF` (or `ENDIF`) closes the block - **required**
- Blocks can be nested

**Example: Nested IF Blocks**
```basic
10 INPUT "Enter age: ", AGE
20 IF AGE >= 18 THEN
30   IF AGE >= 65 THEN
40     PRINT "Senior adult"
50   ELSE
60     PRINT "Adult"
70   END IF
80 ELSE
90   PRINT "Minor"
100 END IF
```

Comparison operators: `=`, `<>`, `<`, `>`, `<=`, `>=`

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

### ON...GOTO / ON...GOSUB - Computed Jumps
The ON statement provides computed branching based on the value of an expression. The expression is evaluated, and program flow jumps to the corresponding line number in the list (1-based index).

```basic
ON expression GOTO line1, line2, line3, ...
ON expression GOSUB line1, line2, line3, ...
```

**Examples:**
```basic
10 REM Menu selection example
20 INPUT "Enter choice (1-3): ", CHOICE
30 ON CHOICE GOTO 100, 200, 300
40 PRINT "Invalid choice"
50 GOTO 20
100 PRINT "You chose option 1": GOTO 400
200 PRINT "You chose option 2": GOTO 400
300 PRINT "You chose option 3"
400 END
```

```basic
10 REM Device handling with subroutines
20 FOR DEVICE = 1 TO 3
30   ON DEVICE GOSUB 100, 200, 300
40 NEXT DEVICE
50 END
100 PRINT "Handling device 1": RETURN
200 PRINT "Handling device 2": RETURN
300 PRINT "Handling device 3": RETURN
```

**Behavior:**
- If the expression evaluates to a value less than 1 or greater than the number of line numbers, execution continues to the next line (no jump occurs)
- ON...GOTO jumps to the target line
- ON...GOSUB calls the target as a subroutine (use RETURN to come back)

---

## 🏷️ Label-Based Programs (No Line Numbers)

As an alternative to traditional line-numbered BASIC programs, you can write programs using **labels** instead of line numbers. This provides a more modern, readable coding style while remaining fully compatible with all BASIC features.

### Detection Rules
The interpreter automatically detects label-mode based on the first non-empty, non-comment line:
- If the first line starts with a **number**, the program uses line numbers
- If the first line starts with anything else, the program uses labels

### Label Syntax
Labels are identifiers followed by a colon at the start of a line:
```basic
LabelName:
```

**Rules:**
- Labels are **case-insensitive** (`Start:` = `START:` = `start:`)
- Labels must start with a letter or underscore
- Labels can contain letters, digits, and underscores
- Every label-mode program **must** have a `START:` label (execution begins there)
- Labels must be unique within a program

### Example: Simple Label-Based Program
```basic
START:
    PRINT "Enter a number (0 to quit):"
    INPUT N
    IF N = 0 THEN GOTO Done
    PRINT "Square is:"; N * N
    GOTO Start

Done:
    PRINT "Goodbye!"
    END
```

### GOTO and GOSUB with Labels
In label-mode programs, use label names instead of line numbers:
```basic
GOTO Start
GOSUB Calculate
```

### ON...GOTO and ON...GOSUB with Labels
Computed jumps work with labels too:
```basic
START:
    PRINT "Menu: 1=Add 2=Sub 3=Quit"
    INPUT Choice
    ON Choice GOTO Add, Sub, Quit
    PRINT "Invalid choice"
    GOTO Start

Add:
    INPUT "A, B: ", A, B
    PRINT "Sum:"; A + B
    GOTO Start

Sub:
    INPUT "A, B: ", A, B
    PRINT "Difference:"; A - B
    GOTO Start

Quit:
    PRINT "Goodbye!"
    END
```

**Note:** You cannot mix line numbers and labels in the same ON...GOTO/GOSUB statement.

### Important Differences from Line-Numbered Programs
| Feature | Line Numbers | Labels |
|---------|--------------|--------|
| Entry point | First line number | `START:` label |
| Line format | `10 PRINT "Hello"` | `PRINT "Hello"` |
| Jump target | `GOTO 100` | `GOTO Done` |
| Listing format | Shows line numbers | Shows line index |

### When to Use Labels
- **New programs** - More readable, easier to maintain
- **Structured code** - Natural fit for subroutines and blocks
- **Modern style** - Familiar to programmers from other languages

### Compatibility Notes
- All BASIC features work identically in both modes
- The `CHECK` command validates label programs and shows "INDX" instead of "LINE"
- `RENUM` command is not applicable to label-based programs

---

### FOR/NEXT - Counting Loops
```basic
START:
    FOR I = 1 TO 10
        PRINT I
    NEXT I
    END
```

With STEP (label-based):
```basic
START:
    FOR I = 10 TO 0 STEP -1
        PRINT I
    NEXT I
    END
```

### WHILE/WEND - Conditional Loops
```basic
START:
    X = 1
    WHILE X <= 10
        PRINT X
        X = X + 1
    WEND
    END
```

### SELECT CASE - Multi-way Branch
The SELECT CASE statement provides a cleaner alternative to multiple IF/ELSEIF chains when testing a single value against multiple options.

```basic
10 INPUT "Enter a number (1-5): ", N
20 SELECT CASE N
30     CASE 1
40         PRINT "One"
50     CASE 2, 3
60         PRINT "Two or Three"
70     CASE 4, 5
80         PRINT "Four or Five"
90     CASE ELSE
100        PRINT "Out of range"
110 END SELECT
120 END
```

**Key features:**
- The test expression is evaluated once at SELECT CASE
- Each CASE can have multiple comma-separated values to match
- Only the first matching CASE block executes (no fall-through)
- CASE ELSE is optional and executes if no other CASE matches
- SELECT CASE blocks can be nested

**String matching example (label-based):**
```basic
START:
    INPUT "Enter day: ", D$
    SELECT CASE D$
        CASE "MON", "TUE", "WED", "THU", "FRI"
            PRINT "Weekday"
        CASE "SAT", "SUN"
            PRINT "Weekend"
        CASE ELSE
            PRINT "Invalid day"
    END SELECT
    END
```

### DIM - Declare Arrays
```basic
START:
    DIM SCORES(10)        ' 1D array
    DIM GRID(5, 5)        ' 2D array
    DIM NAMES$(20)        ' String array
    SCORES(1) = 95
    NAMES$(0) = "Alice"
    END
```

### Associative Arrays (Dictionaries)

Associative arrays use string keys instead of nurmeic indices. Declare them with curly braces `{}`:

```basic
START:
    DIM PHONEBOOK${}         ' String associative array
    DIM SCORES{}             ' Numeric associative array
    PHONEBOOK${"Alice"} = "555-1234"
    PHONEBOOK${"Bob"} = "555-5678"
    SCORES{"Alice"} = 95
    SCORES{"Bob"} = 87
    PRINT "Alice's phone: "; PHONEBOOK${"Alice"}
    PRINT "Bob's score: "; SCORES{"Bob"}
    END
```

Keys can be variables or expressions:
```basic
START:
    DIM DATA{}
    INPUT "Enter name: ", N$
    INPUT "Enter value: ", V
    DATA{N$} = V
    PRINT N$; " = "; DATA{N$}
    END
```

### DEF FN - User-Defined Functions
The DEF FN statement allows you to define your own single-expression functions. These are useful for calculations that are used repeatedly throughout your program.

```basic
DEF FNname(parameter) = expression
```

**Examples (label-based):**
```basic
START:
    REM Define distance function
    DEF FND(X) = SQR(X^2 + Y^2)
    X = 3: Y = 4
    PRINT "Distance: "; FND(0)
    REM Output: Distance: 5
    END
```

```basic
START:
    REM Random number in range
    DEF FNR(N) = INT(RND(1) * N + 1)
    FOR I = 1 TO 5
        PRINT "Random 1-10: "; FNR(10)
    NEXT I
    END
```

```basic
START:
    REM Temperature conversion
    DEF FNC(F) = (F - 32) * 5 / 9
    DEF FNF(C) = C * 9 / 5 + 32
    INPUT "Enter Fahrenheit: ", TEMP
    PRINT TEMP; "F = "; FNC(TEMP); "C"
    END
```

**Key Points:**
- Function names must start with `FN` followed by a letter (e.g., `FNA`, `FNB`, `FND`)
- Functions can have one parameter
- The function body must be a single expression
- User-defined functions can reference global variables
- Call functions using `FNname(argument)`

### REM and ' - Comments
```basic
10 REM This is a full-line comment
20 ' Apostrophe also starts a comment
30 X = 10 ' Inline comment at end of statement
40 PRINT "Hello" ' Comments work after any statement
```

The apostrophe (`'`) can be used anywhere on a line to start a comment. Everything from the `'` to the end of the line is ignored. This is useful for adding inline comments after code.

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
| `SQRT(x)` | Square root | `SQRT(16)` → `4` |
| `SQR(x)` | Square root (alias for SQRT) | `SQR(16)` → `4` |
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
| `BOXCHAR$(n)` | Box-drawing character (1-6) | `BOXCHAR$(1)` → `"┌"` |
| `ASC(s$)` | ASCII from character | `ASC("A")` → `65` |
| `STR$(n)` | Number to string | `STR$(42)` → `"42"` |
| `VAL(s$)` | String to number | `VAL("42")` → `42` |
| `SPACE$(n)` | n spaces | `SPACE$(5)` → `"     "` |
| `UCASE$(s$)` | Uppercase | `UCASE$("hi")` → `"HI"` |
| `LCASE$(s$)` | Lowercase | `LCASE$("HI")` → `"hi"` |
| `TRIM$(s$)` | Remove leading/trailing whitespace | `TRIM$("  hi  ")` → `"hi"` |
| `LTRIM$(s$)` | Remove leading whitespace | `LTRIM$("  hi")` → `"hi"` |
| `RTRIM$(s$)` | Remove trailing whitespace | `RTRIM$("hi  ")` → `"hi"` |
| `INSTR(s$,find$)` | Find position of substring (0 if not found) | `INSTR("hello","ll")` → `3` |
| `REPLACE$(s$,old$,new$)` | Replace all occurrences | `REPLACE$("hello","l","L")` → `"heLLo"` |

### BOXCHAR$(n) - Box Drawing Characters
Returns box-drawing characters, useful for creating frames and boxes. On CP310 capable terminals, these display as graphical line characters. On CP037 terminals, use traditional mainframe boxdrawing characters (+, -, |).

| n | Character | Description |
|---|-----------|-------------|
| 1 | ┌ | Top-left corner |
| 2 | ┐ | Top-right corner |
| 3 | └ | Bottom-left corner |
| 4 | ┘ | Bottom-right corner |
| 5 | ─ | Horizontal line |
| 6 | │ | Vertical line |

```basic
10 REM Draw a simple box
20 PRINT BOXCHAR$(1) + BOXCHAR$(5) + BOXCHAR$(5) + BOXCHAR$(2)
30 PRINT BOXCHAR$(6) + "  " + BOXCHAR$(6)
40 PRINT BOXCHAR$(3) + BOXCHAR$(5) + BOXCHAR$(5) + BOXCHAR$(4)
```

**Tip:** Use `$TermInfo` to check if teh terminal supports CP310, and use ASCII characters (+, -, |) as fallback for CP037 terminals. See `_terminfo.bas` for a complete example.

### CP310$(n) - Extended Graphic Characters
Returns graphic characters from Code Page 310. Use with CP310-capable terminals for enhanced graphics.

| Range | Characters | Description |
|-------|-----------|-------------|
| 1-6 | ┌ ┐ └ ┘ ─ │ | Single-line box (same as BOXCHAR$) |
| 7-12 | ╔ ╗ ╚ ╝ ═ ║ | Double-line box |
| 13-16 | ├ ┤ ┬ ┴ | T-junctions |
| 17-20 | ┼ ╬ ╠ ╣ | Cross junctions |
| 21-28 | █ ▀ ▄ ▌ ▐ ░ ▒ ▓ | Blocks & shades |
| 29-32 | ← → ↑ ↓ | Arrows |
| 33-36 | ■ □ ● ○ | Geometric shapes |
| 37-40 | ▲ ▼ ◄ ► | Triangle arrows |
| 41-44 | ╭ ╮ ╰ ╯ | Rounded corners |
| 45-50 | · • ╳ ╱ ╲ ∙ | Dots and diagonals |

```basic
10 REM Draw a double-line box with CP310$
20 DIM T{} : T{} = $TermInfo
30 IF T{"codepage"} <> "310" THEN PRINT "Need CP310 terminal" : END
40 PRINT CP310$(7) + CP310$(11) + CP310$(11) + CP310$(11) + CP310$(8)
50 PRINT CP310$(12) + " Hi " + CP310$(12)
60 PRINT CP310$(9) + CP310$(11) + CP310$(11) + CP310$(11) + CP310$(10)
70 PRINT
80 PRINT "Blocks: "; CP310$(21); CP310$(22); CP310$(23); CP310$(24); CP310$(25)
90 PRINT "Arrows: "; CP310$(29); CP310$(30); CP310$(31); CP310$(32)
```

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

The `SLEEP(n)` function pauses program execution for the specified number of seconds. Any call of SLEEP with more than 0.25 seconds will reward the program with more allowed iterations and wall clock time before the program is halted for excessive computation or wall clock. SLEEP spares the CPU as it is a non-busy wait function. 

- **Range:** 0.1 to 255 seconds
- **Fractions:** Supports decimal values (e.g., `SLEEP(0.5)` for half a second)
- **CPU-friendly:** Does not consume CPU cylces during the wait
- **Returns:** 0 (can be ignored)

Example (label-based):
```basic
START:
    REM Countdown Timer
    FOR I = 10 TO 0 STEP -1
        PRINT I
        X = SLEEP(1)
    NEXT I
    PRINT "BLAST OFF!"
    END
```

### TAB Function

The `TAB(n)` function is used in PRINT statements to move to a specific column position. It calculates how many spaces are needed to reach column n based on what has already been printed on the current line.

- **Usage:** `PRINT "text"; TAB(n); "more text"`
- **Range:** 1-255 (column 1 is the leftmost position)
- **Behavior:** Adds spaces to reach column n; if already past column n, no spaces are added

**Examples (label-based):**
```basic
START:
    REM Formatted output with TAB
    PRINT "Name"; TAB(15); "Age"; TAB(25); "City"
    PRINT "Alice"; TAB(15); "25"; TAB(25); "Boston"
    PRINT "Bob"; TAB(15); "30"; TAB(25); "Chicago"
    END
```

Output:
```
Name           Age       City
Alice          25        Boston
Bob            30        Chicago
```

```basic
START:
    REM Centering text
    FOR I = 1 TO 5
        PRINT TAB(I * 5); "*"
    NEXT I
    END
```

**Note:** TAB returns spaces to reach the specified column position. It's most useful for creating aligned tabular output.

### EVAL Function

The `EVAL(expr$)` function evaluates a string as a BASIC expression at runtime and returns the results.

- **Input:** A string containing a valid BASIC expression
- **Returns:** The evaluated result (number or string)
- **Variables:** Can reference current program variables

Examples (label-based):
```basic
START:
    REM Simple calculator
    INPUT "Enter expression: ", E$
    PRINT "Result: "; EVAL(E$)
    END
```

```basic
START:
    REM Using variables in EVAL
    A = 10
    B = 5
    PRINT EVAL("A + B")           ' Prints 15
    PRINT EVAL("A * B + 2")       ' Prints 52
    END
```

```basic
START:
    REM Dynamic math
    FORMULA$ = "SIN(X) * 2"
    FOR X = 0 TO 3
        PRINT "X="; X; " Result="; EVAL(FORMULA$)
    NEXT X
    END
```

```basic
START:
    REM String functions in EVAL
    NAME$ = "HELLO WORLD"
    PRINT EVAL("LEFT$(NAME$, 5)")  ' Prints HELLO
    END
```

---

## 🔗 Program Chaining

Call other BASIC programs and share data between them using COMMON and CHAIN.

### COMMON Statement

Declare variables that persist across CHAIN calls:

```basic
COMMON var1, var2, var3$
```

Variables declared with COMMON retain their values when you CHAIN to another program. Variables not declared as COMMON are cleared.

### CHAIN Statement

Load and run another BASIC program:

```basic
CHAIN "programname"
```

When the chained program ends (via END), control returns to the calling program at the line after CHAIN. COMMON variables are preserved in both directions.

**Example - Main Program:**
```basic
10 REM Main program
20 NAME$ = "John"
30 COUNT = 42
40 COMMON NAME$, COUNT, RESULT
50 CHAIN "helper"
60 PRINT "Back from helper"
70 PRINT "Result: "; RESULT
80 END
```

**Example - Helper Program (helper.bas):**
```basic
10 REM Helper program
20 COMMON NAME$, COUNT, RESULT
30 PRINT "Hello, "; NAME$
40 RESULT = COUNT * 2
50 END
```

**Limits:**
- Total COMMON data limited to 1024 bytes
- Programs must exist in your directory or community folder
- COMMON declarations must appear before CHAIN is executed

---

## 📁 File Input/Output

Read and write data files from your BASIC programs.

### OPEN Statement

Open a file for reading, writing, or appending:

```basic
OPEN "filename.dat" FOR INPUT AS #1
OPEN "filename.dat" FOR OUTPUT AS #2
OPEN "filename.dat" FOR APPEND AS #3
```

**Modes:**
- `INPUT` - Read from existing file
- `OUTPUT` - Create new file (overwrites if exists)
- `APPEND` - Add to end of existing file (creates if not exists)

**File Numbers:** Use #1 through #4 (max 4 files open at once)

### PRINT # Statement

Write to an open file:

```basic
PRINT #1, "Hello World"
PRINT #1, "Score: "; SCORE
PRINT #2, A$; ","; B$
```

### INPUT # Statement

Read a line from an open file:

```basic
INPUT #1, LINE$
INPUT #1, DATA$
```

Each INPUT reads one line from the file.

### CLOSE Statement

Close an open file:

```basic
CLOSE #1        ' Close file #1
CLOSE           ' Close all open files
```

**Important:** Always CLOSE files when done. Files are also automatically closed when program ends.

### EOF Function

Check if at end of file:

```basic
IF EOF(1) THEN PRINT "End of file reached"

WHILE NOT EOF(1)
    INPUT #1, LINE$
    PRINT LINE$
WEND
```

Returns 1 if at end of file, 0 otherwise.

### Complete File I/O Examples

**Writing a data file (label-based):**
```basic
START:
    REM Write high scores to file
    OPEN "scores.dat" FOR OUTPUT AS #1
    PRINT #1, "Player1,1500"
    PRINT #1, "Player2,1200"
    PRINT #1, "Player3,900"
    CLOSE #1
    PRINT "Scores saved!"
    END
```

**Reading a data file (label-based):**
```basic
START:
    REM Read and display file contents
    OPEN "scores.dat" FOR INPUT AS #1
    PRINT "=== HIGH SCORES ==="
    WHILE NOT EOF(1)
        INPUT #1, LINE$
        PRINT LINE$
    WEND
    CLOSE #1
    END
```

**Appending to a file (label-based):**
```basic
START:
    REM Add new score
    INPUT "Player name: ", NAME$
    INPUT "Score: ", SCORE
    OPEN "scores.dat" FOR APPEND AS #1
    PRINT #1, NAME$; ","; SCORE
    CLOSE #1
    PRINT "Score added!"
    END
```

**Limits and Security:**
- Maximum file size: 10KB per file
- File names must end in `.dat`
- Files stored in your BASIC directory only
- No path separators allowed in filenames

**Error Messages:**
| Error | Description |
|-------|-------------|
| `?FILE NOT FOUND` | File doesn't exist (INPUT mode) |
| `?FILE ALREADY OPEN` | File handle already in use |
| `?BAD FILE NUMBER` | Invalid handle (not 1-4) or not open |
| `?FILE SIZE LIMIT EXCEEDED` | Write would exceed 10KB |
| `?ILLEGAL FILE NAME` | Invalid characters or missing .dat |
| `?INPUT PAST END` | Attempted read after EOF |

---

## 🟥 3270BBS Data Access

Access live BBS data direcly from BASIC!

### $ChatMessage(n) - Chat Messages (Associative Array)
`$ChatMessage(n)` returns an associative array with structured chat data from the global (public) chat room.

```basic
10 DIM C{}                  ' Declare associative array
20 C{} = $ChatMessage(0)    ' Get most recent message
30 PRINT C{"username"}; ": "; C{"message"}
40 PRINT "Time: "; C{"datetime"}
```

**Available Keys:**
| Key | Description |
|-----|-------------|
| `datetime` | ISO 8601 format: `YYYY-MM-DDTHH:MM:SS` |
| `username` | Who posted the message |
| `message` | Message content |

**Index:**
- `n=0`: Most recent message
- `n=1` or `n=-1`: Second most recent
- Empty values returned if no messages

**Note:** Only returns messages from the public global chat room, not private rooms.

### $Mail(n) - Your Mail Messages (Associative Array)
`$Mail(n)` returns an associative array with structured mail data:

```basic
10 DIM MAIL{}               ' Declare associative array
20 MAIL{} = $Mail(0)        ' Get most recent mail
30 PRINT MAIL{"from"}       ' Sender name
40 PRINT MAIL{"datetime"}   ' ISO 8601: 2025-12-17T14:30:45
50 PRINT MAIL{"body"}       ' Full message body
```

**Available Keys:**
| Key | Description |
|-----|-------------|
| `datetime` | ISO 8601 format: `YYYY-MM-DDTHH:MM:SS` |
| `from` | Sender username |
| `body` | Complete message content |
| `read` | `"1"` if read, `"0"` if unread |
| `replied` | `"1"` if replied, `"0"` if not |
| `id` | Message ID number |

**Index:**
- `n=0`: Most recent message
- `n=-1` or `n=1`: Second most recent
- Empty values returned if no mail exists

### $UserInfo - Your User Information (Associative Array)
`$UserInfo` returns an associative array with your user profile data. Only non-sensitive fields are exposed.

```basic
10 DIM U{}                  ' Declare associative array
20 U{} = $UserInfo          ' Get user info
30 PRINT "Hello, "; U{"username"}
40 IF U{"country"} <> "" THEN PRINT "Country: "; U{"country"}
```

**Available Keys:**
| Key | Description |
|-----|-------------|
| `username` | Your username |
| `country` | Your country (may be empty) |

**Note:** Admin-only fields like email, IP address, role, and ban status are intentionally not exposed to any user, including admins and moderators.

### $TermInfo - Your Terminal Information (Associative Array)
`$TermInfo` returns an associative array with information about your current terminal session.

```basic
10 DIM T{}                  ' Declare associative array
20 T{} = $TermInfo          ' Get terminal info
30 PRINT "Terminal: "; T{"model"}
40 PRINT "Codepage: "; T{"codepage"}
50 IF T{"codepage"} = "310" THEN PRINT "Graphics characters available!"
```

**Available Keys:**
| Key | Description |
|-----|-------------|
| `model` | Terminal model: "Mod2" (24x80), "Mod3" (32x80), or "Mod4" (43x80) |
| `codepage` | Terminal codepage: "310" (with graphics) or "037" (standard EBCDIC) |

### $Topic(n) - Topics You Can Access (Associative Array)
`$Topic(n)` returns an associative array with topic metadata. Only returns topics the user has permission to access (respects admin-only, moderator-only, and banned user restrictions).

```basic
10 DIM T{}                  ' Declare associative array
20 T{} = $Topic(0)          ' Get most recent accessible topic
30 PRINT T{"title"}         ' Topic title
40 PRINT T{"author"}        ' Author username
50 PRINT T{"conference"}    ' Conference name
```

**Available Keys:**
| Key | Description |
|-----|-------------|
| `id` | Topic ID (use with `$Post`) |
| `title` | Topic title |
| `author` | Username who created it |
| `conference` | Conference name |
| `datetime` | ISO 8601: `YYYY-MM-DDTHH:MM:SS` |
| `posts` | Number of posts/replies |
| `views` | View count |
| `likes` | Total likes |

**Index:**
- `n=0`: Most recent topic
- `n=1`: Second most recent
- Empty values returned if no topics or access denied

### $Post(topic_id, n) - Posts from a Topic (Associative Array)
`$Post(topic_id, n)` returns an associative array with post data from a specific topic. Verifies user has permission to access the topic's conference.

```basic
10 DIM T{}
20 T{} = $Topic(0)                    ' Get topic
30 TOPIC_ID = VAL(T{"id"})            ' Get topic ID
40 DIM P{}
50 P{} = $Post(TOPIC_ID, 0)           ' Get first post
60 PRINT P{"author"}; ": "; P{"body"}
```

**Available Keys:**
| Key | Description |
|-----|-------------|
| `id` | Post ID |
| `author` | Username who wrote it |
| `body` | Post content |
| `datetime` | ISO 8601: `YYYY-MM-DDTHH:MM:SS` |
| `likes` | Like count |
| `dislikes` | Dislike count |

**Arguments:**
- `topic_id`: The topic ID (from `T{"id"}` after `$Topic()`)
- `n=0`: First post (oldest), `n=1`: Second post, etc.
- Empty values returned if topic not found or access denied

---

## ⚡ Compiler Optimizations

The BASIC/3270BBS compiler automatically applies safe optimizations to improve runtime performance. These optimizations are performed at compile time when you `LOAD` or enter a program, and are visible in the `CHECK` command's OPTIMIZER REPORT section.

### Constant Folding

When the compiler detects arithmetic operations with literal (constant) numbers, it evaluates them at compile time instead of at runtime. This eliminates redundant calculations during program execution.

**Example - Before optimization:**
```basic
10 X = 2 + 3 * 4
20 AREA = 3.14159 * 10 * 10
30 TIMEOUT = 60 * 60 * 24
```

**After optimization (internally):**
```basic
10 X = 14
20 AREA = 314.159
30 TIMEOUT = 86400
```

**Supported operations:** `+`, `-`, `*`, `/`, `^` (power), `MOD`

**Note:** The compiler will NOT optimize division or MOD by zero - these remain unevaluated to produce proper runtime errors.

### Function Precomputation

For certain built-in functions called with constant (literal) arguments, the compiler evaluates the function at compile time.

**Example - Before optimization:**
```basic
10 SPACE_CODE = ASC(" ")
20 MSG_LEN = LEN("Hello, World!")
30 CHAR_A = CHR$(65)
40 VALUE = VAL("42.5")
50 TEXT = STR$(100)
```

**After optimization (internally):**
```basic
10 SPACE_CODE = 32
20 MSG_LEN = 13
30 CHAR_A = "A"
40 VALUE = 42.5
50 TEXT = "100"
```

**Precomputed functions:**
| Function | Description | Example | Result |
|----------|-------------|---------|--------|
| `LEN()` | String length | `LEN("HELLO")` | `5` |
| `ASC()` | Character to ASCII | `ASC("A")` | `65` |
| `CHR$()` | ASCII to character | `CHR$(65)` | `"A"` |
| `VAL()` | String to number | `VAL("123")` | `123` |
| `STR$()` | Number to string | `STR$(42)` | `"42"` |

### Viewing Optimizations

Use the `CHECK` command to see what optimizations were applied to your program. The listing includes an OPTIMIZER REPORT section:

```
OPTIMIZER REPORT

  LINE   TYPE              ORIGINAL                 OPTIMIZED
  ----   ----              --------                 ---------
    10   CONSTANT_FOLD     2 + 3 * 4                14
    20   CONSTANT_FOLD     3.14159 * 10 * 10        314.159
    30   FUNC_PRECOMPUTE   LEN("Hello, World!")     13
    40   FUNC_PRECOMPUTE   ASC("A")                 65

  TOTAL OPTIMIZATIONS: 4
```

### Safety Guarantees

The optimizer only applies safe transformations that do not change program behavior:

- Only constant expressions are folded (variables are never evaluated at compile time)
- Division/MOD by zero is not optimized (proper runtime error handling preserved)
- Functions with side effects (like `RND`, `TIMER()`, `INKEY$`) are never precomputed
- String concatenation with variables is not optimized

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

### Example 2: Display Last 3 Chat Messages (Label-Based)
This program retrieves and displays the three most recent chat messages from the BBS:

```basic
START:
    REM Display Last 3 Chat Messages
    DIM C{}
    PRINT "=============================="
    PRINT "   RECENT CHAT MESSAGES"
    PRINT "=============================="
    PRINT
    FOR I = 0 TO 2
        C{} = $ChatMessage(I)
        IF C{"message"} = "" THEN GOTO Done
        PRINT C{"datetime"}; " "; C{"username"}; ": "; C{"message"}
    NEXT I

Done:
    PRINT
    PRINT "=============================="
    END
```

### Example 3: User Greeting (Label-Based)
```basic
START:
    REM User Greeting
    DIM U{}
    U{} = $UserInfo
    PRINT "Welcome, "; U{"username"}; "!"
    IF U{"country"} <> "" THEN PRINT "Connecting from: "; U{"country"}
    END
```

### Example 4: Personal Dashboard (Label-Based)
```basic
START:
    REM Personal Dashboard
    DIM U{} : DIM M{} : DIM C{} : DIM T{}
    U{} = $UserInfo
    PRINT "==============================="
    PRINT "  WELCOME, "; U{"username"}
    PRINT "==============================="
    PRINT
    PRINT "Your latest mail:"
    M{} = $Mail(0)
    IF M{"datetime"} <> "" THEN PRINT "  From: "; M{"from"}; " - "; LEFT$(M{"body"}, 40)
    IF M{"datetime"} = "" THEN PRINT "  No mail"
    PRINT
    PRINT "Latest chat:"
    C{} = $ChatMessage(0)
    IF C{"message"} <> "" THEN PRINT "  "; C{"username"}; ": "; C{"message"}
    IF C{"message"} = "" THEN PRINT "  No messages"
    PRINT
    PRINT "Latest topic:"
    T{} = $Topic(0)
    IF T{"title"} <> "" THEN PRINT "  "; T{"title"}; " by "; T{"author"}
    IF T{"title"} = "" THEN PRINT "  No topics"
    END
```

### Example 5: Mail Reader (Label-Based)
This program reads and displays your most recent email with full details.
Demonstrates both single-line and multi-line IF syntax:

```basic
START:
    REM Mail Reader Example
    DIM MAIL{}
    MAIL{} = $Mail(0)
    IF MAIL{"datetime"} = "" THEN GOTO NoMail
    PRINT "From: "; MAIL{"from"}
    PRINT "Date: "; MAIL{"datetime"}
    PRINT "Status: ";
    IF MAIL{"read"} = "1" THEN GOSUB ShowRead ELSE PRINT "Unread" COLOR YELLOW
    PRINT "---Message---"
    PRINT MAIL{"body"}
    END

NoMail:
    PRINT "No mail"
    END

ShowRead:
    PRINT "Read"
    IF MAIL{"replied"} = "1" THEN PRINT "(Replied)"
    RETURN
```

### Example 6: Topic and Posts Reader (Label-Based)
This program reads a topic and displays all its posts:

```basic
START:
    REM Topic and Posts Reader
    DIM T{}
    DIM P{}

    REM Get the most recent topic
    T{} = $Topic(0)
    IF T{"title"} = "" THEN PRINT "No topics available": END

    PRINT "================================"
    PRINT T{"title"}
    PRINT "by "; T{"author"}; " in "; T{"conference"}
    PRINT "Posted: "; T{"datetime"}
    PRINT "================================"
    PRINT

    REM Get the topic ID for fetching posts
    TOPIC_ID = VAL(T{"id"})
    NUM_POSTS = VAL(T{"posts"})

    REM Display all posts in this topic
    FOR I = 0 TO NUM_POSTS - 1
        P{} = $Post(TOPIC_ID, I)
        IF P{"body"} = "" THEN GOTO SkipPost
        PRINT "--- "; P{"author"}; " ("; P{"datetime"}; ") ---"
        PRINT P{"body"}
        PRINT "Likes: "; P{"likes"}; "  Dislikes: "; P{"dislikes"}
        PRINT
SkipPost:
    NEXT I
    END
```

### Example 7: Digital Clock (Label-Based)
This program displays the current date and time using all time functions:

```basic
START:
    REM Digital Clock Display
    PRINT "================================"
    PRINT "    CURRENT DATE AND TIME"
    PRINT "================================"
    PRINT
    PRINT "  Date: "; DATE$()
    PRINT "  Time: "; TIME$()
    PRINT
    PRINT "  Year:   "; YEAR()
    PRINT "  Month:  "; MONTH()
    PRINT "  Day:    "; DAY()
    PRINT "  Hour:   "; HOUR()
    PRINT "  Minute: "; MINUTE()
    PRINT "  Second: "; SECOND()
    PRINT
    PRINT "  Seconds since midnight: "; TIMER()
    END
```

### Example 8: Orbital Mechanics Plot (24x80 terminal)
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

### Example 9: Phone Book (Label-Based)
This program demonstrates associative arrays to create a simple phone book:

```basic
START:
    REM Simple Phone Book using Associative Arrays
    DIM PHONE${}
    PRINT "=== PHONE BOOK ==="
    PRINT
    REM Add some entries
    PHONE${"Alice"} = "555-1234"
    PHONE${"Bob"} = "555-5678"
    PHONE${"Carol"} = "555-9012"
    PHONE${"David"} = "555-3456"
    PRINT "Stored 4 contacts."
    PRINT

Lookup:
    INPUT "Enter name to look up: ", NAME$
    RESULT$ = PHONE${NAME$}
    IF RESULT$ = "" THEN PRINT "Not found!" COLOR RED: GOTO AskAgain
    PRINT NAME$; ": "; RESULT$ COLOR GREEN

AskAgain:
    PRINT
    INPUT "Look up another? (Y/N): ", A$
    IF UCASE$(A$) = "Y" THEN GOTO Lookup
    PRINT "Goodbye!"
    END
```

---

## ⌨️ Keyboard Controls

| Key | Action |
|-----|--------|
| **Enter** | Execute comand / Submit input |
| **Clear** | Clear screen, show new READY prompt |
| **PA1** / **PA2** | Break/stop running program |
| **PF11** / **PF12** | Step through command history |

---

## 💡 Tips

1. **Line Numbers**: Use increments of 10 (10, 20, 30...) so you can insert lines latter
2. **RENUM**: If you run out of space beetween lines, use `RENUM` to renumber
3. **Save Often**: Use `SAVE "myprogram"` to save your work
4. **Debug**: Use `PRINT` statments to check variable values
5. **Variables**: String variables must end wiht `$` (e.g., `NAME$`)

---

##  Quik Reference Card

```
COMMANDS:  RUN LIST NEW SAVE LOAD EDIT BROWSE ERASE FILES FLIST RENUM DELETE HELP VARS BYE

FILES:     FILES [pattern] [/W] [/C] [/U user]   FLIST [pattern] [/W]
           Wildcards: * (any chars), ? (single char)  e.g. FILES *.bas

SYNTAX:    CHECK - Syntax check, generate name.list (or UNNAMED.list)
           VIEW name.list - View listing without clearing program
           EMAIL name.list - Email listing as PDF to your email

STATEMENTS: PRINT INPUT LET IF/THEN/ELSE/ELSEIF/END IF GOTO GOSUB/RETURN
            FOR/NEXT WHILE/WEND SELECT CASE/END SELECT DIM REM ' END CLS
            COMMON CHAIN OPEN CLOSE SLEEP ON...GOTO ON...GOSUB DEF FN

COMMENTS:   REM comment text     ' Full line comment
            code ' comment       ' Inline comment after code

PRINT COLOR: PRINT "text" COLOR colorname [BLINK|REVERSEVIDEO]
            Colors: WHITE RED YELLOW PINK GREEN BLUE TURQUOISE

COMPUTED:  ON expr GOTO line1,line2,...  ' Jump based on expression value
           ON expr GOSUB line1,line2,... ' Call subroutine based on expression
           DEF FNx(param) = expression   ' Define user function

MATH:      ABS INT SGN SQRT SQR SIN COS TAN ATAN ASIN ACOS LOG EXP RND
           PI() RADIANS(deg) DEGREES(rad)

STRING:    LEN LEFT$ RIGHT$ MID$ CHR$ ASC STR$ VAL SPACE$ UCASE$ LCASE$
           TRIM$ LTRIM$ RTRIM$ INSTR REPLACE$

FILE I/O:  OPEN "file.dat" FOR INPUT|OUTPUT|APPEND AS #n
           PRINT #n, expression   INPUT #n, variable   CLOSE #n
           EOF(n) - Returns 1 if at end of file

CHAINING:  COMMON var1, var2      ' Declare shared variables
           CHAIN "program"        ' Call another program

GRAPHICS:  BOXCHAR$(1-6) CP310$(1-50) - Box drawing and grahpic characters

TIME:      TIME$() DATE$() TIMER() HOUR() MINUTE() SECOND()
           YEAR() MONTH() DAY() SLEEP(n)

OUTPUT:    TAB(n) - Move to colun n in PRINT statements

UTILITY:   EVAL(expr$) - Evaluate string as expression at runtime

BBS DATA:  $ChatMessage(n) $Mail(n) $UserInfo $TermInfo $Topic(n) $Post(topic_id,n)
```

---

## 📋 Version History

### Version 2.8.0

**Syntax Checker Improvements:**

- **Fixed OPEN statement with variable filenames**: The syntax checker now correctly handles OPEN statements where the filename is a variable (e.g., `OPEN FILENAME$ FOR INPUT AS #1`). Previously, this would incorrectly report "EXPECTED FOR AFTER FILENAME".

- **Fixed associative array assignments**: The syntax checker now properly validates associative array assignments using curly brace syntax (e.g., `IDX{KEY$} = "value"`). Previously, this would report "EXPECTED =".

- **FN is no longer a reserved keyword**: You can now use `FN` as a variable name (though this is not recommended). This fixes the "UNKNOWN STATEMENT: FN" error when using `FN` as a loop variable or in assignments like `FN = 1`. The `DEF FN` syntax continues to work correctly.

**Note for Programmers:**
- While `FN` can now be used as a variable name, it's strongly recommended to avoid this practice as it may cause confusion with user-defined functions (`DEF FN`).
- The recommended pattern for user-defined functions remains: `DEF FNX(param) = expression`

---

*TIMESHARING BASIC/3270BBS v2.8.0 - Happy coding!* 🚀
