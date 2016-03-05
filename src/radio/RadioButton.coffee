###*
# @overview Defines the RadioButton class, a standard radio button which is
# capable of being grouped by a group ID.
#
# @module stout-ui/radio/RadioButton
###

assign    = require 'lodash/assign'
Container = require '../container/Container'
vars      = require '../vars'
template  = require './radio-button.template'
use       = require 'stout-core/trait/use'
fillable  = require '../fill/fillable'

# Require necessary shared variables.
require '../vars/radio'


###*
# The radio button class applied to the root component.
# @type string
# @const
# @private
###
RADIO_CLS = vars.read 'radio/radio-class'


###*
# The classname of the element which will act as the displayed radio button,
# or the "indicator."
# @type string
# @const
# @private
###
INDICATOR_CLS = vars.readPrefixed 'radio/radio-indicator-class'


###*
# The class name of the radio button label, applied if using the radio buttons
# `label` property.
# @type string
# @const
# @private
###
LABEL_CLS = vars.readPrefixed 'radio/radio-label-class'


###*
# The container classname which will hold the ink fill inside the radio button.
# @type string
# @const
# @private
###
FILL_CLS = vars.readPrefixed 'fill/fill-container-class'


###*
#
# @type string
# @const
# @private
###
FILL_BOUNDS_CLS = vars.readPrefixed 'radio/radio-fill-bounds'


module.exports = class RadioButton extends Container

  ###*
  # The RadioButton class represents a single radio button which may be linked
  # to other RadioButton instances to ensure mutual exlusivity.
  #
  # @param {Object} [init] - Initiation object.
  #
  # @exports stout-ui/radio/RadioButton
  # @extends stout-ui/container/Container
  # @constructor
  ###
  constructor: (init) ->
    super template, null, {renderOnChange: false}, init, ['select', 'unselect']
    @prefixedClasses.add RADIO_CLS
    use(fillable) @

    assign @viewClasses,
      indicator: INDICATOR_CLS
      label: LABEL_CLS
      fillBounds: FILL_BOUNDS_CLS


  ###*
  # The ID of the group this radio button belongs to.
  # @member group
  # @memberof stout-ui/radio/RadioButton
  # @type string|number
  ###
  @property 'group'


  ###*
  # The label for this radio button.
  # @member label
  # @memberof stout-ui/radio/RadioButton
  # @type string
  ###
  @property 'label',
    default: ''
    set: (l) ->
      @contents = "<span class=#{LABEL_CLS}>#{l}</span>"


  render: ->
    super()
    @fill()
