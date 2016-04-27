###*
# @overview Defines the Drawer view-model class.
#
# @module stout-ui/drawer/Drawer
###
Pane = require '../pane/Pane'
Promise = require 'stout-core/promise/Promise'



###*
# The Drawer class is the view-model of a drawer component.
#
# @exports stout-ui/drawer/Drawer
# @extends stout-ui/pane/Pane
# @constructor
###
module.exports = class Drawer extends Pane

  constructor: (init, events = []) ->
    super init, events.concat ['open', 'close']


  ###*
  # The minimum width of the viewport for the drawer to "lock" open.
  #
  # @member minWidth
  # @memberof stout-ui/drawer/Drawer#
  ###
  @property 'minWidth',
    default: 768
    type: 'number'


  ###*
  # The minimum height of the viewport for the drawer to "lock" open.
  #
  # @member minHeight
  # @memberof stout-ui/drawer/Drawer#
  ###
  @property 'minHeight',
    default: 0
    type: 'number'


  ###*
  # The drawer's opening-behavior when not "locked" open. The "overlay" behavior
  # makes the drawer overlay the parent content, while the "push" behavior
  # "pushes" over the parent's content.
  #
  # @member openBehavior
  # @memberof stout-ui/drawer/Drawer#
  ###
  @property 'openBehavior',
    default: 'overlay'
    values: [
      'push'
      'overlay'
    ]


  ###*
  # The side of the viewport where the drawer should open.
  #
  # @member side
  # @memberof stout-ui/drawer/Drawer#
  ###
  @property 'side',
    default: 'left'
    values: [
      'top'
      'right'
      'bottom'
      'left'
    ]


  ###*
  # Opens the drawer.
  #
  # @method open
  # @memberof stout-ui/drawer/Drawer#
  ###
  open: (e) =>
    promise = new Promise
    @fire 'open', {promise}
    promise


  ###*
  # Closes the drawer.
  #
  # @method close
  # @memberof stout-ui/drawer/Drawer#
  ###
  close: (e) =>
    promise = new Promise
    @fire 'close', {promise}
    promise