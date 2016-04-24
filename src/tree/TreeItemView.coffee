###*
# @overview Defines the `TreeItemView` view class, the view portion of a Table of
# Contents item component.
#
# @module stout-ui/tree/TreeItemView
###
defaults        = require 'lodash/defaults'
InteractiveView = require '../interactive/InteractiveView'
Promise         = require 'stout-core/promise/Promise'
template        = require './tree-item.template'
vars            = require '../vars'

# Require shared input variables.
require '../vars/tree'


###*
# The table-of-contents custom tag name.
#
# @type string
# @const
# @private
###
TAG_NAME = vars.readPrefixed 'tree/tree-item-tag'


###*
# The tree custom tag name.
#
# @type string
# @const
# @private
###
TREE_TAG_NAME = vars.readPrefixed 'tree/tree-tag'


###*
# The tree-item class name.
#
# @type string
# @const
# @private
###
TREE_ITEM_CLS = vars.read 'tree/tree-item-class'


###*
# Collapsible class added to items which should be rendered as "collapsible."
#
# @type {string}
# @const
###
COL_CLS = vars.read 'tree/tree-collapsible-class'


###*
# Class indicating that the item is currently collapsed.
#
# @type {string}
# @const
###
COLLAPSED_CLS = vars.read 'tree/tree-collapsed-class'


###*
# The time (in millseconds) a collapse operation should take.
#
# @type {number}
# @const
###
COLLAPSE_T = vars.readTime 'tree/tree-item-collapse-time'


###*
# The time (in millseconds) an expand operation should take.
#
# @type {number}
# @const
###
EXPAND_T = vars.readTime 'tree/tree-item-expand-time'


###*
# Class added to the tree during a collapsing transition.
#
# @type {string}
# @const
###
COLLAPSING_CLS = vars.read 'tree/tree-collapsing-class'


###*
# Class added to the tree during an expand transition.
#
# @type {string}
# @const
###
EXPANDING_CLS = vars.read 'tree/tree-expanding-class'



###*
# Helper function sets then schedules the clearing of the collapse transition
# flag.
#
# @function
# @inner
###
transitionHelper = (dir, target) ->
  t = if dir is 'expand' then EXPAND_T else COLLAPSE_T
  target._collapseTimer = setTimeout ->
    target._collapseTransitioning = false
    target.prefixedClasses.remove EXPANDING_CLS, COLLAPSING_CLS
    if dir is 'collapse' then target.prefixedClasses.add COLLAPSED_CLS
  , t


###*
# Helper function to set the collapse-prevention flag.
#
#
#
###
setCollapseFlag = (target) ->
  if target._collapseTimer then clearTimeout target._collapseTimer
  target._collapseTransitioning = true



