sub init()
    m.top.backgroundURI = "pkg:/images/background-controls.jpg"

    m.save_feed_url = m.top.FindNode("save_feed_url")  'Save url to registry

    m.get_channel_list = m.top.FindNode("get_channel_list") 'get url from registry and parse the feed
    m.get_channel_list.ObserveField("content", "SetContent") 'Is thre content parsed? If so, goto SetContent sub and dsipay list

    m.list = m.top.FindNode("list")
    m.list.ObserveField("itemSelected", "setChannel") 

    m.video = m.top.FindNode("Video")
    m.video.ObserveField("state", "checkState")

    m.settings = m.top.FindNode("settings_page")
    m.settings.ObserveField("selectedChannelId", "onStartupChannelSelected")
    m.settings.ObserveField("requestPlaylistDialog", "onSettingsPlaylistRequested")
    m.settings.ObserveField("requestImportChannels", "onImportChannelsRequested")
    m.settings.ObserveField("visible", "onSettingsVisibility")

    m.browse_master = m.top.FindNode("browse_master")
    m.browse_master.ObserveField("selectedChannels", "onChannelsImported")
    m.browse_master.ObserveField("visible", "onBrowseVisibility")

    ' Observe channelId for deep linking
    m.top.ObserveField("channelId", "onChannelIdChanged")

    ' Load channels from local 1.m3u file automatically
    m.get_channel_list.control = "RUN"
End sub

' **************************************************************

function onKeyEvent(key as String, press as Boolean) as Boolean
    result = false
    
    if(press)'
    
    
        if(key = "right")
            m.list.SetFocus(false)
            m.video.SetFocus(true)
            m.video.translation = [0, 0]
            m.video.width = 1920
            m.video.height = 1080
            result = true
        else if(key = "left")
            m.list.SetFocus(true)
            m.video.translation = [800, 100]
            m.video.width = 960
            m.video.height = 540
            result = true
        else if(key = "back")
            m.list.SetFocus(true)
            m.video.translation = [800, 100]
            m.video.width = 960
            m.video.height = 540
            result = true
        else if(key = "options")
            toggleSettings()
            result = true
        end if
    end if
    
    return result 
end function


sub checkState()
    state = m.video.state
    if(state = "error")
        m.top.dialog = CreateObject("roSGNode", "Dialog")
        m.top.dialog.title = "Error: " + str(m.video.errorCode)
        m.top.dialog.message = m.video.errorMsg
    end if
end sub

sub SetContent()    
    m.list.content = m.get_channel_list.content
    m.list.SetFocus(true)
    
    ' If channelId was set via deep link, play that channel
    if m.top.channelId <> invalid and m.top.channelId <> "" then
        playChannelById(m.top.channelId)
    else
        ' Auto-play configured startup channel (defaults to 0)
        playChannelById(m.global.startupChannelId)
    end if
end sub

sub setChannel()
	if m.list.content.getChild(0).getChild(0) = invalid
		content = m.list.content.getChild(m.list.itemSelected)
	else
		itemSelected = m.list.itemSelected
		for i = 0 to m.list.currFocusSection - 1
			itemSelected = itemSelected - m.list.content.getChild(i).getChildCount()
		end for
		content = m.list.content.getChild(m.list.currFocusSection).getChild(itemSelected)
	end if

	'Probably would be good to make content = content.clone(true) but for now it works like this
	content.streamFormat = "hls, mp4, mkv, mp3, avi, m4v, ts, mpeg-4, flv, vob, ogg, ogv, webm, mov, wmv, asf, amv, mpg, mp2, mpeg, mpe, mpv, mpeg2"

	if m.video.content <> invalid and m.video.content.url = content.url return

	content.HttpSendClientCertificates = true
	content.HttpCertificatesFile = "common:/certs/ca-bundle.crt"
	m.video.EnableCookies()
	m.video.SetCertificatesFile("common:/certs/ca-bundle.crt")
	m.video.InitClientCertificates()

	m.video.content = content

	m.top.backgroundURI = "pkg:/images/rsgde_bg_hd.jpg"
	m.video.trickplaybarvisibilityauto = false

	' Play video in fullscreen
	m.list.SetFocus(false)
	m.video.SetFocus(true)
	m.video.translation = [0, 0]
	m.video.width = 1920
	m.video.height = 1080

	m.video.control = "play"
end sub


sub showdialog()
    PRINT ">>>  ENTERING KEYBOARD <<<"


    keyboarddialog = createObject("roSGNode", "KeyboardDialog")
    keyboarddialog.backgroundUri = "pkg:/images/rsgde_bg_hd.jpg"
    keyboarddialog.title = "ENTER PLAYLIST HERE"

    keyboarddialog.buttons=["OK","Set back to Demo", "Save"]
    keyboarddialog.optionsDialog=true

    m.top.dialog = keyboarddialog
    m.top.dialog.text = m.global.feedurl
    m.top.dialog.keyboard.textEditBox.cursorPosition = len(m.global.feedurl)
    m.top.dialog.keyboard.textEditBox.maxTextLength = 300

    KeyboardDialog.observeFieldScoped("buttonSelected","onKeyPress")  'we observe button ok/cancel, if so goto to onKeyPress sub
