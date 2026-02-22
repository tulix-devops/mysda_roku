' Function to parse actor data
function parseActor(data as object) as object
    actorEntity = []
    for each actor in data
        actorMap = {
            "id": actor["id"],
            "storageRecordId": actor["storageRecordId"],
            "storageRecordTypeId": actor["storageRecordTypeId"],
            "title": actor["title"],
            "description": actor["description"],
            "birthYear": actor["birthYear"]
        }
        actorEntity.push(actorMap)
    end for

    return actorEntity
end function

' Function to parse category data
function parseCategory(data) as object
    categoryEntity = []
    for each cat in data
        catMap = {
            "id": cat["id"],
            "title": cat["title"],
            "menuVisible": cat["menuVisible"],
            "homeVisible": cat["homeVisible"],
        }
        categoryEntity.push(catMap)
    end for
    return categoryEntity
end function

' Function to parse country data
function parseCountry(data) as object

    return {
        "id": data["id"],
        "name": data["name"],
    }
end function


function parseEpisodes(data) as object
    episodeEntity = []
    for each episode in data

        ' print episode
        ' print "Episodes"
        entityMap = {
            "id": episode["id"],
            "videoId": episode["videoId"],
            "title": episode["title"],
            "description": episode["description"],
            "storageRecord": episode["storageRecord"],
            "seasonNumber": episode["seasonNumber"],
            "episodeNumber": episode["episodeNumber"],
            "language": episode["language"],
            "chapters": episode["chapters"],
        }
       
        episodeEntity.push(entityMap)
    end for
    
    return episodeEntity
end function

' Main function to parse VodEntity from a JSON string
function parseHomeVodEntity(jsonString as string) as object
    vodData = ParseJSON(jsonString).data
    ' print type(vodData)
    ' print vodData
    ' print "VodData Type"
    homeData = []
    parsedData = {}
    for each cat in vodData
        VodDataByIndex = {
            "categoryName": cat,
            "VodEntityData": parseVodEntity(vodData[cat])
        }
        homeData.push(VodDataByIndex)
    end for
    return homeData
end function


function parseVodEntity(jsonString) as object
    vodData = jsonString
    parsedVodEntity = []
    indexId = 0
    for each vod in vodData
        ' episodes = parseEpisodes(vod["episodes"])
        print vod
        print "Here is Vod We are LookingFor"
        vodEntity = {
            "countryId": vod["countryId"],
            "description": vod["description"],
            "id": vod["id"],
            "indexId": indexId
            "statusId": vod["statusId"],
            "title": vod["title"],
            "type": vod["type"],
            "typeId": vod["typeId"],
            "sources" : vod["sources"],
            "images" : vod["images"],
            "attributes" : vod["attributes"],
            "duration" : vod["duration"],
            "dvr_url": vod["dvr_url"]
        }
        indexId++

        parsedVodEntity.push(vodEntity)
    end for
    return parsedVodEntity
end function

' VOD SCREEN DATA PARSER
function parseVodScreenEntity(jsonString, limit) as object
    if ParseJSON(jsonString) = invalid
        return []
    end if
    vodData = ParseJSON(jsonString).data
    parsedVodEntity = []
    indexId = 0
    cnt = 0
    for each vod in vodData
        if limit > 0
            cnt = cnt + 1

            if cnt > limit
                exit for
            end if
        end if

        vodEntity = {
            "countryId": vod["countryId"],
            "description": vod["description"],
            "id": vod["id"],
            "indexId": indexId
            "statusId": vod["statusId"],
            "title": vod["title"],
            "type": vod["type"],
            "typeId": vod["typeId"],
            "images": vod["images"],
            "sources" : vod["sources"],
            "attributes" : vod["attributes"],
            "duration" : vod["duration"],
            "seasons" : vod["seasons"],
            "dvr_url": vod["dvr_url"]
        }
        indexId++
        parsedVodEntity.push(vodEntity)
    end for
    return parsedVodEntity
end function

