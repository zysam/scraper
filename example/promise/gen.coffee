"use strict"

http = require 'http'
fs = require 'fs'
co = require 'co'
parallel = require 'co-parallel'

STATUS_CODES = http.STATUS_CODES

getHeader = (url) ->
  new Promise (resolve,reject) ->
    #console.log 'loading : %s',url
    http.get url,(res) ->
      body = ''
      if res.statusCode is 200 or res.statusCode is 302
        return resolve res
      else
        return reject '!200 : ' + STATUS_CODES[res.statusCode]
    .on 'error', (err) -> reject err.toString()

#url = 'http://api.np.mobilem.360.cn/redirect/down/?zhidian_api&appid=9347?app_info=514953?app_info=3.4.4'
Urls = []
do ->
  for i in [1..4]
    Urls.push 'http://www.baidu.com'
    Urls.push 'http://google.com'

status = (url) ->
  try
    res = yield getHeader url
    status = res.statusCode
  catch e
    console.log e
    status = 404

  console.log '%s,%s', url, status
  return [url, status]

co ->
  #res = yield  getHeader url
  reqs = Urls.map status
  ret = yield parallel reqs, 10
  console.log ret

#.catch (e) -> console.log '[err]' + e

