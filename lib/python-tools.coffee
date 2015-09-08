{Range, Point, CompositeDisposable} = require 'atom'
path = require 'path'

module.exports = PythonTools =
  subscriptions: null

  activate: (state) ->
    # Events subscribed to in atom's system can be easily cleaned up with a CompositeDisposable
    @subscriptions = new CompositeDisposable
    @subscriptions.add(
      atom.commands.add 'atom-text-editor',
      'python-tools:show-usages': => @jediToolsRequest('usages')
    )
    @subscriptions.add(
      atom.commands.add 'atom-text-editor',
      'python-tools:goto-definition': => @jediToolsRequest('gotoDef')
    )
    @subscriptions.add(
      atom.commands.add 'atom-text-editor',
      'python-tools:select-all-string': => @selectAllString()
    )

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
    @readline.on 'line', (response) => @handleJsonResponse(response)

  deactivate: ->
    @subscriptions.dispose()
    @readline.close()
    @provider.kill()

  selectAllString: ->
    console.log 'doing stuff'
    editor = atom.workspace.getActiveTextEditor()
    bufferPosition = editor.getCursorBufferPosition()
    line = editor.lineTextForBufferRow(bufferPosition.row)

    start = end = bufferPosition.column

    while line[start] != '\'' and line[start] != '"'
      start = start - 1

    while line[end] != line[start]
      end = end + 1

    editor.setSelectedBufferRange(new Range(
      new Point(bufferPosition.row, start + 1),
      new Point(bufferPosition.row, end),
    ))

  handleJsonResponse: (response) ->
    console.log "tools.py => #{response}"
    @handleJediToolsResponse(JSON.parse(response))

  handleJediToolsResponse: (response) ->
    if response['definitions'].length > 0
      editor = atom.workspace.getActiveTextEditor()

      if response['type'] == 'usages'
        path = editor.getPath()
        selections = []
        for item in response['definitions']
          if item['path'] == path
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
            searchAllPanes: true

          atom.workspace.open(first_def['path'], options).then (editor) ->
            # scroll to top first to get it centered correctly
            editor.scrollToTop()
            editor.scrollToCursorPosition()
      else
        atom.notifications.addError(
          "python-tools error. #{@_issueReportLink}", {
            detail: JSON.stringify(response),
            dismissable: true
          }
        )
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
