# # oriDomi
# ### Fold up the DOM like paper.
# 0.3.0

# [http://oridomi.com](http://oridomi.com)
# #### by [Dan Motzenbecker](http://oxism.com)

# Copyright 2013, MIT License

'use strict'

# Helper Functions
# ================

# Function used to warn the developer that the browser does not support oriDomi.
supportWarning = (prop) ->
  if devMode
    console.warn "oriDomi: Browser does not support oriDomi. Missing support for `#{ prop }`."
    isSupported = false


# This function checks for the presence of CSS properties on the test div.
testProp = (prop) ->
  # Loop through the vendor prefix list and return when we find a match.
  for prefix in prefixList
    return full if testEl.style[(full = prefix + capitalize prop)]?

  # If the un-prefixed property is present, return it.
  return prop if testEl.style[prop]?
  # If no matches are found, return false to denote that the browser is missing this property.
  false


addStyle = (selector, rules) ->
  style = ".#{ selector }{"
  for prop, val of rules
    if prop of css
      prop = css[prop]
      prop = '-' + prop if prop.match /^(webkit|moz|ms)/i

    style += "#{ prop.replace(/([a-z])([A-Z])/g, '$1-$2').toLowerCase() }:#{ val };"

  styleBuffer += style + '}'


getGradient = (anchor) ->
  "#{ css.gradientProp }(#{ anchor }, rgba(0, 0, 0, .5) 0%, rgba(255, 255, 255, .35) 100%)"


capitalize = (s) ->
  s[0].toUpperCase() + s[1...]


createEl = (className) ->
  el = document.createElement 'div'
  el.className = elClasses[className]
  el


cloneEl = (parent, deep, className) ->
  el = parent.cloneNode deep
  el.classList.add elClasses[className]
  el


hideEl = (el) ->
  el.style[css.transform] = 'translate3d(-9999px, 0, 0)'


showEl = (el) ->
  el.style[css.transform] = 'translate3d(0, 0, 0)'


prep = (fn) ->
  ->
    if @_touchStarted
      fn.apply @, arguments
    else
      [a0, a1, a2] = arguments
      opt          = {}
      angle        = anchor = null

      switch fn.length
        when 1
          opt.callback = a0
        when 2
          if typeof a0 is 'function'
            opt.callback = a0
          else
            anchor       = a0
            opt.callback = a1
        when 3
          angle = a0
          if arguments.length is 2
            if typeof a1 is 'object'
              opt = a1
            else if typeof a1 is 'function'
              opt.callback = a1
            else
              anchor = a1
          else if arguments.length is 3
            anchor = a1
            if typeof a2 is 'object'
              opt = a2
            else if typeof a2 is 'function'
              opt.callback = a2

      angle   ?= @_lastOp.angle or 0
      anchor or= @_lastOp.anchor
      @_queue.push [fn, @_normalizeAngle(angle), @_getLonghandAnchor(anchor), opt]
      @_step()
      @


defer = (fn) ->
  setTimeout fn, 0


# Empty function to be used as placeholder for callback defaults
# (instead of creating separate empty functions).
noOp = ->


# Setup
# =====

# Set a reference to jQuery (or another `$`-aliased DOM library).
# If it doesn't exist, set to null so oriDomi knows we are working without jQuery.
# oriDomi doesn't require it to work, but offers a useful plugin bridge.
$ = if window.$?.data then window.$ else null

# `devMode` determines whether oriDomi is vocal in the console with warnings and benchmarks.
# Turn it on externally by calling `OriDomi.devMode()`.
devMode = false

# This variable is set to true and negated later if the browser does
# not support oriDomi.
isSupported = true

anchorList  = ['left', 'right', 'top', 'bottom']
anchorListV = anchorList[..1]
anchorListH = anchorList[2..]

# Create a div for testing CSS3 properties.
testEl = document.createElement 'div'

# Set a list of browser prefixes for testing CSS3 properties.
prefixList = ['Webkit', 'Moz', 'ms']

