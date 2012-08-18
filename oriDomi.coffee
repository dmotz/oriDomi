# [oriDomi](http://oridomi.com)
# =======
# #### by [Dan Motzenbecker](http://oxism.com)
# Fold up the DOM like paper.

# `0.1.1`

# Copyright 2012, MIT License

# Setup
# =========

# Enable strict mode in this scope to keep us in line.
'use strict'

# Set a reference to the global object within this scope.
root = window

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

# Create a div for testing CSS3 properties.
testEl = document.createElement 'div'

# Set a list of browser prefixes for testing CSS3 properties.
prefixList = ['Webkit', 'Moz', 'O', 'ms', 'Khtml']

# A map of the CSS3 properties needed to support oriDomi, with shorthand names as keys.
css = 
  transform: 'transform'
  origin: 'transformOrigin'
  transformStyle: 'transformStyle'
  transitionProp: 'transitionProperty'
  transitionDuration: 'transitionDuration'
  transitionEasing: 'transitionTimingFunction'
  perspective: 'perspective'
  backface: 'backfaceVisibility'

# This function checks for the presence of CSS properties on the test div.
testProp = (prop) ->
  # If the un-prefixed property is present, return it.
  return prop if testEl.style[prop]?
  # Capitalize the property name for camel-casing.
  capProp = prop.charAt(0).toUpperCase() + prop.slice 1
  # Loop through the vendor prefix list and return when we find a match.
  for prefix in prefixList
    if testEl.style[prefix + capProp]?
      return prefix + capProp
  # If no matches are found, return false to denote that the browser is missing this property.
  false


# Loop through the CSS hash and replace each value with the result of `testProp()`.
for key, value of css
  css[key] = testProp value
  # If the returned value is false, warn the user that the browser doesn't support
  # oriDomi, set `oriDomiSupport` to false, and break out of the loop.
  unless css[key]
    devMode and console.warn 'oriDomi: Browser does not support oriDomi'
    oriDomiSupport = false
    break

# CSS3 gradients are used for shading.
# Testing for them is different because they are prefixed values, not properties.
# This invokes an anonymous function to loop through vendor-prefixed linear-gradients.
css.gradientProp = do ->
  for prefix in prefixList
    hyphenated = "-#{ prefix.toLowerCase() }-linear-gradient"
    testEl.style.backgroundImage = "#{ hyphenated }(left, #000, #fff)"
    # After setting a gradient background on the test div, attempt to retrieve it.
    unless testEl.style.backgroundImage.indexOf('gradient') is -1
      return hyphenated
  # If none of the hyphenated values worked, return the un-prefixed version.
  'linear-gradient'

# Invoke a functional scope to set a hyphenated version of the transform property.
css.transformProp = do ->
  # Use a regex to pluck the prefix `testProp` found.
  prefix = css.transform.match(/(\w+)Transform/i)[1]
  if prefix
    "-#{ prefix.toLowerCase() }-transform"
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
  # Check if the extension object is an object literal by casting it and comparing it.
  if source isnt Object source
    devMode and console.warn 'oriDomi: Must pass an object to extend with'
    # Return the original target if its source isn't valid.
    return target
  # If the target isn't an object, set it to an empty object literal.
  if target isnt Object target
    target = {}
  # Loop through the extension object and copy its values to the target if they don't exist.
  for prop of source
    if not target[prop]?
      target[prop] = source[prop]
  
  # Return the extended target object.
  target


# Defaults
# ========

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
  # This class is applied to elements that oriDomi has been invoked so they can be
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
  # Currently, Firefox doesn't handle edge anti-aliasing well and oriDomi looks jagged.
  # This setting forces Firefox to smooth edges, but results in poor performance,
  # so it's not recommended until Firefox's transform performance improves.
  forceAntialiasing: false


# oriDomi Class
# =============

