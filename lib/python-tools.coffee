{Range, Point, CompositeDisposable} = require 'atom'
path = require 'path'

module.exports = PythonTools =
  subscriptions: null

  activate: (state) ->
    # Events subscribed to in atom's system can be easily cleaned up with a CompositeDisposable
    @subscriptions = new CompositeDisposable
    @subscriptions.add atom.commands.add 'atom-text-editor', 'python-tools:show-usages': => @jediToolsRequest('usages')
    @subscriptions.add atom.commands.add 'atom-text-editor', 'python-tools:goto-definition': => @jediToolsRequest('gotoDef')

    @requests = {}

    env = process.env
    if /^win/.test process.platform
      paths = ['C:\\Python2.7',
               'C:\\Python3.4',
               'C:\\Python3.5',
               'C:\\Program Files (x86)\\Python 2.7',
               'C:\\Program Files (x86)\\Python 3.4',
               'C:\\Program Files (x86)\\Python 3.5',
               'C:\\Program Files (x64)\\Python 2.7',
               'C:\\Program Files (x64)\\Python 3.4',
               'C:\\Program Files (x64)\\Python 3.5',
               'C:\\Program Files\\Python 2.7',
               'C:\\Program Files\\Python 3.4',
               'C:\\Program Files\\Python 3.5']
    else:
      paths = ['/usr/local/bin', '/usr/bin', '/bin', '/usr/sbin', '/sbin']
    path_env = (env.PATH or '').split path.delimiter
    for p in paths
      if p not in path_env
        path_env.push p
    env.PATH = path_env.join path.delimiter

    @provider = require('child_process').spawn(
      'python', [__dirname + '/tools.py'], env: env
    )

    @provider.on 'error', (err) =>
      if err.code == 'ENOENT'
        atom.notifications.addWarning(
          "python-tools unable to find python executable: please set " +
          "the path to python directory manually in the package settings and " +
          "restart your editor. #{@_issueReportLink}", {
            detail: err,
            dismissable: true
          }
        )
      else
        atom.notifications.addError(
          "python-tools error. #{@_issueReportLink}", {
            detail: err,
            dismissable: true
          }
        )
    @provider.on 'exit', (code, signal) =>
      if signal != 'SIGTERM'
        atom.notifications.addError(
          "python-tools provider exit. #{@_issueReportLink}", {
            detail: "exit with code #{code}, signal #{signal}",
            dismissable: true
          }
        )

    @readline = require('readline').createInterface(input: @provider.stdout)
    @readline.on 'line', (response) => @_deserialize(response)

  deactivate: ->
    @subscriptions.dispose()
    @readline.close()
    @provider.kill()

  _deserialize: (response) ->
    console.log "tools.py => #{response}"

    response = JSON.parse(response)

    if response['definitions'].length > 0
      editor = atom.workspace.getActiveTextEditor()

      if response['type'] == 'usages'
        selections = []
        for item in response['definitions']
          selections.push new Range(
            new Point(item['line'] - 1, item['col']),
            new Point(item['line'] - 1, item['col'] + item['name'].length),  # Use string length
          )

        editor.setSelectedBufferRanges(selections)

      else if response['type'] == 'gotoDef'
        first_def = response['definitions'][0]

        line = first_def['line']
        column = first_def['col']

        if line != null and column != null
          options =
            initialLine: line
            initialColumn: column

          atom.workspace.open(first_def['path'], options).then((editor) ->
            # scroll to top first to get it centered correctly
            editor.scrollToTop()
            editor.scrollToCursorPosition()
          )
      else
        atom.notifications.addWarning("python-tools received unknown response type '#{response['type']}'")
    else
      atom.notifications.addInfo("python-tools could not find any results!")

  jediToolsRequest: (type) ->
    editor = atom.workspace.getActiveTextEditor()
    grammar = editor.getGrammar()

    console.log "Running '#{type}' for #{grammar.name}"

    if grammar.name == 'Python'
      bufferPosition = editor.getCursorBufferPosition()

      payload =
        type: type
        path: editor.getPath()
        source: editor.getText()
        line: bufferPosition.row
        col: bufferPosition.column

      @provider.stdin.write(JSON.stringify(payload) + '\n')
