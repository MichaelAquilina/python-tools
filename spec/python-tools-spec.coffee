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
          SELECT * FROM foo
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

    it "selects double-line double qoutes correctly", ->
        editor.setCursorBufferPosition(new Point(4, 15))
        pythonTools.selectAllString()
        expect(editor.getSelectedBufferRange()).toEqual(new Range(
            new Point(3, 18),
            new Point(7, 2),
          )
        )

    it "selects double-line single qoutes correctly", ->
        editor.setCursorBufferPosition(new Point(9, 15))
        pythonTools.selectAllString()
        expect(editor.getSelectedBufferRange()).toEqual(new Range(
            new Point(8, 19),
            new Point(10, 2),
          )
        )

  describe "when a response is returned from tools.py", ->
    it "correctly deserializes JSON", ->
      pythonTools.handleJsonResponse('''{
        "type": "usages",
        "definitions": {
          "line": 0, "column": 0, "path": "foo.py", "name": "bar"
        }
      }''')

    it "informs the user with an info notification when no items were found", ->
      pythonTools.handleJediToolsResponse(
        type: "usages"
        definitions: []
      )
      [notification] = atom.notifications.getNotifications()
      expect(notification.type).toBe 'info'

    it "informs the user with an error notifiation on invalid type", ->
      pythonTools.handleJediToolsResponse(
        type: "monkeys"
        definitions: [{
            line: 0
            column: 0
        }   ]
      )
      [notification] = atom.notifications.getNotifications()
      expect(notification.type).toBe 'error'
