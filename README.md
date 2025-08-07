TSU, a 3270 BBS 
===============


This is the same code that runs moshix' Forum3270 3270 terminal BBS. 

It is a BBS / Productivity Suite for users on 3270 terminals. It's written in Go language and is made to compile with Go version 1.17 and up. 

It uses minimum resources. For up to 50 concurrent users, it only uses 25MB (no GB...) of memory. The system has seen upwards of 150 concurrent users with 64MB of memory used. So, you only need a small server to host your own 3270 BBS. 

All data is stored in an SQLite3 database called tsu.db. You can run it in WAL mode or in single user mode. We recommend WAL for performance reasons, but you will need a matching database backup strategy. 
  

Features
--------
- Topics Mgmt
- Messages
- Calendar
- Personal notes management
- Live Chat
- Private chat
- Marketplace
- User rolodex
- User mgmt
- Admin panels
- Session mgmt
- DB creation script
- FTP Server for notes access
- console
- SDSF activity panel
- Updating clock with seeing eye and IBM logo
- Hot air balloon game
- Blackjack game
- TSO command line with several utilities, including send message
- Log viewer
- TLS and TN3270 listeners
- FTPD server and HTTPD server
- Proxy3270 server to other mainframes
- Console view
- Log view
- Forex updated table
- Stocks view
- All Seeing Eye from clock view
- TLS and SSL support with certificates
- Wordle in English, German and Italian
- SSH access to chat and topics


Content Editing
---------------

The editor allows to edit Topics, Posts, Notes, and Messages. The editor has a spelling checker and it is augemented with mainframe world terms such as JCL, ABEND etc. 

Messages and Topics can be edited with these self-explanatory rendering tags:

`<<blue>>, <<white>>, <<red>>, <<pink>>, <<green>>, <<yellow>>, <<turquoise>>, and <<reverse>> and <</reverse>>. These tags work best if put on a line of their own`

The editor function keys available are:

 F2  = Spell checker
 F4  = Delete current line
 F5  = Insert line below
 F6  = Insert line above
 F7  = Scroll up
 F8  = Scroll down
 F10 = Center current line
 F11 = Make centered box
 F13 = Centered box until next empty row

 Save content with SAVE
 Exit editor unsaved with CANCEL



Configuration of the BBS
------------------------
Add the following parameters to your tsu.cnf file to configure the FTP server.
Following values are just examples and can be configured to your needs: 
```
# TLS ports
# Server settings
#
# bbs_name is the name of your BBS, up to 10 characters wide only!
bbs_name=Forum3270

port=2300   #port for non-encrypted traffic

tlsport=2023 #port for TSL 1.x traffic

# your certificate
tlscert=your.crt
tlskey=your.key

#port where the web server listens
httpd_port=9000 # port for the HTTPD listenr
MOTD="Kindly log off by doing a LOGOFF from TSO to free up resources"

# FTP server settings
FTP_port=2100       # Port for FTP server (default: 2100)
FTP_limit=20        # Maximum file size in KB (default: 20)

# MVS (or VM) remote server settings
mvs_address=localhost # for forwarding MVS connectiong
mvs_port=1111         # port

start_FTPD=no       # start ftpd?
start_proxy3270=yes # start proxy to mvs or VM?
start_HTTPD=no      # start web server?

# ssh server settings
start_SSHD=yes
sshd_port=3296
```

Installation And Start
----------------------

##Requirements

- **Go compiler version 1.17.0** is required to build and run this application.  1.21.0 is the recommended and tested version. You can download Go from https://golang.org/dl/

##Go Module Dependencies

The following Go modules are required (see go.mod):

