# sus LAN
Tired of waiting in a lobby with stranger? Your device is too old to play online? Want to feel the power of be your own mobile game server? Then sus LAN is the answer for you!

## Compatibility
Tested on:
iPad3,4 (Retina - 32bit) iOS 8.4.1 - Among Us 2018.12.24.1 - successful;
iPad3,4 (Retina - 32bit) iOS 10.3.3 (coolbooter) - Among Us 2019.10.10.0 - unsuccessful;
iPod7,1 (7th gen) iOS 12.5.4 - succesful;

 
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
#### 1.2.0
- VPN/Offline proxy server
- Improved stability with multithread

#### 1.1.1a
- Fixed bug of client unable to host
- Ability to broadcast fake message to join custom host
- Personalised proxy message
- New name and icon
- Introduction of custom port and VPN broadcast (

#### 1.0.1a
- Inital release: client can join custom host, but can't host.
 
## TO DO
#### Broadcast option:
- [x] Create broadcast message
- [x] Personalised broadcast message
#### Client
- [x] Ensure client can host a game as well
- [ ] Stop fake broadcast message if client choose to host a game
#### Host
- [x] Send fake broadcast message via VPN
- [ ] Replace loop/timer with hearthbeat messages (host)
#### General
- [ ] Improve setting menu with error messages
- [ ] Translate settings to different languages
- [ ] Create a cuter icon
