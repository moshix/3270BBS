<!--
Copyright 2025 by moshix
All rights reserved by moshix
-->

# 3270BBS User Session Structure Documentation

## Overview

The 3270BBS system uses a comprehnsive session structure to maintain state for each connected user. This document provides a technical explanation of teh `session` struct and its fields, along with code examples showing their usage.
  
Obviously, 3270BBS is written in Go, and therefore pls understand this document in the context of the Go language. 
  

## Core Session Structure

```go
// Session holds state for a singel user session with virtual session support
type session struct {
    // Core user and system state
    user                 *models.User
    global               *globalState
    lastCmd              string
    lastEditorReturnData interface{}
    lastChatMessage      *models.ChatMessage

    // UI and connection state
    chatResponse        *go3270.Response
    calendarDate        time.Time
    isTLSConnection     bool
    update              chan struct{}
    discordChannelCache *discordChannelCache

    // Virtual session suport
    virtualSessions     [MaxVirtualSessions]*VirtualSession
    currentVirtualIndex int
    chatOwnerSession    int
    showingVSStatus     bool
    virtualSessionsUsed [MaxVirtualSessions]bool

    // Feature-specific state
    selectedConference string
    previousLoginTime  *time.Time
    lastUserInput      time.Time
    currentMenuType    string
}
```

## Field-by-Field Documentation

### Core User and System State

#### `user *models.User`
**Purpose**: Stores the authenticated user's information and permissions.

**Usage Example**:
```go
func (s *session) mainMenu(conn net.Conn, dev go3270.DevInfo, data any) (go3270.Tx, any, error) {
    // Must be logged in to access main menu
    if s.user == nil {
        return s.login, nil, nil
    }
    
    // Check admin privileges
    if s.user.IsAdmin {
        // Show admin options
    }
}
```

**Contains**: User ID, username, password hash, email, admin flags, karma, last login time, location info.

#### `global *globalState`
**Purpose**: Reference to shared application state across all user sessions.

**Usage Exmple**:
```go
// Access global configuration
bbsName := s.global.config.BBSName

// Access shared chat manager
s.global.chatManager.JoinChat(s.user.ID, s.user.Username)

// Access user session tracking
s.global.userSessionsLock.Lock()
activeUsers := len(s.global.userSessions)
s.global.userSessionsLock.Unlock()
```

**Contains**: Chat manager, configuration, active user sessions map, synchronization mutex.

#### `lastCmd string`
**Purpose**: Stores the last command entered by the user (currently used by virtual sessions).

**Usage Example**:
```go
// In virtual session synchronization
func (s *session) syncWithVirtualSession() {
    vs := s.getCurrentVirtualSession()
    s.lastCmd = vs.lastCmd  // Restore last command from virtual session
}

func (s *session) updateVirtualSessionFromMain() {
    vs := s.getCurrentVirtualSession()
    vs.lastCmd = s.lastCmd  // Save current command to virtual session
}
```

**Note**: This field is primarily used for virtual session state preservation and is not actively used in current command processing.

#### `lastEditorReturnData interface{}`
**Purpose**: Stores return data for editor operations to maintain context when returning from editors.

**Usage Example**:
```go
// In virtual session state management
func (s *session) syncWithVirtualSession() {
    vs := s.getCurrentVirtualSession()
    s.lastEditorReturnData = vs.lastEditorReturnData
}

// When editor completes, this data is used to return to the correct context
// with the appropriate data for the calling screen
```

**Use Cases**: Topic editing, note editing, message composition, post creation.

#### `lastChatMessage *models.ChatMessage`
**Purpose**: Caches the most recently sent chat message for the session.

**Usage**: Used to track and potentially display recent chat activity or for message management operations.

### UI and Connection State

#### `chatResponse *go3270.Response`
**Purpose**: Temporary storage for chat response during auto-refresh operations.

**Usage**: Used in chat screens that have auto-refresh functionality to preserve user input state between screen updates.

#### `calendarDate time.Time`
**Purpose**: Tracks the currently displayed date in calendar views.

**Usage Example**:
```go
// Calendar navigation
func (s *session) adjustCalendarMonth(delta int) {
    date := s.getCalendarDate()
    // Calculate new month with delta
    newMonth := int(date.Month()) + delta
    // ... month calculation logic ...
    s.calendarDate = time.Date(year, time.Month(newMonth), day, 0, 0, 0, 0, time.Local)
}

// Calendar display
func generateCalendar(t time.Time) []go3270.Field {
    year, month, _ := t.Year(), t.Month(), t.Day()
    // Generate calendar fields based on the stored date
}
```