function parseEPGScreenEntity(jsonString as String, limit as Integer) as Object
    parsedVodEntity = []
    indexId = 0
    cnt = 0

    data = ParseJSON(jsonString)
    print data.data
    print "Here is PARSED DVRITEM DATA"
    if data = invalid or data.data = invalid
        return parsedVodEntity
    end if
    
    vodGroupedByDate = data.data
    
    ' 🚀 Manually collect keys in order
    orderedDateKeys = []
    for each key in data.data
        orderedDateKeys.push(key)
    end for
    
    ' Now iterate over the preserved order
    for each dateKey in orderedDateKeys
        vodList = vodGroupedByDate[dateKey]
    
        for each vod in vodList
            if limit > 0
                cnt = cnt + 1
                if cnt > limit
                    return parsedVodEntity
                end if
            end if
    
            vodEntity = {
                "date": dateKey,
                "id": vod.id,
                "start": vod.start,
                "end": vod.end,
                "ogStart": vod.ogStart,
                "name": vod.name,
                "link": vod.link,
                "thumbnail": vod.thumbnail,
                "isFuture": vod.isFuture,
                "description": vod.description,
                "indexId": indexId
            }
    
            parsedVodEntity.push(vodEntity)
            indexId = indexId + 1
        end for
    end for
    print parsedVodEntity[0]
    PRINT parsedVodEntity[1]
    print "Here is Parsed DVRITEM"
    return parsedVodEntity
end function

' DVR RECORDINGS PARSER - Keep native structure with time formatting
function parseDvrRecordingsEntity(jsonString as String, limit as Integer) as Object
    parsedDvrEntity = []
    indexId = 0
    cnt = 0

    data = ParseJSON(jsonString)
    if data = invalid
        print "Invalid DVR recordings data"
        return parsedDvrEntity
    end if
    
    recordings = data.recordings
    dvrItem = data.dvrItem
    
    if recordings = invalid or recordings.count() = 0
        print "No recordings found"
        return parsedDvrEntity
    end if
    
    print "Parsing " + recordings.count().ToStr() + " DVR recordings"
    
    ' Extract parent DVR image once - all recordings use this
    parentBanner = ""
    if dvrItem <> invalid
        ' Try different possible image field names from parent
        if dvrItem.images <> invalid and dvrItem.images.banner <> invalid
            parentBanner = dvrItem.images.banner
        else if dvrItem.image <> invalid
            parentBanner = dvrItem.image
        else if dvrItem.thumbnail <> invalid
            parentBanner = dvrItem.thumbnail
        else if dvrItem.logo <> invalid
            parentBanner = dvrItem.logo
        end if
        print "Using parent DVR image: " + parentBanner
    end if
    
    for each recording in recordings
        if limit > 0
            cnt = cnt + 1
            if cnt > limit
                exit for
            end if
        end if
        
        ' Format time range for display (e.g., "01:00 AM - 01:28 AM")
        timeSchedule = formatDvrTimeRange(recording.starttime, recording.endtime)
        
        ' All recordings use parent DVR image for grid
        dvrEntity = {
            "id": recording.id,
            "indexId": indexId,
            "title": recording.title,
            "description": recording.descr,
            "duration": recording.duration,
            "starttime": recording.starttime,
            "endtime": recording.endtime,
            "timeSchedule": timeSchedule,
            "thumb": recording.thumb,
            "stream": recording.stream,
            "downloadurl": recording.downloadurl,
            "images": {
                "banner": parentBanner
            },
            "sources": {
                "primary": recording.stream,
                "download": recording.downloadurl
            },
            "type": "dvr",
            "typeId": 99,
            "statusId": 1
        }
        
        ' Add DVR parent item info
        if dvrItem <> invalid
            if dvrItem.title <> invalid then dvrEntity.channelTitle = dvrItem.title
            if dvrItem.id <> invalid then dvrEntity.channelId = dvrItem.id
        end if
        
        parsedDvrEntity.push(dvrEntity)
        indexId = indexId + 1
    end for
    
    print "Successfully parsed " + parsedDvrEntity.count().ToStr() + " DVR recordings"
    return parsedDvrEntity
