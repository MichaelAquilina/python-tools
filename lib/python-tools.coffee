{Range, Point, CompositeDisposable} = require 'atom'
path = require 'path'


regexPatternIn = (pattern, list) ->
  for item in list
    if pattern.test item
      return true
  return false


PythonTools =
  config:
    smartBlockSelection:
      type: 'boolean'
      description: 'Do not select whitespace outside logical string blocks'
      default: true
    pythonPath:
      type: 'string'
      default: ''
      title: 'Path to python directory'
      description: '''
      Optional. Set it if default values are not working for you or you want to use specific
      python version. For example: `/usr/local/Cellar/python/2.7.3/bin` or `E:\\Python2.7`
      '''

  subscriptions: null

  _issueReportLink: "https://github.com/michaelaquilina/python-tools/issues/new"

  activate: (state) ->
    # Events subscribed to in atom's system can be easily cleaned up with a CompositeDisposable
    @subscriptions = new CompositeDisposable
    @subscriptions.add(
      atom.commands.add 'atom-text-editor[data-grammar="source python"]',
      'python-tools:show-usages': => @jediToolsRequest('usages')
    )
    @subscriptions.add(
      atom.commands.add 'atom-text-editor[data-grammar="source python"]',
      'python-tools:goto-definition': => @jediToolsRequest('gotoDef')
    )
    @subscriptions.add(
      atom.commands.add 'atom-text-editor[data-grammar="source python"]',
      'python-tools:select-all-string': => @selectAllString()
    )

    env = process.env
    pythonPath = atom.config.get('python-tools.pythonPath')

    if /^win/.test process.platform
      paths = ['C:\\Python2.7',
               'C:\\Python27',
               'C:\\Python3.4',
               'C:\\Python34',
               'C:\\Python3.5',
               'C:\\Python35',
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
    path_env.unshift pythonPath if pythonPath and pythonPath not in path_env
    for p in paths
      if p not in path_env
        path_env.push p
    env.PATH = path_env.join path.delimiter

    @provider = require('child_process').spawn(
      'python', [__dirname + '/tools.py'], env: env
    )

    @readline = require('readline').createInterface(
      input: @provider.stdout
      output: @provider.stdin
    )

    @provider.on 'error', (err) =>
      if err.code == 'ENOENT'
        atom.notifications.addWarning("""
          python-tools was unable to find your machine's python executable.

          Please try set the path in package settings and then restart atom.

          If the issue persists please post an issue on
          #{@_issueReportLink}
          """, {
            detail: err,
            dismissable: true
          }
        )
      else
        atom.notifications.addError("""
          python-tools unexpected error.

          Please consider posting an issue on
          #{@_issueReportLink}
          """, {
              detail: err,
              dismissable: true
            }
        )
    @provider.on 'exit', (code, signal) =>
      if signal != 'SIGTERM'
        atom.notifications.addError(
          """
          python-tools experienced an unexpected exit.

          Please consider posting an issue on
          #{@_issueReportLink}
          """, {
            detail: "exit with code #{code}, signal #{signal}",
            dismissable: true
          }
        )

  deactivate: ->
    @subscriptions.dispose()
    @provider.kill()
    @readline.close()

  selectAllString: ->
    editor = atom.workspace.getActiveTextEditor()
    bufferPosition = editor.getCursorBufferPosition()
    line = editor.lineTextForBufferRow(bufferPosition.row)

    scopeDescriptor = editor.scopeDescriptorForBufferPosition(bufferPosition)
    scopes = scopeDescriptor.getScopesArray()

    block = false
    if regexPatternIn(/string.quoted.single.single-line.*/, scopes)
      delimiter = '\''
    else if regexPatternIn(/string.quoted.double.single-line.*/, scopes)
      delimiter = '"'
    else if regexPatternIn(/string.quoted.double.block.*/,scopes)
      delimiter = '"""'
      block = true
    else if regexPatternIn(/string.quoted.single.block.*/, scopes)
      delimiter = '\'\'\''
      block = true
    else
      return

    if not block
      start = end = bufferPosition.column

      while line[start] != delimiter
        start = start - 1
        if start < 0
          return

      while line[end] != delimiter
        end = end + 1
        if end == line.length
          return

      editor.setSelectedBufferRange(new Range(
        new Point(bufferPosition.row, start + 1),
        new Point(bufferPosition.row, end),
      ))
    else
      start = end = bufferPosition.row
      start_index = end_index = -1

      # Detect if we are at the boundaries of the block string
      delim_index = line.indexOf(delimiter)

      if delim_index != -1
        scopes = editor.scopeDescriptorForBufferPosition(new Point(start, delim_index))
        scopes = scopes.getScopesArray()

        # We are at the beginning of the block
        if regexPatternIn(/punctuation.definition.string.begin.*/, scopes)
          start_index = line.indexOf(delimiter)
          while end_index == -1
            end = end + 1
            line = editor.lineTextForBufferRow(end)
            end_index = line.indexOf(delimiter)

        # We are the end of the block
        else if regexPatternIn(/punctuation.definition.string.end.*/, scopes)
          end_index = line.indexOf(delimiter)
          while start_index == -1
            start = start - 1
            line = editor.lineTextForBufferRow(start)
            start_index = line.indexOf(delimiter)

      else
        # We are neither at the beginning or the end of the block
        while end_index == -1
          end = end + 1
          line = editor.lineTextForBufferRow(end)
          end_index = line.indexOf(delimiter)
        while start_index == -1
          start = start - 1
          line = editor.lineTextForBufferRow(start)
          start_index = line.indexOf(delimiter)

      if atom.config.get('python-tools.smartBlockSelection')
        # Smart block selections
        selections = [new Range(
          new Point(start, start_index + delimiter.length),
          new Point(start, editor.lineTextForBufferRow(start).length),
        )]

        for i in [start + 1 ... end] by 1
          line = editor.lineTextForBufferRow(i)
          trimmed = line.replace(/^\s+/, "")  # left trim
          selections.push new Range(
            new Point(i, line.length - trimmed.length),
            new Point(i, line.length),
          )

        line = editor.lineTextForBufferRow(end)
        trimmed = line.replace(/^\s+/, "")  # left trim

        selections.push new Range(
          new Point(end, line.length - trimmed.length),
          new Point(end, end_index),
        )

        editor.setSelectedBufferRanges(selections.filter (range) -> not range.isEmpty())
      else
        editor.setSelectedBufferRange(new Range(
          new Point(start, start_index + delimiter.length),
          new Point(end, end_index),
        ))

  handleJediToolsResponse: (response) ->
    if 'error' of response
      console.error response['error']
      atom.notifications.addError(response['error'])
      return

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

    bufferPosition = editor.getCursorBufferPosition()

    payload =
      type: type
      path: editor.getPath()
      source: editor.getText()
      line: bufferPosition.row
      col: bufferPosition.column

    # This is needed for the promise to work correctly
    handleJediToolsResponse = @handleJediToolsResponse
    readline = @readline

    return new Promise (resolve, reject) ->
      response = readline.question "#{JSON.stringify(payload)}\n", (response) ->
        handleJediToolsResponse(JSON.parse(response))
        resolve()


module.exports = PythonTools
