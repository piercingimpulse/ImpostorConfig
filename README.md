# sus LAN
 Previously called ImpostorConfig (LAN), this tweak is for iOS 8.x only and it has been succesfully tested on Among Us 2018.12.24.1
 The base of the project is a forked version of ImpostorConfig and has part of code from Proxom.
 
## How to use the Tweak
### Server/Host
 You don't need the tweak if you ONLY hosting, but you have to forward port on your router TCP/UDP to 22023.
 Give your public IP to your guests.

### Guests
 Just activate the tweak from the Setting and input the public IP of the Host.
 Launch Among Us, go to Local and click on "Create Game" and it will connect to the host.
 
 ### Note
 TBW
 
## TO DO
#### Broadcast option:
- [x] Create broadcast message
- [x] Personalised broadcast message
- [ ] VPN option (set IP from Settings)
#### Client
- [x] Ensure client can host a game as well
- [ ] Stop broadcast message if client start hosting
- [ ] Option to change port for broadcast listening (binding/recvfrom)
- [ ] Option to change port packets receiving (binding/recvfrom)
- [x] Option to change port packets sending (sendto)
#### Host
- [ ] Option to change port for broadcast (sendto)
- [ ] Option to change port packets receiving (binding/recvfrom/sendto)
- [x] Option to change port packets sending (sendto)