###*
# The `TreeItemView` class represents the view part of a table of contents
# item component.
#
# @exports stout-ui/tree/TreeItemView
# @extends stout-ui/interactive/InteractiveView
# @constructor
###
module.exports = class TreeItemView extends InteractiveView

  constructor: (init, events) ->
    defaults init, {template, tagName: TAG_NAME}
    super init, events

    @prefixedClasses.add TREE_ITEM_CLS

    @root.setAttribute 'role', 'listitem'

    @_collapseTransitioning = false

    @on 'ready', @_updateCollapsible, @

    # Listen for touchstart/mouseup events to toggle the tree.
    @on 'mouseup', (e) =>
      e.data.stopPropagation()
      @toggle()


  ###*
  # Property indicating if this item's children can be collapsed. This property
  # has no meaning if this item has no children.
  #
  # @member {boolean} collapsible
  # @memberof stout-ui/tree/TreeItemView#
  ###
  @property 'collapsible',
    type: 'boolean'
    default: true


  ###*
  # The current collapsed state of this tree item. This property has no meaning
  # if it has no children.
  #
  # @member {boolean} collapsible
  # @memberof stout-ui/tree/TreeItemView#
  ###
  @property 'collapsed',
    type: 'boolean'
    default: true


  ###*
  # Timer for updating `_collapseTransitioning` flag.
  #
  # @member _collapseTimer
  # @memberof stout-ui/tree/TreeItemView#
  ###


  ###*
  # Flag indicating if the tree is currently expanding or collapsing. A `true`
  # state indicates that transition is currently occurring.
  #
  # @member _collapseTransitioning
  # @memberof stout-ui/tree/TreeItemView#
  ###


  ###*
  # Opens the child tree of this tree item, if it is currently collapsed and
  # is collapsible.
  #
  # @method expand
  # @memberof stout-ui/tree/TreeItemView#
  ###
  expand: ->
    if @collapsible and @collapsed and not @_collapseTransitioning
      @collapsed = false
      setCollapseFlag @
      @prefixedClasses.remove COLLAPSED_CLS
      @prefixedClasses.add EXPANDING_CLS
      @_updateHeight().then =>
        transitionHelper 'expand', @
      .catch (e) ->
        console.error e
    else
      Promise.fulfilled()


  ###*
  # Closes the child tree of this tree item, if it is currently expand and
  # is collapsible.
  #
  # @method collapse
  # @memberof stout-ui/tree/TreeItemView#
  ###
  collapse: ->
    if not @_collapseTransitioning and @collapsible and not @collapsed
      @collapsed = true
      setCollapseFlag @
      @prefixedClasses.add COLLAPSING_CLS
      @_updateHeight(true).then =>
        transitionHelper 'collapse', @
      .catch (e) ->
        console.error e
    else
      Promise.fulfilled()


  ###*
  # Toggles the expanded/collapsed state of this tree view item.
  #
  # @method toggle
  # @memberof stout-ui/tree/TreeItemView#
  ###
  toggle: ->
    if @collapsed then @expand() else @collapse()


  ###*
  # Calculates and returns (as a promise) the height of this tree including
  # any subtrees.
  #
  # @returns {module:stout-core/promise/Promise} Promise resolved to the height
  # of the tree in pixels.
  ###
  _getHeight: ->
    promises = []

    @children.get(TREE_TAG_NAME).every (tree) ->
      promises.push tree.getRenderedDimensions(null, ['height'])

      tree.children.get(TAG_NAME).every (item) ->
        promises.push item._getHeight()

    Promise.all(promises).then (a) ->
      if not a or a.length is 0
        0
      else
        a.reduce ((p, v) -> p + (+v?.height or 0)), 0


  ###*
  # Updates the height of this tree item, then travels up the tree and adjusts
  # the height of all parents trees.
  #
  # @param {boolean} collapse - Set to `true` if closing the tree.
  #
  # @method _updateCollapsible
  # @memberof stout-ui/tree/TreeItemView#
  # @private
  ###
  _updateHeight: (collapse, immediate) ->
    @_getHeight().then (r) =>
      m = if collapse then -1 else 1

      tree = @children.get(TREE_TAG_NAME)[0]

      if tree and not @collapsed
        tree.setHeight(r)
        promise = tree.expand()
      else if tree
        promise = tree.collapse().then ->
          tree.setHeight(0)

      collapseUpTree = (tree) ->
        if not tree then return
        if tree.parent and tree.parent.collapsible
          tree.getRenderedDimensions().then (d) =>
            tree.setHeight(d.height + m * r)
            collapseUpTree tree.parent.parent

      # If we are collapsing the tree, then wait until after the children
      # are collapsed, then collapse the parent trees.
      if immediate or not collapse
        collapseUpTree @parent

      # If expanding, then expand immediately.
      else
        promise.then => collapseUpTree @parent

      # Return the promise from the tree.
      promise



  ###*
  # Updates the "collapsible" display state of this item.
  #
  # @method _updateCollapsible
  # @memberof stout-ui/tree/TreeItemView#
  # @private
  ###
  _updateCollapsible: ->

    # Update collapsed and collapsable classes based on child trees.
    @prefixedClasses.remove COL_CLS, COLLAPSED_CLS

    if @children.get(TREE_TAG_NAME).length > 0 and @collapsible
      @_updateHeight(@collapsed, true)
      @prefixedClasses.add COL_CLS

    if @collapsed and @collapsible
      @prefixedClasses.add COLLAPSED_CLS
