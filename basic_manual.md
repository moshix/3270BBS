# 🖥️ TIMESHARING BASIC/3270BBS Manual

**Copyright © 2025-2026 by moshix. All rights reserved.**

Welcome to the 3270BBS BASIC Interpreter! This manual will guide you through writing and running BASIC programs on teh 3270BBS system.

---

## 🟦 Getting Started

### Entering BASIC
From the Extended Menu, press **B** to enter the BASIC interpreter. You'll see:

```
      TIMESHARING BASIC/3270BBS V1.9.3
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
| `ERASE "name"` | Delete program file (.bas or .list) |
| `FILES` | List your files and community programs |
| `FILES /W` | Wide format: two columns, no timestamps |
| `FILES /U user` | List shared files from another user |
| `FILES /C` | List only community files |
| `FLIST` | List only your files (no community files) |
| `LOAD "user/%file"` | Load a shared file from another user |

**EDIT without a filename:** Opens the program currently in memory in the full-screen editor. This is useful when you've loaded a community program and want to modify it. When you save, it creates `UNTITLED.bas` in your directory.

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
- Section headers highlighted in blue

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

## 🟨 Statements

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

**Examples:**
```basic
10 PRINT "ALERT!" COLOR RED
20 PRINT "Success: "; RESULT$ COLOR GREEN
30 PRINT "WARNING!" COLOR YELLOW BLINK
40 PRINT "Selected item" COLOR WHITE REVERSEVIDEO
50 PRINT "Status: "; S; " - "; MSG$ COLOR PINK
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

### Associative Arrays (Dictionaries)

Associative arrays use string keys instead of nurmeic indices. Declare them with curly braces `{}`:

```basic
10 DIM PHONEBOOK${}         ' String associative array
20 DIM SCORES{}             ' Numeric associative array
30 PHONEBOOK${"Alice"} = "555-1234"
40 PHONEBOOK${"Bob"} = "555-5678"
50 SCORES{"Alice"} = 95
60 SCORES{"Bob"} = 87
70 PRINT "Alice's phone: "; PHONEBOOK${"Alice"}
80 PRINT "Bob's score: "; SCORES{"Bob"}
```

Keys can be variables or expressions:
```basic
10 DIM DATA{}
20 INPUT "Enter name: ", N$
30 INPUT "Enter value: ", V
40 DATA{N$} = V
50 PRINT N$; " = "; DATA{N$}
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
| `SQRT(x)` | Square root | `SQRT(16)` → `4` |
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

### EVAL Function

The `EVAL(expr$)` function evaluates a string as a BASIC expression at runtime and returns the results.

- **Input:** A string containing a valid BASIC expression
- **Returns:** The evaluated result (number or string)
- **Variables:** Can reference current program variables

Examples:
```basic
10 REM Simple calculator
20 INPUT "Enter expression: ", E$
30 PRINT "Result: "; EVAL(E$)

10 REM Using variables in EVAL
20 A = 10
30 B = 5
40 PRINT EVAL("A + B")           ' Prints 15
50 PRINT EVAL("A * B + 2")       ' Prints 52

10 REM Dynamic math
20 FORMULA$ = "SIN(X) * 2"
30 FOR X = 0 TO 3
40 PRINT "X="; X; " Result="; EVAL(FORMULA$)
50 NEXT X

