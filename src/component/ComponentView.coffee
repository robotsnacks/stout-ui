###*
# @overview Defines the ComponentView class, the "View" of the Stout UI MVVM
# architecture.
#
# @module stout-ui/component/ComponentView
###

nextTick           = require 'stout-client/util/nextTick'
Promise            = require 'stout-core/promise/Promise'
TransitionCanceled = require('stout-client/exc').TransitionCanceled
vars               = require '../vars'
View               = require 'stout-client/view/View'
ViewNotRenderedErr = require('stout-client/err').ViewNotRenderedErr

# Load component variables.
require '../vars/component'


###*
# The class name of hidden UI components.
#
# @type string
# @const
###
HIDDEN_CLS = vars.read 'component/hidden'


###*
# The class name prefix.
#
# @type string
# @const
###
PREFIX = vars.read 'component/prefix'


###*
# The class to add to components currently transitioning.
#
# @type string
# @const
###
TRANS_CLS = vars.read 'component/transitioning'


###*
# The class name to add to components currently transitioning-in.
#
# @type string
# @const
###
TRANS_IN_CLS = vars.read 'component/transitioning-in'


###*
# The class name to add to components currently transitioning-out.
#
# @type string
# @const
###
TRANS_OUT_CLS = vars.read 'component/transitioning-out'


###*
# The class name of visible UI components.
#
# @type string
# @const
###
VISIBLE_CLS = vars.read 'component/visible'


###*
# Inner transition function factory.
#
# @param {function} func - The function to call after the transition has
# finished.
#
# @param {string} transitionClass - The class to apply to the component's root
# element while the transition is occurring.
#
# @param {string} removeClass - The class to remove while the transition is
# underway.
#
# @param {string} state - The associated visibility state to set on the
# component's view model.
#
# @param {function} test - Test function which should return `true` or `false`
# to indicate if the transition should be allowed occur.
#
# @returns {function} Transition function which takes an object as a sole
# parameter. The object should have `time` and `callback` keys. The `time` key
# indicates how long the transition should take (usually defined in SASS) and
# the `callback` property is an optional callback function executed after the
# transition has completed.
#
# @function stout-ui/component/ComponentView~makeTransitionFunc
# @inner
###
makeTransitionFunc = (func, transitionClass, removeClass, state, evt, test) ->
  (time) ->
    promise = new Promise()
    nextTick =>
      # Start the transition if the view is rendered and the test function
      # return true.
      if @rendered and test.call(@)
        @prefixedClasses.remove VISIBLE_CLS, HIDDEN_CLS, removeClass

        if func is 'show' then @repaint()

        @prefixedClasses.add TRANS_CLS, transitionClass

        # Cancel the existing transition timer.
        clearTimeout @_transitionTimer

        # Reject any existing transition promise.
        if @_transitionPromise
          msg = 'Transition canceled by another transition event.'
          reason = new TransitionCanceled(msg)
          Promise.reject @_transitionPromise, reason
        @_transitionPromise = promise

        # Set the new transition timer.
        @_transitionTimer = setTimeout =>
          Promise.resolve promise, @[func].call(@)
        , (time or 0)

        if func is 'hide' then @repaint()

        @context.visibility = state

        @fire evt

      # If the view is not rendered, then reject the transition promise.
      else
        msg = "Transition canceled because test function returned false or the
        view is not yet rendered."
        reason = new TransitionCanceled(msg)
        Promise.reject promise, reason
    promise


###*
# Generates and returns a visibility function, i.e. `show()` and `hide()`.
#
# @param {string} addClass - The class to add to the root element.
#
# @param {string} removeClass - The class to remove from the root element.
#
# @param {string} visibility - The final visibility state to set on the context.
#
# @param {string} evt - The event to fire.
#
# @param {function} test - The function to call to determine if the visibility
# change should occur.
#
# @function makeVisibilityFunc
# @inner
###
makeVisibilityFunc = (addClass, removeClass, visibility, evt, test) ->
  ->
    promise = new Promise()
    nextTick =>
      if @rendered
        if test.call @
          if @transitioningIn
            @_stopTransition("Transition canceled by #{evt} event.")
          @prefixedClasses.remove removeClass
          @prefixedClasses.add addClass
          @context.visibility = visibility
          @fire evt
        Promise.fulfill(promise)
      else
        reason = new ViewNotRenderedErr "Can't #{evt} unrendered view."
        Promise.reject(promise, reason)
    promise



