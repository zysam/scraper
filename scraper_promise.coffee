http = require 'http'
cheerio = require 'cheerio'
fs = require 'fs'
Model = require './model'
mongoose = require 'mongoose'
STATUS_CODES = http.STATUS_CODES

loadWebPage = (url) ->
	promise = new Promise (resolve,reject) ->
		console.log 'loading : %s',url
		req = http.get url,(res) ->
			body = ''
			if res.statusCode isnt 200
				reject '!200 : %s',STATUS_CODES[res.statusCode]
			res.on 'data',(chunk) ->
				body += chunk
			res.on 'end', ->
				console.log 'body:' + body
				resolve body
		req.on 'error',(err) ->
			reject 'req error : %s',err

parsePage = (html) ->
	promise = new Promise (resolve,reject) ->
		console.log 'parse...'
		$ = cheerio.load html
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

		resolve docs
db = (docs) ->
	promise = new Promise (resolve,reject) ->
		console.log 'db runing...'
		Model.create docs,(err) ->
			if err then reject err else resolve()

readFile = (path) ->
	promise = new Promise (resolve,reject) ->
		console.log 'readding...'
		fs.readFile path,'utf8',(err,data) ->
			if err then reject err else resolve data

writeFile = (path,data) ->
	promise = new Promise (resolve,reject) ->
		console.log 'writing...'
		fs.writeFile path,JSON.stringify(data),(err) ->
			if err then reject err else resolve 'done!'

closeDB = ->
	console.log '\nall run.\nclose db.'
	mongoose.disconnect()

handleErr = (err) ->
	console.log 'has some error : %s',err

generateUrls = (url,prefix,limit) ->
	if typeof prefix is 'number'
		limit = prefix
		prefix = ''
	urls = []
	urls.push url
	urls.push url + prefix + i for i in [2..limit]

	urls

wizard = (Urls) ->
	if !Urls.length then return console.log 'all urls have run.'
	url = Urls.shift()
	promise = new Promise (resolve,reject) ->
		p = loadWebPage url
		#这个做两件事，一个重新开始，一个后面处理
		p.then ->
			wizard(Urls)
		p.then(parsePage).then(db).then(resolve).catch(reject)

#单个例子
opts = {
	host : 'www.dianping.com'
	path : '/search/category/100/10/g132'
	headers : {
  		'User-Agent' : 'Mozilla/5.0 (Windows NT 6.1; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/41.0.2272.101 Safari/537.36'
  	}
}
#url = 'http://www.dianping.com'

loadWebPage(opts)
	.then(parsePage)
	.then(db)
	.catch(handleErr)
	.then(closeDB)

#并发
#Urls = generateUrls url,'p',50
###
numberOfParallelRequests = 5
promises = wizard Urls for i in [2..numberOfParallelRequests]

Promise.all(promises)
	.then closeDB
	.catch (err)->
		wizard(Urls)
		handleErr(err)
###

#
#本地例子
#
###
filepath = './test/gz_movie_p1.html'
destpath = './test/test_promise.json'

readFile(filepath)
	.then (data) ->
		parsePage(data)
	.then (data) ->
		writeFile destpath,data
	.catch handleErr
	.then closeDB
###
















