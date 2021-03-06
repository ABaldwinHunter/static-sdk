listenToThrottledWindowEvent = require './utils/listenToThrottledWindowEvent'

image_resize_fns        = []
VISIBILITY_THRESHOLD    = 0.5 # multiple of window height to be within

_is_bound = false

visibilityCheck = (image_block) ->
    node = image_block
    y_pos = 0
    while node.offsetParent?
        y_pos += node.offsetTop
        node = node.offsetParent
    return window.pageYOffset + (
            window.innerHeight * (1 + VISIBILITY_THRESHOLD)
        ) > y_pos or not window.pageYOffset?

renderAllImages = ->
    image_resize_fns.forEach (fn) -> fn()

gatherImages = ->
    px_ratio = window.devicePixelAspectRatio or 1
    for el in document.querySelectorAll('.CoverImage')
        unless el.dataset.is_empty is 'true' or el.dataset.is_bound
            do ->
                image_block = el
                image_block.dataset.is_bound = true
                image_resize_fns.push ->
                    if image_block.dataset.is_loading is 'true' or image_block.dataset.loaded is 'true'
                        return

                    if visibilityCheck(image_block)
                        image_block.dataset.is_loading = true

                        sizes = [640, 1280]
                        if image_block.dataset.src_2560
                            sizes.push(2560)
                        image_ar = parseFloat(image_block.dataset.aspect_ratio) or 1
                        sizes = sizes.map (w) -> [w, w / image_ar]


                        if image_block.offsetWidth / image_block.offsetHeight > image_ar
                            comparison_dimension = image_block.offsetWidth
                            comparison_size = 0
                        else
                            comparison_dimension = image_block.offsetHeight
                            comparison_size = 1
                        comparison_dimension = comparison_dimension * px_ratio

                        for size in sizes
                            if size[comparison_size] > comparison_dimension or size is sizes[sizes.length - 1]
                                selected_size = size[0]
                                break

                        src = image_block.dataset["src_#{ selected_size }"]
                        image_block.dataset.selected_size = selected_size

                        console.info("CoverImage: loading #{ src }") if window.DEBUG
                        preloader_img = document.createElement('img')
                        preloader_img.src = src
                        preloader_img.onerror = (err) ->
                            image_block.dataset.is_loading = false
                            image_block.dataset.had_error = true
                            console.error(err)
                        preloader_img.onload = ->
                            image_block.querySelector('._Image').style.backgroundImage = "url('#{ src }')"
                            image_block.dataset.loaded = true
                            image_block.dataset.is_loading = false


init = ->

    gatherImages()
    if image_resize_fns.length > 0
        renderAllImages()
        unless _is_bound
            _is_bound = true
            listenToThrottledWindowEvent('resize', renderAllImages)
            listenToThrottledWindowEvent('scroll', renderAllImages)

module.exports =
    activate: init
require('./client_modules').register('CoverImage', module.exports)
