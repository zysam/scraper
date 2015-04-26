mongoose = require 'mongoose'
Scraper = require './scraper'
Model = require './model'
show = console.log

url = 'http://www.dianping.com/search/category/2/10/g132'
COUNT = 0
PAGES_LIMITS = 50
DB_COUNT = 0

class YoScraper extends Scraper
	constructor : (@url) ->
		COUNT++
		@init()

	init : ->

		@loadWebPage @url,wizard

		@on 'error',@handleErr

		@on 'loaded',@parsePage

		@on 'parsed',@db

		@on 'complete',@complete

	db : (docs) ->
		Model.create docs,(err) =>
			DB_COUNT++
			show '%s db runing.',DB_COUNT
			if err then @emit 'error',err else @emit 'complete'

	complete : ->
		show 'complete website : %s',DB_COUNT
		if DB_COUNT is PAGES_LIMITS
			@exit()

	handleErr : (err) ->
		show 'has some error ,%s',err
		wizard()

	#your cheerio rule.
	parseYourWeb : (html) ->
		$ = @parseLoad html
		docs = []

		#your rule
		#
		#
		
		@emit 'parsed',docs
	exit : ->
		mongoose.disconnect()

generateUrls = (limit) ->
	urls = []
	urls.push url
	urls.push url + 'p' + i for i in [2..limit]

	return urls

Urls = geraterUrls PAGES_LIMITS

wizard = ->
	if !Urls.length
		show 'Run all pages!!'
	else
		url = Urls.shift()
		scraper = new YoScraper url

numberOfParallelRequests = 20
wizard() for i in [1..numberOfParallelRequests]