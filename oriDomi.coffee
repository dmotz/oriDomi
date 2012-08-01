###
* oriDomi
* fold up the DOM
* http://oridomi.com
*
* Dan Motzenbecker
* http://oxism.com
* Copyright 2012
###


root = window
$ = root.$ or false
silent = false
oriDomiSupport = true
testEl = document.createElement 'div'
prefixList = ['Webkit', 'Moz', 'O', 'ms', 'Khtml']


testProp = (prop) ->
  return prop if testEl.style[prop]?
  capProp = prop.charAt(0).toUpperCase() + prop.slice 1
  for prefix in prefixList
    if testEl.style[prefix + capProp]?
      return prefix + capProp
  false


getGradientProp = ->
  for prefix in prefixList
    hyphenated = "-#{ prefix.toLowerCase() }-linear-gradient"
    testEl.style.backgroundImage = "#{ hyphenated }(left, #000, #fff)"
    if testEl.style.backgroundImage.indexOf('gradient') isnt -1
      return hyphenated
  'linear-gradient'


getTransformProp = ->
  prefix = css.transform.match(/(\w+)Transform/i)[1]
  if prefix
    "-#{ prefix.toLowerCase() }-transform"
  else
    'transform'


getTransitionEndProp = ->
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


# one dimensional:
extendObj = (target, source) ->
  if source isnt Object source
    !silent and console?.warn 'oriDomi: Must pass an object to extend with'
    return target
  if target isnt Object target
    target = {}
  for prop of source
    if not target[prop]?
      target[prop] = source[prop]

  target


css = 
  transform: 'transform'
  origin: 'transformOrigin'
  transformStyle: 'transformStyle'
  transitionProp: 'transitionProperty'
  transitionDuration: 'transitionDuration'
  transitionEasing: 'transitionTimingFunction'
  perspective: 'perspective'
  backface: 'backfaceVisibility'


for key, value of css
  css[key] = testProp value
  if !css[key]
    console?.warn 'oriDomi: Browser does not support oriDomi'
    oriDomiSupport = false
    break

css.gradientProp = getGradientProp()
css.transformProp = getTransformProp()
css.transitionEnd = getTransitionEndProp()



defaults =
  vPanels: 6
  hPanels: 5
  perspective: 1000
  shading: true
  hardShading: false
  speed: .6
  oriDomiClass: 'oriDomi'
  silent: false
  smoothStart: true
  shadingIntensity: 1
  easingMethod: ''
  newClass: null
  showOnStart: false
  forceAntialiasing: false