class OriDomi
  # The constructor takes two arguments: a target element and an options object literal.
  constructor: (@el, options) ->
    # If `devMode` is enabled, start a benchmark timer for the constructor.
    devMode and console.time 'oridomiConstruction'
    # If the browser doesn't support oriDomi, return the element unmodified.
    return @el unless oriDomiSupport
    
    # If the constructor wasn't called with the `new` keyword, invoke it again.
    unless @ instanceof OriDomi
      return new oriDomi @el, @settings

    # Extend any passed options with the defaults map.
    @settings = extendObj options, defaults

    # Return if the first argument isn't a DOM element.
    unless @el? or @el.nodeType isnt 1
      return devMode and console.warn 'oriDomi: First argument must be a DOM element'

    # Destructure some instance variables from the settings object.
    {@shading, @shadingIntensity, @vPanels, @hPanels} = @settings
    # Record the current global styling of the target element.
    elStyle = root.getComputedStyle @el

    # Calculate the element's total width by adding all horizontal dimensions.
    @width = parseInt(elStyle.width, 10) +
             parseInt(elStyle.paddingLeft, 10) +
             parseInt(elStyle.paddingRight, 10) +
             parseInt(elStyle.borderLeftWidth, 10) +
             parseInt(elStyle.borderRightWidth, 10)

    # Find the total height in a similar manner.
    @height = parseInt(elStyle.height, 10) +
              parseInt(elStyle.paddingTop, 10) +
              parseInt(elStyle.paddingBottom, 10) +
              parseInt(elStyle.borderTopWidth, 10) +
              parseInt(elStyle.borderBottomWidth, 10)


    # Calculate the panel width and panel height by dividing the total width and
    # height by the requested number of panels in each axis.
    @panelWidth = @width / @vPanels
    @panelHeight = @height / @hPanels

    # Set our current fold angle at `0` and `isFoldedUp` as `false`.
    @lastAngle = 0
    @isFoldedUp = false
    # Set an array of anchor names.
    @anchors = ['left', 'right', 'top', 'bottom']
    # oriDomi starts oriented with the left anchor.
    @lastAnchor = @anchors[0]
    # Create object literals to store panels and stages.
    @panels = {}
    @stages = {}
    # Create a stage div to serve as a prototype. 
    stage = document.createElement 'div'
    # The stage should occupy the full width and height of the target element.
    stage.style.width = @width + 'px'
    stage.style.height = @height + 'px'
    # By default, each stage is hidden and absolutely positioned so they stack
    # on top of each other.
    stage.style.display = 'none'
    stage.style.position = 'absolute'
    # Eliminate padding and margins since the stage is already the full width and height.
    stage.style.padding = '0'
    stage.style.margin = '0'
    # Apply 3D perspective to the stage prototype.
    stage.style[css.perspective] = @settings.perspective + 'px'

    # Loop through the anchors list and create a stage and empty panel set for each.
    for anchor in @anchors
      @panels[anchor] = []
      @stages[anchor] = stage.cloneNode false
      @stages[anchor].className = 'oridomi-stage-' + anchor

    # If shading is enabled, create an object literal to hold shaders.
    if @shading
      @shaders = {}
      # Loop through each anchor and create a nested object literal.
      # For the left and right anchors, create arrays to hold the left and right
      # shader for each panel. Do the same for top and bottom.
      for anchor in @anchors
        @shaders[anchor] = {}
        if anchor is 'left' or anchor is 'right'
          @shaders[anchor].left = []
          @shaders[anchor].right = []
        else
          @shaders[anchor].top = []
          @shaders[anchor].bottom = []

      # Create a shader div prototype to clone.
      shader = document.createElement 'div'
      shader.style[css.transitionProp] = 'opacity'
      shader.style[css.transitionDuration] = @settings.speed + 'ms'
      shader.style[css.transitionEasing] = @settings.easingMethod
      shader.style.position = 'absolute'
      shader.style.width = '100%'
      shader.style.height = '100%'
      shader.style.opacity = '0'
      shader.style.top = '0'
      shader.style.left = '0'

    # The content holder is a clone of the target element.
    # Every panel will contain one.
    contentHolder = @el.cloneNode true
    contentHolder.classList.add 'oridomi-content'
    contentHolder.style.margin = '0'
    contentHolder.style.position = 'relative'
    contentHolder.style.float = 'none'

    # Create a prototype mask div to clone.
    # Masks serve to display only a small offset portion of the content they hold.
    hMask = document.createElement 'div'
    hMask.className = 'oridomi-mask-h'
    hMask.style.position = 'absolute'
    hMask.style.overflow = 'hidden'
    hMask.style.width = '100%'
    hMask.style.height = '100%'
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

    # The bleed variable creates some overlap between the panels to prevent
    # cracks in the paper.
    bleed = 2
    # The panel element holds both its respective mask and all subsequent sibling panels.
    hPanel = document.createElement 'div'
    hPanel.className = 'oridomi-panel-h'
    hPanel.style.width = '100%'
    hPanel.style.height = @panelHeight + bleed + 'px'
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
    if @settings.forceAntialiasing
      hPanel.style.outline = '1px solid transparent'

    # Add the horizontal mask prototype to the horizontal panel prototype.
    hPanel.appendChild hMask

    # Loop through just the horizontal anchors.
    for anchor in ['top', 'bottom']
      # Loop through the number of horizontal panels.
      for i in [0...@hPanels]
        # Clone a copy of the panel prototype for manipulation.
        panel = hPanel.cloneNode true
        # Set a reference to its inner content.
        content = panel.getElementsByClassName('oridomi-content')[0]

        if anchor is 'top'
          # The `yOffset` shifts the content of the panel down so they appear contiguous.
          yOffset = -(i * @panelHeight)
          # This conditional pushes each panel's position down so they stack on top of each other.
          if i is 0
            panel.style.top = '0'
          else
            panel.style.top = @panelHeight + 'px'
        else
          # For bottom panels, make sure the transform origin is `'bottom'`.
          panel.style[css.origin] = 'bottom'
          # For the bottom `yOffset` and top position, we need to work backwards.
          yOffset = -((@hPanels * @panelHeight) - (@panelHeight * (i + 1)))

          if i is 0
            panel.style.top = @panelHeight * (@vPanels - 1) - bleed + 'px'
          else
            panel.style.top = -@panelHeight + 'px'

        content.style.top = yOffset + 'px'

        # Store references to the shader divs in the `shaders` object.
        if @shading
          @shaders[anchor].top[i] = panel.getElementsByClassName('oridomi-shader-top')[0]
          @shaders[anchor].bottom[i] = panel.getElementsByClassName('oridomi-shader-bottom')[0]

        # Store a reference to this panel in the `panels` object.
        @panels[anchor][i] = panel

        # Append each panel to its previous sibling (unless it's the first panel).
        unless i is 0
          @panels[anchor][i - 1].appendChild panel

      # Append the first panel (containing all of its siblings) to its respective stage.
      @stages[anchor].appendChild @panels[anchor][0]

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
    vPanel.style.width = @panelWidth + bleed + 'px'
    vPanel.style.height = '100%'
    vPanel.style[css.origin] = 'left'
    vPanel.appendChild vMask

    # Repeat a similar panel creation process for vertical panels.
    for anchor in ['left', 'right']
      for i in [0...@vPanels]
        panel = vPanel.cloneNode true
        content = panel.getElementsByClassName('oridomi-content')[0]

        if anchor is 'left'
          xOffset = -(i * @panelWidth)
          if i is 0
            panel.style.left = '0'
          else
            panel.style.left = @panelWidth + 'px'
        else
          panel.style[css.origin] = 'right'
          xOffset = -((@vPanels * @panelWidth) - (@panelWidth * (i + 1)))
          if i is 0
            panel.style.left = @panelWidth * (@vPanels - 1) - 1 + 'px'
          else
            panel.style.left = -@panelWidth + 'px'

        content.style.left = xOffset + 'px'

        if @shading
          @shaders[anchor].left[i]  = panel.getElementsByClassName('oridomi-shader-left')[0]
          @shaders[anchor].right[i] = panel.getElementsByClassName('oridomi-shader-right')[0]

        @panels[anchor][i] = panel

        unless i is 0
          @panels[anchor][i - 1].appendChild panel

      @stages[anchor].appendChild @panels[anchor][0]


    # Add a special class to the target element.
    @el.classList.add @settings.oriDomiClass
    # Remove its padding and set a fixed width and height.
    @el.style.padding = '0'
    @el.style.width = @width + 'px'
    @el.style.height = @height + 'px'
    # Remove its background, border, and outline.
    @el.style.backgroundColor = 'transparent'
    @el.style.backgroundImage = 'none'
    @el.style.border = 'none'
    @el.style.outline = 'none'
    # Show the left stage to start with.
    @stages.left.style.display = 'block'
    # Empty the target element.
    @el.innerHTML = ''

    # Append each stage to the target element.
    for anchor in @anchors
      @el.appendChild @stages[anchor]

    # Show the target if applicable.
    if @settings.showOnStart
      @el.style.display = 'block'
      @el.style.visibility = 'visible'

    # Cache a jQuery object of the element if applicable.
    @$el = $ @el if $
    # If a callback was passed in the constructor options, run it.
    @_callback @settings
    # End the constructor benchmark if `devMode` is active.
    devMode and console.timeEnd 'oridomiConstruction'


  # Internal Methods
  # ================

  # `_callback` normalizes callback handling for all public methods.
  _callback: (options) ->
    if typeof options.callback is 'function'
      # Create a local callback for the animation's end.
      onTransitionEnd = (e) =>
        # Remove the event listener immediately to prevent bubbling.
        e.currentTarget.removeEventListener css.transitionEnd, onTransitionEnd, false
        # Invoke the callback.
        options.callback()

      # If there was no transformation (0 degrees) invoke the callback immediately.
      if @lastAngle is 0
        options.callback()
      # Otherwise, attach an event listener to be called on the transition's end.
      else
        @panels[@lastAnchor][0].addEventListener css.transitionEnd, onTransitionEnd, false


  # `_transform` returns a `rotate3d` transform string based on the anchor and angle.
  _transform: (angle, fracture) ->
    switch @lastAnchor
      when 'left'
        axes = [0, 1, 0, angle]
      when 'right'
        axes = [0, 1, 0, -angle]
      when 'top'
        axes = [1, 0, 0, -angle]
      when 'bottom'
        axes = [1, 0, 0, angle]

    # `fracture` is a special option that splits up the panels by rotating them on all axes.
    if fracture
      [axes[0], axes[1], axes[2]] = [1, 1, 1]

    "rotate3d(#{ axes[0] }, #{ axes[1] }, #{ axes[2] }, #{ axes[3] }deg)"


  # `_normalizeAngle` validates a given angle by making sure it's a float and by
  # keeping it within a range of -89/89 degrees. Fully 90 degree angles tend to look glitchy.
  _normalizeAngle: (angle) ->
    angle = parseFloat angle, 10
    if isNaN angle
      0
    else if angle > 89
      devMode and console.warn 'oriDomi: Maximum value is 89'
      89
    else if angle < -89
      devMode and console.warn 'oriDomi: Minimum value is -89'
      -89
    else
      angle


  # `_normalizeArgs` bootstraps every public method.
  _normalizeArgs: (method, args) ->
    # Get a valid angle.
    angle = @_normalizeAngle args[0]
    # Get the full anchor name.
    anchor = @_getLonghandAnchor args[1]
    # Extend the given options with the method's defaults.
    options = extendObj args[2], @_methodDefaults[method]

    # If the user is trying to transform using a different anchor, we must first
    # unfold the current anchor for transition purposes.
    if anchor isnt @lastAnchor or (method is 'foldUp' and @lastAngle isnt 0) or @isFoldedUp
      # Call `reset` and pass a callback to be run when the unfolding is complete.
      @reset =>
        # Show the stage element of the originally requested anchor.
        @_showStage anchor

        # Defer this operation until the next event loop to prevent a sudden jump.
        setTimeout =>
          # `foldUp` is a special method that doesn't accept an angle argument.
          if method is 'foldUp'
            args.shift()

          # We can now call the originally requested method.
          @[method].apply @, args

        , 0

      # Return `false` here to inform the caller method to abort its operation
      # and wait to be called when the stage is ready.
      false
    else
      # Set an instance reference to the last called angle and return the normalized arguments.
      @lastAngle = angle
      [angle, anchor, options]


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
      if @lastAngle < 0
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
      @shaders[anchor].left[i].style.opacity = a
      @shaders[anchor].right[i].style.opacity = b
    else
      @shaders[anchor].top[i].style.opacity = a
      @shaders[anchor].bottom[i].style.opacity = b


  # This is a simple method used by the constructor to set CSS gradient styles.
  # It accepts an anchor argument to start the gradient slope.
  _getShaderGradient: (anchor) ->
    "#{ css.gradientProp }(#{ anchor }, rgba(0, 0, 0, .5) 0%, rgba(255, 255, 255, .35) 100%)"


  # This method shows the requested stage element and sets a reference to it as
  # the current stage.
  _showStage: (anchor) ->
    @stages[anchor].style.display = 'block'
    @stages[@lastAnchor].style.display = 'none'
    @lastAnchor = anchor


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


  # Map of defaults for each method. Some are empty for now.
  _methodDefaults:
    accordion:
      # Sticky keeps the first panel flat on the page.
      sticky: false
      # Stairs creates a stairway effect.
      stairs: false
      # Twist and fracture are similar effects that result in wild non-origami-like splits.
      fracture: false
      twist: false
    curl:
      twist: false
    ramp: {}
    foldUp: {}


  # Public Methods
  # ==============


  # Reset handles resetting all panels back to zero degrees.
  reset: (callback) ->
    # If the stage is folded up, unfold it first.
    if @isFoldedUp
      return @unfold callback

    for panel, i in @panels[@lastAnchor]
      panel.style[css.transform] = @_transform 0
      if @shading
        @_setShader i, @lastAnchor, 0

    # When called internally, `reset` comes with a callback to advance to the next transformation.
    @_callback callback: callback


  # oriDomi's bread and butter effect. Transforms the target like its namesake.
  accordion: (angle, anchor, options) ->
    normalized = @_normalizeArgs 'accordion', arguments
    # If `_normalizeArgs` returns false, we need to abort for a reset operation.
    return unless normalized
    # Otherwise, destructure the normalized arguments into some local variables.
    [angle, anchor, options] = normalized

    # Loop through the panels in this stage.
    for panel, i in @panels[anchor]

      # If it's an odd-numbered panel, reverse the angle.
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
      if options.stairs
        deg = -deg

      # Set the CSS transformation.
      panel.style[css.transform] = @_transform deg, options.fracture
      # Apply shaders.
      if @shading and !(i is 0 and options.sticky) and Math.abs(deg) isnt 180
        @_setShader i, anchor, deg

    # Ask `_callback` to check for a callback.
    @_callback options


  # `curl` appears to bend rather than fold the paper. Its curves can appear smoother
  # with higher panel counts.
  curl: (angle, anchor, options) ->
    normalized = @_normalizeArgs 'curl', arguments
    return unless normalized
    [angle, anchor, options] = normalized
    # Reduce the angle based on the number of panels in this axis.
    angle /=  @_getPanelType anchor

    for panel, i in @panels[anchor]
      panel.style[css.transform] = @_transform angle

      if @shading
        @_setShader i, anchor, 0

    @_callback options


  # `ramp` lifts up all panels after the first one.
  ramp: (angle, anchor, options) ->
    normalized = @_normalizeArgs 'ramp', arguments
    return unless normalized
    [angle, anchor, options] = normalized
    # Rotate the second panel for the lift up.
    @panels[anchor][1].style[css.transform] = @_transform angle

    # For all but the first two panels, set the angle to 0.
    for panel, i in @panels[anchor]
      if i > 1
        @panels[anchor][i].style[css.transform] = @_transform 0

      if @shading
        @_setShader i, anchor, 0

    @_callback options


  # `foldUp` folds up all panels in separate synchronous animations.
  foldUp: (anchor, callback) ->
    # Default to left anchor.
    if not anchor
      anchor = 'left'
    # Check if callback is the first argument.
    else if typeof anchor is 'function'
      callback = anchor

    # `foldUp` uses irregular arguments, so we manually construct the arugments array.
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
      if @shading
        @_setShader i, anchor, angle

    # Called when each panel finishes folding in.
    onTransitionEnd = (e) =>
      # Remove the listener.
      @panels[anchor][i].removeEventListener css.transitionEnd, onTransitionEnd, false
      # Hide the panel so it doesn't collide when bending around.
      @panels[anchor][i].style.display = 'none'
      # Decrement the iterator and check if we're on the first panel.
      if --i is 0
        # If so, invoke the callback directly if applicable.
        callback() if typeof callback is 'function'
      else
        # Otherwise, defer until the next event loop and fold back the next panel.
        setTimeout nextPanel, 0

    # Start the chain of folds.
    nextPanel()


  # Essentially the inverse of `foldUp`.
  unfold: (callback) ->
    # If the target isn't folded up, there's no reason to call this method and
    # the callback is immediately invoked.
    unless @isFoldedUp
      if typeof callback is 'function'
        callback()

    # Reset `isFoldedUp`.
    @isFoldedUp = false
    # Start the iterator on the second panel.
    i = 1
    # Rotate back to 0.
    angle = 0

    nextPanel = =>
      # Show the panel again.
      @panels[@lastAnchor][i].style.display = 'block'
      # Wait for the next event loop so the transition listener works.
      setTimeout =>
        @panels[@lastAnchor][i].addEventListener css.transitionEnd, onTransitionEnd, false
        @panels[@lastAnchor][i].style[css.transform] = @_transform angle
        if @shading
          @_setShader i, @lastAnchor, angle
      , 0
    
    onTransitionEnd = (e) =>
      @panels[@lastAnchor][i].removeEventListener css.transitionEnd, onTransitionEnd, false
      # Increment the iterator and check if we're past the last panel.
      if ++i is @panels[@lastAnchor].length
        callback() if typeof callback is 'function'
      else
        setTimeout nextPanel, 0

    # Start the sequence.
    nextPanel()


  # Convenience Methods
  # ===================


  # Completely folds in target.
  collapse: (anchor, options = {}) ->
    options.sticky = false
    @accordion -89, anchor, options


  # Same as `collapse`, but uses negative angle for slightly different effect.
  collapseAlt: (anchor, options = {}) ->
    options.sticky = false
    @accordion 89, anchor, options


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


