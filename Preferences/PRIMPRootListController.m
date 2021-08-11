#import "PRIMPRootListController.h"


@implementation PRIMPRootListController

- (NSArray *)specifiers {
	if (!_specifiers) {
		_specifiers = [self loadSpecifiersFromPlistName:@"Root" target:self];
		
		NSArray *chosenIDs = @[@"GLOBAL_SWITCH", @"BROADCAST_SWITCH", @"TUNNEL_SWITCH", @"SERVER_SWITCH", @"PORT_SWITCH", @"BROADCAST_GLOBAL", @"GLOBAL_TUNNEL", @"GLOBAL_SERVER", @"GLOBAL_EXPERIMENTAL", @"BROADCAST_MESSAGE", @"BROADCAST_GLOBAL_IP", @"INFINITE_LOOP", @"BROADCAST_TIMER", @"TUNNEL_HOST_IP", @"TUNNEL_CLIENT_IP", @"CLIENTS_NUMBER", @"CLIENT_15", @"CLIENT_14", @"CLIENT_13", @"CLIENT_12", @"CLIENT_11", @"CLIENT_10", @"CLIENT_9", @"CLIENT_8", @"CLIENT_7", @"CLIENT_6", @"CLIENT_5", @"CLIENT_4", @"CLIENT_3", @"CLIENT_2", @"CLIENT_1", @"BROADCAST_PORT", @"HOST_PORT", @"LISTEN_PORT", @"RECEIVE_PORT"];

		self.savedSpecifiers = (_savedSpecifiers) ?: [[NSMutableDictionary alloc] init];
		for(PSSpecifier *specifier in _specifiers){
			if([chosenIDs containsObject:[specifier propertyForKey:@"id"]]){
				[self.savedSpecifiers setObject:specifier forKey:[specifier propertyForKey:@"id"]];
			}
		}
	}
	return _specifiers;
}

-(void)_returnKeyPressed:(id)arg1 {
	[self.view endEditing:YES];
}

- (void)setPreferenceValue:(id)_value specifier:(PSSpecifier *)specifier {
		id value = _value;
		
		NSString *key = [specifier propertyForKey:@"key"];
		HBPreferences *preferences = [HBPreferences preferencesForIdentifier:@"com.piercingimpulse.suslan"];
			if([key isEqualToString:@"TweakLANEnabled"]) {
    			if([value boolValue]) {
     			[preferences setBool:NO forKey:@"TweakVPNEnabled"];
				[self reloadSpecifiers];
				}
			} else if([key isEqualToString:@"TweakVPNEnabled"]) {
    			if([value boolValue]) {
     			[preferences setBool:NO forKey:@"TweakLANEnabled"];
				[preferences setBool:YES forKey:@"TweakBroadcastEnabled"];
				[self reloadSpecifiers];
			}
		}
		if([key isEqualToString:@"TweakBroadcastEnabled"]) {
    			if(![value boolValue]) {
     			[preferences setBool:NO forKey:@"TweakVPNEnabled"];
				[self reloadSpecifiers];
				}
		}


		if ([(NSString *)[specifier propertyForKey:@"key"] isEqualToString:@"HostPort"] || [(NSString *)[specifier propertyForKey:@"key"] isEqualToString:@"ReceivePort"]) {
		NSInteger integerValue = [(NSString *)value integerValue];
		if ((integerValue < 0x0000) || (integerValue > 0xFFFF)) {
			value = @(22023);
			UIAlertController *alert = [UIAlertController
				alertControllerWithTitle:@"Invalid Port"
				message:@"The port must be in the 0-65535 range."
				preferredStyle:UIAlertControllerStyleAlert
			];
			[alert addAction:[UIAlertAction
				actionWithTitle:@"OK"
				style:UIAlertActionStyleDefault
				handler:nil
			]];
			[self presentViewController:alert animated:YES completion:nil];
			}
		}

		if ([(NSString *)[specifier propertyForKey:@"key"] isEqualToString:@"BroadcastPort"] || [(NSString *)[specifier propertyForKey:@"key"] isEqualToString:@"ListenPort"]) {
		NSInteger integerValue = [(NSString *)value integerValue];
		if ((integerValue < 0x0000) || (integerValue > 0xFFFF)) {
			value = @(47777);
			UIAlertController *alert = [UIAlertController
				alertControllerWithTitle:@"Invalid Port"
				message:@"The port must be in the 0-65535 range."
				preferredStyle:UIAlertControllerStyleAlert
			];
			[alert addAction:[UIAlertAction
				actionWithTitle:@"OK"
				style:UIAlertActionStyleDefault
				handler:nil
			]];
			[self presentViewController:alert animated:YES completion:nil];
			}
		}

	if ([(NSString *)[specifier propertyForKey:@"key"] isEqualToString:@"TweakVPNClientNumber"]) {
		NSInteger integerValue = [(NSString *)value integerValue];
		if ((integerValue < 0x00)) {
			value = @(1);
			UIAlertController *alert = [UIAlertController
				alertControllerWithTitle:@"Invalid number"
				message:@"You can't use a negative number."
				preferredStyle:UIAlertControllerStyleAlert
			];
			[alert addAction:[UIAlertAction
				actionWithTitle:@"OK"
				style:UIAlertActionStyleDefault
				handler:nil
			]];
			[self presentViewController:alert animated:YES completion:nil];
			}
		if ((integerValue > 0x0F)) {
			value = @(15);
			UIAlertController *alert = [UIAlertController
				alertControllerWithTitle:@"Invalid number"
				message:@"Only 15 clients maximum allowed."
				preferredStyle:UIAlertControllerStyleAlert
			];
			[alert addAction:[UIAlertAction
				actionWithTitle:@"OK"
				style:UIAlertActionStyleDefault
				handler:nil
			]];
			[self presentViewController:alert animated:YES completion:nil];
			}
		}
		if ([(NSString *)[specifier propertyForKey:@"key"] isEqualToString:@"TweakVPNTimer"]) {
		NSInteger integerValue = [(NSString *)value integerValue];
		if ((integerValue < 0x000) || (integerValue > 0xFFF)) {
			value = @(20);
			UIAlertController *alert = [UIAlertController
				alertControllerWithTitle:@"Invalid number"
				message:@"The cycle must be in the 0-255 range."
				preferredStyle:UIAlertControllerStyleAlert
			];
			[alert addAction:[UIAlertAction
				actionWithTitle:@"OK"
				style:UIAlertActionStyleDefault
				handler:nil
			]];
			[self presentViewController:alert animated:YES completion:nil];
			}
		}

	[super setPreferenceValue:value specifier:specifier];

	[self updateSpecifierVisibility:YES];

		if (value != _value) {
		// Reload the specifier if some code changed the value
		[self reloadSpecifier:specifier];
	}
}


