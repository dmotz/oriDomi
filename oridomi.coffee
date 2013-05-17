# [oriDomi](http://oridomi.com)
# =============================
# #### by [Dan Motzenbecker](http://oxism.com)
# Fold up the DOM like paper.

# `0.3.0`

# Copyright 2013, MIT License

# Setup
# =====
'use strict'

# Set a reference to the global object within this scope.
root = @

# Set a reference to jQuery (or another `$`-aliased DOM library).
# If it doesn't exist, set to false so oriDomi knows we are working without jQuery.
# oriDomi doesn't require it to work, but offers a useful plugin bridge.
$ = root.$ or false

# `devMode` determines whether oriDomi is vocal in the console with warnings and benchmarks.
# Turn it on externally by calling `OriDomi.devMode()`.
devMode = false

# This variable is set to true and negated later if the browser does
# not support oriDomi.
oriDomiSupport = true

# Function used to warn the developer that the browser does not support oriDomi.
supportWarning = (prop) ->
  if devMode
    console.warn "oriDomi: Browser does not support oriDomi. Missing support for `#{ prop }`."
    oriDomiSupport = false

# Create a div for testing CSS3 properties.
testEl = document.createElement 'div'

# Set a list of browser prefixes for testing CSS3 properties.
prefixList = ['Webkit', 'Moz', 'O', 'ms']

# A map of the CSS3 properties needed to support oriDomi, with shorthand names as keys.
css =
  transform: 'transform'
  origin: 'transformOrigin'
  transformStyle: 'transformStyle'
  transitionProp: 'transitionProperty'
  transitionDuration: 'transitionDuration'
  transitionEasing: 'transitionTimingFunction'
  perspective: 'perspective'
  perspectiveOrigin: 'perspectiveOrigin'
  backface: 'backfaceVisibility'

# This function checks for the presence of CSS properties on the test div.
testProp = (prop) ->
  # Capitalize the property name for camel-casing.
  capProp = prop.charAt(0).toUpperCase() + prop.slice 1
  # Loop through the vendor prefix list and return when we find a match.
  for prefix in prefixList
    return full if testEl.style[(full = prefix + capProp)]?

  # If the un-prefixed property is present, return it.
  return prop if testEl.style[prop]?
  # If no matches are found, return false to denote that the browser is missing this property.
  false


# Loop through the CSS hash and replace each value with the result of `testProp()`.
for key, value of css
  css[key] = testProp value
  # If the returned value is false, warn the user that the browser doesn't support
  # oriDomi, set `oriDomiSupport` to false, and break out of the loop.
  unless css[key]
    supportWarning value
    break

# CSS3 gradients are used for shading.
# Testing for them is different because they are prefixed values, not properties.
# This invokes an anonymous function to loop through vendor-prefixed linear-gradients.
css.gradientProp = do ->
  for prefix in prefixList
    hyphenated = "-#{ prefix.toLowerCase() }-linear-gradient"
    testEl.style.backgroundImage = "#{ hyphenated }(left, #000, #fff)"
    # After setting a gradient background on the test div, attempt to retrieve it.
    return hyphenated unless testEl.style.backgroundImage.indexOf('gradient') is -1
  # If none of the hyphenated values worked, return the un-prefixed version.
  'linear-gradient'

# The default cursor style is set to `grab` to prompt the user to interact with the element.
[css.grab, css.grabbing] = do ->
  for prefix in prefixList
    plainGrab = 'grab'
    testEl.style.cursor = (grabValue = "-#{ prefix.toLowerCase() }-#{ plainGrab }")
    # If the cursor was set correctly, return the prefixed pair.
    return [grabValue, "-#{ prefix.toLowerCase() }-grabbing"] if testEl.style.cursor is grabValue
  # Otherwise try the unprefixed version.
  testEl.style.cursor = plainGrab
  if testEl.style.cursor is plainGrab
    [plainGrab, 'grabbing']
  else
    # Fallback to `move`.
    ['move', 'move']

# Invoke a functional scope to set a hyphenated version of the transform property.
css.transformProp = do ->
  # Use a regex to pluck the prefix `testProp` found.
  if prefix = css.transform.match /(\w+)Transform/i
    "-#{ prefix[1].toLowerCase() }-transform"
  else
    'transform'

# Set a `transitionEnd` property based on the browser's prefix for `transitionProperty`.
css.transitionEnd = do ->
  switch css.transitionProp
    when 'transitionProperty'
      'transitionEnd'
    when 'WebkitTransitionProperty'
      'webkitTransitionEnd'
    when 'MozTransitionProperty'
      'transitionend'
    when 'OTransitionProperty'
      'oTransitionEnd'
    when 'MSTransitionProperty'
      'msTransitionEnd'


# This function is used to extend option object literals with a set of defaults.
# It is simple and one dimensional.
extendObj = (target, source) ->
  return {} if !target and !source
  # Check if the extension object is an object literal by casting it and comparing it.
  return target if source isnt Object source
  # If the target isn't an object, set it to an empty object literal.
  target = {} if target isnt Object target
  # Loop through the extension object and copy its values to the target if they don't exist.
  (target[prop] = source[prop] unless target[prop]?) for prop of source
  # Return the extended target object.
  target


