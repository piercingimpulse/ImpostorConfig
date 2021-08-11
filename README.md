# sus LAN
Tired of waiting in a lobby with stranger? Your device is too old to play online? Want to feel the power of be your own mobile game server? Then sus LAN is the answer for you!
**NOTE:** This tweak will work best with a VPN such as ZeroTier, but can be used with your network once the ports 22023 and 47777 (UDP/TCP) are open and linked to the device using the tweak. Can't be used for now only with cellular data or hotspot provided by cellular data.

## Compatibility
Tested on:
Device | bit |iOS Version | Among Us Version | Result
------ | --- |----------- | ---------------- | ------
iPad3,4 (Retina) | 32 | 8.4.1 | 2018.12.24.1 | **successful**;
iPad3,4 (Retina) | 32 | 10.3.3* | 2019.10.10.0 | **_unsuccessful_**
iPod7,1 (7th gen) | 64 | 12.5.4 | 2021.3.5.0 | **succesful**

*_this need more testing as I used a CoolBooter version, so could be that why does not work._

 
## How does it work?
sus LAN exploits the internal server called InnerNet.
While studying [ImpostorConfig](https://github.com/enbyautumn/ImpostorConfig), I've realised that also the "Local" option was affected by the tweak. From that, I've just looked at other project (such us [Proxom](https://github.com/Tudor3510/AndroidProxom) and [AmongUsP2P](https://github.com/InvoxiPlayGames/AmongUsP2P)) and realised that:
1. The internal server while host send a message to port 47777 on the broadcast address and listen on port 22023 for answer;
2. The internal server while client listen on port 47777 and send answer on the the host ip on port 22022.
3. The first bytes of the broadcast message are 0x02 and 0x04 ALWAYS, followed by the user name and ~Open~1~

sus LAN hijacks the sendto() function to forward the UDP packets to a choosen IP, fake broadcast message on your network to be able to join an outside host or even broadcast fake message to 10 clients.

## How to use the Tweak
### Mobile Server/Host
You don't need the tweak necesserily, but if not using a VPN you have to forward port 22023 on your router and give your public IP address to your guests. In case you want to keep it private, think about searching on Google a service such as NoIP.
If you are using a VPN (like ZeroTier), you can broadcast a (customisable) proxy message to your 10 clients by using their VPN IP. It is suggest to use the timer instead of a infinite loop for the broadcast. *(still beta testing)*

### Guests
 Use the Client proxy option and type the IP/Domain of the host. The tweak will then broadcast a (customisable) proxy message to the broadcast address 255.255.255.255 to allow you to join the host.
 
 ### Thanks
* [Randy-420](https://github.com/Randy-420/) ~ got me into development;
* [InvoxiPlayGames](https://github.com/InvoxiPlayGames/) ~ for inspiration;
* [Tudor3510](https://github.com/Tudor3510/) & [Luigi Auriemma](https://aluigi.altervista.org/mytoolz.htm) ~ for their projects "Proxom" and "sudppipe" that have largerly helped the devolping of sus LAN.

## CHANGELOG
### 2.0
- Adjust heartbeat (still need more feedback please)
- The whole setting panel has got a whole restyle:
  - Settings now are less crowded, when toggle the option, it will show/hide the options
  - Unified broadcast option to ensure you can use a time also when tunneling
  - If tunnel active then the server is going to be set OFF and vice versa
  - Both server and broadcast options now are "connected" and activate/deactivate at the same time.
  - Errors shown if using more than 15 clients or less than 0 (lol)
  - Errors using wrong port number (still working on this feature anyway)
  - Add version number and GitHub link page.

#### 1.2.1a
- Introduced a rudimental heartbeat system to avoid VPN being disconnected and broadcast storm;
- Adjusted broadcast timer (still not very precise);
- Increase clients to 15
- Introduced number of clients in the settings always to avoid broadcast storm
- Introduced workaround and improved stability of tunnel by input manually the client IP in case does not work automatically

#### 1.2.0
- VPN proxy server
- Improved stability with multithread

#### 1.1.1a
- Fixed bug of client unable to host
- Ability to broadcast fake message to join custom host
- Personalised proxy message
- New name and icon
- Introduction of custom port and VPN broadcast

#### 1.0.1a
- Inital release: client can join custom host, but can't host
 
## TO DO & KNOWN ISSUES
#### Broadcast option:
- [x] Create broadcast message
- [x] Personalised broadcast message
- [ ] Copy name from binary host file (optional/advanced)
#### Client
- [x] Ensure client can host a game as well
- [x] Workaround for VPN (using client IP in prefs)
- [x] Stop fake broadcast message if client choose to host a game (workaround with timer loop)
- [ ] Ensure tunnel works on cellular data
#### Host
- [x] Send fake broadcast message via VPN
- [x] Replace loop/timer with hearthbeat message
#### Preferences Panel
- [x] Insert all option (also experimental one)
- [ ] Generate errors
- [ ] Translate settings to different languages
- [ ] Create a cuter icon
- [ ] Ping test (optional)
