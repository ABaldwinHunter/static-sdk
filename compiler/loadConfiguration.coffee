SDKError = require './SDKError'

module.exports = (project_package, configuration_name=null) ->

    project_config = {}

    unless project_package.marquee
        throw new SDKError('configuration', "Project missing `package.marquee`.")

    for k,v of project_package.marquee
        unless k is 'configurations'
            project_config[k] = v

    # Override config with specified configuration values.
    if configuration_name
        unless project_package.marquee.configurations[configuration_name]
            _available_configs = Object.keys(project_package.marquee.configurations).map (c) -> "`#{ c }`"
            _available_configs = _available_configs.join(', ')
            throw new SDKError('configuration', "Unknown configuration specified: `#{ configuration_name }`. Package has #{ _available_configs }.")
        for k,v of project_package.marquee.configurations[configuration_name]
            project_config[k] = v

    return project_config