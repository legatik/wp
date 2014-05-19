mongoose = require 'mongoose'
Data = require './model'

module.exports =
	models: {Data}
	connection:
		connect: () ->
			db = mongoose.connect "mongodb://localhost/wape"
		disconnect: () ->
		Types: mongoose.Types
