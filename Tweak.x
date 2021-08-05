#import <Foundation/Foundation.h>
#import <Cephei/HBPreferences.h>
#import <sys/types.h>
#import <sys/socket.h>
#import <arpa/inet.h>
#import <netdb.h>
#import <pthread.h>
#import <errno.h>
#import <ifaddrs.h>
#import <stdio.h>

// Main preference costants
static NSString *const ksusLANPreferenceDomain = @"com.piercingimpulse.suslan";
static NSString *const ksusLANTweakLANEnabled = @"TweakLANEnabled";
static NSString *const ksusLANCustomServerIP = @"HostIPAddress";

// Broadcast preference constants
static NSString *const ksusLANCustomBroadcastMessage = @"CustomBroadcastMessage";

// EXP: ZeroTier preference costants
static NSString *const ksusLANTweakVPNEnabled = @"TweakVPNEnabled";
static NSString *const ksusLANTweakVPNInfiniteLoop = @"TweakVPNInfiniteLoop";
static NSString *const ksusLANTweakVPNTimer = @"TweakVPNTimer";
static NSString *const ksusLANTweakVPNIP0 = @"TweakVPNIP0";
static NSString *const ksusLANTweakVPNIP1 = @"TweakVPNIP1";
static NSString *const ksusLANTweakVPNIP2 = @"TweakVPNIP2";
static NSString *const ksusLANTweakVPNIP3 = @"TweakVPNIP3";
static NSString *const ksusLANTweakVPNIP4 = @"TweakVPNIP4";
static NSString *const ksusLANTweakVPNIP5 = @"TweakVPNIP5";
static NSString *const ksusLANTweakVPNIP6 = @"TweakVPNIP6";
static NSString *const ksusLANTweakVPNIP7 = @"TweakVPNIP7";
static NSString *const ksusLANTweakVPNIP8 = @"TweakVPNIP8";
static NSString *const ksusLANTweakVPNIP9 = @"TweakVPNIP9";
static NSString *const ksusLANTweakVPNIP10 = @"TweakVPNIP10";

// EXP: Port changing
static NSString *const ksusLANTweakPortEnabled = @"TweakPortEnabled";
static NSString *const ksusLANCustomBroadcastPort = @"BroadcastPort";
static NSString *const ksusLANCustomServerPort = @"HostPort";
static NSString *const ksusLANCustomListenPort = @"ListenPort";
static NSString *const ksusLANCustomReceivePort = @"ReceivePort";

// HBPreferences
static HBPreferences *preferences;

// Custom server variables
static NSString *hostName = nil;
static struct hostent *hostEntry = NULL;
static pthread_mutex_t mutex = PTHREAD_MUTEX_INITIALIZER;

// Custom broadcast variables
static const char *BroadcastMessage = 0;
static char finalBroadcastMessage[100];
const char BROADCAST_PROXY[] = "Proxy";
const char BROADCAST_PROXY_FINAL[] = "~Open~1~";

//VPN Variable test
static BOOL TweakVPNInfiniteLoop = NO;
static uint16_t TweakVPNTimer = 0;
static const char *VPNIP0 = 0;
static const char *VPNIP1 = 0;
static const char *VPNIP2 = 0;
static const char *VPNIP3 = 0;
static const char *VPNIP4 = 0;
static const char *VPNIP5 = 0;
static const char *VPNIP6 = 0;
static const char *VPNIP7 = 0;
static const char *VPNIP8 = 0;
static const char *VPNIP9 = 0;
static const char *VPNIP10 = 0;

// Custom broadcast variables
static uint16_t broadcastPort = 0;
static uint16_t customPort = 0;
static uint16_t clientListenPort = 0;
static uint16_t clientReceivePort = 0;

void die(char *sad){
	errno = EHOSTUNREACH;
	perror(sad);
}

