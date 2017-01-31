//
//  AppDelegate.m
//  ULITearOffMenu
//
//  Created by Uli Kusterer on 31/01/2017.
//  Copyright © 2017 Uli Kusterer. All rights reserved.
//

#import "AppDelegate.h"



@class ULITearOffMenuView;


@interface AppDelegate () <NSMenuDelegate>

@property (weak) IBOutlet NSWindow *window;
@property (weak) IBOutlet NSMenu *tearOffMenu;
@property (strong) IBOutlet ULITearOffMenuView *dummyView;
@property (strong) IBOutlet NSVisualEffectView *backgroundView;

@end



@interface ULITearOffMenuView : NSView

@property (strong) NSView* contentView;

@end


@implementation ULITearOffMenuView

-(id)initWithFrame:(NSRect)frameRect
{
	self = [super initWithFrame: frameRect];
	if( self )
	{
		self.contentView = [[NSView alloc] initWithFrame: NSZeroRect];
		self.contentView.autoresizingMask = NSViewMinXMargin | NSViewMaxXMargin | NSViewWidthSizable | NSViewMinYMargin | NSViewMaxYMargin | NSViewHeightSizable;
		self.contentView.frame = (NSRect){ {0,20}, { frameRect.size.width, frameRect.size.height -20 } };
		[self addSubview: self.contentView];
		
	}
	return self;
}


-(id)initWithCoder:(NSCoder*)aDecoder
{
	self = [super initWithCoder: aDecoder];
	if( self )
	{
		self.contentView = [[NSView alloc] initWithFrame: NSZeroRect];
		self.contentView.translatesAutoresizingMaskIntoConstraints = NO;
		[self addSubview: self.contentView];
		[self.contentView.leftAnchor constraintEqualToAnchor: self.leftAnchor];
		[self.contentView.rightAnchor constraintEqualToAnchor: self.rightAnchor];
		[self.contentView.topAnchor constraintEqualToAnchor: self.topAnchor constant: 20];
		[self.contentView.bottomAnchor constraintEqualToAnchor: self.bottomAnchor];
	}
	return self;
}

-(void)	drawRect:(NSRect)dirtyRect
{
	NSImage* img = [NSImage imageNamed: @"fake_title_bar_fill"];
	NSRect box = self.bounds;
	box.size.height = img.size.height;
	[img drawInRect: box];
}


-(BOOL) isFlipped
{
	return YES;
}


-(void) mouseDown:(NSEvent *)event
{
	NSWindow* tearOffWindow = [(AppDelegate*)[NSApplication sharedApplication].delegate window];
	NSVisualEffectView* bgView = [(AppDelegate*)[NSApplication sharedApplication].delegate backgroundView];
	NSRect	windowViewBox = [self convertRect: self.bounds toView: nil];
	NSPoint	windowPos = self.window.frame.origin;
	NSRect viewBox = NSOffsetRect( windowViewBox, windowPos.x, windowPos.y );
	
	NSRect	tearOffWindowFrame = tearOffWindow.frame;
	
	viewBox.origin.y -= tearOffWindowFrame.size.height -viewBox.size.height;
	viewBox.size.height += tearOffWindowFrame.size.height -viewBox.size.height;
//	viewBox.origin.y += windowViewBox.origin.y;
	viewBox.size.width = tearOffWindowFrame.size.width;
	
	[tearOffWindow setFrame: viewBox display: YES];
	NSInteger oldWindowLevel = tearOffWindow.level;
	tearOffWindow.level = 7000;
	
	[self.enclosingMenuItem.menu cancelTrackingWithoutAnimation];
	
	dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.0 * NSEC_PER_SEC)), dispatch_get_main_queue(),
	^{
		[tearOffWindow.contentView addSubview: bgView];
		[tearOffWindow makeKeyAndOrderFront: nil];
		
    	BOOL	keepDragging = YES;
		while( keepDragging )
		{
			@autoreleasepool {
				NSEvent * evt = [[NSApplication sharedApplication] nextEventMatchingMask: NSEventMaskLeftMouseDown | NSEventMaskLeftMouseUp | NSEventMaskLeftMouseDragged untilDate:[NSDate distantFuture] inMode: NSEventTrackingRunLoopMode dequeue: YES];
				if( evt )
				{
					switch( evt.type )
					{
						case NSEventTypeLeftMouseUp:
						case NSEventTypeLeftMouseDown:
							keepDragging = NO;
							break;
						
						case NSEventTypeLeftMouseDragged:
						{
							NSRect	box = tearOffWindow.frame;
							box.origin.x += evt.deltaX;
							box.origin.y -= evt.deltaY;
							[tearOffWindow setFrameOrigin: box.origin];
							break;
						}
						
						default:
							break;
					}
				}
			}
		}
		
		tearOffWindow.level = oldWindowLevel;
	});
}


-(void)	viewDidMoveToWindow
{
	NSWindow* tearOffWindow = [(AppDelegate*)[NSApplication sharedApplication].delegate window];
	NSVisualEffectView* bgView = [(AppDelegate*)[NSApplication sharedApplication].delegate backgroundView];
	[tearOffWindow orderOut: nil];
	[self.contentView addSubview: bgView];
	[self setNeedsDisplay: YES];
}

@end



@implementation AppDelegate

- (void) applicationDidFinishLaunching:(NSNotification *)notification
{
	self.window.opaque = NO;
	NSMenuItem *dummyItem = [self.tearOffMenu itemAtIndex: 0];
	self.dummyView = [[ULITearOffMenuView alloc] initWithFrame: NSMakeRect(0, 0, self.window.frame.size.width, self.window.frame.size.height)];
	dummyItem.view = self.dummyView;
	self.backgroundView.material = NSVisualEffectMaterialMenu;
	self.backgroundView.state = NSVisualEffectStateActive;
	self.backgroundView.translatesAutoresizingMaskIntoConstraints = YES;
	[self.dummyView.contentView addSubview: self.backgroundView];
}

@end
