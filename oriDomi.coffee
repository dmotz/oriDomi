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
testEl = document.createElement 'div'
prefixList = ['Webkit', 'Moz', 'O', 'ms', 'Khtml']
oriDomiSupport = true


testProp = (prop) ->
  return prop if testEl.style[prop]?
  capProp = prop.charAt(0).toUpperCase() + prop.slice 1
  for prefix in prefixList
    if testEl.style[prefix + capProp]?
      return prefix + capProp
  false


getGradientProp = ->
  for prefix in prefixList
    dashed = "-#{ prefix.toLowerCase() }-linear-gradient"
    testEl.style.backgroundImage = "#{ dashed }(left, #000, #fff)"
    if testEl.style.backgroundImage.indexOf('gradient') isnt -1
      return dashed

  'linear-gradient'


getTransformProp = ->
  prefix = css.transform.match(/(\w+)Transform/i)[1]
  if prefix
    "-#{ prefix.toLowerCase() }-transform"
  else
    'transform'


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
  transformOrigin: 'transformOrigin'
  transformStyle: 'transformStyle'
  transitionProp: 'transitionProperty'
  transitionDuration: 'transitionDuration'
  transitionEasing: 'transitionTimingFunction'
  perspective: 'perspective'


for key, value of css
  css[key] = testProp value
  if !css[key]
    console?.warn 'oriDomi: Browser does not support oriDomi'
    break

css.gradientProp = getGradientProp()
css.transformProp = getTransformProp()



defaults =
  vPanels: 6
  hPanels: 2
  perspective: 1000
  shading: true
  speed: .6
  oriDomiClass: 'oriDomi'
  silent: false
  smoothStart: true
  shadingIntensity: 1
  easingMethod: ''
  newClass: null


