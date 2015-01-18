# # OriDomi
# ### Fold up the DOM like paper.
# 1.1.5

# [oridomi.com](http://oridomi.com)
# #### by [Dan Motzenbecker](http://oxism.com)

# Copyright 2014, MIT License


libName = 'OriDomi'

# This variable is set to true and negated later if the browser does
# not support OriDomi.
isSupported = true

# Utility Functions
# =================

# Used for informing the developer which required feature the browser lacks.
supportWarning = (prop) ->
  console?.warn "#{ libName }: Missing support for `#{ prop }`."
  isSupported = false


# Checks for the presence of CSS properties on a test element.
testProp = (prop) ->
  # Loop through the vendor prefix list and return a match is found.
  for prefix in prefixList
    return full if (full = prefix + capitalize prop) of testEl.style

  # If the unprefixed property is present, return it.
  return prop if prop of testEl.style
  # If no matches are found, return false to denote that the browser is
  # missing this property.
  false


# Generates CSS text based on a selector string and a map of styling rules.
addStyle = (selector, rules) ->
  style = ".#{ selector }{"
  for prop, val of rules
    # If the CSS property is among special properties defined later, prefix it.
    if prop of css
      prop = css[prop]
      prop = '-' + prop if prop.match /^(webkit|moz|ms)/i

    # Convert camel case to hyphenated.
    style += "#{ prop.replace(/([a-z])([A-Z])/g, '$1-$2').toLowerCase() }:#{ val };"

  styleBuffer += style + '}'


# Defines gradient directions based on a given anchor.
getGradient = (anchor) ->
  "#{ css.gradientProp }(#{ anchor }, rgba(0, 0, 0, .5) 0%, rgba(255, 255, 255, .35) 100%)"


# Used mainly when creating camel cased strings.
capitalize = (s) ->
  s[0].toUpperCase() + s[1...]


# Create an element and look up the canonical class name.
createEl = (className) ->
  el = document.createElement 'div'
  el.className = elClasses[className]
  el


# Clone an element, add an additional class, and return it.
cloneEl = (parent, deep, className) ->
  el = parent.cloneNode deep
  el.classList.add elClasses[className]
  el


# GPU efficient ways of hiding and showing elements:
hideEl = (el) ->
  el.style[css.transform] = 'translate3d(-99999px, 0, 0)'


showEl = (el) ->
  el.style[css.transform] = 'translate3d(0, 0, 0)'


# This decorator is used on public effect methods to invoke preliminary tasks
# before the effect is applied.
prep = (fn) ->
  ->
    # If the method has been initiated by a touch handler, skip this process.
    if @_touchStarted
      fn.apply @, arguments
    else
      [a0, a1, a2] = arguments
      opt          = {}
      angle        = anchor = null

      # This switch is used to derive the intended order of arguments.
      # This keeps argument requirements flexible, allowing most to be left out.
      # By putting this logic in a decorator, it doesn't have to exist in any
      # of the individual methods.

      # Methods are inferred by their arity.
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
      # Here we add the called function and its normalized arguments to the
      # instance's queue.
      @_queue.push [fn, @_normalizeAngle(angle), @_getLonghandAnchor(anchor), opt]
      # `_step()` manages the queue and decides whether the action will occur now
      # or be deferred.
      @_step()
      # This decorator also returns the instance so effect methods are chainable.
      @


# It's necessary to defer many DOM manipulations to a subsequent event loop tick.
defer = (fn) ->
  setTimeout fn, 0


# Empty function to be used as placeholder for callback defaults
# (instead of creating separate empty functions).
noOp = ->


# Setup
# =====

# Set a reference to jQuery (or another `$`-aliased DOM library).
# If it doesn't exist, set to null so OriDomi knows we are working without jQuery.
# OriDomi doesn't require it to work, but offers a useful plugin bridge if present.
$ = if window?.$?.data then window.$ else null

# List of anchors and their corresponding axis pairs.
anchorList  = ['left', 'right', 'top', 'bottom']
anchorListV = anchorList[..1]
anchorListH = anchorList[2..]

# Create a div for testing CSS3 properties.
testEl = document.createElement 'div'

# The style buffer is later populated with CSS rules and appended to the document.
styleBuffer = ''

# List of browser prefixes for testing CSS3 properties.
prefixList = ['Webkit', 'Moz', 'ms']
baseName   = libName.toLowerCase()
# CSS classes used by style rules.
elClasses  =
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