void* threadFuncBroadcast(void* arg) {
	pthread_detach(pthread_self());
	
	//Create struct of Proxy
	int udp_broadcast = socket(AF_INET, SOCK_DGRAM, 0); // to check
	if (udp_broadcast == -1) {
		die("socket");
	}
	int broadcastEnable = 1;
	if ((setsockopt(udp_broadcast,SOL_SOCKET,SO_BROADCAST,&broadcastEnable,sizeof(broadcastEnable)) == -1)) {
		die("setsocket");
	}

	// Set addresses and bind the proxy
	struct sockaddr_in udpbroadcast, me;
	me.sin_family = AF_INET;
	me.sin_addr.s_addr = htonl(INADDR_ANY);
	if (bind(udp_broadcast,(const struct sockaddr*)&me, sizeof me) == -1) {
	 	die("bind");
	 }

	// This need to be looked again and adjust to a local broadcast
	// rather than global. Global will be great on VPN!
	udpbroadcast.sin_family = AF_INET;
	if (broadcastPort != 0) { // not working atm
	udpbroadcast.sin_port = broadcastPort;
	} else {
	udpbroadcast.sin_port = htons(47777);
	} 
	inet_pton(AF_INET, "255.255.255.255", &udpbroadcast.sin_addr); // Set the broadcast IP address

	// Create fake broadcast message
	finalBroadcastMessage[0] = 4;
	finalBroadcastMessage[1] = 2;
	
	if (strlen(BroadcastMessage) > 0) {
   		strcpy(finalBroadcastMessage + strlen(finalBroadcastMessage), BroadcastMessage);
    } else { 
        strcpy(finalBroadcastMessage + strlen(finalBroadcastMessage), BROADCAST_PROXY);
    }
	strcpy(finalBroadcastMessage + strlen(finalBroadcastMessage) , BROADCAST_PROXY_FINAL);

		while(1){
	sendto(udp_broadcast, finalBroadcastMessage, strlen(finalBroadcastMessage), 0, (struct sockaddr*)&udpbroadcast, sizeof udpbroadcast);
	sleep(1);
}
	close(udp_broadcast);
	return 0;
}


