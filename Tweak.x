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

// LAN preference constants
static NSString *const ksusLANCustomServerIP = @"HostIPAddress";
static NSString *const ksusLANCustomBroadcastMessage = @"CustomBroadcastMessage";

// EXP: ZeroTier preference costants
// static NSString *const ksusLANTweakVPNEnabled = @"TweakVPNEnabled";

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
volatile int runningBroadcast = 0;
static const char *BroadcastMessage = 0;
static char finalBroadcastMessage[100];
const char BROADCAST_PROXY[] = "Proxy";
const char BROADCAST_PROXY_FINAL[] = "~Open~1~";

// Custom broadcast variables
static uint16_t broadcastPort = 0;
static uint16_t customPort = 0;
static uint16_t clientListenPort = 0;
static uint16_t clientReceivePort = 0;

void die(char *sad){
	errno = EHOSTUNREACH;
	perror(sad);
}

void* threadFunc(void* arg) {
	
	//Create struct of Proxy
	struct sockaddr_in udpbroadcast, me;
	int udp_broadcast = socket(AF_INET, SOCK_DGRAM, 0); // to check
	if (udp_broadcast == -1) {
		die("socket");
	}
	int broadcastEnable = 1;
	if ((setsockopt(udp_broadcast,SOL_SOCKET,SO_BROADCAST,&broadcastEnable,sizeof(broadcastEnable)) == -1)) {
		die("setsocket");
	}

	// Set addresses and bind the proxy
	me.sin_family = AF_INET;
	// me.sin_port = htons(48777); // to avoid
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
	// udpbroadcast.sin_addr.s_addr=htonl(INADDR_ANY); // local broadcast, once adjust ifap address.
	 inet_pton(AF_INET, "255.255.255.255", &udpbroadcast.sin_addr); // Set the broadcast IP address

	// Create fake broadcast message
	finalBroadcastMessage[0] = 4;
	finalBroadcastMessage[1] = 2;
	
	if (strlen(BroadcastMessage) > 0){
   		strcpy(finalBroadcastMessage + strlen(finalBroadcastMessage), BroadcastMessage);
    } else { 
        strcpy(finalBroadcastMessage + strlen(finalBroadcastMessage), BROADCAST_PROXY);
    }
	strcpy(finalBroadcastMessage + strlen(finalBroadcastMessage) , BROADCAST_PROXY_FINAL);

	// Create separate while loop thread
	pthread_detach(pthread_self());
	while (1) {
	if (sendto(udp_broadcast, finalBroadcastMessage, strlen(finalBroadcastMessage), 0, (struct sockaddr*)&udpbroadcast, sizeof udpbroadcast) == -1){
	pthread_exit(NULL);
	die("sendto");
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
	rc = pthread_create(&thread_id, NULL, &threadFunc, NULL);
	   if(rc)			/* could not create thread */
    {
		die("rc");
    }
	
}

%group CustomLANServer

%hookf(ssize_t, sendto, int socket, const void *buffer, size_t length, int flags, const struct sockaddr *_destination, socklen_t destinationLength) {
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

	 if (destination.sin_addr.s_addr == inet_addr(addr)) { // need to be change to the right port, still studying about
	
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
		ssize_t ret = %orig(socket, buffer, length, flags, (const struct sockaddr *)&destination, destinationLength);
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
	struct sockaddr_in address = *(struct sockaddr_in *)_addr;
		if(address.sin_port == htons(22023)) {
		address.sin_family = AF_INET;
		address.sin_addr.s_addr = htonl(INADDR_ANY);
		address.sin_port = clientReceivePort;
		int ret=%orig(sockfd, (const struct sockaddr *)&address, addrlen);
		return ret;
	}
		if(address.sin_port == htons(47777)) {
		address.sin_family = AF_INET;
		address.sin_addr.s_addr = htonl(INADDR_ANY);
		address.sin_port = clientListenPort;
		int ret=%orig(sockfd, (const struct sockaddr *)&address, addrlen);
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
	//	ksusLANTweakVPNEnabled : @(NO),
		ksusLANTweakPortEnabled : @(NO),
		ksusLANCustomBroadcastPort : @"47777",
		ksusLANCustomServerPort : @"22023",
		ksusLANCustomListenPort : @"47777",
		ksusLANCustomReceivePort : @"22023"
	}];

	// Initialize the custom server hooks if the user enabled the
	// custom server feature
	NSNumber *LANServerEnabled = [preferences objectForKey:ksusLANTweakLANEnabled];
	if ([LANServerEnabled boolValue]) {
		// Get the hostname
		hostName = [preferences objectForKey:ksusLANCustomServerIP];
		
		// Get the custom broadcast message
		NSString *broadcastmessage = [preferences objectForKey:ksusLANCustomBroadcastMessage];
		const char *Broadcastmsg = [broadcastmessage UTF8String];
		BroadcastMessage = Broadcastmsg;


		// Initialize the hooks
		%init(CustomLANServer);
        Broadcast();
}
	// EXPERIMENTAL NOT WORKING ATM
	//	NSNumber *ExpVPNEnabled = [preferences objectForKey:ksusLANTweakVPNEnabled];
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
