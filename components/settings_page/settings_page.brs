' Settings overlay for choosing startup channel and opening playlist editor

sub init()
    m.list = m.top.findNode("settingsList")
    m.subtitle = m.top.findNode("settingsSubtitle")

    m.top.requestPlaylistDialog = false
    m.top.selectedChannelId = ""
    m.top.requestImportChannels = false

    m.top.ObserveField("content", "onContentChanged")
    m.top.ObserveField("defaultChannelId", "onContentChanged")
    m.top.ObserveField("visible", "onVisibilityChanged")
end sub

sub onVisibilityChanged()
    if m.top.visible then
        m.top.setFocus(true)
        m.list.SetFocus(true)
    end if
end sub

sub onContentChanged()
    ' Build list content from playlist data
    root = CreateObject("roSGNode", "ContentNode")

    changeItem = root.CreateChild("ContentNode")
    changeItem.title = "Change playlist URL"
    changeItem.id = "changePlaylist"

    importItem = root.CreateChild("ContentNode")
    importItem.title = "Add channels from master playlist"
    importItem.id = "importChannels"

    contentNode = m.top.content
    channelIndex = 0

    if contentNode <> invalid and contentNode.getChildCount() > 0
        if contentNode.getChild(0).getChild(0) = invalid then
            ' Flat list
            for i = 0 to contentNode.getChildCount() - 1
                root.AppendChild(createChannelItem(contentNode.getChild(i), channelIndex))
                channelIndex = channelIndex + 1
            end for
        else
            ' Grouped list
            for g = 0 to contentNode.getChildCount() - 1
                group = contentNode.getChild(g)
                for i = 0 to group.getChildCount() - 1
                    root.AppendChild(createChannelItem(group.getChild(i), channelIndex))
                    channelIndex = channelIndex + 1
                end for
            end for
        end if
    end if

    m.list.content = root

    ' Pre-select default channel (offset by 2 because of the change URL and import items)
    defaultIndex = m.top.defaultChannelId.ToInt()
    if defaultIndex < 0 then defaultIndex = 0
    preselect = defaultIndex + 2
    total = m.list.content.getChildCount()
    if preselect >= total
        preselect = total - 1
    end if
    if preselect >= 0 and total > 0
        m.list.itemSelected = preselect
    end if
end sub

function createChannelItem(node as Object, idx as Integer) as Object
    item = CreateObject("roSGNode", "ContentNode")
    title = node.title
    if title = invalid or title = "" then title = "Channel " + idx.ToStr()
    item.title = idx.ToStr() + ": " + title
    item.id = idx.ToStr()
    return item
end function

function onKeyEvent(key as String, press as Boolean) as Boolean
    if not press then return false

    if key = "back"
        m.top.visible = false
        return true
    else if key = "OK" or key = "Select" or key = "select"
        idx = m.list.itemSelected
        if idx = 0
            m.top.requestPlaylistDialog = true
        else if idx = 1
            m.top.requestImportChannels = true
        else if idx > 1
            m.top.selectedChannelId = (idx - 2).ToStr()
        end if
        m.top.visible = false
        return true
    end if

    return false
end function
