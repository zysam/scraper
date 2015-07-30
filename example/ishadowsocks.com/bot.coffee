fs = require 'fs'
Scraper = require '../../lib/'
config = require './data/ssConfig.json'
show = console.log

class Bot extends Scraper
	constructor : (@path,@destpath) ->
		@init()

	init : ->
		show 'Runing ...'

		@loadWebPage @path

		@on 'error',@handleErr

		@on 'loaded',@parse

		@on 'parsed',@write

		@on 'complete',@complete

	write : (data) ->
		data = JSON.stringify data
		fs.writeFile @destpath,data,(err) =>
			if err then @emit 'error', err else @emit 'complete'

	#your cheerio rule and change @on 'parsed'
	parse : (html) ->
		$ = @parseLoad html
		docs = []
		#your rule
		$('#free .container').each (i, elem) ->
			$('.col-lg-4',@).each (i, elem) ->
				obj = {}
				server =$('h4',@).eq(0).text().split(":")
				obj.server = server[1]
				show 'eq(0) %s', obj.server
				obj.server_port = $('h4',@).eq(1).text().split(":")[1]
				show 'eq(1) %s', obj.server_port
				obj.password = $('h4',@).eq(2).text().split(":")[1]
				show 'eq(2) %s', obj.password
				obj.method = $('h4',@).eq(3).text().split(":")[1]
				show 'eq(3) %s', obj.method
				obj.remarks = server[0]
				show 'eq(4) %s', obj.remarks
				docs.push obj

		config.configs = docs
		@emit 'parsed', config

url = 'http://www.ishadowsocks.com/'
destpath = './data/gui-config.json'
realpath = 'D:\\Program Files\\shadowsocks\\gui-config.json'
bot = new Bot(url, realpath)
