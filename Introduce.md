## 一个简单的爬虫习作，以事件来组织代码。

主要受该文章影响。[点我](http://blog.ragingflame.co.za/2014/6/27/using-cheerio-and-mongodb-to-scrape-a-large-website)

---
一个爬虫无非是以下三个过程 ：
载入网页 -> 解析内容 -> 保存数据

再加两个外部事件，错误处理及完成通知。

以事件来说明，是酱子的：

```
		@loadWebPage @url

		@on 'loaded',@parsePage

		@on 'parsed',@db

		@on 'error',@handleErr

		@on 'complete',@complete
```
1.载入网页，直取 node 原生 http.get ;
2.解析内容，这个不能写正则造轮子吧（其实我也不会写）！借用 cheerio 这个变态杀手好了 ;
3.数据保存，写本地就用 fs ，数据库就依赖 mongoose 。

所以 ，主框架 scraper.coffee 如下：
构造器 + 原型函数 

```
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
```
个人模块 bot_test.coffee 
继承主框架 ， 以本地一个 html 来测试 ， 拿大众点评来练手 。

```
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
```
实际上 ， 身为一个合格的爬虫怎能没有并发呢！
正在 bot.coffee 的例子是酱子的：
```
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
		
		#回调这里好 ， 载完网页立即载入 ， loadWebPage 加个 callback
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
		#全部完成后 ， 断开 mongoose ，安静退出 ， 深藏功与名 。
		if DB_COUNT is PAGES_LIMITS
			@exit()
	
	#有错误也不让它结束 ， 爬下个。
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

geraterUrls = (limit) ->
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

```
如有载入网页->解析内容->载入网页 ， 可以再写一个 'init'

另外：
前练习事件写法，无料近论坛有人争论 '事件的自言自语' 是否合适 ， 本人是小白 ， 说得太高深 ，听不进 。 觉得事件写法，有如大白菜之美。

promise 的一点看法：
promise 看来挺高大上 ， 只要写出返回 promise 这种风格函数 ，再用 promise 来组织 。 我拿 mongoose 原生支持 promise 写了两句 。
普通函数有变成 promise 风格的工具 ，这就不好说了。 

以上是我对爬虫 ， 及异步的小小认识