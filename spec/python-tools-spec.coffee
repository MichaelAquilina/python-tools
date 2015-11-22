PythonTools = require '../lib/python-tools'
{Point, Range} = require 'atom'

describe "PythonTools", ->
  pythonTools = null
  beforeEach ->
    waitsForPromise ->
      atom.packages.activatePackage('python-tools')
    waitsForPromise ->
      atom.packages.activatePackage('language-python')
    runs ->
      pythonTools = atom.packages.getActivePackage('python-tools').mainModule

  describe "when running jedi commands", ->
    editor = null
    beforeEach ->
      waitsForPromise ->
        atom.workspace.open('test.py')

      runs ->
        editor = atom.workspace.getActiveTextEditor()
        editor.setText("""
        import json
        """)

    it "does not send too many commands over time", ->
      editor.setCursorBufferPosition(new Point(0, 9))
      spyOn(pythonTools, 'handleJediToolsResponse')
      waitsForPromise ->
        pythonTools.jediToolsRequest('gotoDef')
      waitsForPromise ->
        pythonTools.jediToolsRequest('gotoDef').then ->
          expect(pythonTools.handleJediToolsResponse.calls.length).toEqual(2)

  describe "when running the goto definitions command", ->
    editor = null
    beforeEach ->
      waitsForPromise ->
        atom.workspace.open('mike.py')

      runs ->
        editor = atom.workspace.getActiveTextEditor()
        editor.setText("""
        import json

        class Snake(object):
            def slither(self, dict):
                return json.dumps(dict)

        snake = Snake()
        snake.slither({'x': 10, 'y': 20})

        i_dont_exist()
        """)

    it "moves to the correct class location", ->
      editor.setCursorBufferPosition(new Point(6, 9))
      waitsForPromise ->
        pythonTools.jediToolsRequest('gotoDef').then ->
          expect(editor.getCursorBufferPosition()).toEqual new Point(3, 6)

    it "moves to the correct method location", ->
      editor.setCursorBufferPosition(new Point(7, 7))
      waitsForPromise ->
        pythonTools.jediToolsRequest('gotoDef').then ->
          expect(editor.getCursorBufferPosition()).toEqual new Point(4, 8)

    it "does nothing if symbol does not exist", ->
      editor.setCursorBufferPosition(new Point(9, 7))
      waitsForPromise ->
        pythonTools.jediToolsRequest('gotoDef').then ->
          expect(editor.getCursorBufferPosition()).toEqual new Point(9, 7)

    it "opens appropriate file if required", ->
      editor.setCursorBufferPosition(new Point(0, 9))
      spyOn(atom.workspace, 'open').andCallThrough()
      waitsForPromise ->
        pythonTools.jediToolsRequest('gotoDef').then ->
          path = atom.workspace.open.mostRecentCall.args[0]
          if /^win/.test process.platform
            expect(path).toMatch(/.*\\json\\__init__.py/)
          else
            expect(path).toMatch(/.*\/json\/__init__.py/)

  describe "when tools.py gets an invalid request", ->
    editor = null
    beforeEach ->
      waitsForPromise ->
        atom.workspace.open('error.py')

      runs ->
        editor = atom.workspace.getActiveTextEditor()

  describe "when running the show usages command", ->
    editor = null
    beforeEach ->
      waitsForPromise ->
        atom.workspace.open('foo.py')

      runs ->
        editor = atom.workspace.getActiveTextEditor()
        editor.setText("""
        def my_function(a, b):
            return a + b

        print my_function(10, 20)
        """)

    it "selects the correct symbols", ->
      editor.setCursorBufferPosition(new Point(3, 8))
      waitsForPromise ->
        pythonTools.jediToolsRequest('usages').then ->
          expect(editor.getSelectedBufferRanges()).toEqual([
            new Range(new Point(0, 4), new Point(0, 15)),
            new Range(new Point(3, 6), new Point(3, 17)),
          ])

    it "doesn't alter current selection on no results", ->
      editor.setCursorBufferPosition(new Point(3, 2))
      waitsForPromise ->
        pythonTools.jediToolsRequest('usages').then ->
          expect(editor.getSelectedBufferRanges()).toEqual([
              new Range(new Point(3, 2), new Point(3, 2))
          ])

  describe "when running the select string command", ->
    editor = null
    beforeEach ->
      waitsForPromise ->
        atom.workspace.open('lolcat.py')

      runs ->
        editor = atom.workspace.getActiveTextEditor()
        editor.setText("""
        class Lolcat(object):
          mystring = 'hello world'
          anotherstring = "this is some text"
          block_text = \"\"\"
          This was a triumph!
          I'm making a note here:
          Huge success!
          \"\"\"
          more_blocks = '''
          This is some text
          '''
          sql_text = \"\"\"SELECT *
          FROM foo
          \"\"\"
          sql_text2 = '''SELECT *
          FROM bar
          '''
        """)

    it "selects single-line single qoutes correctly", ->
        editor.setCursorBufferPosition(new Point(1, 17))
        pythonTools.selectAllString()
        expect(editor.getSelectedBufferRange()).toEqual(new Range(
            new Point(1, 14),
            new Point(1, 25),
          )
        )

    it "selects single-line double qoutes correctly", ->
        editor.setCursorBufferPosition(new Point(2, 25))
        pythonTools.selectAllString()
        expect(editor.getSelectedBufferRange()).toEqual(new Range(
            new Point(2, 19),
            new Point(2, 36),
          )
        )

    it "selects block string double qoutes correctly", ->
        atom.config.set('python-tools.smartBlockSelection', false)
        editor.setCursorBufferPosition(new Point(4, 15))
        pythonTools.selectAllString()
        expect(editor.getSelectedBufferRange()).toEqual(new Range(
            new Point(3, 18),
            new Point(7, 2),
          )
        )

    it "smart selects double qoutes correctly", ->
        editor.setCursorBufferPosition(new Point(4, 15))
        pythonTools.selectAllString()
        expect(editor.getSelectedBufferRanges()).toEqual([
          new Range(new Point(4, 2), new Point(4, 21)),
          new Range(new Point(5, 2), new Point(5, 25)),
          new Range(new Point(6, 2), new Point(6, 15)),
        ])

    it "selects block string single qoutes correctly", ->
        atom.config.set('python-tools.smartBlockSelection', false)
        editor.setCursorBufferPosition(new Point(9, 15))
        pythonTools.selectAllString()
        expect(editor.getSelectedBufferRange()).toEqual(new Range(
            new Point(8, 19),
            new Point(10, 2),
          )
        )

    it "smart selects single qoutes correctly", ->
        editor.setCursorBufferPosition(new Point(9, 15))
        pythonTools.selectAllString()
        expect(editor.getSelectedBufferRanges()).toEqual([
          new Range(new Point(9, 2), new Point(9, 19)),
        ])

    it "it selects block SQL double qoutes correctly", ->
        atom.config.set('python-tools.smartBlockSelection', false)
        editor.setCursorBufferPosition(new Point(12, 20))
        pythonTools.selectAllString()
        expect(editor.getSelectedBufferRange()).toEqual(new Range(
            new Point(11, 16),
            new Point(13, 2),
          )
        )

    it "it selects block SQL single qoutes correctly", ->
        atom.config.set('python-tools.smartBlockSelection', false)
        editor.setCursorBufferPosition(new Point(14, 20))
        pythonTools.selectAllString()
        expect(editor.getSelectedBufferRange()).toEqual(new Range(
            new Point(14, 17),
            new Point(16, 2),
          )
        )

  describe "when a response is returned from tools.py", ->

    it "informs the user with an info notification when no items were found", ->
      pythonTools.handleJediToolsResponse(
        type: "usages"
        definitions: []
      )
      [notification] = atom.notifications.getNotifications()
      expect(notification.type).toBe 'info'

    it "informs the user with an error notification on error", ->
      pythonTools.handleJediToolsResponse(
        "error": "this is a test error"
      )
      [notification] = atom.notifications.getNotifications()
      expect(notification.type).toBe 'error'

    it "informs the user with an error notification on invalid type", ->
      pythonTools.handleJediToolsResponse(
        type: "monkeys"
        definitions: [{
            line: 0
            column: 0
        }   ]
      )
      [notification] = atom.notifications.getNotifications()
      expect(notification.type).toBe 'error'