###*
# The ComponentView class defines the view portion of a Stout UI component in an
# MVVM architecture. It creates a solid basis on-top of which a UI component
# can be constructed. This class provides a number of useful features including
# declarative event binding, transitions, hide/show methods, and more.
#
# @param {Object} [init] - Init values for this view.
#
# @param {Array.<string>} [events=[]] - List of events to immediately register.
#
# @exports stout-ui/component/ComponentView
# @extends stout-client/view/View
# @constructor
###
module.exports = class ComponentView extends View

  constructor: (init, events = []) ->
    super init, events.concat ['show', 'hide', 'transition']

    @prefix = PREFIX

    contextEvents =
      'show': @show
      'hide': @hide
      'transition:in': @transitionIn
      'transition:out': @transitionOut

    for event, handler of contextEvents
      self = @
      fn = ((h) ->
        (e) ->
          handlerPromise = h.call self, e.data.time
          if e.data.promise then Promise.resolve e.data.promise, handlerPromise
      )(handler)
      @context.on event, fn, @

    @_transitionTimer = null

    @prefixedClasses.add 'component'


  ###*
  # Reference to the latest transition promise.
  #
  # @member {timer} _transitionPromise
  # @memberof stout-ui/component/ComponentView#
  ###


  ###*
  # Internal reference to the transition timer.
  #
  # @member {timer} _transitionTimer
  # @memberof stout-ui/component/ComponentView#
  ###


  ###*
  # The `context` property defines the `Component` view model to-which this
  # `ComponentView` is bound.
  #
  # @member {stout-ui/component/Component} context
  # @memberof stout-ui/component/ComponentView#
  # @override
  ###


  ###*
  # Member indicating if this component is currently hidden.
  #
  # @member {boolean} hidden
  # @memberof stout-ui/component/ComponentView#
  ###
  @property 'hidden',
    set: (hidden) -> @visible = not hidden
    get: -> not @visible


  ###*
  # Options object which defines various options for this Component view.
  #
  # @member {boolean} options
  # @memberof stout-ui/component/ComponentView#
  ###
  @property 'options',
    default: {showOnRender: true}


  ###*
  # Member indicating if this component is currently transitioning.
  #
  # @property {boolean} transitioning
  # @public
  ###
  @property 'transitioning',
    get: -> @prefixedClasses.contains TRANS_CLS


  ###*
  # Member indicating if this component is currently transitioning-in.
  #
  # @member {boolean} transitioningIn
  # @memberof stout-ui/component/ComponentView#
  ###
  @property 'transitioningIn',
    get: -> @prefixedClasses.contains TRANS_IN_CLS


  ###*
  # Member indicating if this component is currently transitioning-out.
  #
  # @member {boolean} transitioningOut
  # @memberof stout-ui/component/ComponentView#
  ###
  @property 'transitioningOut',
    get: -> @prefixedClasses.contains TRANS_OUT_CLS


  ###*
  # Member indicating if this component is currently visible.
  #
  # @member {boolean} visible
  # @memberof stout-ui/component/ComponentView#
  ###
  @property 'visible',
    set: (visible) -> if visible then @show() else @hide()
    get: -> @prefixedClasses.contains VISIBLE_CLS


  ###*
  # Removes all transition-related classes.
  #
  # @method _removeTransitionClasses
  # @memberof stout-ui/component/ComponentView#
  # @private
  ###
  _removeTransitionClasses: ->
    @prefixedClasses.remove TRANS_CLS, TRANS_IN_CLS, TRANS_OUT_CLS
    return


  ###*
  # Immediately stops an in-progress transition by removing all
  # transition-related classes, rejecting any pending transition promise and
  # clearing pending transition timers.
  #
  # @param {string} reason - Reason string to cancel the transition.
  #
  # @method _stopTransition
  # @memberof stout-ui/component/ComponentView#
  # @private
  ###
  _stopTransition: (reason) ->
    clearTimeout @_transitionTimer
    @_removeTransitionClasses()
    if @_transitionPromise
      Promise.reject @_transitionPromise, new TransitionCanceled(reason)
    return


  ###*
  # Stops any in-progress transition and hides this component. If this
  # component is not rendered, calling this method has no effect.
  #
  # @returns {module:stout-core/promise/Promise} Show promise.
  #
  # @method hide
  # @memberof stout-ui/component/ComponentView#
  ###
  hide: makeVisibilityFunc(
    HIDDEN_CLS,
    VISIBLE_CLS,
    'hidden',
    'hide',
    -> @visible or @transitioning
  )


  ###*
  # Renders this `ComponentView`. If `options.showOnRender` is set, the view
  # is also "shown."
  #
  # @returns {module:stout-core/promise/Promise} Render promise.
  #
  # @method show
  # @memberof stout-ui/component/ComponentView#
  ###
  render: ->
    super().then =>
      if @options.showOnRender
        @show()
      else
        @hide()


  ###*
  # Stops any in-progress transition and makes this component visible. If this
  # component is not rendered calling this method has no effect.
  #
  # @returns {module:stout-core/promise/Promise} Show promise.
  #
  # @method show
  # @memberof stout-ui/component/ComponentView#
  ###
  show: makeVisibilityFunc(
    VISIBLE_CLS,
    HIDDEN_CLS,
    'visible',
    'show',
    -> @hidden or @transitioning
  )


  ###*
  # Transitions-in this component.
  #
  # @param {module:stout-core/event/Event} e - Transition event fired from
  # associated view model. The event data should have `time` and `callback`
  # keys. The `time` value (in milliseconds) indicates how long the transition
  # should take (usually defined in SASS). The `callback` parameter is an
  # optional function should is called after the transition is complete.
  #
  # @returns {this}
  #
  # @method transitionIn
  # @memberof stout-ui/component/ComponentView#
  ###
  transitionIn: makeTransitionFunc(
    'show',
    TRANS_IN_CLS,
    TRANS_OUT_CLS,
    'transitioning:in',
    'transition:in', -> @hidden or @transitioningOut
  )


  ###*
  # Transitions-out this component.
  #
  # @param {module:stout-core/event/Event} e - Transition event fired from
  # associated view model. The event data should have `time` and `callback`
  # keys. The `time` value (in milliseconds) indicates how long the transition
  # should take (usually defined in SASS). The `callback` parameter is an
  # optional function should is called after the transition is complete.
  #
  # @returns {this}
  #
  # @method transitionOut
  # @memberof stout-ui/component/ComponentView#
  ###
  transitionOut: makeTransitionFunc(
    'hide',
    TRANS_OUT_CLS,
    TRANS_IN_CLS,
    'transitioning:out',
    'transition:out', -> @visible or @transitioningIn
  )
