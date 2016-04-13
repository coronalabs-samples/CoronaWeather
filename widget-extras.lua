local widget = require("widget")

function widget.newPanel( options )
    local customOptions = options or {}
    local opt = {}

    opt.location = customOptions.location or "top"
    
    local default_width, default_height
    if ( opt.location == "top" or opt.location == "bottom" ) then
        default_width = display.contentWidth
        default_height = display.contentHeight * 0.33
    else
        default_width = display.contentWidth * 0.33
        default_height = display.contentHeight
    end
    
    opt.width = customOptions.width or default_width
    opt.height = customOptions.height or default_height
    opt.speed = customOptions.speed or 500
    opt.inEasing = customOptions.inEasing or easing.linear
    opt.outEasing = customOptions.outEasing or easing.linear

    if ( customOptions.onComplete and type(customOptions.onComplete) == "function" ) then
        opt.listener = customOptions.onComplete
    else
        opt.listener = nil
    end
    
    local container = display.newContainer( opt.width, opt.height )
    if ( opt.location == "left" ) then
        container.anchorX = 1.0
        container.x = display.screenOriginX
        container.anchorY = 0.5
        container.y = display.contentCenterY
    elseif ( opt.location == "right" ) then
        container.anchorX = 0.0
        container.x = display.actualContentWidth
        container.anchorY = 0.5
        container.y = display.contentCenterY
    elseif ( opt.location == "top" ) then
        container.anchorX = 0.5
        container.x = display.contentCenterX
        container.anchorY = 1.0
        container.y = display.screenOriginY
    else
        container.anchorX = 0.5
        container.x = display.contentCenterX
        container.anchorY = 0.0
        container.y = display.actualContentHeight
    end

    function container:show()
        local options = {
            time = opt.speed,
            transition = opt.inEasing
        }
        if ( opt.listener ) then
            options.onComplete = opt.listener
            self.completeState = "shown"
        end
        if ( opt.location == "top" ) then
            options.y = display.screenOriginY + opt.height
        elseif ( opt.location == "bottom" ) then
            options.y = display.actualContentHeight - opt.height
        elseif ( opt.location == "left" ) then
            options.x = display.screenOriginX + opt.width
        else
            options.x = display.actualContentWidth - opt.width
        end
        transition.to( self, options )
    end

    function container:hide()
        local options = {
            time = opt.speed,
            transition = opt.outEasing
        }
        if ( opt.listener ) then
            options.onComplete = opt.listener
            self.completeState = "hidden"
        end
        if ( opt.location == "top" ) then
            options.y = display.screenOriginY
        elseif ( opt.location == "bottom" ) then
            options.y = display.actualContentHeight
        elseif ( opt.location == "left" ) then
            options.x = display.screenOriginX
        else
            options.x = display.actualContentWidth
        end
        transition.to( self, options )
    end
    return container
end

function native.newScaledTextField(left, top, width, desiredFontSize)
    -- Measure the following font size's content height.
    -- Note: This text object is left on screen for testing purposes only.
    --       It is used to verify that the text object's font height matches the text field's font height.
    local fontSize = desiredFontSize or 40
    local textToMeasure = display.newText("X", display.contentCenterX, 0, native.systemFont, fontSize)
    local textHeight = textToMeasure.contentHeight
    textToMeasure:removeSelf()
    textToMeasure = nil

    -- Calculate what the text field's font size should be per-platform.
    local scaledFontSize = fontSize / display.contentScaleY
    local platformName = system.getInfo("platformName")
    if (platformName == "iPhone OS") then
        local modelName = system.getInfo("model")
        if (modelName == "iPad") or (modelName == "iPad Simulator") then
            scaledFontSize = scaledFontSize / (display.pixelWidth / 768)
        else
            scaledFontSize = scaledFontSize / (display.pixelWidth / 320)
        end
    elseif (platformName == "Android") then
        scaledFontSize = scaledFontSize / (system.getInfo("androidDisplayApproximateDpi") / 160)
    end

    -- Calculate a nice vertical margin between the text field's borders and its text.
    local textMargin = 20 * display.contentScaleY       -- Convert 20 pixels to content coordinates.
    if (platformName == "iPhone OS") then
        -- Apply iOS' scale factor, if applicable.
        local modelName = system.getInfo("model")
        if (modelName == "iPad") or (modelName == "iPad Simulator") then
            textMargin = textMargin * (display.pixelWidth / 768)
        else
            textMargin = textMargin * (display.pixelWidth / 320)
        end
    elseif (platformName == "Android") then
        -- Apply Android's scale factor, if applicable.
        textMargin = textMargin * (system.getInfo("androidDisplayApproximateDpi") / 160)
    end


    -- Create a text field that best fits the font size up above.
    local textField = native.newTextField(
            left,
            top,
            width,
            textHeight + textMargin)
    textField.size = scaledFontSize
    return textField, scaledFontSize