# Set a version flag for easy external retrieval.
OriDomi.VERSION = '0.1.0'

# External function to enable `devMode`.
OriDomi.devMode = ->
  devMode = true

# Attach `OriDomi` constructor to `window`.
root.OriDomi = OriDomi


# Plugin Bridge
# =============


# Only create bridge if jQuery (or the like) exists.
if $
  # Attach an `oriDomi` method to `$`'s prototype.
  $.fn.oriDomi = (options) ->
    # Return selection if oriDomi is unsupported by the browser.
    return @ unless oriDomiSupport

    # If `options` is a string, assume it's a method call.
    if typeof options is 'string'

      # Check if method exists and warn if it doesn't.
      unless typeof OriDomi::[options] is 'function'
        return devMode and console.warn "oriDomi: No such method '#{ options }'"

      # Loop through selection.
      for el in @
        # Retrieve the instance of oriDomi attached to the element.
        instance = $.data el, 'oriDomi'

        # Warn if oriDomi hasn't been initialized on this element.
        unless instance?
          return devMode and console.warn "oriDomi: Can't call #{ options }, oriDomi hasn't been initialized on this element"

        # Convert arguments to a proper array and remove the first element.
        args = Array::slice.call arguments
        args.shift()
        # Call method from instance.
        instance[options].apply instance, args

      # Return selection.
      @

    # If not calling a method, initialize oriDomi on the selection.
    else
      for el in @
        # If the element in the selection already has an instance of oriDomi
        # attached to it, return the instance.
        instance = $.data el, 'oriDomi'
        if instance
          return instance
        else
          # Create an instance of oriDomi and attach it to the element.
          $.data el, 'oriDomi', new OriDomi el, options

      # Return the selection.
      @