void* threadFuncVPNBroadcast(void* arg) {
	pthread_detach(pthread_self());
	
	//Create struct of Proxy
	int udp_broadcast = socket(AF_INET, SOCK_DGRAM, 0); // to check
	if (udp_broadcast == -1) {
		die("socket");
	}
	int broadcastEnable = 1;
	if ((setsockopt(udp_broadcast,SOL_SOCKET,SO_BROADCAST,&broadcastEnable,sizeof(broadcastEnable)) == -1)) {
		die("setsocket");
	}

	// Set addresses and bind the proxy
	struct sockaddr_in udpbroadcast, me, client0, client1, client2, client3, client4, client5, client6, client7, client8, client9, client10;
	me.sin_family = AF_INET;
	me.sin_addr.s_addr = htonl(INADDR_ANY);
	if (bind(udp_broadcast,(const struct sockaddr*)&me, sizeof me) == -1) {
	 	die("bind");
	 }

	udpbroadcast.sin_family = AF_INET;
	if (broadcastPort != 0) { // not working atm
	udpbroadcast.sin_port = broadcastPort;
	} else {
	udpbroadcast.sin_port = htons(47777);
	} 
	inet_pton(AF_INET, "255.255.255.255", &udpbroadcast.sin_addr); // Set the broadcast IP address

	sendto(udp_broadcast, finalBroadcastMessage, strlen(finalBroadcastMessage), 0, (struct sockaddr*)&udpbroadcast, sizeof udpbroadcast);

	// VPN option
	client0.sin_family = AF_INET;
	client0.sin_port = htons(47777);
	inet_pton(AF_INET, VPNIP0, &client0.sin_addr);

	client1.sin_family = AF_INET;
	client1.sin_port = htons(47777);
	inet_pton(AF_INET, VPNIP1, &client1.sin_addr);

	client2.sin_family = AF_INET;
	client2.sin_port = htons(47777);
	inet_pton(AF_INET, VPNIP2, &client2.sin_addr);

	client3.sin_family = AF_INET;
	client3.sin_port = htons(47777);
	inet_pton(AF_INET, VPNIP3, &client3.sin_addr);

	client4.sin_family = AF_INET;
	client4.sin_port = htons(47777);
	inet_pton(AF_INET, VPNIP4, &client4.sin_addr);

	client5.sin_family = AF_INET;
	client5.sin_port = htons(47777);
	inet_pton(AF_INET, VPNIP5, &client5.sin_addr);

	client6.sin_family = AF_INET;
	client6.sin_port = htons(47777);
	inet_pton(AF_INET, VPNIP6, &client6.sin_addr);

	client7.sin_family = AF_INET;
	client7.sin_port = htons(47777);
	inet_pton(AF_INET, VPNIP7, &client7.sin_addr);

	client8.sin_family = AF_INET;
	client8.sin_port = htons(47777);
	inet_pton(AF_INET, VPNIP8, &client8.sin_addr);

	client9.sin_family = AF_INET;
	client9.sin_port = htons(47777);
	inet_pton(AF_INET, VPNIP9, &client9.sin_addr);

	client10.sin_family = AF_INET;
	client10.sin_port = htons(47777);
	inet_pton(AF_INET, VPNIP10, &client10.sin_addr);

	// Create fake broadcast message
	finalBroadcastMessage[0] = 4;
	finalBroadcastMessage[1] = 2;
	
	if (strlen(BroadcastMessage) > 0) {
   		strcpy(finalBroadcastMessage + strlen(finalBroadcastMessage), BroadcastMessage);
    } else { 
        strcpy(finalBroadcastMessage + strlen(finalBroadcastMessage), BROADCAST_PROXY);
    }
	strcpy(finalBroadcastMessage + strlen(finalBroadcastMessage) , BROADCAST_PROXY_FINAL);
	int i = 0;
		while (i <= TweakVPNTimer) {
		sendto(udp_broadcast, finalBroadcastMessage, strlen(finalBroadcastMessage), 0, (struct sockaddr*)&client0, sizeof client0);
		sendto(udp_broadcast, finalBroadcastMessage, strlen(finalBroadcastMessage), 0, (struct sockaddr*)&client1, sizeof client1);
		sendto(udp_broadcast, finalBroadcastMessage, strlen(finalBroadcastMessage), 0, (struct sockaddr*)&client2, sizeof client2);
		sendto(udp_broadcast, finalBroadcastMessage, strlen(finalBroadcastMessage), 0, (struct sockaddr*)&client3, sizeof client3);
		sendto(udp_broadcast, finalBroadcastMessage, strlen(finalBroadcastMessage), 0, (struct sockaddr*)&client4, sizeof client4);
		sendto(udp_broadcast, finalBroadcastMessage, strlen(finalBroadcastMessage), 0, (struct sockaddr*)&client5, sizeof client5);
		sendto(udp_broadcast, finalBroadcastMessage, strlen(finalBroadcastMessage), 0, (struct sockaddr*)&client6, sizeof client6);	
		sendto(udp_broadcast, finalBroadcastMessage, strlen(finalBroadcastMessage), 0, (struct sockaddr*)&client7, sizeof client7);
		sendto(udp_broadcast, finalBroadcastMessage, strlen(finalBroadcastMessage), 0, (struct sockaddr*)&client8, sizeof client8);
		sendto(udp_broadcast, finalBroadcastMessage, strlen(finalBroadcastMessage), 0, (struct sockaddr*)&client9, sizeof client9);
		sendto(udp_broadcast, finalBroadcastMessage, strlen(finalBroadcastMessage), 0, (struct sockaddr*)&client10, sizeof client10);
		if (TweakVPNInfiniteLoop == NO) { 
			++i; 
			}
	sleep(1);
	}
	close(udp_broadcast);
	pthread_exit(NULL);	
	return 0;
	}

