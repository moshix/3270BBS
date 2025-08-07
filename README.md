TSU, a 3270 BBS 
===============


This is the same code that runs moshix' Forum3270 3270 terminal BBS. 

It is a BBS / Productivity Suite for users on 3270 terminals. It's written in Go language and is made to compile with Go version 1.17 and up. 

It uses minimum resources. For up to 50 concurrent users, it only uses 25MB (no GB...) of memory. The system has seen upwards of 150 concurrent users with 64MB of memory used. So, you only need a small server to host your own 3270 BBS. 

All data is stored in an SQLite3 database called tsu.db. You can run it in WAL mode or in single user mode. We recommend WAL for performance reasons, but you will need a matching database backup strategy. 
  
Code Availability
-----------------

Yes, I plan to release the full code, after a period of bug reports and more security audits. Also, I have a bunch of easter eggs that I want found before I release the code. 

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
`
 F2  = Spell checker
 F4  = Delete current line
 F5  = Insert line below
 F6  = Insert line above
 F7  = Scroll up
 F8  = Scroll down
 F10 = Center current line
 F11 = Make centered box
 F13 = Centered box until next empty row
`
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

1. Download the binary for Linux or Windows for x8664 or for ARM64. 




2. **Run the create_tsudb.sh script**. This will create tsu.db with 2 users admin/admin and noreply/noreply.  You must change these passwords when you log in as admin the first time. 

The first one allows you to log in and control your BBS and set other users to admin thru the admin_users, admin_topics, admin_posts panels. Admin users can also start and stop the various servers (tn3270, tn3270tls, FTPD, HTTPD, PROXY3270) from SDSF and from the console. 
  


  
3. Create and edit tsu.greet which will be sent to all new users. 
  
4. Start the BBS with the provided script start_tsu.sh, you should probably tee the log into a log file.

5. Announce your new BBS, and Bob is your uncle. **Make sure to report your BBS here because I will link to all known 3270 BBS instances out there from this page.**


When in doubt how to install or operate your BBS, reach out to moshix on the Forum3270 with your 3270 terminal at www.moshix.tech port 2400


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
  
Final Notes
-----------

This BBS application is made available in binary form only, strictly as is. It is provided without warranties of any kind, either express or implied, including, but not limited to, the implied warranties of merchantability and fitness for a particular purpose.

The developers assume no responsibility or liability for any direct, indirect, incidental, or consequential damages that may result from the use, misuse, or inability to use this software. You are using this application at your own risk.

No technical support, updates, or maintenance releases are guaranteed. However, feedback and bug reports may be submitted through the appropriate community channels, and while not promised, improvements may be considered in future builds.

By using this software, you agree to abide by any applicable local, national, or international laws regarding software usage and telecommunications. Unauthorized modification, reverse engineering, or redistribution is strictly prohibited unless explicitly permitted by the license or author.


    
Moshix, August 8, 2025 - Cutchogue
