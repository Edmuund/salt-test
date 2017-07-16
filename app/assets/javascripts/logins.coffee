# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/

$(document).on 'turbolinks:load', ->

  # progress bar
  $('#new_login').on 'submit', ->
    button = $('#devise_button')
    progress = $('.loading')
    button.fadeOut 500
    setTimeout ( ->
      if button.is(':hidden')
        progress.fadeIn 500
      return
    ), 509
    setInterval ( ->
      $.get
        url: '/logins/stage.json',
        success: (data) ->
          $('#stage').text data['stage']
          return
      return
    ), 400
    return

  # add login
  $('#new-login').on 'click', ->
    myWindow = window.open('/logins/new', 'NewLogin', 'width=600, height=600')
    return

  # refresh button
  $('#refresh').click ->
    $(this).addClass 'rotate'
    return

  # reconnect login
  $('.reconnect').on 'click', ->
    url = $('.reconnect').data('url')
    myWindow = window.open(url, 'ReconnectLogin', 'width=600, height=600')
    return

return