void Broadcast() {
	int rc;
	pthread_t thread_id;
	rc = pthread_create(&thread_id, NULL, &threadFuncBroadcast, NULL);
	   if(rc)			/* could not create thread */
    {
		die("rc");
    }
	
}
void BroadcastVPN() {
	int rc;
	pthread_t thread_id;
	rc = pthread_create(&thread_id, NULL, &threadFuncVPNBroadcast, NULL);
		   if(rc)			/* could not create thread */
    {
		die("rc");
    }
	
}


%group CustomVPNBroadcast

%hookf(ssize_t, sendto, int sockfd, const void *buffer, size_t length, int flags, struct sockaddr *_destination, socklen_t destinationLength) {
	if (destinationLength != sizeof(struct sockaddr_in)) return %orig;
	struct sockaddr_in destination = *(struct sockaddr_in *)_destination;
	if (destination.sin_addr.s_addr == htonl(INADDR_BROADCAST)) {
	// if (destination.sin_port == htons(47777)) {
	inet_pton(AF_INET, VPNIP0, &destination.sin_addr);
	ssize_t ret = %orig(sockfd, buffer, length, flags, (struct sockaddr *)&destination, destinationLength);
	return ret;
	}
	return %orig;
 }

%end

%group CustomLANServer

%hookf(ssize_t, sendto, int sockfd, const void *buffer, size_t length, int flags, const struct sockaddr *_destination, socklen_t destinationLength) {
	// Check if the type of the destination structure is sockaddr_in
	if (destinationLength != sizeof(struct sockaddr_in)) return %orig;
	struct sockaddr_in destination = *(struct sockaddr_in *)_destination;
    struct ifaddrs *ifap, *ifa;
    struct sockaddr_in *sa;
    char *addr;

    getifaddrs (&ifap);
    for (ifa = ifap; ifa; ifa = ifa->ifa_next) {
        if (ifa->ifa_addr && ifa->ifa_addr->sa_family==AF_INET) {
            sa = (struct sockaddr_in *) ifa->ifa_addr;
            addr = inet_ntoa(sa->sin_addr);
            printf("Interface: %s\tAddress: %s\n", ifa->ifa_name, addr);
        }
    }

	// Check if the destination is an Among Us server
	if (destination.sin_family != AF_INET) return %orig;
	if (destination.sin_port != htons(22023)) return %orig;
	if (destination.sin_addr.s_addr == inet_addr("127.0.0.1")) return %orig;

	if (destination.sin_addr.s_addr == inet_addr(addr)) { // need to be change to the right ip, still studying about
	
	// Find the IP address of the host specified by the user
	BOOL hostEntryExists = NO;
	pthread_mutex_lock(&mutex);
	if (!hostEntry) {
		hostEntry = gethostbyname(hostName.UTF8String);
	}
	if (hostEntry) {
		hostEntryExists = YES;
	}
	pthread_mutex_unlock(&mutex);

	// If the IP address was found, send the packet to it. If not,
	// fake an error by setting errno to EHOSTUNREACH and returning
	// -1.
	if (hostEntryExists) {
		if (customPort != 0) {
		destination.sin_port = customPort;
		} else {
		destination.sin_port = htons(22023);
		}
		bcopy(hostEntry->h_addr, &destination.sin_addr.s_addr, hostEntry->h_length);
		ssize_t ret = %orig(sockfd, buffer, length, flags, (const struct sockaddr *)&destination, destinationLength);
		return ret;
	}
	errno = EHOSTUNREACH;
	return -1;
	}
	return %orig;
}
%end

%group ExpPort

