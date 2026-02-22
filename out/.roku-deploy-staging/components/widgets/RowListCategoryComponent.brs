sub init()
    m.categoryTitle = m.top.findNode("categoryTitle")
    m.placeholderRectangle = m.top.findNode("placeholderRectangle")

end sub

sub OnContentSet()
    print "CATEGORY SSET"
    content = m.top.itemContent
    content.observeField("keyPressed", "onKeyPressed")
    if content <> invalid
        setCategoryText(content)
        onSelectedChanged(content)


        if content.isdvr = true then
            m.placeholderRectangle.width = 300
            m.placeholderRectangle.height = 120
            m.categoryTitle.width = 300
            m.categoryTitle.height = 120
            m.categoryTitle.font.size = 32
        else
            m.placeholderRectangle.width = 150
            m.placeholderRectangle.height = 60
            m.categoryTitle.width = 150
            m.categoryTitle.height = 60
            m.categoryTitle.font.size = 20
        end if
    end if
end sub


sub setCategoryText(content)
    print content
    print content.data
    print "Here is content Of Category Text"

    if content.categoryName <> invalid
        title = content.categoryName
        if len(title) > 27
            title = left(title, 24) + "...."
        end if
        m.categoryTitle.text = title
    else
        if content.data.name <> invalid
            title = content.data.name
            if len(title) > 27
                title = left(title, 24) + "...."
            end if
            m.categoryTitle.text = title
        else m.categoryTitle.text = ""
        end if
    end if


end sub


sub onSelectedChanged(content)
    if content.isSelected <> invalid
        if content.isSelected = true then
            m.placeholderRectangle.color = "0x007199"
        else
            m.placeholderRectangle.color = "#9E9E9E26"
        end if
    end if

end sub



