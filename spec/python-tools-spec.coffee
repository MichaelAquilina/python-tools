PythonTools = require '../lib/python-tools'

describe "PythonTools", ->
  pythonTools = null
  beforeEach ->
    waitsForPromise ->
      atom.packages.activatePackage('python-tools')
    runs ->
      pythonTools = atom.packages.getActivePackage('python-tools').mainModule

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
