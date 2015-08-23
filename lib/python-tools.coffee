PythonToolsView = require './python-tools-view'
{CompositeDisposable} = require 'atom'
path = require 'path'

module.exports = PythonTools =
  pythonToolsView: null
  modalPanel: null
  subscriptions: null

  activate: (state) ->
    @pythonToolsView = new PythonToolsView(state.pythonToolsViewState)
    @modalPanel = atom.workspace.addModalPanel(item: @pythonToolsView.getElement(), visible: false)
    # Events subscribed to in atom's system can be easily cleaned up with a CompositeDisposable
    @subscriptions = new CompositeDisposable

    # Register command that toggles this view
    @subscriptions.add atom.commands.add 'atom-workspace', 'python-tools:toggle': => @toggle()
    @subscriptions.add atom.commands.add 'atom-text-editor', 'python-tools:show-usages': => @showUsages()

    atom.contextMenu.add({
      'atom-text-editor': [{
          label: 'Show Usages',
          command: 'python-tools:show-usages'
        }]
    })

    @requests = {}

    env = process.env
    paths = ['/usr/local/bin', '/usr/bin', '/bin', '/usr/sbin', '/sbin']
    path_env = (env.PATH or '').split path.delimiter
    for p in paths
      if p not in path_env
        path_env.push p
    env.PATH = path_env.join path.delimiter

    @provider = require('child_process').spawn(
      'python', [__dirname + '/tools.py'], env: env)

    @provider.on 'error', (err) =>
      if err.code == 'ENOENT'
        atom.notifications.addWarning(
          "python-tools unable to find python executable: please set " +
          "the path to python directory manually in the package settings and " +
          "restart your editor. #{@_issueReportLink}", {
            detail: err,
            dismissable: true})
      else
        atom.notifications.addError(
          "python-tools error. #{@_issueReportLink}", {
            detail: err,
            dismissable: true})
    @provider.on 'exit', (code, signal) =>
      if signal != 'SIGTERM'
        atom.notifications.addError(
          "python-tools provider exit. #{@_issueReportLink}", {
            detail: "exit with code #{code}, signal #{signal}",
            dismissable: true})

    @readline = require('readline').createInterface(input: @provider.stdout)
    @readline.on 'line', (response) => @_deserialize(response)


  deactivate: ->
    @modalPanel.destroy()
    @subscriptions.dispose()
    @pythonToolsView.destroy()

  serialize: ->
    pythonToolsViewState: @pythonToolsView.serialize()

  _deserialize: (response) ->
    console.log "Got some data back from tools.py"
    console.log "#{response}"

  showUsages: ->
    console.log 'Running show usages'
    editor = atom.workspace.getActiveTextEditor()
    bufferPosition = editor.getCursorBufferPosition()

    payload =
      path: editor.getPath()
      source: editor.getText()
      line: bufferPosition.row
      column: bufferPosition.column

    @provider.stdin.write(JSON.stringify(payload) + '\n')

  toggle: ->
    console.log 'PythonTools was toggled!'

    if @modalPanel.isVisible()
      @modalPanel.hide()
    else
      @modalPanel.show()