-(void)updateSpecifierVisibility:(BOOL)animated {	
	//Get value of switch specifier

	PSSpecifier *switchGlobal = [self specifierForID:@"GLOBAL_SWITCH"];
	BOOL switchGlobalValue = [[self readPreferenceValue:switchGlobal] boolValue];

	PSSpecifier *switchBroadcast = [self specifierForID:@"BROADCAST_SWITCH"];
	BOOL switchBroadcastValue = [[self readPreferenceValue:switchBroadcast] boolValue];

	PSSpecifier *switchLoop = [self specifierForID:@"INFINITE_LOOP"];
	BOOL switchLoopValue = [[self readPreferenceValue:switchLoop] boolValue];

	PSSpecifier *switchClient = [self specifierForID:@"TUNNEL_SWITCH"];
	BOOL switchClientValue = [[self readPreferenceValue:switchClient] boolValue];

	PSSpecifier *switchHost = [self specifierForID:@"SERVER_SWITCH"];
	BOOL switchHostValue = [[self readPreferenceValue:switchHost] boolValue];

	PSSpecifier *clientsNumber = [self specifierForID:@"CLIENTS_NUMBER"];
	int clientsNumberValue = [[self readPreferenceValue:clientsNumber] intValue];

	PSSpecifier *portChanger = [self specifierForID:@"PORT_SWITCH"];
	BOOL portChangerValue = [[self readPreferenceValue:portChanger] boolValue];

	if(!switchGlobalValue) {
		[self hideMe:@"BROADCAST_SWITCH" animate:YES];
		[self hideMe:@"BROADCAST_GLOBAL" animate:YES];
		[self hideMe:@"TUNNEL_SWITCH" animate:YES];	
		[self hideMe:@"GLOBAL_TUNNEL" animate:YES];
		[self hideMe:@"SERVER_SWITCH" animate:YES];
		[self hideMe:@"GLOBAL_SERVER" animate:YES];
		[self hideMe:@"GLOBAL_EXPERIMENTAL"animate:YES];
		[self hideMe:@"PORT_SWITCH" animate:YES];
	} 
	if(!switchBroadcastValue || !switchGlobalValue) {
		[self hideMe:@"BROADCAST_MESSAGE" animate:YES];
		[self hideMe:@"BROADCAST_GLOBAL_IP" animate:YES];
		[self hideMe:@"INFINITE_LOOP" animate:YES];
	} 
	if(!switchBroadcastValue || !switchGlobalValue || switchLoopValue) {
		[self hideMe:@"BROADCAST_TIMER" animate:YES];
	}
	if(!switchClientValue || !switchGlobalValue) {
		[self hideMe:@"TUNNEL_HOST_IP" animate:YES];
		[self hideMe:@"TUNNEL_CLIENT_IP" animate:YES];	
	}
	if(!switchHostValue || !switchGlobalValue)  {	
		[self hideMe:@"CLIENTS_NUMBER" animate:YES];	
	}
	if (clientsNumberValue <= 14 || !switchHostValue || !switchGlobalValue) {
		[self hideMe:@"CLIENT_15" animate:YES];
	}
	if (clientsNumberValue <= 13 || !switchHostValue || !switchGlobalValue) {
		[self hideMe:@"CLIENT_14" animate:YES];
	}
	if (clientsNumberValue <= 12 || !switchHostValue || !switchGlobalValue) {
		[self hideMe:@"CLIENT_13" animate:YES];	
	}
	if (clientsNumberValue <= 11 || !switchHostValue || !switchGlobalValue) {
		[self hideMe:@"CLIENT_12" animate:YES];
	}
	if (clientsNumberValue <= 10 || !switchHostValue || !switchGlobalValue) {
		[self hideMe:@"CLIENT_11" animate:YES];
	}					
	if (clientsNumberValue <= 9 || !switchHostValue || !switchGlobalValue) {
		[self hideMe:@"CLIENT_10" animate:YES];
	}
	if (clientsNumberValue <= 8 || !switchHostValue || !switchGlobalValue) {
		[self hideMe:@"CLIENT_9" animate:YES];
	}
	if (clientsNumberValue <= 7 || !switchHostValue || !switchGlobalValue) {
		[self hideMe:@"CLIENT_8" animate:YES];
	}
	if (clientsNumberValue <= 6 || !switchHostValue || !switchGlobalValue) {
		[self hideMe:@"CLIENT_7" animate:YES];
	}
	if (clientsNumberValue <= 5 || !switchHostValue || !switchGlobalValue) {
		[self hideMe:@"CLIENT_6" animate:YES];
	}
	if (clientsNumberValue <= 4 || !switchHostValue || !switchGlobalValue) {
		[self hideMe:@"CLIENT_5" animate:YES];
	}
	if (clientsNumberValue <= 3 || !switchHostValue || !switchGlobalValue) {
		[self hideMe:@"CLIENT_4" animate:YES];
	}
	if (clientsNumberValue <= 2 || !switchHostValue || !switchGlobalValue) {
		[self hideMe:@"CLIENT_3" animate:YES];
	}
	if (clientsNumberValue <= 1 || !switchHostValue || !switchGlobalValue) {
		[self hideMe:@"CLIENT_2" animate:YES];
	}
	if (clientsNumberValue <= 0 || !switchHostValue || !switchGlobalValue) {
		[self hideMe:@"CLIENT_1" animate:YES];
	}				
	if(!portChangerValue || !switchGlobalValue) {
		[self hideMe:@"BROADCAST_PORT" animate:YES];
		[self hideMe:@"HOST_PORT" animate:YES];	
		[self hideMe:@"LISTEN_PORT" animate:YES];	
		[self hideMe:@"RECEIVE_PORT" animate:YES];	
	}
	if(switchGlobalValue) {
		[self showMe:@"BROADCAST_GLOBAL" after:@"GLOBAL_SWITCH" animate:YES];
		[self showMe:@"BROADCAST_SWITCH" after:@"BROADCAST_GLOBAL" animate:YES];
		[self showMe:@"GLOBAL_TUNNEL" after:@"BROADCAST_SWITCH" animate:YES];
		[self showMe:@"TUNNEL_SWITCH" after:@"GLOBAL_TUNNEL" animate:YES];
		[self showMe:@"GLOBAL_SERVER" after:@"TUNNEL_SWITCH" animate:YES];
		[self showMe:@"SERVER_SWITCH" after:@"GLOBAL_SERVER" animate:YES];
		[self showMe:@"GLOBAL_EXPERIMENTAL" after:@"SERVER_SWITCH" animate:YES];
		[self showMe:@"PORT_SWITCH" after:@"GLOBAL_EXPERIMENTAL" animate:YES];
	} 
	if(switchBroadcastValue && switchGlobalValue) {
		[self showMe:@"BROADCAST_MESSAGE" after:@"BROADCAST_SWITCH" animate:YES];
		[self showMe:@"BROADCAST_GLOBAL_IP" after:@"BROADCAST_MESSAGE" animate:YES];
		[self showMe:@"INFINITE_LOOP" after:@"BROADCAST_GLOBAL_IP" animate:YES];
	} 
	if(switchBroadcastValue && switchGlobalValue && !switchLoopValue) {
		[self showMe:@"BROADCAST_TIMER" after:@"INFINITE_LOOP" animate:YES];
	}
	if(switchClientValue && switchGlobalValue) {
		[self showMe:@"TUNNEL_HOST_IP" after:@"TUNNEL_SWITCH" animate:YES];
		[self showMe:@"TUNNEL_CLIENT_IP" after:@"TUNNEL_HOST_IP" animate:YES];	
	}
	if(switchHostValue && switchGlobalValue)  {	
		[self showMe:@"CLIENTS_NUMBER" after:@"SERVER_SWITCH" animate:YES];	
	}
	if (clientsNumberValue >= 1 && switchHostValue && switchGlobalValue) {
		[self showMe:@"CLIENT_1" after:@"CLIENTS_NUMBER" animate:YES];
	}
	if (clientsNumberValue >= 2 && switchHostValue && switchGlobalValue) {
		[self showMe:@"CLIENT_2" after:@"CLIENT_1" animate:YES];
	}
	if (clientsNumberValue >= 3 && switchHostValue && switchGlobalValue) {
		[self showMe:@"CLIENT_3" after:@"CLIENT_2" animate:YES];
	}
	if (clientsNumberValue >= 4 && switchHostValue && switchGlobalValue) {
		[self showMe:@"CLIENT_4" after:@"CLIENT_3" animate:YES];
	}
	if (clientsNumberValue >= 5 && switchHostValue && switchGlobalValue) {
		[self showMe:@"CLIENT_5" after:@"CLIENT_4" animate:YES];
	}
	if (clientsNumberValue >= 6 && switchHostValue && switchGlobalValue) {
		[self showMe:@"CLIENT_6" after:@"CLIENT_5" animate:YES];
	}
	if (clientsNumberValue >= 7 && switchHostValue && switchGlobalValue) {
		[self showMe:@"CLIENT_7" after:@"CLIENT_6" animate:YES];
	}
	if (clientsNumberValue >= 8 && switchHostValue && switchGlobalValue) {
		[self showMe:@"CLIENT_8" after:@"CLIENT_7" animate:YES];
	}
	if (clientsNumberValue >= 9 && switchHostValue && switchGlobalValue) {
		[self showMe:@"CLIENT_9" after:@"CLIENT_8" animate:YES];
	}
	if (clientsNumberValue >= 10 && switchHostValue && switchGlobalValue) {
		[self showMe:@"CLIENT_10" after:@"CLIENT_9" animate:YES];
	}
	if (clientsNumberValue >= 11 && switchHostValue && switchGlobalValue) {
		[self showMe:@"CLIENT_11" after:@"CLIENT_10" animate:YES];
	}
	if (clientsNumberValue >= 12 && switchHostValue && switchGlobalValue) {
		[self showMe:@"CLIENT_12" after:@"CLIENT_11" animate:YES];
	}
	if (clientsNumberValue >= 13 && switchHostValue && switchGlobalValue) {
		[self showMe:@"CLIENT_13" after:@"CLIENT_12" animate:YES];
	}
	if (clientsNumberValue >= 14 && switchHostValue && switchGlobalValue) {
		[self showMe:@"CLIENT_14" after:@"CLIENT_13" animate:YES];
	}
	if (clientsNumberValue >= 15 && switchHostValue && switchGlobalValue) {
		[self showMe:@"CLIENT_15" after:@"CLIENT_14" animate:YES];
	}
	if(portChangerValue && switchGlobalValue) {
		[self showMe:@"BROADCAST_PORT" after:@"PORT_SWITCH" animate:YES];
		[self showMe:@"HOST_PORT" after:@"BROADCAST_PORT" animate:YES];
		[self showMe:@"LISTEN_PORT" after:@"HOST_PORT" animate:YES];	
		[self showMe:@"RECEIVE_PORT" after:@"LISTEN_PORT" animate:YES];	
	}
}
-(void)reloadSpecifiers {
	[super reloadSpecifiers];

	//We set the animated argument to NO to hide cell's animation of being removed
	[self updateSpecifierVisibility:NO];
}

-(void)viewDidLoad {
		[super viewDidLoad];

		[self updateSpecifierVisibility:NO];
	}
	
- (void)loadView {
    [super loadView];
    ((UITableView *)[self table]).keyboardDismissMode = UIScrollViewKeyboardDismissModeOnDrag;
}
-(void) showMe:(NSString *)showMe after:(NSString *)after animate:(bool)animate{
	if (![self containsSpecifier:self.savedSpecifiers[showMe]]){
		[self insertContiguousSpecifiers:@[self.savedSpecifiers[showMe]] afterSpecifierID:after animated:animate];
	}
}

-(void) hideMe:(NSString *)hideMe animate:(bool)animate{
	if ([self containsSpecifier:self.savedSpecifiers[hideMe]]){
		[self removeContiguousSpecifiers:@[self.savedSpecifiers[hideMe]] animated:animate];
	}
}
@end