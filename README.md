A set of Jekyll helpers written in bash.

What does this do?
===========

- Helps you in **partial builds** with Jekyll. It picks up the "section" of website that you want to build and generates only that part - making builds faster. This is done because you generally edit a single post - so why regenerate whole site for that?
You can divide website into independent sub-sections. For example- static assets, home page, static pages, posts - posts in different categories.
- Create a new post. Create a new post with your favorite text editor. Front-matter is set automatically.
- Check built website locally, local server powered by Python `SimpleHTTPServer`.
- Deploy generated website to your preferred host.

Setting Up
=========
Set up a new project as given in the `sample-project` with following hierarchy:
```
    - project
	    -- content
		    // your articles and pages, divided in their respective categories
	    -- source
		    // website source code and configuration
		    // _plugins _data _layouts _includes _config _jekyll-helper...
	    -- public
		    // your generated ready to host website
```
In `_jekyll-helper/generator.sh`, edit the following variables:

`projectSource`
	 set your absolute path to project source directory here.
	 example: `projectSource=~/path/to/project-folder/source/`
	 
`yourName`
set the author name here, will be used as author in newly created posts
example: `yourName="Sid Vishnoi"`

`text_editor`
example: `text_editor="subl"`


Give executable permissions to `generator.sh`
`chmod +x generator.sh`

Examples
====
_(running on `sample-project`)_
```
cd ~/path/to/project/sample-project/content/
./..source/_jekyll-helper/generator.sh -f -c cat1/ -c cat4/ -m -s -l
# will clear the public folder, generate cat1 and cat4 articles and pages, create home page, static assets and serve it on localhost:4000 
```
Options
=========
	-h, --help
		Display this help message and exit.
	-n, --new [location]
		create a new file along with a folder if required
		Where 'location' is the enter location where to create file.
	-f, --fresh
		clear the public folder
	-c, --cat [path]
		build a category
		Where 'path' is the path of category.
	-p, --post [path]
		build a specific post
		Where 'path' is the path of post, relative to content dir.
	-s, --static
		build static files
	-m, --main
		build main home page
	-a, --all
		build all
	-l, --local
		serve to local host
	-d, --deploy
		deploy the public folder


Notes
===
This is just a sample script, made to share the ideas how to make the builds efficient. You can create your own, or contribute to make this one better.
This is currently being used on my blog (http://www.hoopsvilla.com).
Tested on Ubuntu 14.04 and 16.04.
Random text for aricles genereated by https://jaspervdj.be/lorem-markdownum/

**Warning:** Use and Edit with caution. Contains `rm -rf` commands.

