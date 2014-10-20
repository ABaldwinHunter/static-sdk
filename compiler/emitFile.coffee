# React = require 'react'

SDKError    = require './SDKError'
colors      = SDKError.colors

path        = require 'path'
fs          = require 'fs'
util        = require 'util'
mime        = require 'mime'

module.exports = (project_directory, project, config) ->


    # Require the project's copy of React so that the below validation and
    # rendering will work. Fails silently since React is not required at this
    # point. (For some reason, different copies of React can't validate each
    # other's components?)
    project_react_path = path.join(project_directory, 'node_modules', 'react')
    if fs.existsSync(path.join(project_react_path, 'package.json'))
        React = require(project_react_path)

    _processContent = (file_content) ->
        switch typeof file_content
            when 'string'
                console.log "SAVING STRING CONTENT TO", file_path
                return [null, file_content]

            when 'object'
                if React?.isValidComponent(file_content)
                    output_content = React.renderComponentToStaticMarkup(file_content)
                    return ['text/html', "<!doctype html>#{ output_content }"]

                # It looks like a React component but somehow React wasn't
                # installed locally for the project.
                if file_content._store?.props?
                    util.log('project-react', "Did you mean to render a React component? React MUST be installed locally for the project in order to pass `emitFile` a React component.")

                # Try turning the data into JSON
                try
                    output_content = JSON.stringify(file_content)
                catch e
                    util.log(e)
                    new SDKError('emitFile', "Failed to generate file content JSON.")
                return ['application/json', output_content]
            else
                throw new SDKError('emitFile', "emitFile got unknown type of content: #{ typeof file_content }")

    _processPath = (file_path) ->
        return file_path

    # The actual function given to the compiler for generating files.
    emitFile = (file_path, file_content) ->
        output_path     = _processPath(file_path)
        [output_type, output_content]  = _processContent(file_content)

        # If _processContent didn't specify a content type, guess based on
        # the output path.
        unless output_type
            output_type = mime.lookup(output_path)

        util.log("Saving #{ colors.green(output_path) } #{ colors.grey('(' + output_content.length + ' bytes, ' + output_type + ')') }")


    return emitFile