# Defaults
# ========

# Empty function to be used as placeholder for callback defaults
# (instead of creating separate empty functions).
noOp = ->

modifiedStyleKeys = ['padding', 'backgroundColor', 'backgroundImage', 'border', 'outline']

# Map of oriDomi instance defaults.
defaults =
  # The number of vertical panels (for folding left or right).
  vPanels: 3
  # The number of horizontal panels (for folding top or bottom).
  hPanels: 3
  # The determines the distance in pixels (z axis) of the camera/viewer to the paper.
  # The smaller the value, the more distorted and exaggerated the effects will appear.
  perspective: 1000
  # The default shading style is hard, which shows distinct creases in the paper.
  # Other options include `'soft'` -- for a smoother, more rounded look -- or `false`
  # to disable shading altogether for a flat look.
  shading: 'hard'
  # Determines the duration of all animations in milliseconds.
  speed: 700
  # Configurable maximum angle for effects. With most effects, exceeding 90/-90 usually
  # makes the element wrap around and pass through itself leading to some glitchy visuals.
  maxAngle: 90
  # This CSS class is applied to elements that oriDomi has been invoked so they can be
  # easily targeted later if needed.
  oriDomiClass: 'oridomi'
  # This is a multiplier that determines the darkness of shading.
  # If you need subtler shading, set this to a value below 1.
  shadingIntensity: 1
  # This option allows you to supply the name of a custom easing method defined in one
  # of your stylesheets. It defaults to a blank string which is interpreted as `ease`.
  easingMethod: ''
  # To prevent a possible "flash of unstyled content" you can hide your target elements
  # and pass this setting as `true` to show them immediately after initializing them with oriDomi.
  showOnStart: false
  # Currently, Firefox doesn't handle edge anti-aliasing well and oriDomi edges look jagged.
  # This setting forces Firefox to smooth edges, but usually results in poor performance,
  # so it's not recommended for animation-heavy use of oriDomi until Firefox's transform performance improves.
  forceAntialiasing: false
  # Allow the user to fold the target by dragging a finger or the mouse.
  touchEnabled: true
  # Coefficient of touch/drag action's distance delta. Higher numbers cause more movement.
  touchSensitivity: .25
  # Custom callbacks for touch/drag events. Each one is invoked with a relevant value so they can
  # be used to manipulate objects outside of the oriDomi instance (e.g. sliding panels).
  # x values are returned when folding left and right, y values for top and bottom.
  # These are empty functions by default.
  # Invoked with starting coordinate as first argument.
  touchStartCallback: noOp
  # Invoked with current movement distance.
  touchMoveCallback: noOp
  # Inkoked with ending point.
  touchEndCallback: noOp


prep = (fn) ->
  ->
    if @_touchStarted
      fn.apply @, arguments
    else
      args = arguments
      options = {}
      angle = anchor = null
      switch fn.length
        when 1
          options.callback = args[0]
        when 2
          if typeof args[0] is 'function'
            options.callback = args[0]
          else
            anchor = args[0]
            options.callback = args[1]
        when 3
          angle = args[0]
          if args.length is 2
            if typeof args[1] is 'object'
              options = args[1]
            else if typeof args[1] is 'function'
              options.callback = args[1]
            else
              anchor = args[1]
          else if args.length is 3
            anchor = args[1]
            if typeof args[2] is 'object'
              options = args[2]
            else if typeof args[2] is 'function'
              options.callback = args[2]

      angle  or= 0
      anchor or= @lastOp.anchor
      @_queue.push [fn, @_normalizeAngle(angle), @_getLonghandAnchor(anchor), options]
      @_step()
      @


# oriDomi Class
# =============