end sub


sub onKeyPress()
    if m.top.dialog.buttonSelected = 0 ' OK
        url = m.top.dialog.text
        m.global.feedurl = url
        m.save_feed_url.control = "RUN"
        m.top.dialog.close = true
        m.get_channel_list.control = "RUN"
    else if m.top.dialog.buttonSelected = 1 ' Set back to Demo
        m.top.dialog.text = "https://tinyurl.com/yaoc6zpo"
    else if m.top.dialog.buttonSelected = 2 ' Save
        m.global.feedurl = m.top.dialog.text
        m.save_feed_url.control = "RUN"
        '    m.top.dialog.visible ="false"
        '    m.top.unobserveField("buttonSelected")
    end if
end sub

' **************************************************************
' Settings handling
' **************************************************************

sub toggleSettings()
    if m.settings = invalid then return

    if m.settings.visible
        m.settings.visible = false
    else
        ' Populate settings with current content and defaults
        m.settings.content = m.list.content
        m.settings.defaultChannelId = m.global.startupChannelId
        m.settings.visible = true
        m.settings.setFocus(true)
        m.list.SetFocus(false)
        m.video.SetFocus(false)
    end if
end sub

sub onStartupChannelSelected()
    channelId = m.settings.selectedChannelId
    if channelId = invalid or channelId = "" then return

    m.global.startupChannelId = channelId

    ' Persist to registry
    reg = CreateObject("roRegistrySection", "profile")
    reg.Write("startupChannelId", channelId)
    reg.Flush()

    ' Start playing the chosen channel immediately
    playChannelById(channelId)

    ' Return focus to list after selection
    m.settings.visible = false
end sub

sub onSettingsPlaylistRequested()
    if m.settings.requestPlaylistDialog = true
        m.settings.requestPlaylistDialog = false
        m.settings.visible = false
        showdialog()
    end if
end sub

sub onSettingsVisibility()
    ' When settings closes, restore list focus
    if not m.settings.visible
        m.list.SetFocus(true)
    end if
end sub

' **************************************************************
' Browse master playlist
' **************************************************************

sub onImportChannelsRequested()
    if m.settings.requestImportChannels = true
        m.settings.requestImportChannels = false
        
        ' Try to read master URL from .env (won't work on Roku, so use hardcoded for now)
        masterUrl = "https://iptv-org.github.io/iptv/master.m3u"
        
        m.browse_master.masterUrl = masterUrl
        m.browse_master.visible = true
        m.browse_master.setFocus(true)
        m.list.SetFocus(false)
    end if
end sub

sub onChannelsImported()
    selectedChannels = m.browse_master.selectedChannels
    if selectedChannels = invalid or selectedChannels.Count() = 0 then return

    ' Read current playlist
    currentText = ReadAsciiFile("pkg:/1.m3u")
    
    ' Append selected channels
    newLines = []
    for each key in selectedChannels
        channel = selectedChannels[key]
        newLines.Push("#EXTINF:-1,")
        newLines.Push(channel.title)
        newLines.Push(channel.url)
    end for

    ' TODO: Write new m3u file to registry or temp storage since we can't write to pkg:/
    ' For now, just show a message
    dialog = CreateObject("roSGNode", "Dialog")
    dialog.title = "Import Complete"
    dialog.message = selectedChannels.Count().ToStr() + " channels imported. App needs restart to load new channels."
    m.top.dialog = dialog

    m.browse_master.visible = false
    m.list.SetFocus(true)
end sub

sub onBrowseVisibility()
    if not m.browse_master.visible
        m.list.SetFocus(true)
    end if
end sub

' **************************************************************
' Deep linking support
' **************************************************************

sub onChannelIdChanged()
    ' Called when channelId is set via deep link
    if m.list.content <> invalid then
        playChannelById(m.top.channelId)
    end if
end sub

sub playChannelById(channelId as String)
    ' Play channel by index (0-based) or by title match
    print "Playing channel: "; channelId
    
    if m.list.content = invalid then return
    
    ' Try to parse as numeric index first
    channelIndex = channelId.ToInt()
    
    ' Check if we have grouped content or flat list
    if m.list.content.getChild(0).getChild(0) = invalid then
        ' Flat list
        totalChannels = m.list.content.getChildCount()
        if channelIndex >= 0 and channelIndex < totalChannels then
            m.list.itemSelected = channelIndex
            setChannel()
        end if
    else
        ' Grouped list - navigate to the channel
        currentIndex = 0
        for groupIdx = 0 to m.list.content.getChildCount() - 1
            group = m.list.content.getChild(groupIdx)
            for itemIdx = 0 to group.getChildCount() - 1
                if currentIndex = channelIndex then
                    m.list.jumpToItem = currentIndex
                    m.list.itemSelected = currentIndex
                    setChannel()
                    return
                end if
                currentIndex = currentIndex + 1
            end for
        end for
    end if
end sub