%hookf(int, bind, int sockfd, const struct sockaddr *_addr, socklen_t addrlen) {
	struct sockaddr_in addr = *(struct sockaddr_in *)_addr;
		if(addr.sin_port == htons(22023)) {
		addr.sin_family = AF_INET;
		addr.sin_addr.s_addr = htonl(INADDR_ANY);
		addr.sin_port = clientReceivePort;
		int ret=%orig(sockfd, (const struct sockaddr *)&addr, addrlen);
		return ret;
	}
		if(addr.sin_port == htons(47777)) {
		addr.sin_family = AF_INET;
		addr.sin_addr.s_addr = htonl(INADDR_ANY);
		addr.sin_port = clientListenPort;
		int ret=%orig(sockfd, (const struct sockaddr *)&addr, addrlen);
		return ret;
	}
	return %orig;
}

%end

%ctor {
	// Initialize HBPreferences
	preferences = [[HBPreferences alloc] initWithIdentifier:ksusLANPreferenceDomain];
	[preferences registerDefaults:@{
		ksusLANTweakLANEnabled : @(NO),
		ksusLANCustomServerIP : @"127.0.0.1",
		ksusLANCustomBroadcastMessage : @"Proxy",
		ksusLANTweakVPNEnabled : @(NO),
		ksusLANTweakVPNTimer : @"15",
		ksusLANTweakVPNInfiniteLoop : @(NO),
		ksusLANTweakVPNIP0 : @"255.255.255.255",
		ksusLANTweakVPNIP1 : @"",
		ksusLANTweakVPNIP2 : @"",
		ksusLANTweakVPNIP3 : @"",
		ksusLANTweakVPNIP4 : @"",
		ksusLANTweakVPNIP5 : @"",
		ksusLANTweakVPNIP6 : @"",
		ksusLANTweakVPNIP7 : @"",
		ksusLANTweakVPNIP8 : @"",
		ksusLANTweakVPNIP9 : @"",
		ksusLANTweakVPNIP10 : @"",
		ksusLANTweakPortEnabled : @(NO),
		ksusLANCustomBroadcastPort : @"47777",
		ksusLANCustomServerPort : @"22023",
		ksusLANCustomListenPort : @"47777",
		ksusLANCustomReceivePort : @"22023"
	}];

	// Initialize the custom server hooks if the user enabled the
	// custom server feature
	
	// Get the custom broadcast message
	NSString *broadcastmessage = [preferences objectForKey:ksusLANCustomBroadcastMessage];
	const char *Broadcastmsg = [broadcastmessage UTF8String];
	BroadcastMessage = Broadcastmsg;

	NSNumber *LANServerEnabled = [preferences objectForKey:ksusLANTweakLANEnabled];
	if ([LANServerEnabled boolValue]) {
		// Get the hostname
		hostName = [preferences objectForKey:ksusLANCustomServerIP];

		// Initialize the hooks
		%init(CustomLANServer);
		Broadcast();
}

	// EXPERIMENTAL NOT WORKING ATM
		NSNumber *VPNBroadcast = [preferences objectForKey:ksusLANTweakVPNEnabled];
	// Use over ZeroTier
		if ([VPNBroadcast boolValue]) {
		NSNumber *VPNTimerNoLoop = [preferences objectForKey:ksusLANTweakVPNInfiniteLoop];
		TweakVPNInfiniteLoop = [VPNTimerNoLoop boolValue];
			if ([VPNTimerNoLoop boolValue]) {
		NSString *VPNTimer = [preferences objectForKey:ksusLANTweakVPNTimer];
		int VPNTimermsg = [VPNTimer intValue];
		TweakVPNTimer = (uint16_t)VPNTimermsg;
			}
		NSString *vpnip0 = [preferences objectForKey:ksusLANTweakVPNIP0];
		const char *vpnipmsg0 = [vpnip0 UTF8String];
		VPNIP0 = vpnipmsg0;
		NSString *vpnip1 = [preferences objectForKey:ksusLANTweakVPNIP1];
		const char *vpnipmsg1 = [vpnip1 UTF8String];
		VPNIP1 = vpnipmsg1;
		NSString *vpnip2 = [preferences objectForKey:ksusLANTweakVPNIP2];
		const char *vpnipmsg2 = [vpnip2 UTF8String];
		VPNIP2 = vpnipmsg2;
		NSString *vpnip3 = [preferences objectForKey:ksusLANTweakVPNIP3];
		const char *vpnipmsg3 = [vpnip3 UTF8String];
		VPNIP3 = vpnipmsg3;
		NSString *vpnip4 = [preferences objectForKey:ksusLANTweakVPNIP4];
		const char *vpnipmsg4 = [vpnip4 UTF8String];
		VPNIP4 = vpnipmsg4;
		NSString *vpnip5 = [preferences objectForKey:ksusLANTweakVPNIP5];
		const char *vpnipmsg5 = [vpnip5 UTF8String];
		VPNIP5 = vpnipmsg5;
		NSString *vpnip6 = [preferences objectForKey:ksusLANTweakVPNIP6];
		const char *vpnipmsg6 = [vpnip6 UTF8String];
		VPNIP6 = vpnipmsg6;
		NSString *vpnip7 = [preferences objectForKey:ksusLANTweakVPNIP7];
		const char *vpnipmsg7 = [vpnip7 UTF8String];
		VPNIP7 = vpnipmsg7;
		NSString *vpnip8 = [preferences objectForKey:ksusLANTweakVPNIP8];
		const char *vpnipmsg8 = [vpnip8 UTF8String];
		VPNIP8 = vpnipmsg8;
		NSString *vpnip9 = [preferences objectForKey:ksusLANTweakVPNIP9];
		const char *vpnipmsg9 = [vpnip9 UTF8String];
		VPNIP9 = vpnipmsg9;
		NSString *vpnip10 = [preferences objectForKey:ksusLANTweakVPNIP10];
		const char *vpnipmsg10 = [vpnip10 UTF8String];
		VPNIP10 = vpnipmsg10;
		%init(CustomVPNBroadcast);
		BroadcastVPN();

}
		NSNumber *ExpServerEnabled = [preferences objectForKey:ksusLANTweakPortEnabled];
	// Get specified port
		if ([ExpServerEnabled boolValue]) {
		NSString *broadcastport = [preferences objectForKey:ksusLANCustomBroadcastPort];
		NSString *serverport = [preferences objectForKey:ksusLANCustomServerPort];
		NSString *listenport = [preferences objectForKey:ksusLANCustomListenPort];
		NSString *receiveport = [preferences objectForKey:ksusLANCustomReceivePort];
		int rawPort1 = [broadcastport intValue];
				if ((rawPort1 < 0x0000) || (rawPort1 > 0xFFFF)) {
			// The port must be an unsigned 16-bit value!
			[NSException raise:NSInvalidArgumentException format:@"[susLAN] Invalid port: %@", broadcastport];
		 }
		int rawPort2 = [serverport intValue];
				if ((rawPort2 < 0x0000) || (rawPort2 > 0xFFFF)) {
			// The port must be an unsigned 16-bit value!
			[NSException raise:NSInvalidArgumentException format:@"[susLAN] Invalid port: %@", serverport];
		 }
		int rawPort3 = [listenport intValue];
				if ((rawPort3 < 0x0000) || (rawPort3 > 0xFFFF)) {
			// The port must be an unsigned 16-bit value!
			[NSException raise:NSInvalidArgumentException format:@"[susLAN] Invalid port: %@", listenport];
		 }
		int rawPort4 = [receiveport intValue];
		if ((rawPort4 < 0x0000) || (rawPort4 > 0xFFFF)) {
			// The port must be an unsigned 16-bit value!
			[NSException raise:NSInvalidArgumentException format:@"[susLAN] Invalid port: %@", receiveport];
		 }
		// Convert the specified port to the network byte order
		broadcastPort = htons((uint16_t)rawPort1);
		customPort = htons((uint16_t)rawPort2);
		clientListenPort = htons((uint16_t)rawPort3);
		clientReceivePort = htons((uint16_t)rawPort4);

		// Initialize the hooks
		%init(ExpPort);
}
}