class OriDomi
  # The constructor takes two arguments: a target element and an options object literal.
  constructor: (@el, options) ->
    # If the browser doesn't support oriDomi, return the element unmodified.
    return @ unless oriDomiSupport
    # If the constructor wasn't called with the `new` keyword, invoke it again.
    return new oriDomi @el, @settings unless @ instanceof OriDomi
    # Return if the first argument isn't a DOM element.
    if not @el or @el.nodeType isnt 1
      console.warn 'oriDomi: First argument must be a DOM element' if devMode
      return @

    # Record the current global styling of the target element.
    elStyle = root.getComputedStyle @el
    @_originalStyle = {}
    @_originalStyle[key] = elStyle[key] for key in modifiedStyleKeys

    # Extend any passed options with the defaults map.
    @settings = extendObj options, defaults
    # Create an array to act as an animation queue.
    @_queue = []

    # Clone the target element and save a copy of it.
    @cleanEl = @el.cloneNode true
    @cleanEl.style.margin = '0'
    # A faster version of `display: none` when using hardware acceleration.
    @cleanEl.style[css.transform] = 'translate3d(-9999px, 0, 0)'

    # Destructure some instance variables from the settings object.
    {@shading, @shadingIntensity, @vPanels, @hPanels} = @settings

    # Set an array of anchor names.
    @_anchors = ['left', 'right', 'top', 'bottom']
    # oriDomi starts oriented with the left anchor.
    @lastOp = anchor: @_anchors[0]
    # Create object literals to store panels and stages.
    @panels = {}
    @stages = {}
    # Create a stage div to serve as a prototype.
    stage = document.createElement 'div'
    # The stage should occupy the full width and height of the target element.
    stage.style.width = stage.style.height = '100%'
    # By default, each stage is hidden and absolutely positioned so they stack
    # on top of each other.
    stage.style.display = 'none'
    stage.style.position = 'absolute'
    # Eliminate padding and margins since the stage is already the full width and height.
    stage.style.margin = stage.style.padding = '0'
    # Apply 3D perspective and preserve any parent perspective.
    stage.style[css.perspective] = @settings.perspective + 'px'
    stage.style[css.transformStyle] = 'preserve-3d'

    # Each stage needs its own perspective origin so 90 degree folds hide the element.
    perspectiveOrigins = ['0% 50%', '100% 50%', '50% 0%', '50% 100%']
    # Loop through the anchors list and create a stage and empty panel set for each.
    for anchor, i in @_anchors
      @panels[anchor] = []
      stage = @stages[anchor] = stage.cloneNode false
      stage.className = 'oridomi-stage-' + anchor
      stage.style[css.perspectiveOrigin] = perspectiveOrigins[i]

    # If shading is enabled, create an object literal to hold shaders.
    if @shading
      @_shaders = {}
      # Loop through each anchor and create a nested object literal.
      # For the left and right anchors, create arrays to hold the left and right
      # shader for each panel. Do the same for top and bottom.
      for anchor in @_anchors
        @_shaders[anchor] = {}
        if anchor is 'left' or anchor is 'right'
          @_shaders[anchor].left = []
          @_shaders[anchor].right = []
        else
          @_shaders[anchor].top = []
          @_shaders[anchor].bottom = []

      # Create a shader div prototype to clone.
      shader = document.createElement 'div'
      shader.style[css.transitionProp] = 'opacity'
      shader.style[css.transitionDuration] = @settings.speed + 'ms'
      shader.style[css.transitionEasing] = @settings.easingMethod
      shader.style.position = 'absolute'
      shader.style.width = shader.style.height = '100%'
      shader.style.opacity = shader.style.top = shader.style.left = '0'
      shader.style.pointerEvents = 'none'

    # The content holder is a clone of the target element.
    # Every panel will contain one.
    contentHolder = @el.cloneNode true
    contentHolder.classList.add 'oridomi-content'
    contentHolder.style.width = contentHolder.style.height = '100%'
    contentHolder.style.margin = '0'
    contentHolder.style.position = 'relative'
    contentHolder.style.float = 'none'

    # Create a prototype mask div to clone.
    # Masks serve to display only a small offset portion of the content they hold.
    hMask = document.createElement 'div'
    hMask.className = 'oridomi-mask-h'
    hMask.style.position = 'absolute'
    hMask.style.overflow = 'hidden'
    hMask.style.width = hMask.style.height = '100%'
    # Adding `translate3d(0, 0, 0)` prevents flickering during transforms.
    hMask.style[css.transform] = 'translate3d(0, 0, 0)'
    # Add the `contentHolder` div to the mask prototype.
    hMask.appendChild contentHolder

    # If shading is enabled, create top and bottom shaders for the horizontal
    # mask prototype.
    if @shading
      topShader = shader.cloneNode false
      topShader.className = 'oridomi-shader-top'
      topShader.style.background = @_getShaderGradient 'top'
      bottomShader = shader.cloneNode false
      bottomShader.className = 'oridomi-shader-bottom'
      bottomShader.style.background = @_getShaderGradient 'bottom'
      hMask.appendChild topShader
      hMask.appendChild bottomShader

    # The panel element holds both its respective mask and all subsequent sibling panels.
    hPanel = document.createElement 'div'
    hPanel.className = 'oridomi-panel-h'
    hPanel.style.width = hPanel.style.height = '100%'
    hPanel.style.padding = '0'
    hPanel.style.position = 'relative'
    # The panel element is the target of the transforms.
    hPanel.style[css.transitionProp] = css.transformProp
    hPanel.style[css.transitionDuration] = @settings.speed + 'ms'
    hPanel.style[css.transitionEasing] = @settings.easingMethod
    hPanel.style[css.origin] = 'top'
    hPanel.style[css.transformStyle] = 'preserve-3d'
    hPanel.style[css.backface] = 'hidden'

    # Apply a transparent border to force edge smoothing on Firefox.
    # (This setting hurts performance significantly.)
    hPanel.style.outline = '1px solid transparent' if @settings.forceAntialiasing

    # Add the horizontal mask prototype to the horizontal panel prototype.
    hPanel.appendChild hMask

    @_createPanels 'y', hPanel

    # Now that the horizontal panels are done, we can clone the `hMask` for the vertical mask prototype.
    vMask = hMask.cloneNode true
    vMask.className = 'oridomi-mask-v'

    # Create left and right shaders if applicable.
    if @shading
      leftShader = vMask.getElementsByClassName('oridomi-shader-top')[0]
      leftShader.className = 'oridomi-shader-left'
      leftShader.style.background = @_getShaderGradient 'left'
      rightShader = vMask.getElementsByClassName('oridomi-shader-bottom')[0]
      rightShader.className = 'oridomi-shader-right'
      rightShader.style.background = @_getShaderGradient 'right'

    # Clone the `hPanel` prototype and adjust its styling for vertical use.
    vPanel = hPanel.cloneNode false
    vPanel.className = 'oridomi-panel-v'
    vPanel.style[css.origin] = 'left'
    vPanel.appendChild vMask

    # Repeat a similar panel creation process for vertical panels.
    @_createPanels 'x', vPanel

    # Add a special class to the target element.
    @el.classList.add @settings.oriDomiClass

    # Remove its padding and set a fixed width and height.
    @el.style.padding = '0'
    # Remove its background, border, and outline.
    @el.style.backgroundColor = 'transparent'
    @el.style.backgroundImage = @el.style.border = @el.style.outline = 'none'
    @el.style.position = 'relative'
    # Show the left stage to start with.
    @stages.left.style.display = 'block'

    # Create an element to hold stages.
    @stageHolder = document.createElement 'div'
    @stageHolder.style.width = @stageHolder.style.height = '100%'
    @stageHolder.style.position = 'absolute'
    @stageHolder.style[css.transform] = 'translateY(-100%)'

    # Enable touch events.
    @enableTouch() if @settings.touchEnabled

    # Append each stage to the target element.
    @stageHolder.appendChild @stages[anchor] for anchor in @_anchors

    # Show the target if applicable.
    if @settings.showOnStart
      @el.style.display = 'block'
      @el.style.visibility = 'visible'

    # Hide the original content and insert the oriDomi version.
    @el.innerHTML = ''
    @el.appendChild @cleanEl
    @el.appendChild @stageHolder

    # These properties record starting angles for touch/drag events.
    # Initialize both to zero.
    @_xLast = @_yLast = 0

    # Cache a jQuery object of the element if applicable.
    @$el = $ @el if $
    @accordion 0


  # Internal Methods
  # ================


  _createPanels: (axis, proto) ->
    if axis is 'x'
      anchors = ['left', 'right']
      count   = @vPanels
      metric  = 'width'
    else
      anchors = ['top', 'bottom']
      count   = @hPanels
      metric  = 'height'

    percent = 100 / count

    for anchor, n in anchors
      for i in [0...count]
        panel = proto.cloneNode true
        panel.style[metric] = percent + '%' if i is 0
        content = panel.getElementsByClassName('oridomi-content')[0]
        content.style[metric] = count * 100 + '%'

        if n is 0
          content.style[anchor] = -i * 100 + '%'
          if i is 0
            panel.style[anchor] = '0'
          else
            panel.style[anchor] = '100%'
        else
          content.style[anchors[0]] = -(count - i - 1) * 100 + '%'
          panel.style[css.origin] = anchor
          if i is 0
            panel.style[anchors[0]] = 100 - percent + '%'
          else
            panel.style[anchors[0]] = '-100%'

        if @shading
          for a in anchors
            @_shaders[anchor][a][i] = panel.getElementsByClassName("oridomi-shader-#{ a }")[0]

        @panels[anchor][i] = panel
        @panels[anchor][i - 1].appendChild panel unless i is 0

      @stages[anchor].appendChild @panels[anchor][0]


  _step: =>
    return if @_inTrans or !@_queue.length
    @_inTrans = true
    [fn, angle, anchor, options] = @_queue.shift()
    @unfreeze() if @isFrozen
    if anchor isnt @lastOp.anchor
      @_stageReset anchor, =>
        @_setCallback {angle, anchor, options, fn}
        fn.call @, angle, anchor, options
    else
      @_setCallback {angle, anchor, options, fn}
      fn.call @, angle, anchor, options


  # This method tests if the called action is identical to the previous one.
  # If two identical operations were called in a row, the transition callback
  # wouldn't be called due to no animation taking place. This method reasons if
  # movement has taken place, preventing this pitfall of transition listeners.
  _isIdenticalOperation: (op) ->
    return false if @lastOp.angle isnt op.angle
    for k, v of op.options
      return false if op.options[k] isnt @lastOp.options[k] and k isnt 'callback'
    true


  # `_callback` normalizes callback handling for all public methods.
  _setCallback: (operation) ->
    # If there was no transformation, invoke the callback immediately.
    if @_isIdenticalOperation operation
      @_conclude operation.options.callback
    # Otherwise, attach an event listener to be called on the transition's end.
    else
      @panels[@lastOp.anchor][0].addEventListener css.transitionEnd, @_onTransitionEnd, false

    @lastOp = operation


  # Handler called when a CSS transition ends.
  _onTransitionEnd: (e) =>
    # Remove the event listener immediately to prevent bubbling.
    e.currentTarget.removeEventListener css.transitionEnd, @_onTransitionEnd, false
    # Initialize transition teardown process.
    @_conclude @lastOp.options.callback


  # `_conclude` is used to handle the end process of transitions and to initialize
  # queued operations.
  _conclude: (cb) =>
    setTimeout =>
      @_inTrans = false
      @_step()
      cb?()
    , 0


  # `_transform` returns a `rotate3d` transform string based on the anchor and angle.
  _transform: (angle, anchor, fracture) ->
    switch anchor
      when 'left'
        axes = [0, angle, 0]
        translate = 'X(-1'
      when 'right'
        axes = [0, -angle, 0]
        translate = 'X(1'
      when 'top'
        axes = [-angle, 0, 0]
        translate = 'Y(-1'
      when 'bottom'
        axes = [angle, 0, 0]
        translate = 'Y(1'

    axes = [angle, angle, angle] if fracture
    "rotateX(#{ axes[0] }deg) rotateY(#{ axes[1] }deg) rotateZ(#{ axes[2] }deg) translate#{ translate }px)"


  # `_normalizeAngle` validates a given angle by making sure it's a float and by
  # keeping it within the maximum range specified in the instance settings.
  _normalizeAngle: (angle) ->
    angle = parseFloat angle, 10
    max   = @settings.maxAngle
    if isNaN angle
      0
    else if angle > max
      max
    else if angle < -max
      -max
    else
      angle


  # `_setShader` determines a shader's opacity based upon panel position, anchor, and angle.
  _setShader: (i, anchor, angle) ->
    # Store the angle's absolute value and generate an opacity based on `shadingIntensity`.
    abs = Math.abs angle
    opacity = abs / 90 * @shadingIntensity

    # With hard shading, opacity is reduced and `angle` is based on the global
    # `lastAngle` so all panels' shaders share the same direction. Soft shaders
    # have alternating directions.
    if @shading is 'hard'
      opacity *= .15
      if @lastOp.angle < 0
        angle = abs
      else
        angle = -abs
    else
      opacity *= .4

    # This block makes sure left and top shaders appear for negative angles and right
    # and bottom shaders appear for positive ones.
    switch anchor
      when 'left', 'top'
        if angle < 0
          a = opacity
          b = 0
        else
          a = 0
          b = opacity
      when 'right', 'bottom'
        if angle < 0
          a = 0
          b = opacity
        else
          a = opacity
          b = 0

    # Only manipulate shader opacity for the current axis.
    if anchor is 'left' or anchor is 'right'
      @_shaders[anchor].left[i].style.opacity = a
      @_shaders[anchor].right[i].style.opacity = b
    else
      @_shaders[anchor].top[i].style.opacity = a
      @_shaders[anchor].bottom[i].style.opacity = b


  # This is a simple method used by the constructor to set CSS gradient styles.
  # It accepts an anchor argument to start the gradient slope.
  _getShaderGradient: (anchor) ->
    "#{ css.gradientProp }(#{ anchor }, rgba(0, 0, 0, .5) 0%, rgba(255, 255, 255, .35) 100%)"


  # This method shows the requested stage element and sets a reference to it as
  # the current stage.
  _showStage: (anchor) ->
    if anchor isnt @lastOp.anchor
      @stages[anchor].style.display = 'block'
      @stages[@lastOp.anchor].style.display = 'none'
      @lastOp.anchor = anchor


  _stageReset: (anchor, cb) =>
    fn = (e) =>
      e.currentTarget.removeEventListener css.transitionEnd, fn, false if e
      @_showStage anchor
      setTimeout cb, 1

    return fn() if @lastOp.angle is 0
    @panels[@lastOp.anchor][0].addEventListener css.transitionEnd, fn, false

    for panel, i in @panels[@lastOp.anchor]
      panel.style[css.transform] = @_transform 0, @lastOp.anchor
      @_setShader i, @lastOp.anchor, 0 if @shading
    @


  # Simple method that returns the correct panel set based on an anchor.
  _getPanelType: (anchor) ->
    if anchor is 'left' or anchor is 'right'
      @vPanels
    else
      @hPanels


  # Converts a shorthand anchor name to a full one.
  _getLonghandAnchor: (shorthand) ->
    switch shorthand
      when 'left', 'l', '4', 4
        'left'
      when 'right', 'r', '2', 2
        'right'
      when 'top', 't', '1', 1
        'top'
      when 'bottom', 'b', '3', 3
        'bottom'
      else
        # Left is always default.
        'left'


  # Gives the element a resize cursor to prompt the user to drag the mouse.
  _setCursor: ->
    if @_touchEnabled
      @stageHolder.style.cursor = css.grab
    else
      @stageHolder.style.cursor = 'default'


  # Touch / Drag Event Handlers
  # ===========================

  # Adds or removes handlers from the element based on the boolean argument given.
  _setTouch: (toggle) ->
    if toggle
      return @ if @_touchEnabled
      listenFn = 'addEventListener'
    else
      return @ unless @_touchEnabled
      listenFn = 'removeEventListener'

    @_touchEnabled = toggle
    @_setCursor()
    # Array of event type pairs.
    eventPairs = [['TouchStart', 'MouseDown'], ['TouchEnd', 'MouseUp'],
                  ['TouchMove', 'MouseMove'], ['TouchLeave', 'MouseLeave']]
    # Detect native `mouseleave` support.
    mouseLeaveSupport = 'onmouseleave' of window
    # Attach touch/drag event listeners in related pairs.
    for eventPair in eventPairs
      for eString in eventPair
        unless eString is 'TouchLeave' and not mouseLeaveSupport
          @stageHolder[listenFn] eString.toLowerCase(), @['_on' + eventPair[0]], false
        else
          @stageHolder[listenFn] 'mouseout', @_onMouseOut, false
          break
    @


  # This method is called when a finger or mouse button is pressed on the element.
  _onTouchStart: (e) =>
    return unless @_touchEnabled
    e.preventDefault()
    # Clear queued animations.
    @emptyQueue()
    # Set a property to track touch starts.
    @_touchStarted = true
    # Change the cursor to the active `grabbing` state.
    @stageHolder.style.cursor = css.grabbing
    # Disable tweening to enable instant 1 to 1 movement.
    @setSpeed false
    # Derive the axis to fold on.
    @_touchAxis = if @lastOp.anchor is 'left' or @lastOp.anchor is 'right' then 'x' else 'y'
    # Set a reference to the last folded angle to accurately derive deltas.
    @["_#{ @_touchAxis }Last"] = @lastOp.angle

    # Determine the starting tap's coordinate for touch and mouse events.
    if e.type is 'mousedown'
      @["_#{ @_touchAxis }1"] = e["page#{ @_touchAxis.toUpperCase() }"]
    else
      @["_#{ @_touchAxis }1"] = e.targetTouches[0]["page#{ @_touchAxis.toUpperCase() }"]

    # Return that value to an external listener.
    @settings.touchStartCallback @["_#{ @_touchAxis }1"]


  # Called on touch/mouse movement.
  _onTouchMove: (e) =>
    return unless @_touchEnabled and @_touchStarted
    e.preventDefault()
    # Set a reference to the current x or y position.
    if e.type is 'mousemove'
      current = e["page#{ @_touchAxis.toUpperCase() }"]
    else
      current = e.targetTouches[0]["page#{ @_touchAxis.toUpperCase() }"]

    # Calculate distance and multiply by `touchSensitivity`.
    distance = (current - @["_#{ @_touchAxis }1"]) * @settings.touchSensitivity

    # Calculate final delta based on starting angle, anchor, and what side of zero
    # the last operation was on.
    if @lastOp.angle < 0
      if @lastOp.anchor is 'right' or @lastOp.anchor is 'bottom'
        delta = @["_#{ @_touchAxis }Last"] - distance
      else
        delta = @["_#{ @_touchAxis }Last"] + distance
      delta = 0 if delta > 0
    else
      if @lastOp.anchor is 'right' or @lastOp.anchor is 'bottom'
        delta = @["_#{ @_touchAxis }Last"] + distance
      else
        delta = @["_#{ @_touchAxis }Last"] - distance
      delta = 0 if delta < 0


    delta = @_normalizeAngle delta
    @lastOp.angle = delta
    # Invoke the effect method with the delta as an angle argument.
    @lastOp.fn.call @, delta, @lastOp.anchor, @lastOp.options
    # Pass the delta to the movement callback.
    @settings.touchMoveCallback delta


  # Teardown process when touch/drag event ends.
  _onTouchEnd: =>
    return unless @_touchEnabled
    # Restore the initial touch status and cursor.
    @_touchStarted = @_inTrans = false
    @stageHolder.style.cursor = css.grab
    # Enable tweening again.
    @setSpeed true
    # Pass callback final value.
    @settings.touchEndCallback @["_#{ @_touchAxis }Last"]


  # End folding when the mouse or finger leaves the composition.
  _onTouchLeave: =>
    return unless @_touchEnabled and @_touchStarted
    @_onTouchEnd()


  # A fallback for browsers that don't support `mouseleave`.
  _onMouseOut: (e) =>
    return unless @_touchEnabled and @_touchStarted
    @_onTouchEnd() if e.toElement and not @el.contains e.toElement


  # Public Methods
  # ==============


  # Allows other methods to change the tween duration or disable it altogether.
  setSpeed: (speed) ->
    # If the speed value is `true` reset the speed to the original settings.
    # Set it to zero if `false`.
    if typeof speed is 'boolean'
      speed = if speed then @settings.speed + 'ms' else '0ms'

    # To loop through the shaders, derive the correct pair from the current anchor.
    if @lastOp.anchor is 'left' or @lastOp.anchor is 'right'
      shaderPair = ['left', 'right']
    else
      shaderPair = ['top', 'bottom']

    # Loop through the panels in this anchor and set the transition duration to the new speed.
    for panel, i in @panels[@lastOp.anchor]
      panel.style[css.transitionDuration] = speed
      if @shading
        for side in shaderPair
          @_shaders[@lastOp.anchor][side][i].style[css.transitionDuration] = speed

    @


  # Disables oriDomi slicing by showing the original, untouched target element.
  # This is useful for certain user interactions on the inner content.
  freeze: (callback) ->
    # Return if already frozen.
    if @isFrozen
      callback?()
    else
      # Make sure to reset folding first.
      @_stageReset @lastOp.anchor, =>
        @isFrozen = true
        # Swap the visibility of the elements.
        @stageHolder.style[css.transform] = 'translate3d(-9999px, 0, 0)'
        @cleanEl.style[css.transform] = 'translate3d(0, 0, 0)'
        callback?()
    @


  # Restores the oriDomi version of the element for folding purposes.
  unfreeze: ->
    # Only unfreeze if already frozen.
    if @isFrozen
      @isFrozen = false
      # Swap the visibility of the elements.
      @cleanEl.style[css.transform] = 'translate3d(-9999px, 0, 0)'
      @stageHolder.style[css.transform] = 'translateY(-100%)'
      # Set `lastAngle` to 0 so an immediately subsequent call to `freeze` triggers the callback.
      @lastOp.angle = 0
    @


  # Removes the oriDomi element and marks its instance for garbage collection.
  destroy: (callback) ->
    # First restore the original element.
    @freeze =>
      # Remove event listeners.
      @_setTouch false
      # Remove the data reference if using jQuery.
      $.data @el, 'oriDomi', null if $
      # Remove the oriDomi element from the DOM.
      @el.innerHTML = @cleanEl.innerHTML
      # Reset original styles.
      @el.style[key] = val for key, val of @_originalStyle
      callback?()
    null


  # Empties the queue should you want to cancel scheduled animations.
  emptyQueue: ->
    @_queue = []
    setTimeout (=> @_inTrans = false), 1
    @


  # Enables touch events.
  enableTouch: ->
    @_setTouch true


  # Disables touch events.
  disableTouch: ->
    @_setTouch false


  wait: (ms) ->
    fn = => setTimeout @_conclude, ms
    if @_inTrans
      @_queue.push [fn, @lastOp.angle, @lastOp.anchor, @lastOp.options]
    else
      fn()
    @


  # oriDomi's most basic effect. Transforms the target like its namesake.
  accordion: prep (angle, anchor, options) ->
    # Loop through the panels in this stage.
    for panel, i in @panels[anchor]
      # If it's an odd-numbered panel, reverse the angle.
      if i % 2 isnt 0 and not options.twist
        deg = -angle
      else
        deg = angle

      # If sticky, keep the first panel flat.
      if options.sticky
        if i is 0
          deg = 0
        else if i > 1 or options.stairs
          deg *= 2
      else
        # Double the angle to counteract the angle of the parent panel.
        deg *= 2 unless i is 0

      # In stairs mode, keep all the angles on the same side of 0.
      deg *= -1 if options.stairs

      # Set the CSS transformation.
      panel.style[css.transform] = @_transform deg, anchor, options.fracture
      # Apply shaders.
      if @shading and !(i is 0 and options.sticky) and Math.abs(deg) isnt 180
        @_setShader i, anchor, deg


  # `curl` appears to bend rather than fold the paper. Its curves can appear smoother
  # with higher panel counts.
  curl: prep (angle, anchor, options) ->
    # Reduce the angle based on the number of panels in this axis.
    angle /=  @_getPanelType anchor

    for panel, i in @panels[anchor]
      panel.style[css.transform] = @_transform angle, anchor
      @_setShader i, anchor, 0 if @shading


  # `ramp` lifts up all panels after the first one.
  ramp: prep (angle, anchor, options) ->
    # Rotate the second panel for the lift up.
    @panels[anchor][1].style[css.transform] = @_transform angle, anchor

    # For all but the first two panels, set the angle to 0.
    for panel, i in @panels[anchor]
      @panels[anchor][i].style[css.transform] = @_transform 0, anchor if i > 1
      @_setShader i, anchor, 0 if @shading



  # `foldUp` folds up all panels in separate synchronous animations.
  foldUp: (anchor, callback) ->
    # Default to left anchor.
    unless anchor
      anchor = 'left'
    # Check if callback is the first argument.
    else if typeof anchor is 'function'
      callback = anchor

    # `foldUp` uses irregular arguments, so we manually construct the arguments array.
    normalized = @_normalizeArgs 'foldUp', [0, anchor, {}]
    return unless normalized
    anchor = normalized[1]
    # Set `isFoldedUp` to `true` so we are forced to unfold before calling other methods.
    @isFoldedUp = true
    # Start an iterator at the last panel in this anchor.
    i = @panels[anchor].length - 1
    # Rotate 100 degrees.
    angle = 100

    # Local function that sets an event listener on the current panel and transforms it.
    nextPanel = =>
      @panels[anchor][i].addEventListener css.transitionEnd, onTransitionEnd, false
      @panels[anchor][i].style[css.transform] = @_transform angle
      @_setShader i, anchor, angle if @shading

    # Called when each panel finishes folding in.
    onTransitionEnd = (e) =>
      # Remove the listener.
      @panels[anchor][i].removeEventListener css.transitionEnd, onTransitionEnd, false
      # Hide the panel so it doesn't collide when bending around.
      @panels[anchor][i].style.display = 'none'
      # Decrement the iterator and check if we're on the first panel.
      if --i is 0
        # If so, invoke the callback directly if applicable.
        callback?()
      else
        # Otherwise, defer until the next event loop and fold back the next panel.
        setTimeout nextPanel, 0

    # Start the chain of folds.
    nextPanel()


  # The inverse of `foldUp`.
  unfold: (callback) ->
    # If the target isn't folded up, there's no reason to call this method and
    # the callback is immediately invoked.
    callback?() unless @isFoldedUp

    # Reset `isFoldedUp`.
    @isFoldedUp = false
    # Start the iterator on the second panel.
    i = 1
    # Rotate back to 0.
    angle = 0

    nextPanel = =>
      # Show the panel again.
      @panels[@lastOp.anchor][i].style.display = 'block'
      # Wait for the next event loop so the transition listener works.
      setTimeout =>
        @panels[@lastOp.anchor][i].addEventListener css.transitionEnd, onTransitionEnd, false
        @panels[@lastOp.anchor][i].style[css.transform] = @_transform angle, anchor
        @_setShader i, @lastOp.anchor, angle if @shading
      , 0

    onTransitionEnd = (e) =>
      @panels[@lastOp.anchor][i].removeEventListener css.transitionEnd, onTransitionEnd, false
      # Increment the iterator and check if we're past the last panel.
      if ++i is @panels[@lastOp.anchor].length
        callback?()
      else
        setTimeout nextPanel, 0

    # Start the sequence.
    nextPanel()
    @


  # Convenience Methods
  # ===================



  # Reset handles resetting all panels back to zero degrees.
  reset: (callback) ->
    @accordion 0, {callback}


  # Convenience proxy to accordion-fold instance to maximum angle.
  collapse: (anchor, options = {}) ->
    options.sticky = false
    @accordion -90, anchor, options


  # Same as `collapse`, but uses positive angle for slightly different effect.
  collapseAlt: (anchor, options = {}) ->
    options.sticky = false
    @accordion 90, anchor, options


  # Simply proxy for calling `accordion` with `sticky` enabled.
  # Keeps first panel flat on page.
  reveal: (angle, anchor, options = {}) ->
    options.sticky = true
    @accordion angle, anchor, options


  # Proxy to enable stairs mode on `accordion`.
  stairs: (angle, anchor, options = {}) ->
    options.stairs = true
    options.sticky = true
    @accordion angle, anchor, options


  # `fracture: true` proxy.
  fracture: (angle, anchor, options = {}) ->
    options.fracture = true
    @accordion angle, anchor, options


  # `twist: true` proxy.
  twist: (angle, anchor, options = {}) ->
    options.fracture = true
    options.twist = true
    @accordion angle / 10, anchor, options


  # Class Members
  # =============


  # Set a version flag for easy external retrieval.
  @VERSION = '0.3.0'


  # Externally check if oriDomi is supported by the browser.
  @isSupported = oriDomiSupport


  # External function to enable `devMode`.
  @devMode = -> devMode = true


