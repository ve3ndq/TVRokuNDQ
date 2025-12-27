' Browse and add channels from master playlist

sub init()
    m.groupsList = m.top.findNode("groupsList")
    m.channelsList = m.top.findNode("channelsList")
    m.loadingLabel = m.top.findNode("loadingLabel")
    m.statusLabel = m.top.findNode("statusLabel")

    m.groups = {}
    m.selectedChannels = {}
    m.currentGroup = ""
    m.focusLeft = true

    m.top.ObserveField("masterUrl", "onMasterUrlChanged")
    m.top.ObserveField("content", "onContentChanged")

    m.groupsList.ObserveField("itemSelected", "onGroupSelected")
    m.channelsList.ObserveField("itemSelected", "onChannelToggle")

    ' Async fetch task wiring
    m.fetchTask = m.top.findNode("fetchTask")
    if m.fetchTask <> invalid then
        m.fetchTask.ObserveField("status", "onFetchStatus")
        m.fetchTask.ObserveField("groups", "onFetchGroups")
        m.fetchTask.ObserveField("error", "onFetchError")
    end if
end sub

sub onMasterUrlChanged()
    if m.top.masterUrl = "" or m.top.masterUrl = invalid then return

    m.loadingLabel.visible = true
    m.statusLabel.visible = true
    m.groupsList.visible = false
    m.channelsList.visible = false
    m.statusLabel.text = "Fetching master playlist..."

    ' Start async fetch task if available
    if m.fetchTask <> invalid then
        m.fetchTask.url = m.top.masterUrl
        m.fetchTask.control = "RUN"
    else
        ' Fallback to synchronous parsing (may block UI)
        parseMasterPlaylist(m.top.masterUrl)
    end if
end sub

sub parseMasterPlaylist(url as String)
    http = CreateObject("roUrlTransfer")
    http.setUrl(url)
    http.SetCertificatesFile("common:/certs/ca-bundle.crt")
    http.initClientCertificates()

    m.statusLabel.text = "Downloading: " + url
    response = http.GetToString()

    if response = "" then
        m.statusLabel.text = "Failed to download master playlist"
        m.loadingLabel.visible = false
        return
    end if

    m.statusLabel.text = "Parsing master playlist..."

    ' Parse M3U
    lines = response.Split(chr(10))
    reExtinf = CreateObject("roRegex", "(?i)^#EXTINF:\s*(\d+|-1|-0).*,\s*(.*)$", "")
    reHasGroups = CreateObject("roRegex", "group-title\=" + chr(34) + "?([^" + chr(34) + "]*)"+chr(34)+"?,","")
    rePath = CreateObject("roRegex", "^([^#].*)$", "")

    inExtinf = false
    title = ""
    groupName = "Uncategorized"

    for each line in lines
        if inExtinf then
            maPath = rePath.Match(line)
            if maPath.Count() = 2 then
                if m.groups[groupName] = invalid then
                    m.groups[groupName] = []
                end if
                m.groups[groupName].Push({title: title, url: maPath[1]})
                inExtinf = false
            end if
        end if

        maExtinf = reExtinf.Match(line)
        if maExtinf.Count() = 3 then
            groupMatch = reHasGroups.Match(line)
            if groupMatch.Count() = 2 then
                groupName = groupMatch[1]
            else
                groupName = "Uncategorized"
            end if
            title = maExtinf[2]
            inExtinf = true
        end if
    end for

    ' Build groups list
    groupsRoot = CreateObject("roSGNode", "ContentNode")
    for each groupKey in m.groups
        item = groupsRoot.CreateChild("ContentNode")
        item.title = groupKey + " (" + m.groups[groupKey].Count().ToStr() + ")"
        item.id = groupKey
    end for

    m.groupsList.content = groupsRoot
    m.currentGroup = ""

    m.loadingLabel.visible = false
    m.statusLabel.visible = true
    m.groupsList.visible = true
    m.channelsList.visible = true
    m.groupsList.SetFocus(true)
    m.focusLeft = true

    if groupsRoot.getChildCount() > 0 then
        m.groupsList.itemSelected = 0
        onGroupSelected()
    end if
