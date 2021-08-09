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
#import <stdlib.h>
#import <netinet/in.h>
#import <string.h>
#import <unistd.h>
#import <sys/ioctl.h>
#import <net/if.h>

// Main preference costants
static NSString *const ksusLANPreferenceDomain = @"com.piercingimpulse.suslan";
static NSString *const ksusLANTweakEnabled = @"TweaksusEnabled";
static NSString *const ksusLANTweakLANEnabled = @"TweakLANEnabled";
static NSString *const ksusLANCustomServerIP = @"HostIPAddress";
static NSString *const ksusLANCustomClientIP = @"ClientIPAddress";


// Broadcast preference constants
static NSString *const ksusLANCustomBroadcastMessage = @"CustomBroadcastMessage";
static NSString *const ksusLANTGlobalBroadcast = @"GlobalBroadcast";

// Host preference costants
static NSString *const ksusLANTweakVPNEnabled = @"TweakVPNEnabled";
static NSString *const ksusLANTweakVPNInfiniteLoop = @"TweakVPNInfiniteLoop";
static NSString *const ksusLANTweakVPNTimer = @"TweakVPNTimer";
static NSString *const ksusLANTweakVPNClientNumber = @"TweakVPNClientNumber";
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
static NSString *const ksusLANTweakVPNIP11 = @"TweakVPNIP11";
static NSString *const ksusLANTweakVPNIP12 = @"TweakVPNIP12";
static NSString *const ksusLANTweakVPNIP13 = @"TweakVPNIP13";
static NSString *const ksusLANTweakVPNIP14 = @"TweakVPNIP14";
static NSString *const ksusLANTweakVPNIP15 = @"TweakVPNIP15";

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
static NSString *clientName = nil;
static struct hostent *hostEntry = NULL;
const char *manualAddr = 0;
static pthread_mutex_t mutex = PTHREAD_MUTEX_INITIALIZER;

// Custom broadcast variables
static const char *GlobalBroadcast = 0;
static const char *BroadcastMessage = 0;
static char finalBroadcastMessage[100];
const char BROADCAST_PROXY[] = "Proxy";
const char BROADCAST_PROXY_FINAL[] = "~Open~1~";
static int startBroadcast = 0;
static int timerBroadcast = 20;

//VPN Variable test
static BOOL TweakVPNInfiniteLoop = NO;
static uint16_t TweakVPNTimer = 0;
static int TweakVPNClientNumber = 0;
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
static const char *VPNIP11 = 0;
static const char *VPNIP12 = 0;
static const char *VPNIP13 = 0;
static const char *VPNIP14 = 0;
static const char *VPNIP15 = 0;

// Custom broadcast variables
static uint16_t broadcastPort = 0;
static uint16_t customPort = 0;
static uint16_t clientListenPort = 0;
static uint16_t clientReceivePort = 0;

// Error void
void die(char *Error){
	errno = EHOSTUNREACH;
	perror(Error);
}

// Create fake broadcast message variables
void FakeBroadcastMsg() {
	finalBroadcastMessage[0] = 4;
	finalBroadcastMessage[1] = 2;
	
	if (strlen(BroadcastMessage) > 0) {
   		strcpy(finalBroadcastMessage + strlen(finalBroadcastMessage), BroadcastMessage);
    } else { 
        strcpy(finalBroadcastMessage + strlen(finalBroadcastMessage), BROADCAST_PROXY);
    }
	strcpy(finalBroadcastMessage + strlen(finalBroadcastMessage) , BROADCAST_PROXY_FINAL);
}

