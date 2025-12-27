' Async task to download and parse master M3U with detailed status

sub init()
    m.top.functionName = "run"
end sub

sub run()
    ts = CreateObject("roTimespan")
    ts.Mark()

    url = m.top.url
    if url = invalid or url = "" then
        m.top.status = "No URL provided"
        m.top.error = "missing_url"
        return
    end if

    m.top.status = "Starting download: " + url

    http = CreateObject("roUrlTransfer")
    http.SetCertificatesFile("common:/certs/ca-bundle.crt")
    http.InitClientCertificates()
    http.SetUrl(url)

    response = ""
    ' Perform download (synchronous within Task)
    response = http.GetToString()

    if response = invalid or response = "" then
        m.top.responseLength = 0
        m.top.status = "Download failed"
        m.top.error = "download_failed"
        m.top.durationMs = ts.TotalMilliseconds()
        return
    end if

    m.top.responseLength = len(response)
    m.top.status = "Downloaded " + str(len(response)) + " bytes. Parsing..."

    ' Parse
    lines = response.Split(chr(10))
    reExtinf = CreateObject("roRegex", "(?i)^#EXTINF:\s*(\d+|-1|-0).*,\s*(.*)$", "")
    reHasGroups = CreateObject("roRegex", "group-title\=" + chr(34) + "?([^" + chr(34) + "]*)"+chr(34)+"?,","")
    rePath = CreateObject("roRegex", "^([^#].*)$", "")

    groups = {}
    inExtinf = false
    title = ""
    groupName = "Uncategorized"
    channelsParsed = 0

    for each line in lines
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
            ' Update status periodically for visibility
        else if inExtinf then
            maPath = rePath.Match(line)
            if maPath.Count() = 2 then
                if groups[groupName] = invalid then
                    groups[groupName] = []
                end if
                groups[groupName].Push({ title: title, url: maPath[1] })
                channelsParsed = channelsParsed + 1
                inExtinf = false
                if (channelsParsed mod 100) = 0 then
                    m.top.status = "Parsed channels: " + str(channelsParsed)
                end if
            end if
        end if
    end for

    ' Finalize
    m.top.groups = groups
    m.top.groupsCount = groups.Count()
    m.top.channelCount = channelsParsed
    m.top.status = "Parsed " + str(channelsParsed) + " channels across " + str(m.top.groupsCount) + " groups."
    m.top.durationMs = ts.TotalMilliseconds()
end sub
