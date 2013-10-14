CI.inner.Crumb = class Crumb extends CI.inner.Obj
  constructor: (options) ->
    @active = false
    if options? and options.active?
      @active = options.active

  styles: () =>
    @komp =>
      'label-active': @active

  name: () =>
    # user-visible name of this crumb. must override
    null

  path: () =>
    # url-path to where this crumb goes when you click it
    null


CI.inner.ProjectCrumb = class ProjectCrumb extends Crumb
  constructor: (@username, @project, options) ->
    super(options)

  name: () =>
    "#{@username}/#{@project}"

  path: () =>
    CI.paths.project_path(@username, @project)

CI.inner.ProjectSettingsCrumb = class ProjectCrumb extends Crumb
  constructor: (@username, @project, options) ->
    super(options)

  name: () =>
    "Edit settings"

  path: () =>
    CI.paths.project_settings_path(@username, @project)

CI.inner.ProjectBranchCrumb = class ProjectBranchCrumb extends Crumb
  constructor: (@username, @project, @branch, options) ->
    super(options)

    # FIXME: branch is a computed observable because of the BuildPage definition

  name: () =>
    if @branch()
      CI.stringHelpers.trimMiddle(@branch(), 45)
    else
      "..."

  path: () =>
    CI.paths.project_branch_path(@username, @project, @branch())

CI.inner.BuildCrumb = class BuildCrumb extends Crumb
  constructor: (@username, @project, @build_num, options) ->
    super(options)

  name: () =>
    "build #{@build_num}"

  path: () =>
    CI.paths.build_path(@username, @project, @build_num)
