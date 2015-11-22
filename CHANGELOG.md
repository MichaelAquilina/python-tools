0.6.7
-----
* Better error handling and logging when something fails in the python handler

0.6.6
-----
* Remove deprecated scrollToTop

0.6.5
-----
* More informative error messages

0.6.4
-----
* Add the following to the default list of windows paths to look up for python
   * C:\\Python27
   * C:\\Python34
   * C:\\Python35
* Fix a nasty bug where the number of tabs open from goto definitions would grow for each command sent
* Python tools is now only run in editors specifically running the python grammar
* Fix an issue where report link would not show on package error
* Improvements to test coverage

0.6.3
-----

* I'll be making an effort to maintain a changelog on each release now so that you guys can actually know what's creeping in with each update.

* From the initial release, a number of minor bug fixes have been released and the package now has some test coverage to prevent breakages.

* Notifications are now displayed when no results are returned by Jedi. If you find something is not acting the way you expect it to, it probably is Jedi failing to find what you're looking for. You should probably post an Issue on their page.

* The README has been updated to explain each feature with a short gif demo .

* A new feature in the form of "Select String" has been added. See the README for a demo.