10 REM String functions in EVAL
20 NAME$ = "HELLO WORLD"
30 PRINT EVAL("LEFT$(NAME$, 5)")  ' Prints HELLO
```

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
This program retrieves and displays the three most recent chat messages from the BBS:

```basic
10 REM Display Last 3 Chat Messages
20 DIM C{}
30 PRINT "=============================="
40 PRINT "   RECENT CHAT MESSAGES"
50 PRINT "=============================="
60 PRINT
70 FOR I = 0 TO 2
80   C{} = $ChatMessage(I)
90   IF C{"message"} = "" THEN GOTO 120
100   PRINT C{"datetime"}; " "; C{"username"}; ": "; C{"message"}
110 NEXT I
120 PRINT
130 PRINT "=============================="
140 END
```

### Example 3: User Greeting
```basic
10 REM User Greeting
20 DIM U{}
30 U{} = $UserInfo
40 PRINT "Welcome, "; U{"username"}; "!"
50 IF U{"country"} <> "" THEN PRINT "Connecting from: "; U{"country"}
60 END
```

### Example 4: Personal Dashboard
```basic
10 REM Personal Dashboard
20 DIM U{} : DIM M{} : DIM C{} : DIM T{}
30 U{} = $UserInfo
40 PRINT "==============================="
50 PRINT "  WELCOME, "; U{"username"}
60 PRINT "==============================="
70 PRINT
80 PRINT "Your latest mail:"
90 M{} = $Mail(0)
100 IF M{"datetime"} <> "" THEN PRINT "  From: "; M{"from"}; " - "; LEFT$(M{"body"}, 40)
110 IF M{"datetime"} = "" THEN PRINT "  No mail"
120 PRINT
130 PRINT "Latest chat:"
140 C{} = $ChatMessage(0)
150 IF C{"message"} <> "" THEN PRINT "  "; C{"username"}; ": "; C{"message"}
160 IF C{"message"} = "" THEN PRINT "  No messages"
170 PRINT
180 PRINT "Latest topic:"
190 T{} = $Topic(0)
200 IF T{"title"} <> "" THEN PRINT "  "; T{"title"}; " by "; T{"author"}
210 IF T{"title"} = "" THEN PRINT "  No topics"
220 END
```

### Example 5: Mail Reader
This program reads and displays your most recent email with full details:

```basic
10 REM Mail Reader Example
20 DIM MAIL{}
30 MAIL{} = $Mail(0)
40 IF MAIL{"datetime"} = "" THEN PRINT "No mail": END
50 PRINT "From: "; MAIL{"from"}
60 PRINT "Date: "; MAIL{"datetime"}
70 PRINT "Status: ";
80 IF MAIL{"read"} = "1" THEN PRINT "Read"; ELSE PRINT "Unread";
90 PRINT
100 PRINT "---Message---"
110 PRINT MAIL{"body"}
120 END
```

### Example 6: Topic and Posts Reader
This program reads a topic and displays all its posts:

```basic
10 REM Topic and Posts Reader
20 DIM T{}
30 DIM P{}
40 
50 REM Get the most recent topic
60 T{} = $Topic(0)
70 IF T{"title"} = "" THEN PRINT "No topics available": END
80 
90 PRINT "================================"
100 PRINT T{"title"}
110 PRINT "by "; T{"author"}; " in "; T{"conference"}
120 PRINT "Posted: "; T{"datetime"}
130 PRINT "================================"
140 PRINT
150 
160 REM Get the topic ID for fetching posts
170 TOPIC_ID = VAL(T{"id"})
180 NUM_POSTS = VAL(T{"posts"})
190 
200 REM Display all posts in this topic
210 FOR I = 0 TO NUM_POSTS - 1
220   P{} = $Post(TOPIC_ID, I)
230   IF P{"body"} = "" THEN GOTO 280
240   PRINT "--- "; P{"author"}; " ("; P{"datetime"}; ") ---"
250   PRINT P{"body"}
260   PRINT "Likes: "; P{"likes"}; "  Dislikes: "; P{"dislikes"}
270   PRINT
280 NEXT I
290 END
```

### Example 7: Digital Clock (Time Functions)
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

### Example 9: Phone Book (Associative Arrays)
This program demonstrates associative arrays to create a simple phone book:

```basic
10 REM Simple Phone Book using Associative Arrays
20 DIM PHONE${}
30 PRINT "=== PHONE BOOK ==="
40 PRINT
50 REM Add some entries
60 PHONE${"Alice"} = "555-1234"
70 PHONE${"Bob"} = "555-5678"
80 PHONE${"Carol"} = "555-9012"
90 PHONE${"David"} = "555-3456"
100 PRINT "Stored 4 contacts."
110 PRINT
120 REM Look up contacts
130 INPUT "Enter name to look up: ", NAME$
140 RESULT$ = PHONE${NAME$}
150 IF RESULT$ = "" THEN PRINT "Not found!"
160 IF RESULT$ <> "" THEN PRINT NAME$; ": "; RESULT$
170 PRINT
180 INPUT "Look up another? (Y/N): ", A$
190 IF UCASE$(A$) = "Y" THEN GOTO 130
200 PRINT "Goodbye!"
210 END
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

## ❓ Quick Reference Card

```
COMMANDS:  RUN LIST NEW SAVE LOAD EDIT ERASE FILES FILES/W RENUM DELETE HELP VARS BYE

SYNTAX:    CHECK - Syntax check, generate name.list (or UNNAMED.list)
           VIEW name.list - View listing without clearing program
           EMAIL name.list - Email listing as PDF to your email

STATEMENTS: PRINT INPUT LET IF/THEN/ELSE GOTO GOSUB/RETURN
            FOR/NEXT WHILE/WEND DIM REM END CLS

PRINT COLOR: PRINT "text" COLOR colorname [BLINK|REVERSEVIDEO]
            Colors: WHITE RED YELLOW PINK GREEN BLUE TURQUOISE

MATH:      ABS INT SGN SQRT SIN COS TAN ATAN ASIN ACOS LOG EXP RND
           PI() RADIANS(deg) DEGREES(rad)

STRING:    LEN LEFT$ RIGHT$ MID$ CHR$ ASC STR$ VAL SPACE$ UCASE$ LCASE$
           TRIM$ LTRIM$ RTRIM$ INSTR REPLACE$

GRAPHICS:  BOXCHAR$(1-6) CP310$(1-50) - Box drawing and graphic characters

TIME:      TIME$() DATE$() TIMER() HOUR() MINUTE() SECOND()
           YEAR() MONTH() DAY() SLEEP(n)

UTILITY:   EVAL(expr$) - Evaluate string as expression at runtime

BBS DATA:  $ChatMessage(n) $Mail(n) $UserInfo $TermInfo $Topic(n) $Post(topic_id,n)
```

---

*TIMESHARING BASIC/3270BBS Interpreter v2.1.1 - Happy coding!* 🚀
