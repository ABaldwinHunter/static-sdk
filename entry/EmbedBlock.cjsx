React = require 'react'

querystring     = require 'querystring'
url             = require 'url'


{ Classes } = require 'shiny'
module.exports = React.createClass
    displayName: 'EmbedBlock'
    render: ->
        unless @props.block.content
            return null

        layout = @props.block.layout or {}
        size = layout.size or 'medium'
        position = layout.position or 'center'

        credit = @props.block.credit
        caption = @props.block.caption
        unless caption
            if @props.block.annotations
                for anno in @props.block.annotations
                    if anno.type is 'caption'
                        caption = anno.content
                        break

        variants = new Classes()
        variants.set('size', size)
        unless size is 'full'
            variants.set('position', position)

        embed_video_url = parseVideoURL(@props.block.content)
        if embed_video_url
            embed = <iframe
                        className   = '_EmbedFrame'
                        src         = embed_video_url
                        frameBorder = 0
                        webkitAllowFullScreen
                        mozallowfullscreen
                        allowFullScreen
                    />
        else
            embed = <div dangerouslySetInnerHTML={ __html: @props.block.content } />

        <figure
            className = "Block EmbedBlock #{ variants }"
        >
            <div className='_Content'>
                <div className='_EmbedWrapper'>
                    {embed}
                </div>
                {
                    if caption or credit
                        <figcaption className='_Caption'>
                            <span className='_CaptionText'>{caption}</span>
                            <span className='_Credit'>{credit}</span>
                        </figcaption>
                }
            </div>
        </figure>



parseVideoURL = (_url) ->
    parsed_url = url.parse(_url)
    query = querystring.parse(parsed_url.query)

    unless parsed_url.hostname
        return null

    switch parsed_url.hostname.replace('www.','')
        when 'youtube.com'
            return "http://www.youtube.com/embed/#{ query.v }?modestbranding=1"
        when 'youtu.be'
            return "http://www.youtube.com/embed#{ parsed_url.pathname }?modestbranding=1"
        when 'vimeo.com'
            return "http://player.vimeo.com/video#{ parsed_url.pathname }"
        else
            console.error("Unknown video host: #{ parsed_url.hostname }")
    return