# Each class is namespaced to prevent styling collisions.
elClasses[k] = "#{ baseName }-#{ v }" for k, v of elClasses

# Map of the CSS3 properties needed to support OriDomi, with shorthand names as keys.
# The keys and values are initialized as identical pairs to start with and prefixed
# subsequently when necessary.
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
    'mask'
  ]
  @

# This section is wrapped in a function call so that it can exit
# early when discovering a lack of browser support to prevent unnecessary work.
do ->
  # Loop through the CSS map and replace each value with the result of `testProp()`.
  for key, value of css
    css[key] = testProp value
    # If the returned value is false, warn the user that the browser doesn't support
    # OriDomi, set `isSupported` to false, and break out of the loop.
    return supportWarning value unless css[key]

  # Test for `preserve-3d` as a transform style. This is particularly important
  # since it's necessary for nested 3D transforms and recent versions of IE that
  # support 3D transforms lack it.
  p3d = 'preserve-3d'
  testEl.style[css.transformStyle] = p3d
  # Failure is indicated when querying the style lacks the correct string.
  unless testEl.style[css.transformStyle] is p3d
    return supportWarning p3d

  # CSS3 linear gradients are used for shading.
  # Testing for them is different because they are prefixed values, not properties.
  # This invokes an anonymous function to loop through vendor-prefixed linear gradients.
  css.gradientProp = do ->
    for prefix in prefixList
      hyphenated = "-#{ prefix.toLowerCase() }-linear-gradient"
      testEl.style.backgroundImage = "#{ hyphenated }(left, #000, #fff)"
      # After setting a gradient background on the test div, attempt to retrieve it.
      return hyphenated unless testEl.style.backgroundImage.indexOf('gradient') is -1
    # If none of the hyphenated values worked, return the unprefixed version.
    'linear-gradient'

  # The default cursor style is set to `grab` to prompt the user to interact with the element.
  # `grab` as a value isn't supported in all browsers so it has to be detected.
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

  # Like gradients, transform (as a transition value) needs to be detected and prefixed.
  css.transformProp =
    # Use a regular expression to pluck the prefix `testProp` found.
    if prefix = css.transform.match /(\w+)Transform/i
      "-#{ prefix[1].toLowerCase() }-transform"
    else
      'transform'

  # Set a `transitionEnd` property based on the browser's prefix for `transitionProperty`.
  css.transitionEnd =
    switch css.transitionProperty.toLowerCase()
      when 'transitionproperty'       then 'transitionEnd'
      when 'webkittransitionproperty' then 'webkitTransitionEnd'
      when 'moztransitionproperty'    then 'transitionend'
      when 'mstransitionproperty'     then 'msTransitionEnd'


  # These calls generate OriDomi's stylesheet.
  do (i = (s) -> s + ' !important') ->
    addStyle elClasses.active,
      backgroundColor: i 'transparent'
      backgroundImage: i 'none'
      boxSizing:       i 'border-box'
      border:          i 'none'
      outline:         i 'none'
      padding:         i '0'
      transformStyle:  i p3d
      mask:            i 'none'
      position:          'relative'

    addStyle elClasses.clone,
      margin:    i '0'
      boxSizing: i 'border-box'
      overflow:  i 'hidden'
      display:   i 'block'

    addStyle elClasses.holder,
      width:          '100%'
      position:       'absolute'
      top:            '0'
      bottom:         '0'
      transformStyle: p3d

    addStyle elClasses.stage,
      width:          '100%'
      height:         '100%'
      position:       'absolute'
      transform:      'translate3d(-9999px, 0, 0)'
      margin:         '0'
      padding:        '0'
      transformStyle: p3d

    # Each anchor needs a particular perspective origin.
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

    # Linear gradient directions depend on their anchor.
    for anchor in anchorList
      addStyle elClasses['shader' + capitalize anchor], background: getGradient anchor

    addStyle elClasses.content,
      margin:    i '0'
      position:  i 'relative'
      float:     i 'none'
      boxSizing: i 'border-box'
      overflow:  i 'hidden'

    addStyle elClasses.mask,
      width:              '100%'
      height:             '100%'
      position:           'absolute'
      overflow:           'hidden'
      transform:          'translate3d(0, 0, 0)'
      outline:            '1px solid transparent'

    addStyle elClasses.panel,
      width:              '100%'
      height:             '100%'
      padding:            '0'
      position:           'absolute'
      transitionProperty: css.transformProp
      transformOrigin:    'left'
      transformStyle:     p3d

    addStyle elClasses.panelH, transformOrigin: 'top'
    addStyle "#{ elClasses.stageRight } .#{ elClasses.panel }", transformOrigin: 'right'
    addStyle "#{ elClasses.stageBottom } .#{ elClasses.panel }", transformOrigin: 'bottom'

  styleEl      = document.createElement 'style'
  styleEl.type = 'text/css'

  # Once the style buffer is ready, it's appended to the document as a stylesheet.
  if styleEl.styleSheet
    styleEl.styleSheet.cssText = styleBuffer
  else
    styleEl.appendChild document.createTextNode styleBuffer

  document.head.appendChild styleEl


