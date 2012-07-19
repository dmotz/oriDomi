###
* oriDomi
* fold up the DOM
*
* Dan Motzenbecker
* (c) 2012
###


root = window
$ = root.$ or false
silent = false
testEl = document.createElement 'div'
prefixList = ['webkit', 'Moz', 'O', 'ms', 'Khtml']
transitionEnd = 'webkitTransitionEnd transitionend oTransitionEnd MSTransitionEnd KhtmlTransitionEnd'
oriDomiSupport = true


testProp = (prop) ->
  return prop if testEl.style[prop]?
  capProp = prop.charAt(0).toUpperCase() + prop.slice 1
  for prefix in prefixList
    if testEl.style[prefix + capProp]?
      return prefix + capProp
  false


extendObj = (target, source) ->
  if not target?
    return source
  for prop of source
    if not target[prop]?
      target[prop] = source[prop]

  target


transformProp = testProp 'transform'
transformOriginProp = testProp 'transformOrigin'
transformStyleProp = testProp 'transformStyle'
transitionProp = testProp 'transition'
perspectiveProp = testProp 'perspective'
backfaceProp = testProp 'backfaceVisibility'
gradientProp = testProp 'linearGradient'

if !transformProp or !transitionProp or !perspectiveProp or 
  !backfaceProp or !transformOriginProp or !transformStyleProp
    oriDomiSupport = false
    console?.warn 'oriDomi: Browser does not support CSS 3D tranforms, disabling'


