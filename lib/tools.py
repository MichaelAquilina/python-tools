import os
import io
import sys
import json
import traceback

# Load jedi library included with this package
sys.path.append(os.path.dirname(__file__))
import jedi


class JediTools(object):
    def __init__(self):
        self.default_sys_path = sys.path
        self._input = io.open(sys.stdin.fileno(), encoding='utf-8')

    @classmethod
    def _get_top_level_module(cls, path):
        """Recursively walk through directories looking for top level module.

        Jedi will use current filepath to look for another modules at same path,
        but it will not be able to see modules **above**, so our goal
        is to find the higher python module available from filepath.
        """
        _path, _ = os.path.split(path)
        if os.path.isfile(os.path.join(_path, '__init__.py')):
            return cls._get_top_level_module(_path)
        return path

    def _serialize(self, usages):
        _usages = []
        for usage in usages:
            _usages.append({
                'full_name': usage.full_name,
                'name': usage.name,
                'line': usage.line,
                'column': usage.column,
            })
        return json.dumps(_usages)

    def _process_request(self, request):
        request = json.loads(request)

        path = self._get_top_level_module(request.get('path', ''))
        if path not in sys.path:
            sys.path.insert(0, path)
        try:
            script = jedi.api.Script(
                source=request['source'], line=request['line'] + 1,
                column=request['column'], path=request.get('path', ''))
            usages = script.usages()
        except KeyError:
            usages = []
        except Exception:
            with open('error.log', 'wa') as fp:
                traceback.print_exc(file=fp)
            usages = []
        self._write_response(self._serialize(usages))

    def _write_response(self, response):
        sys.stdout.write(response + '\n')
        sys.stdout.flush()

    def watch(self):
        while True:
            try:
                data = self._input.readline()
                self._process_request(data)
            except Exception:
                with open('error.log', 'wa') as fp:
                    traceback.print_exc(file=fp)

if __name__ == '__main__':
    JediTools().watch()