**Features**: Allows users to navigate between months (F10/F11) and maintains calendar context across virtual sessions.

#### `isTLSConnection bool`
**Purpose**: Tracks whether the current connection is using TLS encryption.

**Usage Example**:
```go
// In login screen display
{Row: 2, Col: 36, Content: fmt.Sprintf("%s - %d", getPortType(s.isTLSConnection), func() int {
    if s.isTLSConnection {
        return s.global.config.TLSPort
    }
    return s.global.config.Port
}()), Color: go3270.Green}

// Connection type determination
func getPortType(isTLS bool) string {
    if isTLS {
        return "TLS"
    }
    return "NoTLS"
}
```

**Purpose**: Used for security indicators, logging, and connection-specific behavior.

#### `update chan struct{}`
**Purpose**: Channel for signaling chat updates and coordinating real-time features.

**Usage**: Used in chat systems for notifying about new messages and triggering screen refreshes.

#### `discordChannelCache *discordChannelCache`
**Purpose**: Caches Discord channel information to avoid repeated API calls.

**Usage**: Stores Discord channel list and metadata for the Discord integration feature, improving performance by avoiding API rate limits.

### Virtual Session Support

#### `virtualSessions [MaxVirtualSessions]*VirtualSession`
**Purpose**: Array of virtual sessions (currently supports 2 sessions: indices 0 and 1).

**Usage Example**:
```go
// Initialize virtual sessions on login
func (s *session) initVirtualSessions() {
    s.virtualSessions[0] = &VirtualSession{
        currentScreen:        s.mainMenu,
        currentData:          nil,
        lastCmd:              "",
        lastEditorReturnData: nil,
        calendarDate:         time.Now(),
        discordChannelCache:  nil,
    }
    s.virtualSessionsUsed[0] = true
}

// Save state when switching
func (s *session) saveCurrentVirtualState(screen go3270.Tx, data interface{}) {
    if s.virtualSessions[s.currentVirtualIndex] != nil {
        s.virtualSessions[s.currentVirtualIndex].currentScreen = screen
        s.virtualSessions[s.currentVirtualIndex].currentData = data
    }
}
```

**Each VirtualSession Contains**:
- `currentScreen go3270.Tx`: The screen function the session is currently on
- `currentData interface{}`: Data context for the current screen
- `lastCmd string`: Last command entered in this session
- `lastEditorReturnData interface{}`: Editor return context
- `calendarDate time.Time`: Calendar navigation state
- `discordChannelCache *discordChannelCache`: Discord cache state

#### `currentVirtualIndex int`
**Purpose**: Tracks which virtual session is currently active (0 or 1).

**Usage Example**:
```go
// Switch between virtual sessions (F24)
func (s *session) switchVirtualSession() (go3270.Tx, interface{}, error) {
    // Switch to the other virtual session
    if s.currentVirtualIndex == 0 {
        s.currentVirtualIndex = 1
    } else {
        s.currentVirtualIndex = 0
    }
    
    // Load the target virtual session state
    return s.loadVirtualSessionState()
}
```

#### `chatOwnerSession int`
**Purpose**: Tracks which virtual session currently owns chat access (-1 if none).

**Usage Example**:
```go
// Chat access control
func (s *session) canEnterChat() bool {
    return s.chatOwnerSession == -1 || s.chatOwnerSession == s.currentVirtualIndex
}

func (s *session) claimChatForCurrentSession() {
    s.chatOwnerSession = s.currentVirtualIndex
}

func (s *session) releaseChatFromCurrentSession() {
    s.chatOwnerSession = -1
}
```

**Constraint**: Only one virtual session per user can access chat at a time to prevent conflicts.

#### `showingVSStatus bool`
**Purpose**: Tracks whether the virtual session status overlay is currently displayed.

**Usage Example**:
```go
// Toggle virtual session status display (F5)
case go3270.AIDPF5:
    if s.showingVSStatus {
        s.showingVSStatus = false
    } else {
        s.showingVSStatus = true
    }
    return s.mainMenu, nil, nil
```

#### `virtualSessionsUsed [MaxVirtualSessions]bool`
**Purpose**: Tracks which virtual session indices have been initialized and used.

**Usage Example**:
```go
// Track virtual session usage
s.virtualSessionsUsed[0] = true  // Session 0 always used (default)
s.virtualSessionsUsed[1] = false // Session 1 only used when F23/F24 pressed

// Count active sessions
func (s *session) countUsedVirtualSessions() int {
    count := 0
    for i := 0; i < MaxVirtualSessions; i++ {
        if s.virtualSessionsUsed[i] {
            count++
        }
    }
    return count
}
```