# Defaults
# ========

# These defaults are used by all OriDomi instances unless overridden.
defaults =
  # The number of vertical panels (for folding left or right).
  # You can use either an integer, or an array of percentages if you want custom
  # panel widths, e.g. `[20, 10, 10, 20, 10, 20, 10]`.
  # The numbers must add up to 100 (or near it, so you can use values like
  # `[33, 33, 33]`).
  vPanels: 3
  # The number of horizontal panels (for folding top or bottom) or an array of percentages.
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
  # Ripple mode causes effects to fold in a staggered, cascading manner.
  # `1` indicates a forward cascade, `2` is backwards. It is disabled by default.
  ripple: 0
  # This CSS class is applied to OriDomi elements so they can be easily targeted later.
  oriDomiClass: libName.toLowerCase()
  # This is a multiplier that determines the darkness of shading.
  # If you need subtler shading, set this to a value below 1.
  shadingIntensity: 1
  # This option allows you to supply the name of a CSS easing method or a
  # cubic bezier formula for customized animation easing.
  easingMethod: ''
  # Number of pixels to offset each panel to prevent small gaps from appearing
  # between them. This is configurable if you have a need for precision.
  gapNudge: 1.5
  # Allows the user to fold the element via touch or mouse.
  touchEnabled: true
  # Coefficient of touch/drag action's distance delta. Higher numbers cause more movement.
  touchSensitivity: .25
  # Custom callbacks for touch/drag events. Each one is invoked with a relevant
  # value so they can be used to manipulate objects outside of the OriDomi
  # instance (e.g. sliding panels). x values are returned when folding left and
  # right, y values for top and bottom. The second argument passed is the original
  # touch or mouse event. These are empty functions by default. Invoked with
  # starting coordinate as first argument.
  touchStartCallback: noOp
  # Invoked with the folded angle.
  touchMoveCallback: noOp
  # Invoked with ending point.
  touchEndCallback: noOp


# Constructor
# ===========