```
require (
    github.com/fclairamb/ftpserverlib v0.25.0
    github.com/gorilla/mux v1.8.1
    github.com/gorilla/sessions v1.4.0
    github.com/mattn/go-sqlite3 v1.14.27
    github.com/piquette/finance-go v1.1.0
    github.com/racingmars/go3270 v0.9.2
    github.com/spf13/afero v1.14.0
)

require (
    github.com/fclairamb/go-log v0.5.0 // indirect
    github.com/gorilla/securecookie v1.1.2 // indirect
    github.com/shopspring/decimal v0.0.0-20180709203117-cd690d0c9e24 // indirect
    golang.org/x/net v0.40.0 // indirect
    golang.org/x/sys v0.33.0 // indirect
    golang.org/x/text v0.25.0 // indirect
)

// Use the fork of finance-go that has fixes for the recent Yahoo Finance API changes
replace github.com/piquette/finance-go => github.com/psanford/finance-go v0.0.0-20250222221941-906a725c60a0
```

##Building
Option 1: run the INSTALL.bash script which will check your environment, create your database, check your configuration script and create the two minimum required accounts (admin and reply). 

Option 2: 

**Run the create_tsudb.sh script**. This will create tsu.db with 2 users admin/admin and noreply/noreply.  You must change these passwords when you log in as admin the first time. 

The first one allows you to log in and control your BBS and set other users to admin thru the admin_users, admin_topics, admin_posts panels. Admin users can also start and stop the various servers (tn3270, tn3270tls, FTPD, HTTPD, PROXY3270) from SDSF and from the console. 
  
Make sure to change the passwords to admin and noreply before releasing to your public. 


After either Option 1, or Option2:
  
Create and edit tsu.greet which will be sent to all new users. 
  
Start the BBS with the provided script start_tsu.sh, you should probably tee the log into a log file.

Announce your new BBS, and Bob is your uncle. 

Operation of the BBS, User and Content Management
-------------------------------------------------

The application is very stable and stays up for months on end. However, any BBS requires constant care and content maintenance. Trolls naturally appear where online communities form and their posts and dropppings need to be cleaned. 

Even though the BBS has a password retrieval process with PF9 from the logon panel, some users will forget the city they live in, and their email so recovery in those cases is impossible and they have to register a new user and you will have to delete the old one from admin_users. 

Users can also delete their own account fromt the 0 Edit Profile option in the main menu. 

There is a script to prune users who have not logged in for more than X days. Pruning does not remove their posts or topics, but does remove their messages from the database. The script is called remove_old_users.bash. 

 A dictionary is provided for the spell checker in the Editor and in the chat applets. If you need to insert more words into the dictionary, use the script insert_to_dictionary.bash.

Finally there is a script import_calendar.sh to import .ics files into an individual calendar, if you want your Google calendar or whatever to be also featured in in the BBS 

Daily pruning and removing of bad content is much easier than doing it once a month or once a  year. Stay in touch with your users and advertise your BBS in the communities where you want to attract users from. 

Have a look at the ./essentials_scripts directory. It has some SQL scripts that help you manage content and users.   

If you enable FTP, then users can upload notes to their NOTES directly, or also download them. This way they can edit longer notes and then upload them with FTP. Same wth HTTP. 

From Notes, then users can post a note to Topics. 

Admin Only Panels
-----------------
- LOG command from main menu
- F4 from SDSF
- start and stop components from the MVS Console in Extended Menu

Proxying to another mainframe
-----------------------------
3270 BBS can proxy users to another mainframe if you added it to the tsu.cnf file and if you enable the PROXY server from the tsu.cnf file or from SDSF. 

TLS terminal access
--------------------
For secure TLS access, you will need certificates and you will have to point to the certificate from tsu.cnf

SSH access
----------
Configure the port at which the SSHD internal server will listen for users. Users must already be registered to be able to use ssh access. 


SDSF Commands
------------

In the SDSF Activity screen, admins can issue the following commands:

'P FTPD       - Stop the FTPD server'  
'S fTPD       - Start the FTPD server'  
Same for PROXY, HTTPD, TN3270TLS, TN3270  
    
'C U=MOSHIX   - Terminate the session of user MOSHIX'  
  
'$PJES2,TERM  - Terminate the BBS gracefully '  
'LOG          - View BBS log. Top/BOT F7/F8 will navigate inside the log view'  
  
  

Moshix, July 16, 2025 - Munich