# A map of the CSS3 properties needed to support oriDomi, with shorthand names as keys.
css = new ->
  @[key] = key for key in [
    'transform'
    'transformOrigin'
    'transformStyle'
    'transitionProperty'
    'transitionDuration'
    'transitionDelay'
    'transitionTimingFunction'
    'perspective'
    'perspectiveOrigin'
    'backfaceVisibility'
    'boxSizing'
  ]
  @

# Loop through the CSS hash and replace each value with the result of `testProp()`.
for key, value of css
  css[key] = testProp value
  # If the returned value is false, warn the user that the browser doesn't support
  # oriDomi, set `isSupported` to false and break out of the loop.
  unless css[key]
    supportWarning value
    break

p3d = 'preserve-3d'
if isSupported and css.transformStyle
  testEl.style[css.transformStyle] = p3d
  unless testEl.style[css.transformStyle] is p3d
    isSupported = false
    supportWarning p3d

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
  switch css.transitionProperty.toLowerCase()
    when 'transitionproperty'       then 'transitionEnd'
    when 'webkittransitionproperty' then 'webkitTransitionEnd'
    when 'moztransitionproperty'    then 'transitionend'
    when 'mstransitionproperty'     then 'msTransitionEnd'


baseName  = 'oridomi'
elClasses =
  active:       'active'
  clone:        'clone'
  holder:       'holder'
  stage:        'stage'
  stageLeft:    'stage-left'
  stageRight:   'stage-right'
  stageTop:     'stage-top'
  stageBottom:  'stage-bottom'
  content:      'content'
  mask:         'mask'
  maskH:        'mask-h'
  maskV:        'mask-v'
  panel:        'panel'
  panelH:       'panel-h'
  panelV:       'panel-v'
  shader:       'shader'
  shaderLeft:   'shader-left'
  shaderRight:  'shader-right'
  shaderTop:    'shader-top'
  shaderBottom: 'shader-bottom'


elClasses[k] = "#{ baseName }-#{ v }" for k, v of elClasses
styleBuffer  = ''

addStyle elClasses.active,
  backgroundColor: 'transparent'
  backgroundImage: 'none'
  padding:         '0'
  boxSizing:       'border-box'
  border:          'none'
  outline:         'none'
  position:        'relative'

addStyle elClasses.clone, margin: '0'

addStyle elClasses.holder,
  width:     '100%'
  height:    '100%'
  position:  'absolute'
  transform: 'translateY(-100%)'

addStyle elClasses.stage,
  width:          '100%'
  height:         '100%'
  position:       'absolute'
  transform:      'translate3d(-9999px, 0, 0)'
  margin:         '0'
  padding:        '0'
  transformStyle: p3d

for k, v of {Left: '0% 50%', Right: '100% 50%', Top: '50% 0%', Bottom: '50% 100%'}
  addStyle elClasses['stage' + k], perspectiveOrigin: v

addStyle elClasses.shader,
  width:              '100%'
  height:             '100%'
  position:           'absolute'
  opacity:            '0'
  top:                '0'
  left:               '0'
  pointerEvents:      'none'
  transitionProperty: 'opacity'

for anchor in anchorList
  addStyle elClasses['shader' + capitalize anchor], background: getGradient anchor

addStyle elClasses.content,
  width:     '100%'
  height:    '100%'
  margin:    '0'
  position:  'relative'
  float:     'none'
  boxSizing: 'border-box'

addStyle elClasses.mask,
  width:     '100%'
  height:    '100%'
  position:  'absolute'
  overflow:  'hidden'
  transform: 'translate3d(0, 0, 0)'
  backfaceVisibility: 'hidden'

addStyle elClasses.panel,
  width:              '100%'
  height:             '100%'
  padding:            '0'
  position:           'relative'
  transitionProperty: css.transformProp
  transformOrigin:    'left'
  transformStyle:     p3d
  backfaceVisibility: 'hidden'

addStyle elClasses.panelH, transformOrigin: 'top'
addStyle "#{ elClasses.stageRight } .#{ elClasses.panel }", transformOrigin: 'right'
addStyle "#{ elClasses.stageBottom } .#{ elClasses.panel }", transformOrigin: 'bottom'

