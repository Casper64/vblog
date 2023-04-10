module main

import vweb
import vblog
import db.pg
import os
import time

const (
	pages_dir  = os.abs_path('src/templates/pages')
	upload_dir = os.abs_path('uploads')
)

struct App {
	vweb.Context
	vweb.Controller
pub:
	pages_dir  string
	upload_dir string
pub mut:
	db     pg.DB  [vweb_global]
	dev    bool   [vweb_global]
	s_html string
}

fn main() {
	db := pg.connect(user: 'dev', password: 'password', dbname: 'vblog')!
	controllers := vblog.init(db, pages_dir, upload_dir)!

	mut app := &App{
		pages_dir: pages_dir
		upload_dir: upload_dir
		db: db
		controllers: controllers
	}

	app.handle_static('src/static', true)
	vblog.start(mut app, 8080)!
}

['/']
pub fn (mut app App) home() vweb.Result {
	title := 'Home'

	articles := vblog.get_all_articles(mut app.db).filter(it.show == true)

	content := $tmpl('./templates/home.html')
	layout := $tmpl('./templates/layout.html')
	app.s_html = layout
	return app.html(layout)
}

['/articles/:article_id']
pub fn (mut app App) article_page(article_id int) vweb.Result {
	article := vblog.get_article(mut app.db, article_id) or { return app.not_found() }
	if article.show == false {
		return app.not_found()
	}

	title := 'VBlog | ${article.name}'

	content := os.read_file('src/templates/pages/${article_id}.html') or {
		eprintln(err)
		return app.not_found()
	}
	layout := $tmpl('./templates/layout.html')
	app.s_html = layout
	return app.html(layout)
}

// string format function used in templates
pub fn format_time(t_str string) string {
	t := time.parse(t_str) or { return '' }
	return t.md() + 'th'
}