class root.OriDomi

  constructor: (@el, @settings = {}) ->
    console.time 'oridomiConstruction'
    return @el if !oriDomiSupport

    if !(@ instanceof OriDomi)
      return new oriDomi @el, @settings

    silent = true if @settings.silent
    if !@el? or @el.nodeType isnt 1
      return !silent and console?.warn 'oriDomi: First argument must be a DOM element'

    {@shading, @shadingIntensity, @vPanels, @hPanels} = @settings
    @$el = $ @el if $
    elStyle = root.getComputedStyle @el

    @width = parseInt(elStyle.width, 10) +
             parseInt(elStyle.paddingLeft, 10) +
             parseInt(elStyle.paddingRight, 10)

    @height = parseInt(elStyle.height, 10) +
              parseInt(elStyle.paddingTop, 10) +
              parseInt(elStyle.paddingBottom, 10)

    @panelWidth = @width / @vPanels
    @panelHeight = @height / @hPanels

    @lastAngle = 0
    @anchors = ['left', 'right', 'top', 'bottom']
    @lastAnchor = @anchors[0]
    @panels = {}
    @stages = {}
    stage = document.createElement 'div'
    stage.style.width = @width + 'px'
    stage.style.height = @height + 'px'
    stage.style.display = 'none'
    stage.style.position = 'absolute'
    stage.style.padding = '0'
    stage.style.margin = '0'
    stage.style[css.perspective] = @settings.perspective + 'px'

    for anchor in @anchors
      @panels[anchor] = []
      @stages[anchor] = stage.cloneNode false
      @stages[anchor].className = 'oridomi-stage-' + anchor

    if @shading
      @shaders = {}
      for anchor in @anchors
        @shaders[anchor] = {}
        if anchor is 'left' or anchor is 'right'
          @shaders[anchor].left = []
          @shaders[anchor].right = []
        else
          @shaders[anchor].top = []
          @shaders[anchor].bottom = []

      shader = document.createElement 'div'
      shader.style[css.transitionProp] = 'opacity'
      shader.style[css.transitionDuration] = @settings.speed + 's'
      shader.style[css.transitionEasing] = @settings.easingMethod
      shader.style.position = 'absolute'
      shader.style.width = '100%'
      shader.style.height = '100%'
      shader.style.opacity = '0'
      shader.style.top = '0'
      shader.style.left = '0'

    contentHolder = @el.cloneNode true
    contentHolder.classList.add 'oridomi-content'
    contentHolder.style.margin = '0'
    contentHolder.style.position = 'relative'
    

    hMask = document.createElement 'div'
    hMask.className = 'oridomi-mask-h'
    hMask.style.position = 'absolute'
    hMask.style.overflow = 'hidden'
    hMask.style.width = '100%'
    hMask.style.height = '100%'
    hMask.style[css.transform] = 'translate3d(0, 0, 0)'
    hMask.appendChild contentHolder

    if @shading
      topShader = shader.cloneNode false
      topShader.className = 'oridomi-shader-top'
      topShader.style.background = @_getShaderGradient 'top'
      bottomShader = shader.cloneNode false
      bottomShader.className = 'oridomi-shader-bottom'
      bottomShader.style.background = @_getShaderGradient 'bottom'
      hMask.appendChild topShader
      hMask.appendChild bottomShader

    bleed = 2
    hPanel = document.createElement 'div'
    hPanel.className = 'oridomi-panel-h'
    hPanel.style.width = '100%'
    hPanel.style.height = @panelHeight + bleed + 'px'
    hPanel.style.padding = '0'
    hPanel.style.position = 'relative'
    hPanel.style[css.transitionProp] = css.transformProp
    hPanel.style[css.transitionDuration] = @settings.speed + 's'
    hPanel.style[css.transitionEasing] = @settings.easingMethod
    hPanel.style[css.origin] = 'top'
    hPanel.style[css.transformStyle] = 'preserve-3d'
    hPanel.style[css.backface] = 'hidden'
    if @settings.forceAntialiasing
      hPanel.style.outline = '1px solid transparent'

    hPanel.appendChild hMask

    for anchor in ['top', 'bottom']
      for i in [0...@hPanels]
        panel = hPanel.cloneNode true
        content = panel.getElementsByClassName('oridomi-content')[0]

        if anchor is 'top'
          yOffset = -(i * @panelHeight)
          if i is 0
            panel.style.top = '0'
          else
            panel.style.top = @panelHeight + 'px'
        else
          panel.style[css.origin] = 'bottom'
          yOffset = -((@hPanels * @panelHeight) - (@panelHeight * (i + 1)))
          
          if i is 0
            panel.style.top = @panelHeight * (@vPanels - 2) - 2 + 'px'
          else
            panel.style.top = -@panelHeight + 'px'

        content.style.top = yOffset + 'px'

        if @shading
          @shaders[anchor].top[i] = panel.getElementsByClassName('oridomi-shader-top')[0]
          @shaders[anchor].bottom[i] = panel.getElementsByClassName('oridomi-shader-bottom')[0]

        @panels[anchor][i] = panel

        unless i is 0
          @panels[anchor][i - 1].appendChild panel

      @stages[anchor].appendChild @panels[anchor][0]

    vMask = hMask.cloneNode true
    vMask.className = 'oridomi-mask-v'

    if @shading
      leftShader = vMask.getElementsByClassName('oridomi-shader-top')[0]
      leftShader.className = 'oridomi-shader-left'
      leftShader.style.background = @_getShaderGradient 'left'
      rightShader = vMask.getElementsByClassName('oridomi-shader-bottom')[0]
      rightShader.className = 'oridomi-shader-right'
      rightShader.style.background = @_getShaderGradient 'right'

    vPanel = hPanel.cloneNode false
    vPanel.className = 'oridomi-panel-v'
    vPanel.style.width = @panelWidth + bleed + 'px'
    vPanel.style.height = '100%'
    vPanel.style[css.origin] = 'left'
    vPanel.appendChild vMask

    for anchor in ['left', 'right']
      for i in [0...@vPanels]
        panel = vPanel.cloneNode true
        content = panel.getElementsByClassName('oridomi-content')[0]

        if anchor is 'left'
          xOffset = -(i * @panelWidth)
          if i is 0
            panel.style.left = 0
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


    @el.classList.add @settings.oriDomiClass
    @el.style.padding = '0'
    @el.style.width = @width + 'px'
    @el.style.height = @height + 'px'
    @el.style.backgroundColor = 'transparent'
    @stages.left.style.display = 'block'
    @el.innerHTML = ''

    for anchor in @anchors
      @el.appendChild @stages[anchor]
    
    if @settings.showOnStart
      @el.style.display = 'block'
      @el.style.visibility = 'visible'
    
    @_callback @settings
    console.timeEnd 'oridomiConstruction'


  _callback: (options) ->
    if typeof options.callback is 'function'
      # transitionend events are unreliable at the moment unfortunately
      if @lastAngle is 0
        delay = 0
      else
        delay = @settings.speed * 1000
      setTimeout options.callback, delay


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
      
    if fracture
      [axes[0], axes[1], axes[2]] = [1, 1, 1]

    "rotate3d(#{ axes[0] }, #{ axes[1] }, #{ axes[2] }, #{ axes[3] }deg)"


  _normalizeAngle: (angle) ->
    angle = parseFloat angle, 10
    if isNaN angle
      0
    else if angle > 90
      !silent and console?.warn 'oriDomi: Maximum value is 90'
      90
    else if angle < -90
      !silent and console?.warn 'oriDomi: Minimum value is -90'
      -90
    else
      angle


  _normalizeArgs: (method, args) ->
    angle = @lastAngle = @_normalizeAngle args[0]
    anchor = @_getLonghandAnchor args[1]
    options = extendObj args[2], @_methodDefaults[method]
    if anchor isnt @lastAnchor
      @reset =>
        @_showStage anchor
        setTimeout =>
          @[method].apply @, args
        , 0
      false
    else
      [angle, anchor, options]


  _setShader: (i, anchor, angle) ->
    opacity = Math.abs(angle) / 90 * @shadingIntensity * .3

    if @settings.hardShading
      angle = Math.abs angle

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
    
    if anchor is 'left' or anchor is 'right'
      @shaders[anchor].left[i].style.opacity = a
      @shaders[anchor].right[i].style.opacity = b
    else
      @shaders[anchor].top[i].style.opacity = a
      @shaders[anchor].bottom[i].style.opacity = b


  _getShaderGradient: (anchor) ->
    "#{ css.gradientProp }(#{ anchor }, rgba(0, 0, 0, .5) 0%, rgba(255, 255, 255, .35) 100%)"


  _showStage: (anchor) ->
    @stages[anchor].style.display = 'block'
    @stages[@lastAnchor].style.display = 'none'
    @lastAnchor = anchor


  _getPanelType: (anchor) ->
    if anchor is 'left' or anchor is 'right'
      @vPanels
    else
      @hPanels


  _getLonghandAnchor: (shorthand) ->
    switch shorthand
      when 'left', 'l', 4
        'left'
      when 'right', 'r', 2
        'right'
      when 'top', 't', 1
        'top'
      when 'bottom', 'b', 3
        'bottom'
      else
        'left'


  _methodDefaults:
    accordion:
      sticky: false
      stairs: false
      fracture: false
      twist: false
    curl:
      twist: false
    ramp: {}


  reset: (callback) ->
    for panel, i in @panels[@lastAnchor]
      panel.style[css.transform] = @_transform 0
      if @shading
        @_setShader i, @lastAnchor, 0

    @_callback callback: callback


  accordion: (angle, anchor, options) ->
    normalized = @_normalizeArgs 'accordion', arguments
    return if !normalized
    [angle, anchor, options] = normalized

    for panel, i in @panels[anchor]

      if i % 2 isnt 0 and !options.twist
        deg = -angle
      else
        deg = angle

      if options.sticky
        if i is 0
          deg = 0
        else if i > 1 or options.stairs
          deg *= 2
      else
        deg *= 2 unless i is 0

      panel.style[css.transform] = @_transform deg, options.fracture
      if @shading and !(i is 0 and options.sticky) and Math.abs(deg) isnt 180
        @_setShader i, anchor, deg

    @_callback options


  collapse: (anchor, options = {}) ->
    options.sticky = false
    @accordion -90, anchor, options


  collapseAlt: (anchor, options = {}) ->
    options.sticky = false
    @accordion 90, anchor, options


  reveal: (angle, anchor, options = {}) ->
    options.sticky = true
    @accordion angle, anchor, options


  stairs: (angle, anchor, options = {}) ->
    options.stairs = true
    options.sticky = true
    @accordion angle, anchor, options


  fracture: (angle, anchor, options = {}) ->
    options.fracture = true
    @accordion angle, anchor, options


  twist: (angle, anchor, options = {}) ->
    options.fracture = true
    options.twist = true
    @accordion angle / 10, anchor, options


  curl: (angle, anchor, options = {}) ->
    normalized = @_normalizeArgs 'curl', arguments
    return if !normalized
    [angle, anchor, options] = normalized
    angle /=  @_getPanelType anchor

    for panel, i in @panels[anchor]
      panel.style[css.transform] = @_transform angle
      
      if @shading
        @_setShader i, anchor, 0

    @_callback options


  ramp: (angle, anchor, options) ->
    normalized = @_normalizeArgs 'ramp', arguments
    return if !normalized
    [angle, anchor, options] = normalized
    @panels[anchor][1].style[css.transform] = @_transform angle
    @_callback options


    
    if anchor isnt @lastAnchor
      return @reset =>
        @_showStage anchor
        setTimeout =>
          @ramp angle, options
        , 0

    @lastAngle = angle = @_normalizeAngle angle
    rotation = @_getRotation anchor, angle

    @panels[anchor][1].style[css.transform] = @_transform @_getXy(1, anchor), rotation

    @_callback options


  setAngles: (angles, options = {}) ->
    if !Array.isArray angles
      return !silent and console?.warn 'oriDomi: Argument must be an array of angles'

    for panel, i in @panels
      x = if i is 0 then 0 else @panelWidth - 1
      angle = @_normalizeAngle(angles[i])

      unless i is 0
        angle *= 2

      panel.style[css.transform] = "translate3d(#{x}px, 0, 0) rotate3d(0, 1, 0, #{angle}deg)"

    @_callback options


# $ BRIDGE

if $
  $.fn.oriDomi = (options) ->
    return @ if !oriDomiSupport

    if typeof options is 'string'

      if typeof OriDomi::[options] isnt 'function'
        return !silent and console?.warn "oriDomi: No such method '#{options}'"

      for el in @
        instance = $.data el, 'oriDomi'

        if not instance?
          return !silent and console?.warn "oriDomi: Can't call #{options}, oriDomi hasn't been initialized on this element"

        args = Array::slice.call arguments
        args.shift()
        instance[options].apply instance, args

      @

    else
      settings = extendObj options, defaults

      for el in @
        instance = $.data el, 'oriDomi'
        if instance
          return instance
        else
          $.data el, 'oriDomi', new OriDomi el, settings

      @

