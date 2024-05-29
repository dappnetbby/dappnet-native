#import <Cocoa/Cocoa.h>
#import <WebKit/WebKit.h>

@interface CustomSchemeHandler : NSObject <WKURLSchemeHandler>
@end

@implementation CustomSchemeHandler

- (void)webView:(WKWebView *)webView startURLSchemeTask:(id<WKURLSchemeTask>)urlSchemeTask {
    NSURL *url = urlSchemeTask.request.URL;
    // Check if the URL is what you need to handle
    if ([url.host hasSuffix:@".eth"]) {
        // Fetch data for the URL    
        // get the path from the URL and add it onto the local gateway URL
        NSString *path = url.path;
        NSString *gatewayURL = [NSString stringWithFormat:@"http://localhost:10422%@", path];
        NSLog(@"Load host=%@ gateway=%@", url.host, gatewayURL);


        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:gatewayURL]];
        request.HTTPMethod = @"POST"; // non-idempotent
        [request setValue:url.host forHTTPHeaderField:@"Host"];
        NSURLSession *session = [NSURLSession sharedSession];
        NSURLSessionDataTask *task = [session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
            if (error) {
                [urlSchemeTask didFailWithError:error];
            } else {
                [urlSchemeTask didReceiveResponse:response];
                [urlSchemeTask didReceiveData:data];
                [urlSchemeTask didFinish];
            }
        }];
        [task resume];
    } else {
        [urlSchemeTask didFailWithError:[NSError errorWithDomain:NSCocoaErrorDomain code:NSUserCancelledError userInfo:nil]];
    }
}

- (void)webView:(WKWebView *)webView stopURLSchemeTask:(id<WKURLSchemeTask>)urlSchemeTask {
    // Handle stopping tasks if necessary
}

@end




NSString *stringFromFileAtPath(NSString *path) {
    NSError *error = nil;
    NSString *fileContents = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:&error];
    if (fileContents == nil) {
        NSLog(@"Error reading file at %@: %@", path, error.localizedDescription);
        return nil;
    }
    return fileContents;
}







@interface AppDelegate : NSObject <NSApplicationDelegate>
@property (strong, nonatomic) NSWindow *window;

@property (strong, nonatomic) NSStatusItem *statusItem;
@property (strong, nonatomic) NSMenu *menu;

@end

@implementation AppDelegate

- (void) quitApp {
    [NSApp terminate:self];
}

- (void)applicationDidFinishLaunching:(NSNotification *)notification {
    [NSApp setActivationPolicy:NSApplicationActivationPolicyAccessory];

    self.statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];
        NSImage *iconImage = [NSImage imageNamed:@"output.png"];


    self.statusItem.button.image = iconImage;

    self.menu = [[NSMenu alloc] init];
    [self.menu addItemWithTitle:@"Dappnet" action:nil keyEquivalent:@""];
    [self.menu addItem:[NSMenuItem separatorItem]];  // Separator
    [self.menu addItemWithTitle:@"Quit" action:@selector(quitApp) keyEquivalent:@"q"];
    [self.menu addItemWithTitle:@"About" action:@selector(showAbout) keyEquivalent:@""];
    [self.menu addItemWithTitle:@"Launch Browser" action:@selector(setupMainWindow) keyEquivalent:@""];
    [self.menu addItemWithTitle:@"Wallet: 0 ETH (0x...)" action:nil keyEquivalent:@""];
    [self.menu itemAtIndex:4].enabled = NO;  // Gray out the wallet balance

    self.statusItem.menu = self.menu;
}

- (void)setupMainMenu {
    // Create the main menu bar
    NSMenu *mainMenu = [[NSMenu alloc] init];

    // Edit menu
    NSMenuItem *editMenuItem = [[NSMenuItem alloc] initWithTitle:@"Edit" action:nil keyEquivalent:@""];
    [mainMenu addItem:editMenuItem];
    NSMenu *editMenu = [[NSMenu alloc] initWithTitle:@"Edit"];
    [editMenuItem setSubmenu:editMenu];

    // Add Copy
    NSMenuItem *copyItem = [[NSMenuItem alloc] initWithTitle:@"Copy" action:@selector(copy:) keyEquivalent:@"c"];
    [copyItem setKeyEquivalentModifierMask:NSEventModifierFlagCommand];
    [editMenu addItem:copyItem];

    // Add Paste
    NSMenuItem *pasteItem = [[NSMenuItem alloc] initWithTitle:@"Paste" action:@selector(paste:) keyEquivalent:@"v"];
    [pasteItem setKeyEquivalentModifierMask:NSEventModifierFlagCommand];
    [editMenu addItem:pasteItem];

    // Add Cut
    NSMenuItem *cutItem = [[NSMenuItem alloc] initWithTitle:@"Cut" action:@selector(cut:) keyEquivalent:@"x"];
    [cutItem setKeyEquivalentModifierMask:NSEventModifierFlagCommand];
    [editMenu addItem:cutItem];

    // Add Undo
    NSMenuItem *undoItem = [[NSMenuItem alloc] initWithTitle:@"Undo" action:@selector(undo:) keyEquivalent:@"z"];
    [undoItem setKeyEquivalentModifierMask:NSEventModifierFlagCommand];
    [editMenu addItem:undoItem];

    // Add Select All
    NSMenuItem *selectAllItem = [[NSMenuItem alloc] initWithTitle:@"Select All" action:@selector(selectAll:) keyEquivalent:@"a"];
    [selectAllItem setKeyEquivalentModifierMask:NSEventModifierFlagCommand];
    [editMenu addItem:selectAllItem];
    
    NSMenuItem *toolsMenuItem = [[NSMenuItem alloc] initWithTitle:@"Tools" action:nil keyEquivalent:@""];
    [mainMenu addItem:toolsMenuItem];
    NSMenu *toolsMenu = [[NSMenu alloc] initWithTitle:@"Tools"];
    [toolsMenuItem setSubmenu:toolsMenu];

    // Adding "Open URL Dialog" menu item with Command-K shortcut
    NSMenuItem *openURLItem = [[NSMenuItem alloc] initWithTitle:@"Open URL" action:@selector(promptForURL:) keyEquivalent:@"k"];
    [openURLItem setKeyEquivalentModifierMask:NSEventModifierFlagCommand];
    [toolsMenu addItem:openURLItem];

    // Create the application menu
    NSMenuItem *appMenuItem = [[NSMenuItem alloc] init];
    [mainMenu addItem:appMenuItem];
    NSMenu *appMenu = [[NSMenu alloc] init];
    NSMenuItem *quitMenuItem = [[NSMenuItem alloc] initWithTitle:@"Quit"
                                                        action:@selector(terminate:)
                                                keyEquivalent:@"q"];
    [appMenu addItem:quitMenuItem];
    [appMenuItem setSubmenu:appMenu];

    // Assign the menu to the application
    [[NSApplication sharedApplication] setMainMenu:mainMenu];
}




@end



int main(int argc, const char * argv[]) {
    @autoreleasepool {
        NSApplication *application = [NSApplication sharedApplication];
        AppDelegate *appDelegate = [[AppDelegate alloc] init];
        application.delegate = appDelegate;
        [application run];
    }
    return 0;
}

