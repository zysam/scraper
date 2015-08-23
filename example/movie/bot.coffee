fs = require 'fs'
iconv = require 'iconv-lite'
Scraper = require '../../lib/'
#config = require './data/'
#movie = require './model/movie'
#
show = console.log

class Sis extends Scraper
	constructor : (@path,@destpath) ->
		#@init()

	init : ->
		show 'Runing ...'

		@read @path,'gbk'

		@on 'loaded',@parse

		@on 'parsed',@write

		@on 'complete',@complete

		@on 'error',@handleErr

	read : (path, opt) ->
		opt = opt or false
		console.log 'reading file...'
		fs.readFile path, (err, data) =>
			if opt
				data = iconv.decode(data, opt)
			#data = iconv.encode(data,'utf8')
			#show 'data: ' + data
			if err then @emit 'error',err else @emit 'loaded', data
	write : (data) ->
		data = JSON.stringify data
		fs.writeFile @destpath,data,(err) =>
			if err then @emit 'error', err else @emit 'complete'

	#your cheerio rule and change @on 'parsed'
	parse : (html) ->
		show 'parse ...'
		#show 'html :' + html
		$ = @parseLoad html
		docs = []
		#your rule
		$('body #wrapper div div.mainbox form table').eq(3).each (i, elem) ->
			#show 'i: ' + i
			#if i is 3
			$('tbody',@).each (i, elem) ->
				obj = 
					type : []
					name : ''
					url : ''
					size : ''

				obj.type[0] = $('th em a',@).text()
				obj.type[1] = $('th em a',@).attr('href')
				show 'type %s', obj.type.join('\t')

				obj.name = $('th span a',@).text()
				obj.url = $('th span a',@).attr('href')
				show 'name %s', obj.name.join('\t')

				obj.size = $('td.nums',@).eq(1).text().split('\t')[0]
				show 'size %s', obj.size

				docs.push obj

		@emit 'parsed', docs

class Sis002 extends Sis
	init: ->
		super()

	parse: (html) ->
		show 'Sis002 parse ...'
		$ = @parseLoad html
		docs = []

		$('.postmessage.defaultpost').eq(0).each (i, e) ->
			obj = 
				name : ''
				imagesUrls : []
				content : ''
				torrent : ''

			that = $('div',@)
			#show 'h2:' + $('h2',@).text()
			#content = that.text()
			#show 'content: ' + that.eq(2).text()
			#obj.content = that.eq(2).text()

			that.eq(2).each (i, e) ->
				#show 'i:' + i
				obj.content = $(@).text()
				$('img',@).each (i, e) ->
					obj.imagesUrls.push $(@).attr('src')
					show 'iUrls:' + obj.imagesUrls[i]

			that.eq(3).each (i, e) ->
				obj.name = $('dl dt a',@).eq(1).text().split('@')[2]
				show 'name: ' + obj.name
				obj.torrent = $('dl dt a',@).eq(1).attr('href')
				show 'torrent: ' + obj.torrent 
			docs.push obj

		@emit 'parsed', docs

###
url = './test/wIndex.html'
destpath = './data/wIndex.json'
sis001 = new Sis(url, destpath)
sis001.init()
###
url = './test/01.html'
destpath = './data/sis002.json'
sis002 = new Sis002(url, destpath)
sis002.init()


