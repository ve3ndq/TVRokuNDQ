' Manage/remove favorites stored in registry

sub init()
    m.list = m.top.findNode("favList")
    m.status = m.top.findNode("status")

    loadFavorites()
end sub

sub loadFavorites()
    reg = CreateObject("roRegistrySection", "profile")
    favJson = "[]"
    if reg.Exists("favorites") then favJson = reg.Read("favorites")
    favs = ParseJson(favJson)
    if favs = invalid then favs = []

    root = CreateObject("roSGNode", "ContentNode")
    for i = 0 to favs.Count() - 1
        fav = favs[i]
        if fav <> invalid and fav.url <> invalid
            item = root.CreateChild("ContentNode")
            item.title = fav.title
            item.id = fav.url
        end if
    end for

    m.list.content = root
    if root.getChildCount() > 0 then
        m.list.itemSelected = 0
    end if

    if root.getChildCount() = 0 then
        m.status.text = "No favorites saved."
    else
        m.status.text = "Select a favorite and press OK to remove."
    end if
end sub

function onKeyEvent(key as String, press as Boolean) as Boolean
    if not press then return false

    if key = "back"
        m.top.visible = false
        return true
    else if key = "OK" or key = "Select" or key = "select"
        removeSelected()
        return true
    end if

    return false
end function

sub removeSelected()
    idx = m.list.itemSelected
    if idx = invalid or m.list.content = invalid then return

    item = m.list.content.getChild(idx)
    if item = invalid then return

    url = item.id

    ' Load
    reg = CreateObject("roRegistrySection", "profile")
    favJson = "[]"
    if reg.Exists("favorites") then favJson = reg.Read("favorites")
    favs = ParseJson(favJson)
    if favs = invalid then favs = []

    ' Filter out selected URL
    newFavs = []
    removedTitle = item.title
    for each f in favs
        if f <> invalid and f.url <> invalid and f.url <> url
            newFavs.Push(f)
        end if
    end for

    reg.Write("favorites", FormatJson(newFavs))
    reg.Flush()

    m.status.text = "Removed: " + removedTitle

    ' Refresh list
    loadFavorites()
end sub
