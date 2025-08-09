A 3270 BBS 
==========


This is the same code that runs my Forum3270 BBS for 3270 terminals, [real](https://youtube.com/shorts/deyGhLtKzp8?si=_f4SYaz37xLR54Zj) and emulated. 

It uses minimum resources. For up to 50 concurrent users, it only uses 25MB (not GB...) of memory. The system has seen upwards of 150 concurrent users with 64MB of memory used. So, you only need a small server to host your own 3270 BBS. A simple VPS server instance is perfectly fine. The code is heavily multi-threaded, therefore more cores are better, but not required. The BBS is blazing fast even with just one core. 

All data is stored in an SQLite3 database called **tsu.db**. You can run it in WAL mode or in single mode. We recommend WAL for performance reasons. After six months of service, and hundreds of users, with lots of activity, my tsu.db is still less than 50MB. Disk space is not a concern. 
  
3270BBS, by the way, loves to run on Linux/s390x (especially on AlmaLinux!)  

Pre-Requisites
--------------

-Make sure you have **sqlite3** installed.   
-And make sure you have a 3270 terminal to connect, obviously. Something like c3270 or x3270, or [Vista3270](https://www.tombrennansoftware.com/) is perfectly fine.

  
Code Availability
-----------------

| Availability                                     | Supported          |
|--------------------------------------------------|--------------------|
| Linux 64amd                                      | :white_check_mark: |
| Linux 64arm                                      | :white_check_mark: |
| Linux s390x                                      | :white_check_mark: |
| FreeBSD                                          | :white_check_mark: |
| Macos Universal                                  | :white_check_mark: |
| Windoze                                          |  :x:               |
| Is it awesome?                                   | :white_check_mark: |

Yes, I plan to release the full code, after a period of bug reports and more security audits.  
Also, I have a bunch of easter eggs that I want found before I release the code. 

  
Features
--------

| Feature                                           | Included          |
|--------------------------------------------------|--------------------|
| Topics Mgmt                                      | :white_check_mark: |
| Messages                                         | :white_check_mark: |
| Calendar                                         | :white_check_mark: |
| Live Chat                                        | :white_check_mark: |
| Private chat                                     | :white_check_mark: |
| Marketplace                                      | :white_check_mark: |
| User rolodex                                     | :white_check_mark: |
| User mgmt                                        | :white_check_mark: |
| Admin panels                                     | :white_check_mark: |
| Session mgmt                                     | :white_check_mark: |
| DB creation script                               | :white_check_mark: |
| FTP Server for notes access                      | :white_check_mark: |
| Web Server for notes, topics, sysadmin access    | :white_check_mark: |
| Console                                          | :white_check_mark: |
| SDSF activity panel                              | :white_check_mark: |
| Updating clock with seeing eye and IBM logo      | :white_check_mark: |
| Hot air balloon game                             | :white_check_mark: |
| Blackjack game                                   | :white_check_mark: |
| Wordle in English/Italian/German                 | :white_check_mark: |
| TSO command line with several utilities          | :white_check_mark: |
| Log viewer                                       | :white_check_mark: |
| TLS and TN3270 listeners                         | :white_check_mark: |
| FTPD server and HTTPD server                     | :white_check_mark: |
| Proxy3270 server to other mainframes             | :white_check_mark: |
| Console view                                     | :white_check_mark: |
| Forex updated table                              | :white_check_mark: |
| Stocks view                                      | :white_check_mark: |
| All Seeing Eye from clock view                   | :white_check_mark: |
| TLS and SSL support with certificates            | :white_check_mark: |
| SSH access to chat and topics                    | :white_check_mark: |
| Screensaver to protect from burn-in              | :white_check_mark: |
| DELTAMON performance monitor                     | :white_check_mark: |
| Doors to other 3270BBS communities               | :white_check_mark: |
| No root privileges required                      | :white_check_mark: |



Content Editing
---------------

3270BBS contains its own Editor. The Editor allows to edit Topics, Posts, Notes, marketplace items, and Messages. The editor has a spelling checker
which is augemented with mainframe world terms such as JCL, ABEND etc.   

Messages and Topics can be edited with these self-explanatory rendering tags:  

`<<blue>>, <<white>>, <<red>>, <<pink>>, <<green>>, <<yellow>>, <<turquoise>>, and <<reverse>> and <</reverse>>.`  
These tags work best if they are put on a line of their own. 

The Editor function keys available are:


```
- F1  = Scroll to first line
– F2  = Spell checker
– F4  = Delete current line
– F5  = Insert line below
– F6  = Insert line above
– F7  = Scroll up
– F8  = Scroll down
- F9  = Scroll to last line
– F10 = Center current line
– F11 = Make centered box
– F13 = Centered box until next empty row
– Save content with SAVE
– Exit editor unsaved with CANCEL
```

Configuration of the BBS
------------------------
Add the following parameters to your **tsu.cnf** file to configure your 3270BBS. The 3270BBS application **needs**
tsu.cnf to start up properly!  

So, you must create tsu.cnf, even if you just take the example below to get started fast. 
  
The following **values are just examples** and you should change them to your needs:   
```
# Server settings
# (c) 2025 by Moshix. All rights reserved. 
# bbs_name is the name of your BBS, up to 10 characters wide only!
bbs_name=My3270BBS
MOTD="Welcome to my 3270 BBS"

# 3270 ports
port=3270                  #port for non-encrypted traffic
tlsport=3271               #port for TSL 1.x encrypted traffic

# your certificate
tlscert=your.crt
tlskey=your.key


#web server port
httpd_port=9000            # port for the HTTPD listenr

# FTP server settings
FTP_port=2100             # Port for FTP server (default: 2100)
FTP_limit=20              # Maximum file size in KB (default: 20)

start_FTPD=no             # start ftpd?
start_proxy3270=no        # start proxy to mvs or VM?
start_HTTPD=no            # start web server? do not open to public, for admins only

# ssh server settings
start_SSHD=yes
sshd_port=2022

# remote mainframe settings
# Up to 15 can be configured.
# The remote hosts are being read in dynamically at runtine
# So you can make changes to the tsu.cnf file for remote hosts without needign to restart the BBS
remote1=MVS3.8
remote1_description="MVS 3.8 TK5 community mainframe"
remote1_addr=localhost
remote1_port=1111

remote2=SDFVM
remote2_description="VM/SP rel5 with PROFS at SDF"
remote2_addr=sdfvm.sdf.org
remote2_port=24

remote3=Secureproxy3270
remote3_description="Some other mainframe"
remote3_addr=9.9.1.1       # IPV6 also works!
remote3_port=3270
```
  
Installation And Start
----------------------

1. Download the [binary for Macos, Linux 64amd and 64arm and s390x, FreeBSD](https://github.com/moshix/3270BBS/releases/tag/26.7).

2. **Rename the downloaded binary to tsu** for the provided scripts to work, or change the scripts. 


3. **Run the create_tsudb.sh script**. This will create tsu.db with 2 users admin/admin and noreply/noreply.  You must change these passwords when you log in as admin the first time. 

The admin account allows you to log in and control your BBS and set other users to admin thru the admin_users, admin_topics, admin_posts panels. Admin users can also start and stop the various servers (tn3270, tn3270tls, FTPD, HTTPD, PROXY3270) from SDSF and from the console.  The reply account is only used for internal system messages to users, but you need to change the password for user noreply once you log in as admin from the panel ADMIN USERS (option 7).   
  

4. Edit the sample tsu.greet from this repo. It's the greeting for all new users. Remember to keep it 80 characters wide, max,for easey reading on 3270 terminals.   
  
5. Start the BBS with the provided script start_tsu.sh, you should probably tee the log into a log file.  

6. Announce your new BBS, and Bob is your uncle. **Make sure to report your BBS here because I will link to all known 3270 BBS instances out there from this page.**  


When in doubt how to install or operate your BBS, reach out to moshix on the Forum3270 with your 3270 terminal at www.moshix.tech port 2400


Operation of the BBS, User and Content Management
-------------------------------------------------

The application is very stable and stays up for months on end. However, any BBS requires constant care and content maintenance. Trolls naturally form where online communities exist, and their many dropppings need to be cleaned. A BBS without some kind of moderator activity will either wither and die, or degenerate into a reputational problem for you. 
  
Daily pruning and removing of bad content is much easier than doing it once a month or once a  year. Stay in touch with your users and advertise your BBS in the communities where you want to attract users from. 
  
There is a script to prune users who have not logged in for more than X days. Pruning does not remove their posts or topics, but does remove their messages from the database. The script is called remove_old_users.bash. 
  
Even though the BBS has a password retrieval process with PF9 from the logon panel, some users will forget the city they live in, and their email so recovery in those cases is impossible and they have to register a new user and you will have to delete the old one from admin_users. 
  
Users can also delete their own account fromt the 0 Edit Profile option in the main menu. 
  
A dictionary is provided for the spell checker in the Editor and in the chat applets. If you need to insert more words into the dictionary, use the script insert_to_dictionary.bash.
  
Finally there is a script import_calendar.sh to import .ics files into an individual calendar, if you want your Google calendar or whatever to be also featured in in the BBS 
  
I am providing some eseential scripts to manage your BBS in this repo.
  
If you enable FTP, then users can upload notes to their NOTES directly, or also download them. This way they can edit longer notes and then upload them with FTP. Same wth HTTP. 
  
From Notes, then users can post a note to Topics. This is useful to first edit the Note until  you are happy with it and then turn into a post with one function key.   

The web interface can be opened to the public, but what's the point for a 3270 BBS system?

Admin Only Panels
-----------------
- LOG command from main menu
- F4 from SDSF
- start and stop components from the MVS Console in Extended Menu

Proxying to another mainframe
-----------------------------
3270 BBS can proxy users to another mainframe if you added it to the tsu.cnf file and if you enable the PROXY server from the tsu.cnf file or from SDSF. This other mainframe can of course also be just another instance of 3270BBS. 

The way to return to the BBS from a remote host is by pressing the **PA3** attention key in your terminal emulator.

TLS terminal access
--------------------
For secure TLS access, you will need certificates and you will have to point to the certificate from tsu.cnf

SSH access
----------
Configure the port at which the SSHD internal server will listen for users. Users must already be registered to be able to use ssh access. The same password is used for both 3270 and ssh access. I don not intend to other other features in ssh mode other than chat and topics, as this is a 3270 BBS after all. 

SDSF Commands
------------
In the SDSF Activity screen, admins can issue the following commands:

`P FTPD            - Stop the FTPD server`  
`S FTPD            - Start the FTPD server` 
Same for PROXY, HTTPD, TN3270TLS, TN3270 (which are self-explanatory)
    
`C U=MOSHIX         - Terminate the session of user MOSHIX`
(sometimes people just leave their terminals open on the BBS and go on vacation (really happened).   
  
`$PJES2,TERM        - Terminate the BBS gracefully ` 
`LOG                - View BBS log. Top/BOT F7/F8 will navigate inside the log view`
`Admin Users Panel`
`Admin Topics Panel`
`Admin Posts Panel`


Backup Strategy
---------------

If you have real users, you need a real backup strategy. If you don't run the tsu.db sqlite database in WAL mode, then just make hourly or daily copies of the database.     
In WAL mode, (which is what I run) I just create an hourly dump of the database into an *.sql file which can very easily be restored. So far, I never lost data.   
  
Technical Implementation Details
--------------------------------

By far the most complex screen is the real time chat because of the number of things it does. It's heavily multi-threaded. If you want to read more about it's implemented, [read this](https://github.com/moshix/BITNETServices/blob/master/forum3270_chat.md) 
  
Final Notes
-----------

The code consits of roughly 40,000 lines of Go language. I wrote it all myself, and if you don't like this app, I am the only one to blame, no one else. 

The library I use is [go3270](https://github.com/racingmars/go3270) by the **genial #racingmars.** 

This BBS application is made available in binary form only, strictly as is. It is provided without warranties of any kind, either express or implied, including, but not limited to, the implied warranties of merchantability and fitness for a particular purpose.

The developers assume no responsibility or liability for any direct, indirect, incidental, or consequential damages that may result from the use, misuse, or inability to use this software. You are using this application at your own risk.

No technical support, updates, or maintenance releases are guaranteed. However, feedback and bug reports may be submitted through the appropriate community channels, and while not promised, improvements may be considered in future builds.

By using this software, you agree to abide by any applicable local, national, or international laws regarding software usage and telecommunications. Unauthorized modification, reverse engineering, or redistribution is strictly prohibited unless explicitly permitted by the license or author.

<img src="3270BBS.jpg">
    
Moshix, August 8, 2025 - Cutchogue
