listenToThrottledWindowEvent = require '../utils/listenToThrottledWindowEvent'

init = ->
    progress_bars = []
    for indicator_el in document.querySelectorAll('.ReadingProgress')
        progress_bars.push(indicator_el.querySelector('._ProgressBar'))

    listenToThrottledWindowEvent 'scroll', (e) ->
        if window.pageYOffset > 80
            width = window.pageYOffset / (document.body.offsetHeight - window.innerHeight)
            width = "#{ width * 100 }%"
        else
            width = 0
        progress_bars.forEach (bar) ->
            bar.style.width = width

module.exports =
    activate: init
require('../client_modules').register('ReadingProgress', module.exports)