styleEl      = document.createElement 'style'
styleEl.type = 'text/css'

if styleEl.styleSheet
  styleEl.styleSheet.cssText = styleBuffer
else
  styleEl.appendChild document.createTextNode styleBuffer

document.head.appendChild styleEl


# Defaults
# ========

# Object literal of oriDomi instance defaults.
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


# oriDomi Prototype
# =================

class OriDomi

  constructor: (@el, options = {}) ->
    return unless isSupported
    return new OriDomi arguments... unless @ instanceof OriDomi
    @el = document.querySelector @el if typeof @el is 'string'
    unless @el and @el.nodeType is 1
      console.warn 'oriDomi: First argument must be a DOM element' if devMode
      return

    @_settings = new ->
      for k, v of defaults
        if options[k]?
          @[k] = options[k]
        else
          @[k] = v
      @

    @_queue   = []
    @_panels  = {}
    @_stages  = {}
    @_lastOp  = anchor: anchorList[0]
    @_xLast   = @_yLast = 0
    @_shading = @_settings.shading

    if @_shading
      @_shaders    = {}
      shaderProtos = {}
      shaderProto  = createEl 'shader'
      shaderProto.style[css.transitionDuration]       = @_settings.speed + 'ms'
      shaderProto.style[css.transitionTimingFunction] = @_settings.easingMethod

    stageProto = createEl 'stage'
    stageProto.style[css.perspective] = @_settings.perspective + 'px'

    for anchor in anchorList
      @_panels[anchor] = []
      @_stages[anchor] = cloneEl stageProto, false, 'stage' + capitalize anchor
      if @_shading
        @_shaders[anchor] = {}
        if anchor in anchorListV
          @_shaders[anchor][side] = [] for side in anchorListV
        else
          @_shaders[anchor][side] = [] for side in anchorListH

        shaderProtos[anchor] = cloneEl shaderProto, false, 'shader' + capitalize anchor

    contentHolder = cloneEl @el, true, 'content'

    maskProto = createEl 'mask'
    maskProto.appendChild contentHolder

    panelProto = createEl 'panel'
    panelProto.style[css.transitionDuration]       = @_settings.speed + 'ms'
    panelProto.style[css.transitionTimingFunction] = @_settings.easingMethod

    for axis in ['x', 'y']
      if axis is 'x'
        anchorSet   = anchorListV
        count       = @_settings.vPanels
        metric      = 'width'
        classSuffix = 'V'
      else
        anchorSet   = anchorListH
        count       = @_settings.hPanels
        metric      = 'height'
        classSuffix = 'H'

      percent = 100 / count

      mask = cloneEl maskProto, true, 'mask' + classSuffix
      mask.children[0].style[metric] = count * 100 + '%'
      mask.appendChild shaderProtos[anchor] for anchor in anchorSet

      proto = cloneEl panelProto, false, 'panel' + classSuffix
      proto.appendChild mask

      for anchor, n in anchorSet
        for panelN in [0...count]
          panel = proto.cloneNode true
          panel.style[metric] = percent + '%' if panelN is 0
          content = panel.children[0].children[0]

          if n is 0
            content.style[anchor] = -panelN * 100 + '%'
            if panelN is 0
              panel.style[anchor] = '0'
            else
              panel.style[anchor] = '100%'
          else
            content.style[anchorSet[0]] = (count - panelN - 1) * -100 + '%'
            panel.style[css.origin] = anchor
            if panelN is 0
              panel.style[anchorSet[0]] = 100 - percent + '%'
            else
              panel.style[anchorSet[0]] = '-100%'

          if @_shading
            for a, i in anchorSet
              @_shaders[anchor][a][panelN] = panel.children[0].children[i + 1]

          @_panels[anchor][panelN] = panel
          @_panels[anchor][panelN - 1].appendChild panel unless panelN is 0

        @_stages[anchor].appendChild @_panels[anchor][0]

    @_stageHolder = createEl 'holder'
    @_stageHolder.appendChild @_stages[anchor] for anchor in anchorList

    @el.classList.add elClasses.active
    showEl @_stages.left
    hideEl @cloneEl = @el.cloneNode true
    @el.innerHTML   = ''
    @el.appendChild @cloneEl
    @el.appendChild @_stageHolder
    @$el = $ @el if $
    @accordion 0
    @enableTouch() if @_settings.touchEnabled


  # Internal Methods
  # ================

  _step: =>
    return if @_inTrans or !@_queue.length
    @_inTrans = true
    [fn, angle, anchor, options] = @_queue.shift()
    @unfreeze() if @isFrozen

    next = =>
      @_setCallback {angle, anchor, options, fn}
      args = [angle, anchor, options]
      args.shift() if fn.length < 3
      fn.apply @, args

    if @isFoldedUp
      @_unfold next
    else if anchor isnt @_lastOp.anchor
      @_stageReset anchor, next
    else
      next()


  # This method tests if the called action is identical to the previous one.
  # If two identical operations were called in a row, the transition callback
  # wouldn't be called due to no animation taking place. This method reasons if
  # movement has taken place, preventing this pitfall of transition listeners.
  _isIdenticalOperation: (op) ->
    return true unless @_lastOp.fn
    return false if @_lastOp.reset
    (return false if @_lastOp[key] isnt op[key]) for key in ['angle', 'anchor', 'fn']
    (return false if v isnt @_lastOp.options[k] and k isnt 'callback') for k, v of op.options
    true


  # `_callback` normalizes callback handling for all public methods.
  _setCallback: (operation) ->
    # If there was no transformation, invoke the callback immediately.
    if @_isIdenticalOperation operation
      @_conclude operation.options.callback
    # Otherwise, attach an event listener to be called on the transition's end.
    else
      @_panels[@_lastOp.anchor][0].addEventListener css.transitionEnd, @_onTransitionEnd, false

    (@_lastOp = operation).reset = false


  # Handler called when a CSS transition ends.
  _onTransitionEnd: (e) =>
    # Remove the event listener immediately to prevent bubbling.
    e.currentTarget.removeEventListener css.transitionEnd, @_onTransitionEnd, false
    # Initialize transition teardown process.
    @_conclude @_lastOp.options.callback


  # `_conclude` is used to handle the end process of transitions and to initialize
  # queued operations.
  _conclude: (cb) =>
    defer =>
      @_inTrans = false
      @_step()
      cb?()


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
    max   = @_settings.maxAngle
    if isNaN angle
      0
    else if angle > max
      max
    else if angle < -max
      -max
    else
      angle


  # Allows other methods to change the transiton duration/delay or disable it altogether.
  _setTrans: (duration, delay) ->
    @_iterate @_lastOp.anchor, (panel, i, len) => @_setPanelTrans arguments..., duration, delay


  _setPanelTrans: (panel, i, len, duration, delay) ->
    {anchor} = @_lastOp
    delayMs  = do =>
      switch delay
        when 0 then 0
        when 1 then @_settings.speed / len * (len - i - 1)
        when 2 then @_settings.speed / len * i

    panel.style[css.transitionDuration] = duration + 'ms'
    panel.style[css.transitionDelay]    = delayMs  + 'ms'
    if @_shading
      for side in (if anchor in anchorListV then anchorListV else anchorListH)
        @_shaders[anchor][side][i].style[css.transitionDuration] = duration + 'ms'
        @_shaders[anchor][side][i].style[css.transitionDelay]    = delayMs  + 'ms'

    delayMs


  # `_setShader` determines a shader's opacity based upon panel position, anchor, and angle.
  _setShader: (n, anchor, angle) ->
    # Store the angle's absolute value and generate an opacity based on `shadingIntensity`.
    abs     = Math.abs angle
    opacity = abs / 90 * @_settings.shadingIntensity

    # With hard shading, opacity is reduced and `angle` is based on the global
    # `lastAngle` so all panels' shaders share the same direction. Soft shaders
    # have alternating directions.
    if @_shading is 'hard'
      opacity *= .15
      if @_lastOp.angle < 0
        angle = abs
      else
        angle = -abs
    else
      opacity *= .4

    # This block makes sure left and top shaders appear for negative angles and right
    # and bottom shaders appear for positive ones.
    if anchor in anchorListV
      if angle < 0
        a = opacity
        b = 0
      else
        a = 0
        b = opacity
      @_shaders[anchor].left[n].style.opacity  = a
      @_shaders[anchor].right[n].style.opacity = b
    else
      if angle < 0
        a = 0
        b = opacity
      else
        a = opacity
        b = 0
      @_shaders[anchor].top[n].style.opacity    = a
      @_shaders[anchor].bottom[n].style.opacity = b


  # This method shows the requested stage element and sets a reference to it as
  # the current stage.
  _showStage: (anchor) ->
    if anchor isnt @_lastOp.anchor
      hideEl @_stages[@_lastOp.anchor]
      @_lastOp.anchor = anchor
      @_lastOp.reset  = true
      @_stages[anchor].style[css.transform] = 'translate3d(' + do =>
        switch anchor
          when 'left'
            '0, 0, 0)'
          when 'right'
            "-#{ @vPanels * .5 }px, 0, 0)"
          when 'top'
            '0, 0, 0)'
          when 'bottom'
            "0, #{ @hPanels * .5 }px, 0)"


  _stageReset: (anchor, cb) =>
    fn = (e) =>
      e.currentTarget.removeEventListener css.transitionEnd, fn, false if e
      @_showStage anchor
      defer cb

    return fn() if @_lastOp.angle is 0
    @_panels[@_lastOp.anchor][0].addEventListener css.transitionEnd, fn, false

    @_iterate @_lastOp.anchor, (panel, i) =>
      panel.style[css.transform] = @_transform 0, @_lastOp.anchor
      @_setShader i, @_lastOp.anchor, 0 if @_shading

    @


  # Converts a shorthand anchor name to a full one.
  _getLonghandAnchor: (shorthand) ->
    switch shorthand.toString()
      when 'left',   'l', '4'
        'left'
      when 'right',  'r', '2'
        'right'
      when 'top',    't', '1'
        'top'
      when 'bottom', 'b', '3'
        'bottom'
      else
        # Left is always default.
        'left'


  # Gives the element a resize cursor to prompt the user to drag the mouse.
  _setCursor: (bool = @_touchEnabled) ->
    if bool
      @_stageHolder.style.cursor = css.grab
    else
      @_stageHolder.style.cursor = 'default'


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
          @_stageHolder[listenFn] eString.toLowerCase(), @['_on' + eventPair[0]], false
        else
          @_stageHolder[listenFn] 'mouseout', @_onMouseOut, false
          break
    @


  # This method is called when a finger or mouse button is pressed on the element.
  _onTouchStart: (e) =>
    return if !@_touchEnabled or @isFoldedUp
    e.preventDefault()
    # Clear queued animations.
    @emptyQueue()
    # Set a property to track touch starts.
    @_touchStarted = true
    # Change the cursor to the active `grabbing` state.
    @_stageHolder.style.cursor = css.grabbing
    # Disable tweening to enable instant 1 to 1 movement.
    @_setTrans 0, 0
    # Derive the axis to fold on.
    @_touchAxis = if @_lastOp.anchor in anchorListV then 'x' else 'y'
    # Set a reference to the last folded angle to accurately derive deltas.
    @["_#{ @_touchAxis }Last"] = @_lastOp.angle
    axis1 = "_#{ @_touchAxis }1"
    # Determine the starting tap's coordinate for touch and mouse events.
    if e.type is 'mousedown'
      @[axis1] = e["page#{ @_touchAxis.toUpperCase() }"]
    else
      @[axis1] = e.targetTouches[0]["page#{ @_touchAxis.toUpperCase() }"]

    # Return that value to an external listener.
    @_settings.touchStartCallback @[axis1]


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
    distance = (current - @["_#{ @_touchAxis }1"]) * @_settings.touchSensitivity

    # Calculate final delta based on starting angle, anchor, and what side of zero
    # the last operation was on.
    if @_lastOp.angle < 0
      if @_lastOp.anchor is 'right' or @_lastOp.anchor is 'bottom'
        delta = @["_#{ @_touchAxis }Last"] - distance
      else
        delta = @["_#{ @_touchAxis }Last"] + distance
      delta = 0 if delta > 0
    else
      if @_lastOp.anchor is 'right' or @_lastOp.anchor is 'bottom'
        delta = @["_#{ @_touchAxis }Last"] + distance
      else
        delta = @["_#{ @_touchAxis }Last"] - distance
      delta = 0 if delta < 0


    delta = @_normalizeAngle delta
    @_lastOp.angle = delta
    @_lastOp.fn.call @, delta, @_lastOp.anchor, @_lastOp.options
    @_settings.touchMoveCallback delta



  # Teardown process when touch/drag event ends.
  _onTouchEnd: =>
    return unless @_touchEnabled
    # Restore the initial touch status and cursor.
    @_touchStarted = @_inTrans = false
    @_stageHolder.style.cursor = css.grab
    # Enable tweening again.
    @_setTrans @_settings.speed, 0
    # Pass callback final value.
    @_settings.touchEndCallback @["_#{ @_touchAxis }Last"]


  # End folding when the mouse or finger leaves the composition.
  _onTouchLeave: =>
    return unless @_touchEnabled and @_touchStarted
    @_onTouchEnd()


  # A fallback for browsers that don't support `mouseleave`.
  _onMouseOut: (e) =>
    return unless @_touchEnabled and @_touchStarted
    @_onTouchEnd() if e.toElement and not @el.contains e.toElement


  _unfold: (callback) ->
    return callback?() unless @isFoldedUp
    @_inTrans = true

    @_iterate @_lastOp.anchor, (panel, i, len) =>
      delay = @_setPanelTrans arguments..., @_settings.speed, 2

      do (panel, i, delay) =>
        defer =>
          panel.style[css.transform] = @_transform 0, @_lastOp.anchor
          setTimeout =>
            showEl panel.children[0]
            if i is len - 1
              @_inTrans = @isFoldedUp = false
              callback?()
              @_lastOp.fn = @accordion
            defer => panel.style[css.transitionDuration] = @_settings.speed
          , delay + @_settings.speed * .25


  _iterate: (anchor, fn) ->
    fn.call @, panel, i, panels.length for panel, i in panels = @_panels[anchor]


  # Public Methods
  # ==============


  setSpeed: (speed) ->
    @_setTweening (@_settings.speed = speed), 0


  # Disables oriDomi slicing by showing the original, untouched target element.
  # This is useful for certain user interactions on the inner content.
  freeze: (callback) ->
    # Return if already frozen.
    if @isFrozen
      callback?()
    else
      # Make sure to reset folding first.
      @_stageReset @_lastOp.anchor, =>
        @isFrozen = true
        # Swap the visibility of the elements.
        hideEl @_stageHolder
        showEl @cloneEl
        @_setCursor false
        callback?()
    @


  # Restores the oriDomi version of the element for folding purposes.
  unfreeze: ->
    # Only unfreeze if already frozen.
    if @isFrozen
      @isFrozen = false
      # Swap the visibility of the elements.
      hideEl @cloneEl
      showEl @_stageHolder
      @_setCursor()
      # Set `lastAngle` to 0 so an immediately subsequent call to `freeze` triggers the callback.
      @_lastOp.angle = 0
    @


  # Removes the oriDomi element and restores the original element.
  destroy: (callback) ->
    # First restore the original element.
    @freeze =>
      # Remove event listeners.
      @_setTouch false
      # Remove the data reference if using jQuery.
      $.data @el, baseName, null if $
      # Remove the oriDomi element from the DOM.
      @el.innerHTML = @cloneEl.innerHTML
      # Reset original styles.
      @el.classList.remove elClasses.active
      callback?()
    null


  # Empties the queue should you want to cancel scheduled animations.
  emptyQueue: ->
    @_queue = []
    defer => @_inTrans = false
    @


  # Enables touch events.
  enableTouch: ->
    @_setTouch true


  # Disables touch events.
  disableTouch: ->
    @_setTouch false


  # Setter method for `maxAngle`.
  constrainAngle: (angle) ->
    @_settings.maxAngle = parseFloat(angle, 10) or defaults.maxAngle
    @


  wait: (ms) ->
    fn = => setTimeout @_conclude, ms
    if @_inTrans
      @_queue.push [fn, @_lastOp.angle, @_lastOp.anchor, @_lastOp.options]
    else
      fn()
    @


  # oriDomi's most basic effect. Transforms the target like its namesake.
  accordion: prep (angle, anchor, options) ->
    # Loop through the panels in this stage.
    @_iterate anchor, (panel, i) =>
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
      if @_shading and !(i is 0 and options.sticky) and Math.abs(deg) isnt 180
        @_setShader i, anchor, deg


  # `curl` appears to bend rather than fold the paper. Its curves can appear smoother
  # with higher panel counts.
  curl: prep (angle, anchor, options) ->
    # Reduce the angle based on the number of panels in this axis.
    angle /= if anchor in anchorListV then @_settings.vPanels else @_settings.hPanels

    @_iterate anchor, (panel, i) =>
      panel.style[css.transform] = @_transform angle, anchor
      @_setShader i, anchor, 0 if @_shading


  # `ramp` lifts up all panels after the first one.
  ramp: prep (angle, anchor, options) ->
    # Rotate the second panel for the lift up.
    @_panels[anchor][1].style[css.transform] = @_transform angle, anchor

    # For all but the first two panels, set the angle to 0.
    @_iterate anchor, (panel, i) =>
      @_panels[anchor][i].style[css.transform] = @_transform 0, anchor if i > 1
      @_setShader i, anchor, 0 if @_shading


  # Hides the element by folding each panel in a cascade of animations.
  foldUp: prep (anchor, callback) ->
    @_stageReset anchor, =>
      return callback?() if @isFoldedUp
      @_inTrans = @isFoldedUp = true

      @_iterate anchor, (panel, i, len) =>
        duration  = @_settings.speed
        duration /= 2 if i is 0
        delay     = @_setPanelTrans arguments..., duration, 1

        do (panel, i, delay) =>
          defer =>
            panel.style[css.transform] = @_transform (if i is 0 then 90 else 170), anchor
            setTimeout =>
              if i is 0
                @_inTrans = false
                callback?()
              else
                hideEl panel.children[0]

            , delay + @_settings.speed * .25


  # The inverse of `foldUp`.
  unfold: prep (callback) -> @_unfold arguments...


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
    options.stairs = options.sticky =  true
    @accordion angle, anchor, options


  # `fracture: true` proxy.
  fracture: (angle, anchor, options = {}) ->
    options.fracture = true
    @accordion angle, anchor, options


  # `twist: true` proxy.
  twist: (angle, anchor, options = {}) ->
    options.fracture = options.twist = true
    @accordion angle / 10, anchor, options


  # Class Members
  # =============


  # Set a version flag for easy external retrieval.
  @VERSION = '0.3.0'


  # Externally check if oriDomi is supported by the browser.
  @isSupported = isSupported


  # External function to enable `devMode`.
  @devMode = -> devMode = true


# Export constructor on `window` and `module.exports` (if applicable).
window.OriDomi = OriDomi
module.exports = OriDomi if module?.exports



# Plugin Bridge
# =============


# Only create bridge if jQuery (or an imitation supporting `data()`) exists.
if $
  # Attach an `oriDomi` method to `$`'s prototype.
  $::oriDomi = (options) ->
    # Return selection if oriDomi is unsupported by the browser.
    return @ unless isSupported

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
        unless instance = $.data el, baseName
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
        if instance = $.data el, baseName
          return instance
        else
          # Create an instance of oriDomi and attach it to the element.
          $.data el, baseName, new OriDomi el, options

      # Return the selection.
      @