// Broadcast Client Proxy
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
	if (broadcastPort != 0) {
		udpbroadcast.sin_port = broadcastPort;
	} else {
		udpbroadcast.sin_port = htons(47777);
	}
	if (strlen(GlobalBroadcast) != 0) {
		inet_pton(AF_INET, GlobalBroadcast, &udpbroadcast.sin_addr);
	} else {
	 	inet_pton(AF_INET, "255.255.255.255", &udpbroadcast.sin_addr);
	}
	
	FakeBroadcastMsg();

	while(startBroadcast <= timerBroadcast){
	if(sendto(udp_broadcast, finalBroadcastMessage, strlen(finalBroadcastMessage), 0, (struct sockaddr*)&udpbroadcast, sizeof udpbroadcast) == -1) {
		die("sendto()");
	}
	++startBroadcast;
		if (startBroadcast == timerBroadcast) {
			startBroadcast = 1;
			sleep(1);
		}
	}
	close(udp_broadcast);
	return 0;
	pthread_exit(NULL);	
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
	struct sockaddr_in me, client1, client2, client3, client4, client5, client6, client7, client8, client9, client10, client11, client12, client13, client14, client15;
	me.sin_family = AF_INET;
	me.sin_addr.s_addr = htonl(INADDR_ANY);
	if (bind(udp_broadcast,(const struct sockaddr*)&me, sizeof me) == -1) {
	 	die("bind");
	 }
	
	// VPN option
	client1.sin_family = AF_INET;
	if (broadcastPort != 0) {
		client1.sin_port = broadcastPort;
	} else {
		client1.sin_port = htons(47777);
	} 
	inet_pton(AF_INET, VPNIP1, &client1.sin_addr);

	client2.sin_family = AF_INET;
	if (broadcastPort != 0) {
		client2.sin_port = broadcastPort;
	} else {
		client2.sin_port = htons(47777);
	} 
	inet_pton(AF_INET, VPNIP2, &client2.sin_addr);

	client3.sin_family = AF_INET;
	if (broadcastPort != 0) {
		client3.sin_port = broadcastPort;
	} else {
		client3.sin_port = htons(47777);
	} 
	inet_pton(AF_INET, VPNIP3, &client3.sin_addr);

	client4.sin_family = AF_INET;
	if (broadcastPort != 0) {
		client4.sin_port = broadcastPort;
	} else {
		client4.sin_port = htons(47777);
	} 
	inet_pton(AF_INET, VPNIP4, &client4.sin_addr);

	client5.sin_family = AF_INET;
	if (broadcastPort != 0) {
		client5.sin_port = broadcastPort;
	} else {
		client5.sin_port = htons(47777);
	} 
	inet_pton(AF_INET, VPNIP5, &client5.sin_addr);

	client6.sin_family = AF_INET;
	if (broadcastPort != 0) {
		client6.sin_port = broadcastPort;
	} else {
		client6.sin_port = htons(47777);
	} 
	inet_pton(AF_INET, VPNIP6, &client6.sin_addr);

	client7.sin_family = AF_INET;
	if (broadcastPort != 0) {
		client7.sin_port = broadcastPort;
	} else {
		client7.sin_port = htons(47777);
	} 
	inet_pton(AF_INET, VPNIP7, &client7.sin_addr);

	client8.sin_family = AF_INET;
	if (broadcastPort != 0) {
		client8.sin_port = broadcastPort;
	} else {
		client8.sin_port = htons(47777);
	} 
	inet_pton(AF_INET, VPNIP8, &client8.sin_addr);

	client9.sin_family = AF_INET;
	if (broadcastPort != 0) {
		client9.sin_port = broadcastPort;
	} else {
		client9.sin_port = htons(47777);
	} 
	inet_pton(AF_INET, VPNIP9, &client9.sin_addr);

	client10.sin_family = AF_INET;
	if (broadcastPort != 0) {
		client10.sin_port = broadcastPort;
	} else {
		client10.sin_port = htons(47777);
	} 
	inet_pton(AF_INET, VPNIP10, &client10.sin_addr);

	client11.sin_family = AF_INET;
	if (broadcastPort != 0) {
		client11.sin_port = broadcastPort;
	} else {
		client11.sin_port = htons(47777);
	} 
	inet_pton(AF_INET, VPNIP11, &client11.sin_addr);

	client12.sin_family = AF_INET;
	if (broadcastPort != 0) {
		client12.sin_port = broadcastPort;
	} else {
		client12.sin_port = htons(47777);
	} 
	inet_pton(AF_INET, VPNIP12, &client12.sin_addr);

	client13.sin_family = AF_INET;
	if (broadcastPort != 0) {
		client13.sin_port = broadcastPort;
	} else {
		client13.sin_port = htons(47777);
	} 
	inet_pton(AF_INET, VPNIP13, &client13.sin_addr);

	client14.sin_family = AF_INET;
	if (broadcastPort != 0) {
		client14.sin_port = broadcastPort;
	} else {
		client14.sin_port = htons(47777);
	} 
	inet_pton(AF_INET, VPNIP14, &client14.sin_addr);

	client15.sin_family = AF_INET;
	if (broadcastPort != 0) {
		client15.sin_port = broadcastPort;
	} else {
		client15.sin_port = htons(47777);
	} 
	inet_pton(AF_INET, VPNIP15, &client15.sin_addr);

	FakeBroadcastMsg();

	 	while (startBroadcast <= TweakVPNTimer) {
		if (TweakVPNClientNumber >= 1){ 
			if(sendto(udp_broadcast, finalBroadcastMessage, strlen(finalBroadcastMessage), 0, (struct sockaddr*)&client1, sizeof client1) == -1) {
				die("sendto1()");
				continue;
			}
		}
		if (TweakVPNClientNumber >= 2){ 
			if(sendto(udp_broadcast, finalBroadcastMessage, strlen(finalBroadcastMessage), 0, (struct sockaddr*)&client2, sizeof client2) == -1) {
				die("sendto2()");
				continue;
			}
		}
		if (TweakVPNClientNumber >= 3){ 
			if(sendto(udp_broadcast, finalBroadcastMessage, strlen(finalBroadcastMessage), 0, (struct sockaddr*)&client3, sizeof client3) == -1) {
				die("sendto3()");
				continue;
			}
		}
		if (TweakVPNClientNumber >= 4){ 
			if(sendto(udp_broadcast, finalBroadcastMessage, strlen(finalBroadcastMessage), 0, (struct sockaddr*)&client4, sizeof client4) == -1) {
				die("sendto4()");
				continue;
			}
		}
		if (TweakVPNClientNumber >= 5){ 
			if(sendto(udp_broadcast, finalBroadcastMessage, strlen(finalBroadcastMessage), 0, (struct sockaddr*)&client5, sizeof client5) == -1) {
				die("sendto5()");
				continue;
			}
		}
		if (TweakVPNClientNumber >= 6){ 
			if(sendto(udp_broadcast, finalBroadcastMessage, strlen(finalBroadcastMessage), 0, (struct sockaddr*)&client6, sizeof client6) == -1) {
				die("sendto6()");
				continue;
			}
		}
		if (TweakVPNClientNumber >= 7){ 
			if(sendto(udp_broadcast, finalBroadcastMessage, strlen(finalBroadcastMessage), 0, (struct sockaddr*)&client7, sizeof client7) == -1) {
				die("sendto7()");
				continue;
			}
		}
		if (TweakVPNClientNumber >= 8){ 
			if(sendto(udp_broadcast, finalBroadcastMessage, strlen(finalBroadcastMessage), 0, (struct sockaddr*)&client8, sizeof client8) == -1) {
				die("sendto8()");
				continue;
			}
		}
		if (TweakVPNClientNumber >= 9){ 
			if(sendto(udp_broadcast, finalBroadcastMessage, strlen(finalBroadcastMessage), 0, (struct sockaddr*)&client9, sizeof client9) == -1) {
				die("sendto9()");
				continue;
			}
		}
		if (TweakVPNClientNumber >= 10){ 
			if(sendto(udp_broadcast, finalBroadcastMessage, strlen(finalBroadcastMessage), 0, (struct sockaddr*)&client10, sizeof client10) == -1) {
				die("sendto10()");
				continue;
			}
		}
		if (TweakVPNClientNumber >= 11){ 
			if(sendto(udp_broadcast, finalBroadcastMessage, strlen(finalBroadcastMessage), 0, (struct sockaddr*)&client11, sizeof client11) == -1) {
				die("sendto11()");
				continue;
			}
		}
		if (TweakVPNClientNumber >= 12){ 
			if(sendto(udp_broadcast, finalBroadcastMessage, strlen(finalBroadcastMessage), 0, (struct sockaddr*)&client12, sizeof client12) == -1) {
				die("sendto12()");
				continue;
			}
		}
		if (TweakVPNClientNumber >= 13){ 
			if(sendto(udp_broadcast, finalBroadcastMessage, strlen(finalBroadcastMessage), 0, (struct sockaddr*)&client13, sizeof client13) == -1) {
				die("sendto13()");
				continue;
			}
		}
		if (TweakVPNClientNumber >= 14){ 
			if(sendto(udp_broadcast, finalBroadcastMessage, strlen(finalBroadcastMessage), 0, (struct sockaddr*)&client14, sizeof client14) == -1) {
				die("sendto14()");
				continue;
			}
		}
		if (TweakVPNClientNumber >= 15){ 
			if(sendto(udp_broadcast, finalBroadcastMessage, strlen(finalBroadcastMessage), 0, (struct sockaddr*)&client15, sizeof client15) == -1) {
				die("sendto15()");
				continue;
			}
		}
		if (TweakVPNInfiniteLoop == NO) {
			++startBroadcast;
			if (timerBroadcast <= TweakVPNTimer && startBroadcast == timerBroadcast) {
				sleep(2);
			}
					if (startBroadcast == TweakVPNTimer) break;
				}
			sleep(2);
		}
	close(udp_broadcast);
	return 0;
	pthread_exit(NULL);	
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
	if (strlen(GlobalBroadcast) > 0) {
		inet_pton(AF_INET, GlobalBroadcast, &destination.sin_addr);
	} else {
		inet_pton(AF_INET, "255.255.255.255", &destination.sin_addr);
	}
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

	// Check if the destination is an Among Us server
	if (destination.sin_family != AF_INET) return %orig;
	if (destination.sin_port != htons(22023)) return %orig;
	if (destination.sin_addr.s_addr == inet_addr("127.0.0.1")) return %orig;

    struct ifaddrs *ifap, *ifa;
    struct sockaddr_in *sa;
    char *addr;

    getifaddrs (&ifap);
    for (ifa = ifap; ifa; ifa = ifa->ifa_next) {
        if (ifa->ifa_addr && ifa->ifa_addr->sa_family==AF_INET && ifa->ifa_name) {
            sa = (struct sockaddr_in *) ifa->ifa_addr;
            addr = inet_ntoa(sa->sin_addr);
        }
    }

	manualAddr = clientName.UTF8String;

	if (destination.sin_addr.s_addr == inet_addr(addr) || destination.sin_addr.s_addr == inet_addr(manualAddr)) { // need to be change to the right ip, still studying about
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
		ksusLANTweakEnabled : @(NO),
		ksusLANTweakLANEnabled : @(NO),
		ksusLANCustomServerIP : @"127.0.0.1",
		ksusLANCustomClientIP : @"127.0.0.1",
		ksusLANCustomBroadcastMessage : @"Proxy",
		ksusLANTGlobalBroadcast : @"255.255.255.255",
		ksusLANTweakVPNEnabled : @(NO),
		ksusLANTweakVPNTimer : @"15",
		ksusLANTweakVPNInfiniteLoop : @(NO),
		ksusLANTweakVPNClientNumber : @"15",
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
		ksusLANTweakVPNIP11 : @"",
		ksusLANTweakVPNIP12 : @"",
		ksusLANTweakVPNIP13 : @"",
		ksusLANTweakVPNIP14 : @"",
		ksusLANTweakVPNIP15 : @"",
		ksusLANTweakPortEnabled : @(NO),
		ksusLANCustomBroadcastPort : @"47777",
		ksusLANCustomServerPort : @"22023",
		ksusLANCustomListenPort : @"47777",
		ksusLANCustomReceivePort : @"22023"
	}];

	// Initialize the custom server hooks if the user enabled the tweak
	NSNumber *ServerEnabled = [preferences objectForKey:ksusLANTweakEnabled];
		if ([ServerEnabled boolValue]) {
			// Get the custom broadcast message
			NSString *broadcastmessage = [preferences objectForKey:ksusLANCustomBroadcastMessage];
			const char *Broadcastmsg = [broadcastmessage UTF8String];
			BroadcastMessage = Broadcastmsg;
			NSString *globalbroadcast = [preferences objectForKey:ksusLANTGlobalBroadcast];
			const char *globalbroadcastmsg = [globalbroadcast UTF8String];
			GlobalBroadcast = globalbroadcastmsg;

			// Custom broadcast
			NSNumber *LANServerEnabled = [preferences objectForKey:ksusLANTweakLANEnabled];
				if ([LANServerEnabled boolValue]) {
				
				// Get the IPs
				hostName = [preferences objectForKey:ksusLANCustomServerIP];
				clientName = [preferences objectForKey:ksusLANCustomClientIP];

				// Initialize the hooks for client proxy
				%init(CustomLANServer);
				Broadcast();
				}

			// Custom Client Proxy hooks
			NSNumber *VPNBroadcast = [preferences objectForKey:ksusLANTweakVPNEnabled];
				if ([VPNBroadcast boolValue]) {
					NSNumber *VPNTimerNoLoop = [preferences objectForKey:ksusLANTweakVPNInfiniteLoop];
					TweakVPNInfiniteLoop = [VPNTimerNoLoop boolValue];
					NSString *VPNTimer = [preferences objectForKey:ksusLANTweakVPNTimer];
					int VPNTimermsg = [VPNTimer intValue];
					TweakVPNTimer = (uint16_t)VPNTimermsg;
					NSString *numberclient = [preferences objectForKey:ksusLANTweakVPNClientNumber];
					int clientnumber = [numberclient intValue];
					TweakVPNClientNumber = clientnumber;
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
					NSString *vpnip11 = [preferences objectForKey:ksusLANTweakVPNIP11];
					const char *vpnipmsg11 = [vpnip11 UTF8String];
					VPNIP11 = vpnipmsg11;
					NSString *vpnip12 = [preferences objectForKey:ksusLANTweakVPNIP12];
					const char *vpnipmsg12 = [vpnip12 UTF8String];
					VPNIP12 = vpnipmsg12;
					NSString *vpnip13 = [preferences objectForKey:ksusLANTweakVPNIP13];
					const char *vpnipmsg13 = [vpnip13 UTF8String];
					VPNIP13 = vpnipmsg13;
					NSString *vpnip14 = [preferences objectForKey:ksusLANTweakVPNIP14];
					const char *vpnipmsg14 = [vpnip14 UTF8String];
					VPNIP14 = vpnipmsg14;
					NSString *vpnip15 = [preferences objectForKey:ksusLANTweakVPNIP15];
					const char *vpnipmsg15 = [vpnip15 UTF8String];
					VPNIP15 = vpnipmsg15;
					%init(CustomVPNBroadcast);
					BroadcastVPN();
				}
		// EXPERIMENTAL PORT HOOKS
		NSNumber *ExpServerEnabled = [preferences objectForKey:ksusLANTweakPortEnabled];
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
}