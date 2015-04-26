
fs = require 'fs'
Scraper = require './scraper'
show = console.log

class Tscraper extends Scraper
	constructor : (@path,@destpath) ->
		@init2Test()

	init2Test : ->
		show ' test...'

		@read2Test @path

		@on 'error',@handleErr

		@on 'loaded',@parsePage

		@on 'parsed',@write2Test

		@on 'complete',@complete

	read2Test : (path) ->
		fs.readFile path,{encoding:'utf8'},(err,data) =>
			show 'reading file.'
			if err then @emit 'error',err else @emit 'loaded',data

	write2Test : (data) ->
		data = JSON.stringify data
		fs.writeFile @destpath,data,(err) =>
			if err then @emit 'error',err else @emit 'complete'

	#your cheerio rule and change @on 'parsed'
	parseYour : (html) ->
		$ = @parseLoad html
		docs = []

		#your rule
		#
		#
		@emit 'parsed',docs

filepath = './test/gz_movie_p1.html'
destpath = './test/test_gz_movie.json'

scraper = new Tscraper filepath,destpath