### Feature-Specific State

#### `selectedConference string`
**Purpose**: Stores the currently selected conference name for filtering topics.

**Usage Example**:
```go
// Conference selection
func (s *session) conferenceTopics(conn net.Conn, dev go3270.DevInfo, data any) (go3270.Tx, any, error) {
    selectedConference := ""
    if data != nil {
        if conf, ok := data.(string); ok {
            selectedConference = conf
        }
    }
    
    // Store selected conference for topic filtering
    s.selectedConference = selectedConference
    
    // Filter topics by selected conference
    return s.topicsList, map[string]interface{}{
        "caller": s.conferencesList,
    }, nil
}
```

#### `previousLoginTime *time.Time`
**Purpose**: Stores the user's previous login time before the current session for conference update checking.

**Usage Example**:
```go
// Set during login (auth.go)
if s.user.LastLogin.Valid {
    s.previousLoginTime = &s.user.LastLogin.Time
} else {
    s.previousLoginTime = nil
}

// Used for conference update detection (conference.go)
func (s *session) hasConferenceNewUpdates(conferenceName string) bool {
    if s.previousLoginTime == nil {
        return false
    }
    
    lastLoginTime := *s.previousLoginTime
    // Check for new topics/posts since previous login
}
```

**Purpose**: Enables showing conferences with new activity since the user's last visit in pink color.

#### `lastUserInput time.Time`
**Purpose**: Tracks the last time the user pressed any AID key for automatic screensaver functionality.

**Usage Example**:
```go
// Initialize on login
s.lastUserInput = time.Now()

// Update when user presses keys
func (s *session) updateUserInput() {
    s.lastUserInput = time.Now()
}

// Check for screensaver timeout
func (s *session) checkScreensaverTimeout(menuType string) (go3270.Tx, interface{}, bool) {
    if time.Since(s.lastUserInput) >= screensaverTimeout {
        // Activate screensaver after 3 minutes of inactivity
        return s.screenSaver, screensaverData, true
    }
    return nil, nil, false
}
```

#### `currentMenuType string`
**Purpose**: Tracks which menu the user is currently on ("main" or "extended") for context-aware operations.

**Usage Example**:
```go
// Database activity optimization
if s.user != nil && s.currentMenuType != "main" {
    // Only update database when entering from different screen
    _ = models.UpdateUserActivity(s.user.ID, models.ActivityMainMenu)
}

// Screensaver return context
screensaverData := map[string]interface{}{
    "returnMenu": menuType,  // Return to correct menu after screensaver
}
```

## Related Structures

### GlobalState
```go
type globalState struct {
    chatManager      *models.LiveChat           // Global chat manager
    config           Config                     // Application configuration
    userSessions     map[int64]*UserSession     // Active user sessions by user ID
    userSessionsLock sync.Mutex                 // Thread-safe access to userSessions
}
```

### UserSession
```go
type UserSession struct {
    Conn        net.Conn   // Network connection
    ConnectedAt time.Time  // Connection timestamp
}
```

### VirtualSession
```go
type VirtualSession struct {
    currentScreen        go3270.Tx            // Current screen function
    currentData          interface{}          // Screen data context
    lastCmd              string               // Last command in this session
    lastEditorReturnData interface{}          // Editor return context
    calendarDate         time.Time            // Calendar navigation state
    discordChannelCache  *discordChannelCache // Discord cache state
}
```

## Session Lifecycle

### 1. Session Creation
```go
// In main connection handler
state := &session{
    user:                 nil,
    global:               &global,
    lastCmd:              "",
    lastEditorReturnData: nil,
    lastChatMessage:      nil,
    chatResponse:         nil,
    calendarDate:         time.Time{},
    isTLSConnection:      false,
    update:               make(chan struct{}, 1),
    discordChannelCache:  nil,
    // Virtual session fields initialized in initVirtualSessions()
}
```

### 2. Login Initialization
```go
// In auth.go login function
s.user = user
s.previousLoginTime = &s.user.LastLogin.Time
s.lastUserInput = time.Now()
s.currentMenuType = ""
s.initVirtualSessions()

// TLS connection detection
if _, isTLS := conn.(*tls.Conn); isTLS {
    state.isTLSConnection = true
}
```

