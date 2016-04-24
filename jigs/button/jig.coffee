buttonFactory = require '../../button'
parser = require 'stout-client/parser'


window.onload = ->

  parser.parse()

  # Size examples.
  for size in ['tiny', 'small', 'normal', 'large', 'huge', 'massive']
    buttonFactory
      label: 'Make Reservation'
      parentEl: '.size-' + size
      size: size
    .render().then (v) ->
      console.log 'rendered!'
    .error (e) ->
      console.error 'Failed to render button: ', e


  # Inverse button style example.
  buttonFactory
    label: 'Confirm Order'
    parentEl: '.inverse'
    type: 'inverse'
  .render()


  # Flat button styles
  for style in ['normal', 'primary', 'inverse', 'warn', 'danger']

    buttonFactory
      label: style + ' flat button'
      parentEl: ".#{style}-flat"
      type: style + '-flat'
    .render()



  # Primary button style example.
  buttonFactory
    label: 'Place Order'
    parentEl: '.primary'
    type: 'primary'
  .render()



  # Warn button style example.
  buttonFactory
    label: 'Launch Missile'
    parentEl: '.warn'
    type: 'warn'
  .render()


  # Danger button style example.
  buttonFactory
    label: 'Delete Everything'
    parentEl: '.danger'
    type: 'danger'
  .render()


  # Disabled button example.
  for style in ['normal', 'primary', 'inverse']

    disabledButton = buttonFactory
      label: 'Button Disabled'
      parentEl: ".disabled-#{style} .subject"
      type: style
    disabledButton.disable().render()

    buttonFactory
      label: 'Enable'
      size: 'tiny'
      parentEl: ".disabled-#{style} .controls"
      click: ((db) ->
        -> db.enable()
      )(disabledButton)
    .render()

    buttonFactory
      label: 'Disable'
      size: 'tiny'
      parentEl: ".disabled-#{style} .controls"
      tap: -> console.log 'tapped!'
      click: ((db) ->
        -> db.disable()
      )(disabledButton)
    .render()



  # Show-hide example buttons.
  showButtonEx = buttonFactory
    label: 'Reveal Example'
    parentEl: '.show-hide .subject'
    type: 'primary'
    classes: 'show-hide-subject'
  showButtonEx.render()

  buttonFactory
    label: 'Show'
    size: 'tiny'
    parentEl: '.show-hide .controls'
    classes: 'show-button'
    click: ->
      showButtonEx.show()
  .render()

  buttonFactory
    label: 'Hide'
    size: 'tiny'
    parentEl: '.show-hide .controls'
    classes: 'hide-button'
    click: ->
      showButtonEx.hide()
  .render()
