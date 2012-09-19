requirejs.vim
=============

Simple vim plugin that allows 'gt' in javascript files that include dependencies with require.js

This the first vim plugin i created. Recommendations for improvements most welcome.

Install and Use
---------------
To install, copy the javascript file into vim's ftplugin folder.

To use it, open a file with require.js define/require instructions, move the
cursor either over the filename-string or the name of a module and press gt and
the module's file will be opened in a new tab.

How it works
------------
The script scans your current workingdirectory recursively for a
requirejs.config statement, gets the baseUrl and paths configs.

When you perform a gt, the module will be found using the baseUrl and paths (if
exist).

Todos
-----
* make sure that we are in a file with require.js instructions (define,
  require)
* save map for each buffer
* update map after creating new dependency


