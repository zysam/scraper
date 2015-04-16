
EventEmitter = require('events').EventEmitter
cheerio = require 'cheerio'
http = require 'http'

STATUS_CODES = http.STATUS_CODES
show = console.log

class Scraper extends EventEmitter
	constructor : (@url) ->

	###
	init : ->
		@loadWebPage @url

		@on 'error',@handleErr

		@on 'loaded',@parsePage

		@on 'parsed',@db

		@on 'complete',@complete
	###

	loadWebPage : (opts,fn) ->
		fn = fn or ->
		if typeof opts is 'string'
			show 'Loading ' + opts
		else
			show 'Loading ' + opts.host + opts.path

		req = http.get opts,(res) =>
			body = ''
			if res.statusCode isnt 200
				@emit 'error',STATUS_CODES[res.statusCode]

			res.on 'data',(chunk) ->
				body += chunk

			res.on 'end', =>
				@emit 'loaded',body
				fn()
			return
		req.on 'error',(err) =>
			@emit 'error',err
		return

	parseLoad : (html) ->
		cheerio.load html

	parsePage : (html) ->
		show 'parse...'
		$ = @parseLoad html
		docs = []

		$('#shop-all-list ul li')
			.each (i,elem) ->
				model = new Object 
					shopName : ''
					link : ''
					pic : ''
					addr : ''
					cate : 
						life : new Array
						buss : new Array
					comment : new Array
					
				#console.log 'i:%s',i
				#console.log i + ':' + $('.txt .tag-addr span',@).text()
				model.shopName = $('.txt .tit a',@).attr('title')
				model.link = $('.txt .tit a',@).attr('href')
				model.pic = $('.pic a img',@).attr('data-src')
				
				$('.txt .tag-addr',@)
					.each (i,elem) ->
						model.addr = $('.addr',@).text()
						model.cate.life.push $('a span',@).eq(0).text(),$('a',@).eq(0).attr('href')
						model.cate.buss.push $('a span',@).eq(1).text(),$('a',@).eq(1).attr('href')

				model.comment.push $('.txt .comment span',@).attr('title')

				$('.txt .comment a',@)
					.each (i,elem) ->
						model.comment.push $(@).children().text()
				docs.push model

		@emit 'parsed',docs

	handleErr : (err) ->
		show 'has some error ,%s',err

	complete : ->
		show 'all have done!!'

module.exports = Scraper

