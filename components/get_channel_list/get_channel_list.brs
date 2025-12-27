sub init()
	m.top.functionName = "getContent"
end sub

' **********************************************

sub getContent()
	' Read from local 1.m3u file instead of URL
	text = ReadAsciiFile("pkg:/1.m3u")

	reHasGroups = CreateObject("roRegex", "group-title\=" + chr(34) + "?([^" + chr(34) + "]*)"+chr(34)+"?,","")
	hasGroups = reHasGroups.isMatch(text)
	print hasGroups

	reLineSplit = CreateObject ("roRegex", "(?>\r\n|[\r\n])", "")
	reExtinf = CreateObject ("roRegex", "(?i)^#EXTINF:\s*(\d+|-1|-0).*,\s*(.*)$", "")

	rePath = CreateObject ("roRegex", "^([^#].*)$", "")
	inExtinf = false
	con = CreateObject("roSGNode", "ContentNode")
	if not hasGroups
		group = con
	else
		groups = []
	end if

	channelIndex = 0
	
	REM #EXTINF:-1 tvg-logo="" group-title="uk",BBC ONE HD
	for each line in reLineSplit.Split (text)
		if inExtinf
			maPath = rePath.Match (line)
			if maPath.Count () = 2
				item = group.CreateChild("ContentNode")
				item.url = maPath [1]
				' Prepend channel ID to title
				item.title = "[" + channelIndex.ToStr() + "] " + title

				channelIndex = channelIndex + 1
				inExtinf = False
			end if
		end if
		maExtinf = reExtinf.Match (line)
		if maExtinf.Count () = 3
			if hasGroups
				groupName = reHasGroups.Match(line)[1]
				group = invalid
				REM Don't know why, but FindNode refused to work here
				for x = 0 to con.getChildCount()-1
					node = con.getChild(x)
					if node.id = groupName
						group = node
						exit for
					end if
				end for
				if group = invalid
					group = con.CreateChild("ContentNode")
					group.contenttype = "SECTION"
					group.title = groupName
					group.id = groupName
				end if
			end if
			length = maExtinf[1].ToInt ()
			if length < 0 then length = 0
			title = maExtinf[2]
			inExtinf = True
		end if
	end for

	' Prepend Favorites group from registry (if any)
	reg = CreateObject("roRegistrySection", "profile")
	if reg.Exists("favorites") then
		favJson = reg.Read("favorites")
		favs = ParseJson(favJson)
		if favs <> invalid and favs.Count() > 0 then
			favGroup = con.CreateChild("ContentNode")
			favGroup.contenttype = "SECTION"
			favGroup.title = "Favorites"
			favGroup.id = "Favorites"

			for each fav in favs
				if fav <> invalid and fav.url <> invalid then
					item = favGroup.CreateChild("ContentNode")
					item.url = fav.url
					item.title = fav.title
				end if
			end for
		end if
	end if

	m.top.content = con
end sub