end function

' Format DVR time range (just time, no date)
' Input: "2025-10-13T01:00:00-05:00", "2025-10-13T01:28:30-05:00"
' Output: "01:00 AM - 01:28 AM"
function formatDvrTimeRange(startTime as String, endTime as String) as String
    if startTime = invalid or startTime = "" or endTime = invalid or endTime = ""
        return ""
    end if
    
    startFormatted = extractTimeFromISO(startTime)
    endFormatted = extractTimeFromISO(endTime)
    
    if startFormatted <> "" and endFormatted <> ""
        return startFormatted + " - " + endFormatted
    end if
    
    return ""
end function

' Extract and format time from ISO timestamp
' Input: "2025-10-13T01:00:00-05:00"
' Output: "01:00 AM"
function extractTimeFromISO(isoTimestamp as String) as String
    if isoTimestamp = invalid or isoTimestamp = ""
        return ""
    end if
    
    ' Split by "T" to get time part
    parts = isoTimestamp.Split("T")
    if parts.count() < 2
        return ""
    end if
    
    timePart = parts[1]  ' "01:00:00-05:00"
    
    ' Parse time
    timeComponents = timePart.Split(":")
    if timeComponents.count() < 2
        return ""
    end if
    
    hour = val(timeComponents[0])
    minute = timeComponents[1]
    
    ' Convert to 12-hour format
    ampm = "AM"
    if hour >= 12
        ampm = "PM"
        if hour > 12
            hour = hour - 12
        end if
    else if hour = 0
        hour = 12
    end if
    
    ' Format: "01:00 AM"
    formatted = hour.ToStr() + ":" + minute + " " + ampm
    return formatted
end function

' Convert DVR recordings to EPG format (grouped by date)
function convertDvrRecordingsToEpg(jsonString as String) as Object
    parsedEpgEntity = []
    indexId = 0

    data = ParseJSON(jsonString)
    if data = invalid
        print "Invalid DVR recordings data for EPG conversion"
        return parsedEpgEntity
    end if
    
    recordings = data.recordings
    
    if recordings = invalid or recordings.count() = 0
        print "No recordings to convert to EPG"
        return parsedEpgEntity
    end if
    
    print "Converting " + recordings.count().ToStr() + " DVR recordings to EPG format"
    
    for each recording in recordings
        ' Extract date from starttime (e.g., "2025-10-13T00:00:00-05:00" -> "2025-10-13")
        dateStr = extractDateFromTimestamp(recording.starttime)
        
        ' Format time range for display
        timeSchedule = formatDvrTimeRange(recording.starttime, recording.endtime)
        
        ' Add time to title: "PROGRAM NAME • 01:00 AM - 01:28 AM"
        displayName = recording.title
        if timeSchedule <> ""
            displayName = recording.title + " • " + timeSchedule
        end if
        
        epgEntity = {
            "date": dateStr,
            "id": recording.id,
            "start": recording.starttime,
            "end": recording.endtime,
            "ogStart": recording.starttime,
            "name": displayName,
            "link": recording.stream,
            "thumbnail": recording.thumb,
            "isFuture": false,
            "description": recording.descr,
            "indexId": indexId
        }
        
        parsedEpgEntity.push(epgEntity)
        indexId = indexId + 1
    end for
    
    print "Successfully converted to " + parsedEpgEntity.count().ToStr() + " EPG entries"
    return parsedEpgEntity
end function

' Helper function to extract date from ISO timestamp
function extractDateFromTimestamp(timestamp as String) as String
    if timestamp = invalid or timestamp = ""
        return ""
    end if
    
    ' Extract date part from "2025-10-13T00:00:00-05:00"
    parts = timestamp.Split("T")
    if parts.count() > 0
        return parts[0]
    end if
    
    return ""
end function