end

function native.getScaledFontSize(textField, desiredFontSize)
    local fontSize = desiredFontSize
    local textMargin = 10 * display.contentScaleY       -- Convert 20 pixels to content coordinates.
    local platformName = system.getInfo("platformName")

    if (platformName == "iPhone OS") then
        -- Apply iOS' scale factor, if applicable.
        local modelName = system.getInfo("model")
        if (modelName == "iPad") or (modelName == "iPad Simulator") then
            textMargin = textMargin * (display.pixelWidth / 768)
        else
            textMargin = textMargin * (display.pixelWidth / 320)
        end
    elseif (platformName == "Android") then
        -- Apply Android's scale factor, if applicable.
        textMargin = textMargin * (system.getInfo("androidDisplayApproximateDpi") / 160)
    end


    -- Calculate a font size that will best fit the above text fields height.

    local textToMeasure = display.newText("X", 0, 0, native.systemFont, fontSize)
    fontSize = fontSize * ((textField.contentHeight - textMargin) / textToMeasure.contentHeight)
    textToMeasure:removeSelf()
    textToMeasure = nil


    -- Update the above text field's font size to best fit its current height.
    -- Note: We have to convert the font size above for the text field's native units and scale.
    local nativeScaledFontSize = fontSize / display.contentScaleY
    if (platformName == "iPhone OS") then
        local modelName = system.getInfo("model")
        if (modelName == "iPad") or (modelName == "iPad Simulator") then
            nativeScaledFontSize = nativeScaledFontSize / (display.pixelWidth / 768)
        else
            nativeScaledFontSize = nativeScaledFontSize / (display.pixelWidth / 320)
        end
    elseif (platformName == "Android") then
        nativeScaledFontSize = nativeScaledFontSize / (system.getInfo("androidDisplayApproximateDpi") / 160)
    end
    return nativeScaledFontSize
end