class OriDomi

  constructor: (@el, options = {}) ->
    return unless isSupported
    # Fix constructor calls made without `new`.
    return new OriDomi @el, options unless @ instanceof OriDomi
    # Support selector strings as well as elements.
    @el = document.querySelector @el if typeof @el is 'string'
    # Make sure element is valid.
    unless @el and @el.nodeType is 1
      console?.warn "#{ libName }: First argument must be a DOM element"
      return

    # Fill in passed options with defaults.
    @_config = new ->
      for k, v of defaults
        if k of options
          @[k] = options[k]
        else
          @[k] = v
      @

    # The ripple setting is converted to a number to allow boolean settings.
    @_config.ripple = Number @_config.ripple
    # The queue holds animation sequences.
    @_queue   = []
    @_panels  = {}
    @_stages  = {}
    # Set the starting anchor to left.
    @_lastOp  = anchor: anchorList[0]
    @_shading = @_config.shading
    # Alias `shading: true` as hard shading.
    @_shading = 'hard' if @_shading is true

    # The shader elements are constructed in a conditional so the process can be
    # skipped if shading is disabled.
    if @_shading
      @_shaders    = {}
      shaderProtos = {}
      shaderProto  = createEl 'shader'
      shaderProto.style[css.transitionDuration]       = @_config.speed + 'ms'
      shaderProto.style[css.transitionTimingFunction] = @_config.easingMethod

    stageProto = createEl 'stage'
    stageProto.style[css.perspective] = @_config.perspective + 'px'

    for anchor in anchorList
      # Each anchor has a unique set of panels.
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
    panelProto.style[css.transitionDuration]       = @_config.speed + 'ms'
    panelProto.style[css.transitionTimingFunction] = @_config.easingMethod

    # These arrays store panel offsets so they don't have to be computed twice
    # for each axis.
    offsets = left: [], top: []

    # This loop builds all of the panels.
    for axis in ['x', 'y']
      if axis is 'x'
        anchorSet   = anchorListV
        metric      = 'width'
        classSuffix = 'V'
      else
        anchorSet   = anchorListH
        metric      = 'height'
        classSuffix = 'H'

      panelConfig = @_config[panelKey = classSuffix.toLowerCase() + 'Panels']

      # If the panel set configuration is an integer (as it is by default),
      # an array is filled with equal percentages.
      if typeof panelConfig is 'number'
        count       = Math.abs parseInt panelConfig, 10
        percent     = 100 / count
        panelConfig = @_config[panelKey] = (percent for [0...count])
      else
        count = panelConfig.length
        unless 99 <= panelConfig.reduce((p, c) -> p + c) <= 100.1
          throw new Error "#{ libName }: Panel percentages do not sum to 100"

      # Clone a new mask element and append it to a panel element prototype.
      mask = cloneEl maskProto, true, 'mask' + classSuffix

      if @_shading
        mask.appendChild shaderProtos[anchor] for anchor in anchorSet

      proto = cloneEl panelProto, false, 'panel' + classSuffix
      proto.appendChild mask

      for anchor, rightOrBottom in anchorSet
        for panelN in [0...count]
          panel   = proto.cloneNode true
          content = panel.children[0].children[0]
          content.style.width = content.style.height = '100%'

          if rightOrBottom
            panel.style[css.origin] = anchor
            # Panels on the right and bottom axes are placed backwards.
            index = panelConfig.length - panelN - 1
            prev  = index + 1
          else
            index = panelN
            prev  = index - 1
            # The inner content of each panel is offset relative to the panel
            # index to display a contiguous composition.
            if panelN is 0
              offsets[anchor].push 0
            else
              offsets[anchor].push (offsets[anchor][prev] - 100) * (panelConfig[prev] / panelConfig[index])

          if panelN is 0
            panel.style[anchor] = '0'
            # Only the first panel has its size set to the nominal target percentage.
            panel.style[metric] = panelConfig[index] + '%'
          else
            # Each subsequent panel is offset by its predecessor/parent's size.
            panel.style[anchor] = '100%'
            # Subsequent panels have their percentages set relative to their
            # parent panel's percentage to counteract it in an absolute sense.
            panel.style[metric] = panelConfig[index] / panelConfig[prev] * 100 + '%'

          if @_shading
            for a, i in anchorSet
              @_shaders[anchor][a][panelN] = panel.children[0].children[i + 1]

          # The inner content retains the original dimensions of the element
          # while being inside a small slice. By manipulating the number based
          # on the total number of panels and the absolute percentage, the size
          # reduction of the parent is undone and sizing flexibility is achieved.
          content.style[metric] =
            content.style['max' + capitalize metric] =
              (count / panelConfig[index] * 10000 / count) + '%'

          content.style[anchorSet[0]] = offsets[anchorSet[0]][index] + '%'

          @_transformPanel panel, 0, anchor
          @_panels[anchor][panelN] = panel

          # Panels are nested inside each other.
          @_panels[anchor][panelN - 1].appendChild panel unless panelN is 0

        # Append the first panel to each stage.
        @_stages[anchor].appendChild @_panels[anchor][0]

    @_stageHolder = createEl 'holder'
    @_stageHolder.setAttribute 'aria-hidden', 'true'
    @_stageHolder.appendChild @_stages[anchor] for anchor in anchorList

    # Override default styling if original positioning is absolute.
    if window.getComputedStyle(@el).position is 'absolute'
      @el.style.position = 'absolute'

    @el.classList.add elClasses.active
    showEl @_stages.left
    # The original element is cloned and hidden via transforms so the dimensions
    # of the OriDomi content are maintained by it.
    @_cloneEl = cloneEl @el, true, 'clone'
    @_cloneEl.classList.remove elClasses.active
    hideEl @_cloneEl
    # Once the clone is stored the original element is emptied and appended with
    # the clone and the OriDomi content.
    @el.innerHTML = ''
    @el.appendChild @_cloneEl
    @el.appendChild @_stageHolder
    # This ensures mouse events work correctly when panels are transformed
    # away from the viewer.
    @el.parentNode.style[css.transformStyle] = 'preserve-3d'

    # An effect method is called since touch events rely on using the last
    # method called.
    @accordion 0
    @setRipple @_config.ripple if @_config.ripple
    @enableTouch() if @_config.touchEnabled


  # Internal Methods
  # ================

  # This method is called for the action shifted off the queue.
  _step: =>
    # Return if the composition is currently in transition or the queue is empty.
    return if @_inTrans or !@_queue.length
    @_inTrans = true
    # Destructure action arguments from the front of the queue.
    [fn, angle, anchor, options] = @_queue.shift()
    @unfreeze() if @isFrozen

    # A local function for the next action is created should the call need to be
    # deferred (if the stage is folded up or on the wrong anchor).
    next = =>
      @_setCallback {angle, anchor, options, fn}
      args = [angle, anchor, options]
      args.shift() if fn.length < 3
      fn.apply @, args

    if @isFoldedUp
      if fn.length is 2
        next()
      else
        @_unfold next
    else if anchor isnt @_lastOp.anchor
      @_stageReset anchor, next
    else
      next()


  # This method tests if the called action is identical to the previous one.
  # If two identical operations were called in a row, the transition callback
  # wouldn't be called due to no animation taking place. This method reasons if
  # movement has taken place, avoiding this pitfall of transition listeners.
  _isIdenticalOperation: (op) ->
    return true unless @_lastOp.fn
    return false if @_lastOp.reset
    (return false if @_lastOp[key] isnt op[key]) for key in ['angle', 'anchor', 'fn']
    (return false if v isnt @_lastOp.options[k] and k isnt 'callback') for k, v of op.options
    true


  # This method normalizes callback handling for all public methods.
  _setCallback: (operation) ->
    # If there was no transformation, invoke the callback immediately.
    if !@_config.speed or @_isIdenticalOperation operation
      @_conclude operation.options.callback
    # Otherwise, attach an event listener to be called on the transition's end.
    else
      @_panels[@_lastOp.anchor][0].addEventListener css.transitionEnd, @_onTransitionEnd, false

    (@_lastOp = operation).reset = false


  # Handler called when a CSS transition ends.
  _onTransitionEnd: (e) =>
    # Remove the event listener immediately to prevent bubbling.
    e.currentTarget.removeEventListener css.transitionEnd, @_onTransitionEnd, false
    # Initialize the transition teardown process.
    @_conclude @_lastOp.options.callback, e


  # Used to handle the end process of transitions and to initialize queued operations.
  _conclude: (cb, event) =>
    defer =>
      @_inTrans = false
      @_step()
      cb? event, @


  # Transforms a given element based on angle, anchor, and fracture boolean.
  _transformPanel: (el, angle, anchor, fracture) ->
    x = y = z = 0
    switch anchor
      when 'left'
        y = angle
        transPrefix = 'X(-'
      when 'right'
        y = -angle
        transPrefix = 'X('
      when 'top'
        x = -angle
        transPrefix = 'Y(-'
      when 'bottom'
        x = angle
        transPrefix = 'Y('

    # Rotate on every axis in fracture mode.
    x = y = z = angle if fracture

    el.style[css.transform] = "
                              rotateX(#{ x }deg)
                              rotateY(#{ y }deg)
                              rotateZ(#{ z }deg)
                              translate#{ transPrefix }#{ @_config.gapNudge }px)
                              "


  # This validates a given angle by making sure it's a float and by
  # keeping it within the maximum range specified in the instance settings.
  _normalizeAngle: (angle) ->
    angle = parseFloat angle, 10
    max   = @_config.maxAngle
    if isNaN angle
      0
    else if angle > max
      max
    else if angle < -max
      -max
    else
      angle


  # Allows other methods to change the transition duration/delay or disable it altogether.
  _setTrans: (duration, delay, anchor = @_lastOp.anchor) ->
    @_iterate anchor, (panel, i, len) => @_setPanelTrans anchor, arguments..., duration, delay


  # This method changes the transition duration and delay of panels and shaders.
  _setPanelTrans: (anchor, panel, i, len, duration, delay) ->
    delayMs =
      # Delay is a `ripple` value. The milliseconds are derived based on the
      # speed setting and the number of panels.
      switch delay
        when 0 then 0
        when 1 then @_config.speed / len * i
        when 2 then @_config.speed / len * (len - i - 1)

    panel.style[css.transitionDuration] = duration + 'ms'
    panel.style[css.transitionDelay]    = delayMs  + 'ms'
    if @_shading
      for side in (if anchor in anchorListV then anchorListV else anchorListH)
        shader = @_shaders[anchor][side][i]
        shader.style[css.transitionDuration] = duration + 'ms'
        shader.style[css.transitionDelay]    = delayMs  + 'ms'

    delayMs


  # Determines a shader's opacity based upon panel position, anchor, and angle.
  _setShader: (n, anchor, angle) ->
    # Store the angle's absolute value and generate an opacity based on `shadingIntensity`.
    abs     = Math.abs angle
    opacity = abs / 90 * @_config.shadingIntensity

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
      @_stages[anchor].style[css.transform] = 'translate3d(' +
        switch anchor
          when 'left'
            '0, 0, 0)'
          when 'right'
            "-#{ @_config.vPanels.length }px, 0, 0)"
          when 'top'
            '0, 0, 0)'
          when 'bottom'
            "0, -#{ @_config.hPanels.length }px, 0)"


  # If the composition needs to switch stages or fold up, it must first unfold
  # all panels to 0 degrees.
  _stageReset: (anchor, cb) =>
    fn = (e) =>
      e.currentTarget.removeEventListener css.transitionEnd, fn, false if e
      @_showStage anchor
      defer cb

    # If already unfolded to 0, immediately invoke the change function.
    return fn() if @_lastOp.angle is 0
    @_panels[@_lastOp.anchor][0].addEventListener css.transitionEnd, fn, false

    @_iterate @_lastOp.anchor, (panel, i) =>
      @_transformPanel panel, 0, @_lastOp.anchor
      @_setShader i, @_lastOp.anchor, 0 if @_shading


  # Converts a shorthand anchor name to a full one.
  # Numerical shorthands are based on CSS shorthand ordering.
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
      @el.style.cursor = css.grab
    else
      @el.style.cursor = 'default'


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
        unless eString is 'TouchLeave' and !mouseLeaveSupport
          @el[listenFn] eString.toLowerCase(), @['_on' + eventPair[0]], false
        else
          @el[listenFn] 'mouseout', @_onMouseOut, false
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
    @el.style.cursor = css.grabbing
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
    @_config.touchStartCallback @[axis1], e


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
    distance = (current - @["_#{ @_touchAxis }1"]) * @_config.touchSensitivity

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


    @_lastOp.angle = delta = @_normalizeAngle delta
    @_lastOp.fn.call @, delta, @_lastOp.anchor, @_lastOp.options
    @_config.touchMoveCallback delta, e



  # Teardown process when touch/drag event ends.
  _onTouchEnd: (e) =>
    return unless @_touchEnabled
    # Restore the initial touch status and cursor.
    @_touchStarted = @_inTrans = false
    @el.style.cursor = css.grab
    # Enable transitions again.
    @_setTrans @_config.speed, @_config.ripple
    # Pass callback final coordinate.
    @_config.touchEndCallback @["_#{ @_touchAxis }Last"], e


  # End folding when the mouse or finger leaves the composition.
  _onTouchLeave: (e) =>
    return unless @_touchEnabled and @_touchStarted
    @_onTouchEnd e


  # A fallback for browsers that don't support `mouseleave`.
  _onMouseOut: (e) =>
    return unless @_touchEnabled and @_touchStarted
    @_onTouchEnd e if e.toElement and !@el.contains e.toElement


  # This method unfolds the composition after it's been folded up. It's private
  # and doesn't use the decorator because it's used internally by other methods
  # and skips the queue. Its public counterpart is a queued alias.
  _unfold: (callback) ->
    @_inTrans = true
    {anchor}  = @_lastOp
    @_iterate anchor, (panel, i, len) =>
      delay = @_setPanelTrans anchor, arguments..., @_config.speed, 1

      do (panel, i, delay) =>
        defer =>
          @_transformPanel panel, 0, anchor
          @_setShader i, anchor, 0 if @_shading

          setTimeout =>
            showEl panel.children[0]
            if i is len - 1
              @_inTrans = @isFoldedUp = false
              callback?()
              @_lastOp.fn    = @accordion
              @_lastOp.angle = 0

            defer => panel.style[css.transitionDuration] = @_config.speed

          , delay + @_config.speed * .25


  # This method is used by many others to iterate among panels within a given anchor.
  _iterate: (anchor, fn) ->
    fn.call @, panel, i, panels.length for panel, i in panels = @_panels[anchor]


  # Public Methods
  # ==============


  # Enables touch events.
  enableTouch: ->
    @_setTouch true


  # Disables touch events.
  disableTouch: ->
    @_setTouch false


  # Public setter for transition durations.
  setSpeed: (speed) ->
    for anchor in anchorList
      @_setTrans (@_config.speed = speed), @_config.ripple, anchor
    @


  # Disables OriDomi slicing by showing the original, untouched target element.
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
        showEl @_cloneEl
        @_setCursor false
        callback?()
    @


  # Restores the OriDomi version of the element for folding purposes.
  unfreeze: ->
    # Only unfreeze if already frozen.
    if @isFrozen
      @isFrozen = false
      # Swap the visibility of the elements.
      hideEl @_cloneEl
      showEl @_stageHolder
      @_setCursor()
      # Set `lastAngle` to 0 so an immediately subsequent call to `freeze` triggers the callback.
      @_lastOp.angle = 0
    @


  # Removes the OriDomi element and restores the original element.
  destroy: (callback) ->
    # First restore the original element.
    @freeze =>
      # Remove event listeners.
      @_setTouch false
      # Remove the data reference if using jQuery.
      $.data @el, baseName, null if $
      # Remove the OriDomi element from the DOM.
      @el.innerHTML = @_cloneEl.innerHTML
      # Reset original styling.
      @el.classList.remove elClasses.active
      callback?()
    null


  # Empties the queue should you want to cancel scheduled animations.
  emptyQueue: ->
    @_queue = []
    defer => @_inTrans = false
    @


  # Enable or disable ripple. 1 is forwards, 2 is backwards, 0 is disabled.
  setRipple: (dir = 1) ->
    @_config.ripple = Number dir
    @setSpeed @_config.speed
    @


  # Setter method for `maxAngle`.
  constrainAngle: (angle) ->
    @_config.maxAngle = parseFloat(angle, 10) or defaults.maxAngle
    @


  # Pause in the midst of an animation sequence, in milliseconds.
  # E.g.: el.reveal(20).wait(5000).accordion(-33)
  wait: (ms) ->
    fn = => setTimeout @_conclude, ms
    if @_inTrans
      @_queue.push [fn, @_lastOp.angle, @_lastOp.anchor, @_lastOp.options]
    else
      fn()
    @


  # This method is used to externally manipulate the styling or contents of the
  # composition. Manipulation instructions can be supplied via a function (invoked
  # with each panel element), or a map of selectors with instructions.
  # Instruction values can be text to implicitly update `innerHTML` content or
  # objects with `style` and/or `content` keys. Style keys should contain object
  # literals with camel-cased CSS properties as keys.
  modifyContent: (fn) ->
    if typeof fn isnt 'function'
      selectors = fn

      set = (el, content, style) ->
        el.innerHTML = content if content
        if style
          el.style[key] = value for key, value of style
          null

      fn = (el) ->
        for selector, value of selectors
          content = style = null
          if typeof value is 'string'
            content = value
          else
            {content, style} = value

          if selector is ''
            set el, content, style
            continue

          set match, content, style for match in el.querySelectorAll selector

        null

    for anchor in anchorList
      for panel, i in @_panels[anchor]
        fn panel.children[0].children[0], i, anchor
    @


  # Effect Methods
  # ==============


  # Base effect with alternating peaks and valleys.
  # `reveal` relies on it by calling it with `sticky: true` to keep the first
  # panel flat.
  accordion: prep (angle, anchor, options) ->
    @_iterate anchor, (panel, i) =>
      # With an odd-numbered panel, reverse the angle.
      if i % 2 isnt 0 and !options.twist
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
      @_transformPanel panel, deg, anchor, options.fracture

      if @_shading
        if options.twist or options.fracture or (i is 0 and options.sticky)
          @_setShader i, anchor, 0
        else if Math.abs(deg) isnt 180
          @_setShader i, anchor, deg


  # This effect appears to bend rather than fold the paper. Its curves can
  # appear smoother with higher panel counts.
  curl: prep (angle, anchor, options) ->
    # Reduce the angle based on the number of panels in this axis.
    angle /= if anchor in anchorListV then @_config.vPanels.length else @_config.hPanels.length

    @_iterate anchor, (panel, i) =>
      @_transformPanel panel, angle, anchor
      @_setShader i, anchor, 0 if @_shading


  # Lifts up all panels after the first one.
  ramp: prep (angle, anchor, options) ->
    # Rotate the second panel for the lift up.
    @_transformPanel @_panels[anchor][1], angle, anchor

    # For all but the second panel, set the angle to 0.
    @_iterate anchor, (panel, i) =>
      @_transformPanel panel, 0, anchor if i isnt 1
      @_setShader i, anchor, 0 if @_shading


  # Hides the element by folding each panel in a cascade of animations.
  foldUp: prep (anchor, callback) ->
    return callback?() if @isFoldedUp
    @_stageReset anchor, =>
      @_inTrans = @isFoldedUp = true

      @_iterate anchor, (panel, i, len) =>
        duration  = @_config.speed
        duration /= 2 if i is 0
        delay     = @_setPanelTrans anchor, arguments..., duration, 2

        do (panel, i, delay) =>
          defer =>
            @_transformPanel panel, (if i is 0 then 90 else 170), anchor
            setTimeout =>
              if i is 0
                @_inTrans = false
                callback?()
              else
                hideEl panel.children[0]

            , delay + @_config.speed * .25


  # This is the queued version of `_unfold`.
  unfold: prep @::_unfold


  # For custom folding behavior, you can pass a function to `map()` that will
  # determine the folding angle applied to each panel. The passed function
  # is supplied with the input angle, the panel index, and the number of
  # panels in the active anchor. Calling map returns a new function bound to
  # the instance and the lambda, e.g. `oridomi.map(randomFn)(30).reveal(20)`.
  map: (fn) ->
    prep (angle, anchor, options) =>
      @_iterate anchor, (panel, i, len) =>
        @_transformPanel panel, fn(angle, i, len), anchor, options.fracture
    .bind @


  # Convenience Methods
  # ===================


  # Resets all panels back to zero degrees.
  reset: (callback) ->
    @accordion 0, {callback}


  # Simply proxy for calling `accordion` with `sticky` enabled.
  # Keeps first panel flat on page.
  reveal: (angle, anchor, options = {}) ->
    options.sticky = true
    @accordion angle, anchor, options


  # Proxy to enable stairs mode on `accordion`.
  stairs: (angle, anchor, options = {}) ->
    options.stairs = options.sticky = true
    @accordion angle, anchor, options


  # The composition is split apart by its panels rather than folded.
  fracture: (angle, anchor, options = {}) ->
    options.fracture = true
    @accordion angle, anchor, options


  # Similar to `fracture`, but the panels are twisted as well.
  twist: (angle, anchor, options = {}) ->
    options.fracture = options.twist = true
    @accordion angle / 10, anchor, options


  # Convenience proxy to accordion-fold instance to maximum angle.
  collapse: (anchor, options = {}) ->
    options.sticky = false
    @accordion -@_config.maxAngle, anchor, options


  # Same as `collapse`, but uses positive angle for slightly different effect.
  collapseAlt: (anchor, options = {}) ->
    options.sticky = false
    @accordion @_config.maxAngle, anchor, options


  # Statics
  # =======


  # Set a version flag for easy external retrieval.
  @VERSION = '1.1.5'

  # Externally reveal if OriDomi is supported by the browser.
  @isSupported = isSupported


# Expose the OriDomi constructor via CommonJS, AMD, or the window object.
if module?.exports
  module.exports = OriDomi
else if define?.amd
  define -> OriDomi
else
  window.OriDomi = OriDomi



# Plugin Bridge
# =============


# Only create bridge if jQuery (or an imitation supporting `data()`) exists.
return unless $
# Attach an `OriDomi` method to `$`'s prototype.
$::oriDomi = (options) ->
  # Return selection if OriDomi is unsupported by the browser.
  return @ unless isSupported
  return $.data @[0], baseName if options is true

  # If `options` is a string, assume it's a method call.
  if typeof options is 'string'
    methodName = options
    # Check if method exists and warn if it doesn't.
    unless typeof (method = OriDomi::[methodName]) is 'function'
      console?.warn "#{ libName }: No such method `#{ methodName }`"
      return @

    for el in @

      unless instance = $.data el, baseName
        instance = $.data el, baseName, new OriDomi el, options

      # Call the requested method with arguments.
      method.apply instance, Array::slice.call(arguments)[1...]


  # If not calling a method, initialize OriDomi on the selection.
  else
    for el in @
      # If the element in the selection already has an instance of OriDomi
      # attached to it, return the instance.
      if instance = $.data el, baseName
        continue
      else
        # Create an instance of OriDomi and attach it to the element.
        $.data el, baseName, new OriDomi el, options


  # Return the selection.
  @

