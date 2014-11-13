
React = require 'react'
path = require 'path'
fs = require 'fs-extra'
marked = require 'marked'

for_deploy = '--production' in process.argv

source_directory = __dirname
build_directory = __dirname
if for_deploy
    build_directory = path.join(build_directory, '.build')
    if fs.existsSync(build_directory)
        fs.removeSync(build_directory)
    fs.mkdirSync(build_directory)
    deploy_config_path = path.join(__dirname, '.env.json')
    unless fs.existsSync(deploy_config_path)
        throw new Error('You need a .env.json with the necessary config.')
    deploy_config = JSON.parse(fs.readFileSync(deploy_config_path).toString())

project_directory = path.join(__dirname, '..')
asset_source_dir = asset_cache_dir = asset_dest_dir = path.join(__dirname, '_assets')

_writeFile = require('../compiler/writeFile')(build_directory)
_emitFile = require('../compiler/emitFile')(
    project_directory   : project_directory
    project             : {}
    config              : {}
    writeFile           : _writeFile
)

{ processAsset } = require '../compiler/compileAssets'
getCurrentCommit = require '../compiler/getCurrentCommit'
putFilesToS3 = require '../deployment/putFilesToS3'
walkSync = require '../compiler/walkSync'

{ GoogleAnalytics, ChartbeatStart } = require '../base/Analytics'
{ BuildInfo, makeMetaTags, Asset, Favicon, GoogleFonts } = require '../base'

console.log 'Compiling docs in', build_directory, for_deploy

global.config =
    PUBLICATION_SHORT_NAME: 'marquee-static-sdk'

MarqueeBranding = require '../components/MarqueeBranding'

Base = React.createClass
    render: ->
        google_analytics_id = null
        <html>
            <head>
                <title>{ if @props.title then "#{ @props.title } - " else null }Marquee Static SDK</title>
                <meta charSet='utf-8' />
                <meta name='viewport' content='width=device-width, initial-scale=1, minimum-scale=1.0' />

                {makeMetaTags(@props.meta)}

                <Asset path='style.sass' inline=true />
                <GoogleFonts fonts={
                    'Open+Sans': ['400italic', '400', '600italic', '600']
                }/>
                <Favicon />
                {@props.extra_head}

            </head>
            <body className='Site__'>

                {@props.children}

                {@props.extra_body}

                <GoogleAnalytics id=google_analytics_id />
                <BuildInfo />
            </body>
        </html>

MarkdownPage = React.createClass
    render: ->
        output_content = fs.readFileSync(@props.file).toString()

        # http://tools.ietf.org/html/rfc2119
        KEYWORDS = ['MUST', 'MUST NOT', 'REQUIRED', 'SHALL', 'SHALL NOT', 'SHOULD', 'SHOULD NOT', 'RECOMMENDED', 'MAY', 'OPTIONAL']
        KEYWORDS.forEach (word) ->
            exp = new RegExp(word,'g')
            output_content = output_content.replace(exp, """
                <em class="SpecKeyword" data-word="#{ word }">#{ word }</em>
            """.trim())
        output_content = marked(output_content)
        <div className='Page__' dangerouslySetInnerHTML={ __html: output_content } />

_dashesToTitle = (text) ->
    text = text.split('-').map (seg) -> seg.substring(0,1).toUpperCase() + seg.substring(1)
    return text.join(' ')

Nav = React.createClass
    render: ->
        nav_links = @props.files.map (f) =>
            _f = f.replace(/\.md$/,'')
            if for_deploy
                link = "/#{ deploy_config.PREFIX }/"
                unless _f is 'index'
                    link += "#{ _f }/"
            else
                link = "./#{ _f }.html"
            if _f is 'index'
                text = 'Marquee Static SDK'
            else
                text = _dashesToTitle(_f)
            current = if f is @props.current then '-current' else ''
            return <a className="_Link #{ current }" href=link key=_f>{text}</a>
        <nav className='Nav'>
            {nav_links}
            <MarqueeBranding campaign='docs' logo_only=true />
        </nav>

getCurrentCommit project_directory, (commit_sha) ->
    processAsset
        asset_source_dir    : asset_source_dir
        asset_cache_dir     : asset_cache_dir
        asset_dest_dir      : asset_dest_dir
        asset               : path.join(asset_source_dir, 'style.sass')
        project_directory   : project_directory
        callback: ->
            global.build_info =
                project_directory       : project_directory
                commit                  : commit_sha
                date                    : new Date()
                build_directory         : build_directory
                asset_cache_directory   : asset_cache_dir

            doc_files = fs.readdirSync(source_directory).filter (f) ->
                f.split('.').pop() is 'md' and f isnt 'index.md'
            doc_files.unshift('index.md')
            doc_files.forEach (f) ->
                title = f.replace(/\.md$/, '')
                if for_deploy and f isnt 'index.md'
                    output_name = title
                else
                    output_name = "#{ title }.html"
                title = _dashesToTitle(title)

                if for_deploy and deploy_config.PREFIX
                    output_name = path.join(deploy_config.PREFIX, output_name)
                _emitFile(
                    output_name,
                    <Base title=title>
                        <div className='_Nav__'>
                            <Nav files=doc_files current=f />
                        </div>
                        <div className='_Content__'>
                            <MarkdownPage file={path.join(source_directory, f)} />
                        </div>
                    </Base>
                )

            if for_deploy
                files_to_deploy = walkSync(build_directory)
                putFilesToS3 build_directory, files_to_deploy, deploy_config, ->
                    console.log arguments
                    console.log 'DEPLOYED!'