class root.OriDomi

  constructor: (@el, @settings = {}) ->
    console.time 'oridomiConstruction'
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

    @panelWidth = Math.floor(@width / @vPanels) or 1
    @panelHeight = Math.floor(@height / @hPanels) or 1

    @axes = ['left', 'right', 'top', 'bottom']
    @lastAnchor = @axes[0]
    @lastAngle = 0
    @panels = {}
    @stages = {}
    stage = document.createElement 'div'
    stage.style.display = 'none'
    stage.style.width = @width + 'px'
    stage.style.height = @height + 'px'
    stage.style.position = 'absolute'
    stage.style.padding = '0'
    stage.style.margin = '0'


    for axis in @axes
      @panels[axis] = []
      @stages[axis] = stage.cloneNode false
      @stages[axis].className = 'oridomi-stage-' + axis

    if @shading
      @shaders = {}
      for axis in @axes
        @shaders[axis] = {}
        if axis is 'left' or axis is 'right'
          @shaders[axis].left = []
          @shaders[axis].right = []
        else
          @shaders[axis].top = []
          @shaders[axis].bottom = []

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
    contentHolder.margin = '0'

    hMask = document.createElement 'div'
    hMask.className = 'oridomi-mask-h'
    hMask.style.position = 'absolute'
    hMask.style.overflow = 'hidden'
    hMask.style.height = @panelHeight + 'px'
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

    hPanel = document.createElement 'div'
    hPanel.className = 'oridomi-panel-h'
    hPanel.style.width = '100%'
    hPanel.style.height = @panelHeight + 'px'
    hPanel.style.padding = '0'
    hPanel.style[css.transitionProp] = css.transformProp
    hPanel.style[css.transitionDuration] = @settings.speed + 's'
    hPanel.style[css.transitionEasing] = @settings.easingMethod
    hPanel.style[css.transformOrigin] = 'top'
    hPanel.style[css.transformStyle] = 'preserve-3d'
    hPanel.appendChild hMask

    for anchor in ['top', 'bottom']
      for i in [1..@hPanels]
        panel = hPanel.cloneNode true
        content = panel.getElementsByClassName('oridomi-content')[0]
        panel.style[css.transform] = @_transform @_getXy i - 1, anchor

        if anchor is 'top'
          yOffset = -((i - 1) * @panelHeight)
        else
          panel.style[css.transformOrigin] = 'bottom'
          yOffset = -((@hPanels * @panelHeight) - (@panelHeight * i))

        content.style[css.transform] = @_transform [0, yOffset]

        if @shading
          @shaders[anchor].top[i - 1] = panel.getElementsByClassName('oridomi-shader-top')[0]
          @shaders[anchor].bottom[i - 1] = panel.getElementsByClassName('oridomi-shader-bottom')[0]

        @panels[anchor][i - 1] = panel

        unless i is 1
          @panels[anchor][i - 2].appendChild panel

      @stages[anchor].appendChild @panels[anchor][0]

    vMask = hMask.cloneNode true
    vMask.className = 'oridomi-mask-v'
    vMask.style.width = @panelWidth + 'px'
    vMask.style.height = '100%'

    if @shading
      leftShader = vMask.getElementsByClassName('oridomi-shader-top')[0]
      leftShader.className = 'oridomi-shader-left'
      leftShader.style.background = @_getShaderGradient 'left'
      rightShader = vMask.getElementsByClassName('oridomi-shader-bottom')[0]
      rightShader.className = 'oridomi-shader-right'
      rightShader.style.background = @_getShaderGradient 'right'

    vPanel = hPanel.cloneNode false
    vPanel.className = 'oridomi-panel-v'
    vPanel.style.width = @panelWidth + 'px'
    vPanel.style.height = '100%'
    vPanel.style[css.transform] = @_transform [@panelWidth, 0]
    vPanel.style[css.transformOrigin] = 'left'
    vPanel.appendChild vMask

    for anchor in ['left', 'right']
      for i in [1..@vPanels]
        panel = vPanel.cloneNode true
        content = panel.getElementsByClassName('oridomi-content')[0]
        panel.style[css.transform] = @_transform @_getXy i - 1, anchor

        if anchor is 'left'
          xOffset = -((i - 1) * @panelWidth)
        else
          panel.style[css.transformOrigin] = 'right'
          xOffset = -((@vPanels * @panelWidth) - (@panelWidth * i))

        content.style[css.transform] = @_transform [xOffset, 0]

        if @shading
          @shaders[anchor].left[i - 1]  = panel.getElementsByClassName('oridomi-shader-left')[0]
          @shaders[anchor].right[i - 1] = panel.getElementsByClassName('oridomi-shader-right')[0]

        @panels[anchor][i - 1] = panel

        unless i is 1
          @panels[anchor][i - 2].appendChild panel

      @stages[anchor].appendChild @panels[anchor][0]


    @el.classList.add @settings.oriDomiClass
    @el.style.padding = '0'
    @el.style.width = @width + 'px'
    @el.style.height = @height + 'px'
    @el.style.backgroundColor = 'transparent'
    @el.style[css.perspective] = @settings.perspective
    @stages.left.style.display = 'block'
    @el.innerHTML = ''

    for axis in @axes
      @el.appendChild @stages[axis]

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


  _transform: (translation, rotation) ->
    [x, y] = translation
    if !rotation
      "translate3d(#{ x }px, #{ y }px, 0)"
    else
      [rX, rY, rZ, deg] = rotation
      "translate3d(#{ x }px, #{ y }px, 0) rotate3d(#{ rX }, #{ rY }, #{ rZ }, #{ deg }deg)"


  _normalizeAngle: (percent) ->
    percent = parseFloat percent, 10
    if isNaN percent
      0
    else if percent > 90
      !silent and console?.warn 'oriDomi: Maximum value is 90'
      90
    else if percent < -90
      !silent and console?.warn 'oriDomi: Minimum value is -90'
      -90
    else
      percent


  _getXy: (i, anchor) ->
    switch anchor
      when 'left'
        y = 0
        if i is 0
          x = 0
        else
          x = @panelWidth - 1
      when 'right'
        y = 0
        if i is 0
          x = @_getRightAnchorCoord()
        else
          x = -@panelWidth + 1
      when 'top'
        x = 0
        if i is 0
          y = 0
        else
          y = @panelHeight - 1
      when 'bottom'
        x = 0
        if i is 0
          y = @_getBottomAnchorCoord()
        else
          y = -@panelHeight + 1

    [x, y]


  _setShader: (i, anchor, deg) ->
    opacity = Math.abs(deg) / 90 * @shadingIntensity * .4
    if anchor is 'left' or anchor is 'right'
      if deg < 0
        @shaders[anchor].right[i].style.opacity = 0
        @shaders[anchor].left[i].style.opacity = opacity
      else
        @shaders[anchor].left[i].style.opacity = 0
        @shaders[anchor].right[i].style.opacity = opacity
    else
      if deg < 0
        @shaders[anchor].bottom[i].style.opacity = 0
        @shaders[anchor].top[i].style.opacity = opacity
      else
        @shaders[anchor].top[i].style.opacity = 0
        @shaders[anchor].bottom[i].style.opacity = opacity


  _getShaderGradient: (anchor) ->
    "#{ css.gradientProp }(#{ anchor }, rgba(0, 0, 0, .5) 0%, rgba(255, 255, 255, .35) 100%)"


  _showStage: (anchor) ->
    @stages[anchor].style.display = 'block'
    @stages[@lastAnchor].style.display = 'none'
    @lastAnchor = anchor


  _getOppositeAnchor: (anchor) ->
    switch anchor
      when 'left'
        'right'
      when 'right'
        'left'
      when 'top'
        'bottom'
      when 'bottom'
        'top'


  _getPanelType: (anchor) ->
    if anchor is 'left' or anchor is 'right'
      @vPanels
    else
      @hPanels


  _getRightAnchorCoord: ->
    @panelWidth * (@vPanels - 1) - @vPanels + 1


  _getBottomAnchorCoord: ->
    @panelHeight * (@hPanels - 1) - @hPanels + 1


  _accordionDefaults:
    anchor: 'left'
    sticky: false
    stairs: false
    fracture: false
    twist: false


  reset: (callback) ->
    for panel, i in @panels[@lastAnchor]
      panel.style[css.transform] = @_transform @_getXy i, @lastAnchor
      if @shading
        @_setShader i, @lastAnchor, 0

    @_callback callback: callback


  accordion: (angle, options) ->
    options = extendObj options, @_accordionDefaults
    {anchor} = options
    
    if anchor isnt @lastAnchor
      return @reset =>
        @_showStage anchor
        setTimeout =>
          @accordion angle, options
        , 0

    @lastAngle = angle = @_normalizeAngle angle

    for panel, i in @panels[anchor]

      if i % 2 isnt 0 and !options.twist
        deg = -angle
      else
        deg = angle

      if anchor is 'right' or anchor is 'bottom'
        deg = -deg

      if options.sticky
        if i is 0
          deg = 0
        else if i > 1 or options.stairs
          deg *= 2
      else
        deg *= 2 unless i is 0

      if options.fracture
        rotation = [1, 1, 1, deg]
      else
        if anchor is 'left' or anchor is 'right'
          rotation = [0, 1, 0, deg]
        else
          rotation = [1, 0, 0, -deg]

      panel.style[css.transform] = @_transform @_getXy(i, anchor), rotation

      if @shading and !(i is 0 and options.anchor) and Math.abs(deg) isnt 180
        @_setShader i, anchor, deg

    @_callback options


  collapse: (options = {}) ->
    options.sticky = false
    @accordion -90


  collapseAlt: (options = {}) ->
    options.sticky = false
    @accordion 90


  reveal: (angle, options = {}) ->
    options.sticky = true
    @accordion angle, options


  stairs: (angle, options = {}) ->
    options.stairs = true
    options.sticky = true
    @accordion angle, options


  fracture: (angle, options = {}) ->
    options.fracture = true
    @accordion angle, options


  twist: (angle, options = {}) ->
    options.fracture = true
    options.twist = true
    @accordion angle / 10, options


  _curlDefaults:
    anchor: 'left'
    twist: false


  curl: (angle, options = {}) ->
    options = extendObj options, @_curlDefaults
    {anchor} = options
    angle = @_normalizeAngle(angle) /  @_getPanelType anchor

    if anchor isnt @lastAnchor
      return @reset =>
        @_showStage anchor
        setTimeout =>
          @curl angle, options
        , 0

    @lastAngle = angle = @_normalizeAngle angle

    if anchor is 'left' or anchor is 'right'
      rotation = [0, 1, 0, angle]
    else
      rotation = [1, 0, 0, -angle]

    for panel, i in @panels[anchor]
      panel.style[css.transform] = @_transform @_getXy(i, anchor), rotation

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

