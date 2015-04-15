mongoose = require 'mongoose'

uri = 'mongodb://localhost:27017/Shops'
mongoose.connect uri
mongoose.connection.on 'error',->
	console.error 'MongoDB Connection Error.Make sure MongoDB is running.'

Shops = new mongoose.Schema 
	shopName : String
	link : String
	pic : String
	addr : String
	cate : Object
	comment : Array
	created : Date

Model = mongoose.model 'Shops',Shops

Shops.pre 'save',(next,done) ->
	prom = Model.findOne({shopName:@link}).exec()

	prom.addErrback (err)->
		console.log 'error'
		done(err)

	prom.then (doc) =>
		if !@created then @created = new Date()

		if doc
			console.log @.shopName + ' has existed! save fail!'
			done()
		else
			next()
module.exports = Model

