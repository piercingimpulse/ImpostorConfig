#import <Foundation/Foundation.h>
#import <Cephei/HBPreferences.h>
#import <sys/types.h>
#import <sys/socket.h>
#import <arpa/inet.h>
#import <netdb.h>
#import <pthread.h>
#import <errno.h>

// Preference constants
static NSString *const kImpostorConfigPreferenceDomain = @"com.pixelomer.impostorconfig";
static NSString *const kImpostorConfigCustomServerEnabled = @"CustomServerEnabled";
static NSString *const kImpostorConfigCustomServerIP = @"IPAddress";
static NSString *const kImpostorConfigCustomServerPort = @"Port"; //it's not in use atm

// HBPreferences
static HBPreferences *preferences;

// Custom server variables
static NSString *hostName = nil;
static struct hostent *hostEntry = NULL;
// static uint16_t customPort = 0;  //it's not in use atm
static pthread_mutex_t mutex = PTHREAD_MUTEX_INITIALIZER;

%group CustomServer

%hookf(ssize_t, sendto, int socket, const void *buffer, size_t length, int flags, const struct sockaddr *_destination, socklen_t destinationLength) {
	// Check if the type of the destination structure is sockaddr_in
	if (destinationLength != sizeof(struct sockaddr_in)) return %orig;
	struct sockaddr_in destination = *(struct sockaddr_in *)_destination;

	// Check if the destination is an Among Us server
	if (destination.sin_family != AF_INET) return %orig;
	if (destination.sin_port != htons(22023)) return %orig;
	// if (destination.sin_addr.s_addr == inet_addr("127.0.0.1")) return %orig; // This will allow in the future to Host a game even if the tweak it's active once broadcast message will be available

	// While with this if, we are able to play other real LAN game even when the tweak is active. It necessary to avoid being redirect always to the same custom host.
	if (destination.sin_addr.s_addr == inet_addr("127.0.0.1")) {
	
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
	//	destination.sin_port = customPort;	// not necessary atm.
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

%ctor {
	// Initialize HBPreferences
	preferences = [[HBPreferences alloc] initWithIdentifier:kImpostorConfigPreferenceDomain];
	[preferences registerDefaults:@{
		kImpostorConfigCustomServerEnabled : @(NO),
		kImpostorConfigCustomServerIP : @"172.105.251.170",
		kImpostorConfigCustomServerPort : @"22023"
	}];

	// Initialize the custom server hooks if the user enabled the
	// custom server feature
	NSNumber *customServerEnabled = [preferences objectForKey:kImpostorConfigCustomServerEnabled];
	if ([customServerEnabled boolValue]) {
		// Get specified port
		// NSString *port = [preferences objectForKey:kImpostorConfigCustomServerPort];
		// int rawPort = [port intValue];
		// This if it is not in use atm
		// if ((rawPort < 0x0000) || (rawPort > 0xFFFF)) {
			// The port must be an unsigned 16-bit value!
		//	[NSException raise:NSInvalidArgumentException format:@"[ImpostorConfig] Invalid port: %@", port];
		// }

		// Convert the specified port to the network byte order
		// customPort = htons((uint16_t)rawPort); // not in use atm

		// Get the hostname
		hostName = [preferences objectForKey:kImpostorConfigCustomServerIP];

		// Initialize the hooks
		%init(CustomServer);
	}
}
