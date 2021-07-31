# ImpostorConfig (LAN)
 ImpostorConfig is an iOS tweak that makes it easy to use custom Among Us servers.
 This is a fork made specifically for iOS 8.x - it allows the player to join a game hosted in LAN.
 
## How to use the Tweak
### Server/Host
 You don't need the tweak if you ONLY hosting, but you have to forward port on your router TCP/UDP to 22023.
 Give your public IP to your guests.

### Guests
 Just activate the tweak from the Setting and input the public IP of the Host.
 Launch Among Us, go to Local and click on "Create Game" and it will connect to the host.
 
## TO DO
#### Broadcast option:
- [x] Create broadcast message
- [ ] Personalised broadcast message
- [ ] VPN option (set IP from Settings)
### Client
- [x] Ensure client can host a game as well
- [ ] Stop broadcast message if client start hosting
- [ ] Option to change port for broadcast listening (binding/recvfrom)
- [ ] Option to change port packets receiving (binding/recvfrom)
- [x] Option to change port packets sending (sendto)
### Host
- [ ] Option to change port for broadcast (sendto)
- [ ] Option to change port packets receiving (binding/recvfrom/sendto)
- [x] Option to change port packets sending (sendto)