end sub

sub onGroupSelected()
    idx = m.groupsList.itemSelected
    if idx < 0 or m.groupsList.content = invalid then return

    group = m.groupsList.content.getChild(idx)
    if group = invalid then return

    m.currentGroup = group.id
    channels = m.groups[m.currentGroup]

    ' Build channels list
    channelsRoot = CreateObject("roSGNode", "ContentNode")
    for each channel in channels
        item = channelsRoot.CreateChild("ContentNode")
        selected = m.selectedChannels[channel.title] <> invalid
        prefix = ""
        if selected then prefix = "[+] " else prefix = "[ ] "
        item.title = prefix + channel.title
        item.id = channel.title
    end for

    m.channelsList.content = channelsRoot
    if channelsRoot.getChildCount() > 0 then
        m.channelsList.itemSelected = 0
    end if

    m.statusLabel.text = "Select groups on left, toggle channels on right with OK"
end sub

sub onChannelToggle()
    idx = m.channelsList.itemSelected
    if idx < 0 or m.channelsList.content = invalid then return

    item = m.channelsList.content.getChild(idx)
    if item = invalid then return

    channelTitle = item.id
    channels = m.groups[m.currentGroup]

    ' Toggle selection
    if m.selectedChannels[channelTitle] <> invalid then
        m.selectedChannels.Delete(channelTitle)
    else
        ' Find the channel and store it
        for each channel in channels
            if channel.title = channelTitle then
                m.selectedChannels[channelTitle] = channel
                exit for
            end if
        end for
    end if

    ' Update display
    onGroupSelected()
end sub

function onKeyEvent(key as String, press as Boolean) as Boolean
    if not press then return false

    if key = "back"
        ' Don't close, let parent handle it
        return false
    else if key = "OK" or key = "Select" or key = "select"
        if m.focusLeft then
            m.focusLeft = false
            m.groupsList.SetFocus(false)
            m.channelsList.SetFocus(true)
        else
            onChannelToggle()
        end if
        return true
    else if key = "left"
        m.focusLeft = true
        m.groupsList.SetFocus(true)
        m.channelsList.SetFocus(false)
        return true
    else if key = "right"
        m.focusLeft = false
        m.groupsList.SetFocus(false)
        m.channelsList.SetFocus(true)
        return true
    end if

    return false
end function

' **************************************************************
' Async fetch handlers
' **************************************************************

sub onFetchStatus()
    if m.fetchTask = invalid then return
    msg = m.fetchTask.status
    if msg = invalid then return
    m.statusLabel.visible = true
    m.statusLabel.text = msg
end sub

sub onFetchError()
    if m.fetchTask = invalid then return
    err = m.fetchTask.error
    if err = invalid or err = "" then return
    m.loadingLabel.visible = false
    m.statusLabel.visible = true
    m.statusLabel.text = "Error: " + err
end sub

sub onFetchGroups()
    if m.fetchTask = invalid then return
    groups = m.fetchTask.groups
    if groups = invalid then return

    ' Persist parsed groups and rebuild lists
    m.groups = groups

    groupsRoot = CreateObject("roSGNode", "ContentNode")
    for each groupKey in m.groups
        item = groupsRoot.CreateChild("ContentNode")
        countStr = "0"
        if m.groups[groupKey] <> invalid then countStr = m.groups[groupKey].Count().ToStr()
        item.title = groupKey + " (" + countStr + ")"
        item.id = groupKey
    end for

    m.groupsList.content = groupsRoot
    m.currentGroup = ""

    m.loadingLabel.visible = false
    m.groupsList.visible = true
    m.channelsList.visible = true
    m.groupsList.SetFocus(true)
    m.focusLeft = true

    if groupsRoot.getChildCount() > 0 then
        m.groupsList.itemSelected = 0
        onGroupSelected()
    else
        m.statusLabel.visible = true
        m.statusLabel.text = "No groups found in master playlist"
    end if
end sub