# Attach `OriDomi` constructor to `window`.
root.OriDomi = OriDomi


# Plugin Bridge
# =============


# Only create bridge if jQuery (or an imitation supporting `data()`) exists.
if root.jQuery? or root.$?.data?
  # Attach an `oriDomi` method to `$`'s prototype.
  $.fn.oriDomi = (options) ->
    # Return selection if oriDomi is unsupported by the browser.
    return @ unless oriDomiSupport

    # If `options` is a string, assume it's a method call.
    if typeof options is 'string'
      methodName = options
      # Check if method exists and warn if it doesn't.
      unless typeof OriDomi::[methodName] is 'function'
        console.warn "oriDomi: No such method '#{ methodName }'" if devMode
        return @

      # Convert arguments to a proper array and remove the first element.
      args = Array::slice.call arguments
      args.shift()
      # Loop through the jQuery selection.
      for el in @
        # Warn if oriDomi hasn't been initialized on this element.
        unless instance = $.data el, 'oriDomi'
          console.warn "oriDomi: Can't call #{ methodName }, oriDomi hasn't been initialized on this element" if devMode
          return @

        # Call the requested method with arguments.
        instance[methodName] args

      # Return selection.
      @

    # If not calling a method, initialize oriDomi on the selection.
    else
      for el in @
        # If the element in the selection already has an instance of oriDomi
        # attached to it, return the instance.
        if instance = $.data el, 'oriDomi'
          return instance
        else
          # Create an instance of oriDomi and attach it to the element.
          $.data el, 'oriDomi', new OriDomi el, options

      # Return the selection.
      @
