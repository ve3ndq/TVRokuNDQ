' ********** Copyright 2016 Roku Corp.  All Rights Reserved. ********** 

sub Main(args as Dynamic)

    reg = CreateObject("roRegistrySection", "profile")
    if reg.Exists("primaryfeed") then
        url = reg.Read("primaryfeed")
    else
        url = "https://tinyurl.com/yaoc6zpo"
    end if

    ' Default startup channel index (string). Fall back to 0 if not set.
    startupChannelId = "0"
    if reg.Exists("startupChannelId") then
        startupChannelId = reg.Read("startupChannelId")
    end if

    screen = CreateObject("roSGScreen")
    m.port = CreateObject("roMessagePort")
    screen.setMessagePort(m.port)
    m.global = screen.getGlobalNode()
    m.global.addFields({feedurl: url, startupChannelId: startupChannelId})
    
    ' Handle deep linking - extract channel parameter
    channelId = invalid
    if args <> invalid and args.contentId <> invalid then
        channelId = args.contentId
        print "Deep link received: channelId = "; channelId
    end if
    
    scene = screen.CreateScene("MainScene")
    
    ' Pass channel ID to scene if provided
    if channelId <> invalid then
        scene.channelId = channelId
    end if
    
    screen.show()

    while(true) 
        msg = wait(0, m.port)
        msgType = type(msg)
        print "msgTYPE >>>>>>>>"; type(msg)
        if msgType = "roSGScreenEvent"
            if msg.isScreenClosed() then return
        end if
    end while
    
end sub