### 3. Virtual Session Initialization
```go
func (s *session) initVirtualSessions() {
    s.virtualSessions[0] = &VirtualSession{
        currentScreen:        s.mainMenu,
        currentData:          nil,
        lastCmd:              "",
        lastEditorReturnData: nil,
        calendarDate:         time.Now(),
        discordChannelCache:  nil,
    }
    
    s.virtualSessionsUsed[0] = true
    s.virtualSessionsUsed[1] = false
    s.currentVirtualIndex = 0
    s.chatOwnerSession = -1
}
```

## Key Design Patterns

### 1. State Preservation Across Virtual Sessions
```go
// Save current state before switching
func (s *session) saveCurrentVirtualState(screen go3270.Tx, data interface{}) {
    if s.virtualSessions[s.currentVirtualIndex] != nil {
        s.virtualSessions[s.currentVirtualIndex].currentScreen = screen
        s.virtualSessions[s.currentVirtualIndex].currentData = data
    }
}

// Restore state when switching back
func (s *session) syncWithVirtualSession() {
    vs := s.getCurrentVirtualSession()
    s.lastCmd = vs.lastCmd
    s.lastEditorReturnData = vs.lastEditorReturnData
    s.calendarDate = vs.calendarDate
    s.discordChannelCache = vs.discordChannelCache
}
```

### 2. Context-Aware Database Updates
```go
// Only update database activity when genuinely entering from different screen
if s.user != nil && s.currentMenuType != "main" {
    _ = models.UpdateUserActivity(s.user.ID, models.ActivityMainMenu)
}
```

### 3. Automatic Screensaver Management
```go
// Track actual user input for screensaver timeout
func (s *session) updateUserInput() {
    s.lastUserInput = time.Now()
}

// Check for inactivity timeout
if time.Since(s.lastUserInput) >= screensaverTimeout {
    return s.screenSaver, screensaverData, true
}
```

### 4. Conference Update Detection
```go
// Use previous login time for conference update highlighting
func (s *session) hasConferenceNewUpdates(conferenceName string) bool {
    if s.previousLoginTime == nil {
        return false
    }
    
    lastLoginTime := *s.previousLoginTime
    // Query for new topics/posts since previous login
}
```

## Thread Safety Considerations

### Global State Access
```go
// Always use mutex when accessing global user sessions
s.global.userSessionsLock.Lock()
for _, session := range s.global.userSessions {
    // Process active sessions
}
s.global.userSessionsLock.Unlock()
```

### Chat Channel Management
```go
// Chat updates use buffered channel
s.update = make(chan struct{}, 1)

// Non-blocking chat notifications
select {
case s.update <- struct{}{}:
default:
    // Channel full, skip update
}
```

## Performance Optimizations

### 1. Minimal Database Updates
- Database activity updates only on genuine screen transitions
- Menu refreshes and function key navigation don't trigger database writes
- Reduces database load by ~80%

### 2. Efficient Conference Checking
- Previous login time cached in session to avoid repeated database queries
- Conference update checking uses single combined SQL query

### 3. Virtual Session Efficiency
- State synchronization only occurs during virtual session switches
- Lazy initialization of virtual session 1 (only created when needed)

## Security Features

### 1. Chat Access Control
```go
// Only one virtual session can own chat
func (s *session) canEnterChat() bool {
    return s.chatOwnerSession == -1 || s.chatOwnerSession == s.currentVirtualIndex
}
```

### 2. TLS Connection Tracking
```go
// Security indicators based on connection type
if s.isTLSConnection {
    // Show TLS port and security indicators
}
```

### 3. Session Isolation
- Each user session is completely isolated
- Virtual sessions within a user session share controlled state
- No cross-user session interference

## Error Handling and Cleanup

### Session Cleanup
```go
func (s *session) cleanupVirtualSessions() {
    // Release chat ownership
    if s.chatOwnerSession != -1 {
        s.releaseChatFromCurrentSession()
    }
    
    // Reset all virtual sessions
    for i := 0; i < MaxVirtualSessions; i++ {
        s.virtualSessions[i] = nil
        s.virtualSessionsUsed[i] = false
    }
    
    s.currentVirtualIndex = 0
    s.chatOwnerSession = -1
}
```

### Graceful Degradation
- All fields have safe defaults which increases the resilience of th appp
- Nil checks prevent crashes when features are disabled
- Fallback behavior for missing or corrupted state

## Conclusion

The 3270BBS session structure provides a robust foundation for managing complex user interactions across multiple virtual sessions while guaranteein performance, security, and state consistensy. The design emphasizes minimum resource usage, thread safety, and graceful handling of edge cases.