function widget.newTextField(options)
    local customOptions = options or {}
    local opt = {}
    opt.left = customOptions.left or 0
    opt.top = customOptions.top or 0
    opt.x = customOptions.x or 0
    opt.y = customOptions.y or 0
    opt.width = customOptions.width or (display.contentWidth * 0.75)
    opt.height = customOptions.height or 20
    opt.id = customOptions.id
    opt.listener = customOptions.listener or nil
    opt.text = customOptions.text or ""
    opt.inputType = customOptions.inputType or "default"
    opt.isSecure = customOptions.isSecure or false
    opt.font = customOptions.font or native.systemFont
    opt.fontSize = customOptions.fontSize or opt.height * 0.67
    opt.fontColor = customOptions.fontColor or { 0.25, 0.25, 0.25 }
    opt.placeholder = customOptions.placeholder or nil
    opt.label = customOptions.label or ""
    opt.labelWidth = customOptions.labelWidth or opt.width * 0.10
    opt.labelFont = customOptions.labelFont or native.systemFontBold
    opt.labelFontSize = customOptions.labelFontSize or opt.fontSize
    opt.labelFontColor = customOptions.labelFontColor or { 0, 0, 0 }

    -- Vector options
    opt.strokeWidth = customOptions.strokeWidth or 2
    opt.cornerRadius = customOptions.cornerRadius or opt.height * 0.33 or 10
    opt.strokeColor = customOptions.strokeColor or {0, 0, 0}
    opt.backgroundColor = customOptions.backgroundColor or { 1, 1, 1 }

    local field = display.newGroup()
   
    local bgWidth = opt.width

    local background = display.newRoundedRect( 0, 0, bgWidth, opt.height, opt.cornerRadius )
    background:setFillColor(unpack(opt.backgroundColor))
    background.strokeWidth = opt.strokeWidth
    background.stroke = opt.strokeColor
    field:insert(background)

    if opt.left then
        field.x = opt.left + opt.width * 0.5
    elseif opt.left then
        field.x = opt.x
    end
    if opt.top then
        field.y = opt.top + opt.height * 0.5
    elseif opt.top then
        field.y = opt.y
    end

    -- Support adding a label.
    -- iOS 6 and earlier and Android draw the Label above the field.
    -- iOS 7 draws it in the field.
    local platformName = system.getInfo("platformName")
    print(platformName)
    local fieldLabel
    if  platformName == "iPhone OS" or platformName == "Mac OS X"  then
        local labelParameters = {
            x = 0,
            y = 0, 
            text = opt.label,
            width = opt.labelWidth,
            height = 0,
            font = opt.labelFont,
            fontSize = opt.labelFontSize, 
            align = "left"
        }

        fieldLabel = display.newText(labelParameters)
        fieldLabel:setFillColor(unpack(opt.labelFontColor))
        fieldLabel.x = background.x - bgWidth / 2 + opt.cornerRadius + opt.labelWidth * 0.5
        fieldLabel.y = background.y
        if not widget.isSeven() then
            fieldLabel.y = background.y + opt.height + 5
        end
        field:insert(fieldLabel)
    end
    -- create the native.newTextField to handle the input

    local labelPadding = 0
    if platformName == "iPhone OS" or platformName == "Mac OS X" then
        labelPadding = opt.labelWidth
    end

    local labelWidth = fieldLabel.width or 0
    print("labelWidth", labelWidth)
    field.textField = native.newTextField(0, 0, opt.width - opt.cornerRadius - labelPadding, opt.height )
    field.textField.x = labelWidth / 2
    field.textField.y = 0 -- tHeight / 2
    field.textField.anchorX = 0.5
    --field.textField.isVisible = false
    field.textField.hasBackground = false
    field.textField.inputType = opt.inputType
    field.textField.text = opt.text
    field.textField.isSecure = opt.isSecure
    field.textField.size = opt.fontSize
    field.textField.id = opt.id
    print(field.x, field.y, field.textField.x, field.textField.y)
    print(opt.listener, type(opt.listener))
    if opt.listener and type(opt.listener) == "function" then
        field.textField._listener = opt.listener
    end
    field.textField.placeholder = opt.placeholder
    field:insert(field.textField)

    -- Function to listen for textbox events
    function field.textField:_inputListener( event )
        local phase = event.phase
        
        -- If there is a listener defined, execute it
        if self._listener then
            self._listener( event )
        end
    end
    
    field.textField.userInput = field.textField._inputListener
    field.textField:addEventListener( "userInput" )
    --local nativeFontSize = native.getScaledFontSize( field.textField, opt.fontSize )

    field.textField.font = native.newFont( opt.font, opt.fontSize )
    field.textField.size = nativeFontSize

    function field:finalize( event )
        print("finalize event triggered")
        --field.textField:removeSelf()
        --field.textField = nil
    end

    field:addEventListener( "finalize" )

    return field
end  