defaults =
  panels: 5
  vPanels: 5
  hPanels: 5
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
    if !(@ instanceof OriDomi)
      return new oriDomi @el, @settings
    
    silent = true if @settings.silent
    
    if !@el? or @el.nodeType isnt 1
      return !silent and console?.warn 'oriDomi: First argument must be a DOM element'

    @$el = $ @el if $
    elStyle = root.getComputedStyle @el
    @width = parseInt(elStyle.width, 10) +
             parseInt(elStyle.paddingLeft, 10) +
             parseInt(elStyle.paddingRight, 10)

    @height = parseInt(elStyle.height, 10) +
              parseInt(elStyle.paddingTop, 10) +
              parseInt(elStyle.paddingBottom, 10)

    @panelWidth = Math.floor(@width / @settings.panels) or 1
    @panels = []
    @leftShaders = []
    @rightShaders = []

    mask = document.createElement 'div'
    mask.className = 'oriDomi-mask'
    mask.style.position = 'absolute'
    mask.style.overflow = 'hidden'
    mask.style.width = @panelWidth + 'px'
    
    if @settings.shading
      vShader = document.createElement 'div'
      vShader.className = 'oriDomi-shader'
      vShader.style[transitionProp] = "opacity #{@settings.speed}s"
      vShader.style.position = 'absolute'
      vShader.style.width = '100%'
      vShader.style.height = '100%'
      vShader.style.opacity = 0
      vShader.style.top = 0
      mask.appendChild vShader
      mask.appendChild vShader.cloneNode()

    holder = document.createElement 'div'
    holder.className = @el.className += ' oriDomi-holder'
    holder.style.margin = 0

    panelProto = @el.cloneNode true
    panelProto.removeAttribute 'id'
    panelProto.style.width = @panelWidth + 'px'
    panelProto.style.height = '100%'
    panelProto.style.padding = '0'
    panelProto.style[transformProp] = "translate3d(#{@panelWidth}px, 0, 0) rotate3d(0, 1, 0, 0deg)"
    panelProto.style[transitionProp] = "all #{@settings.speed}s #{@settings.easingMethod}"
    panelProto.style[transformOriginProp] = 'left'
    panelProto.style[transformStyleProp] = 'preserve-3d'
    panelProto.style[backfaceProp] = 'hidden'

    contents = panelProto.innerHTML
    holder.innerHTML = contents
    mask.innerHTML += holder.outerHTML
    panelProto.innerHTML = mask.outerHTML

    for i in [1..@settings.panels]
      panel = panelProto.cloneNode true
      panel.classList.add 'oriDomi-panel' + i
      panelHolder = panel.getElementsByClassName('oriDomi-holder')[0]
      panelHolder.style.marginLeft = parseInt((i - 1) * @panelWidth * -1, 10) + 'px'
      
      if @settings.shading
        shaders = panel.getElementsByClassName 'oriDomi-shader'
        leftShader = shaders[0]
        rightShader = shaders[1]
        leftShader.style.background =
          '-webkit-linear-gradient(left, rgba(0, 0, 0, .5) 0%, rgba(255, 255, 255, .35) 100%)'
        rightShader.style.background =
          '-webkit-linear-gradient(right, rgba(0, 0, 0, .5) 0%, rgba(255, 255, 255, .35) 100%)'
        
        @leftShaders.push leftShader
        @rightShaders.push rightShader

      @panels.push panel
      
      unless i is 1
        @panels[i - 2].appendChild panel
      else
        panel.style[transformProp] = 'translate3d(0, 0, 0)'
      
    #if @settings.smoothStart
      #@accordion 0
      #@settings.speed = originalSpeed

    if @settings.newClass?
      @el.className = newClass

    @el.classList.add @settings.oriDomiClass
    @el.style.padding = '0'
    @el.style.width = @width + 'px'
    @el.style.height = @height + 'px'
    @el.style.backgroundColor = 'transparent'
    @el.style[transitionProp] = "all #{@settings.speed}s #{@settings.easingMethod}"
    @el.style[perspectiveProp] = @settings.perspective
    @el.innerHTML = ''
    @el.appendChild @panels[0]

    @_callback @settings


  _callback: (options) ->
    if typeof options.callback is 'function'
      @panels[0].addEventListener transitionEnd, =>
        @panels[0].removeEventListener transitionEnd, true
        options.callback()
      , true


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


  _accordionDefaults:
    anchor: true
    stairs: false
    fracture: false
    twist: false


  accordion: (angle, options) ->
    options = extendObj options, @_accordionDefaults
    angle = @_normalizeAngle angle
    left = @panelWidth - 1

    for panel, i in @panels
      if i % 2 isnt 0 and !options.twist
        deg = -angle
      else
        deg = angle

      x = left
      ++x if angle is 90

      if options.anchor
        if i is 0
          x = 0
          deg = 0
        else if i > 1 or options.stairs
          deg *= 2
      else
        if i is 0
          x = 0
        else
          deg *= 2


      if options.fracture
        rotation = "rotate3d(1, 1, 1, #{deg}deg)"
      else
        rotation = "rotate3d(0, 1, 0, #{deg}deg)"


      panel.style[transformProp] = "translate3d(#{x}px, 0, 0) #{rotation}"

      if @settings.shading and !(i is 0 and options.anchor)
        opacity = Math.abs(angle) / 90 * @settings.shadingIntensity * .4
        
        if deg < 0
          @rightShaders[i].style.opacity = 0
          @leftShaders[i].style.opacity = opacity
        else
          @leftShaders[i].style.opacity = 0
          @rightShaders[i].style.opacity = opacity

    @_callback options


  reset: ->
    @accordion 0


  collapse: ->
    @accordion -90, anchor: false


  collapseAlt: ->
    @accordion 90, anchor: false


  reveal: (angle, options = {}) ->
    options.anchor = true
    @accordion angle, options


  stairs: (angle, options = {}) ->
    options.stairs = true
    options.anchor = true
    @accordion angle, options


  fracture: (angle, options = {}) ->
    options.fracture = true
    @accordion angle, options


  twist: (angle, options = {}) ->
    options.fracture = true
    options.twist = true
    @accordion angle / 10, options


  curl: (angle, options = {}) ->
    angle = @_normalizeAngle(angle) / @panelWidth * 10

    for panel, i in @panels
      x = if i is 0 then 0 else @panelWidth - 1
      panel.style[transformProp] = "translate3d(#{x}px, 0, 0) rotate3d(0, 1, 0, #{angle}deg)"

    @_callback options


  setAngles: (angles, options = {}) ->
    if !Array.isArray angles
      return !silent and console?.warn 'oriDomi: Argument must be an array of angles'
    
    for panel, i in @panels
      x = if i is 0 then 0 else @panelWidth - 1
      angle = @_normalizeAngle(angles[i])
      
      unless i is 0
        angle *= 2
      
      panel.style[transformProp] = "translate3d(#{x}px, 0, 0) rotate3d(0, 1, 0, #{angle}deg)"
      
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