function widget.newNavigationBar( options )
    local customOptions = options or {}
    local opt = {}
    opt.left = customOptions.left or nil
    opt.top = customOptions.top or nil
    opt.width = customOptions.width or display.contentWidth
    opt.height = customOptions.height or 50
    if customOptions.includeStatusBar == nil then
        opt.includeStatusBar = true -- assume status bars for business apps
    else
        opt.includeStatusBar = customOptions.includeStatusBar
    end

    local statusBarPad = 0
    if opt.includeStatusBar then
        statusBarPad = display.topStatusBarContentHeight
    end

    opt.x = customOptions.x or display.contentCenterX
    opt.y = customOptions.y or (opt.height + statusBarPad) * 0.5
    opt.id = customOptions.id
    opt.isTransluscent = customOptions.isTransluscent or true
    opt.background = customOptions.background
    opt.backgroundColor = customOptions.backgroundColor
    opt.title = customOptions.title or ""
    opt.titleColor = customOptions.titleColor or { 0, 0, 0 }
    opt.font = customOptions.font or native.systemFontBold
    opt.fontSize = customOptions.fontSize or 18
    opt.leftButton = customOptions.leftButton or nil
    opt.rightButton = customOptions.rightButton or nil



    if opt.left then
    	opt.x = opt.left + opt.width * 0.5
    end
    if opt.top then
    	opt.y = opt.top + (opt.height + statusBarPad) * 0.5
    end

    local barContainer = display.newGroup()
    local background = display.newRect(barContainer, opt.x, opt.y, opt.width, opt.height + statusBarPad )
    if opt.background then
        background.fill = { type = "image", filename=opt.background}
    elseif opt.backgroundColor then
        background.fill = opt.backgroundColor
    else
        if widget.isSeven() then
            background.fill = {1,1,1} 
        else
            background.fill = { type = "gradient", color1={0.5, 0.5, 0.5}, color2={0, 0, 0}}
        end
    end

    barContainer._title = display.newText(opt.title, background.x, background.y + statusBarPad * 0.5, opt.font, opt.fontSize)
    barContainer._title:setFillColor(unpack(opt.titleColor))
    barContainer:insert(barContainer._title)

    local leftButton
    if opt.leftButton then
        if opt.leftButton.defaultFile then -- construct an image button
            leftButton = widget.newButton({
                id = opt.leftButton.id,
                width = opt.leftButton.width,
                height = opt.leftButton.height,
                baseDir = opt.leftButton.baseDir,
                defaultFile = opt.leftButton.defaultFile,
                overFile = opt.leftButton.overFile,
                onEvent = opt.leftButton.onEvent,
            })
        else -- construct a text button
            leftButton = widget.newButton({
                id = opt.leftButton.id,
                label = opt.leftButton.label,
                onEvent = opt.leftButton.onEvent,
                font = opt.leftButton.font or opt.font,
                fontSize = opt.fontSize,
                labelColor = opt.leftButton.labelColor or { default={ 1, 1, 1 }, over={ 0, 0, 0, 0.5 } },
                labelAlign = "left",
            })
        end
        leftButton.x = 15 + leftButton.width * 0.5
        leftButton.y = barContainer._title.y
        barContainer:insert(leftButton)
    end

    local rightButton
    if opt.rightButton then
        if opt.rightButton.defaultFile then -- construct an image button
            rightButton = widget.newButton({
                id = opt.rightButton.id,
                width = opt.rightButton.width,
                height = opt.rightButton.height,
                baseDir = opt.rightButton.baseDir,
                defaultFile = opt.rightButton.defaultFile,
                overFile = opt.rightButton.overFile,
                onEvent = opt.rightButton.onEvent,
            })
        else -- construct a text button
            rightButton = widget.newButton({
                id = opt.rightButton.id,
                label = opt.rightButton.label or "Default",
                onEvent = opt.rightButton.onEvent,
                font = opt.leftButton.font or opt.font,
                fontSize = opt.fontSize,
                labelColor = opt.rightButton.labelColor or { default={ 1, 1, 1 }, over={ 0, 0, 0, 0.5 } },
                labelAlign = "right",
            })
        end
        rightButton.x = display.contentWidth - (15 + rightButton.width * 0.5)
        rightButton.y = barContainer._title.y
        barContainer:insert(rightButton)
    end

    function barContainer:setLabel( text )
        self._title.text = text
    end

    function barContainer:getLabel()
        return(self._title.text)
    end


    return barContainer
end