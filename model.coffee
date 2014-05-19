mongoose = require 'mongoose'

ObjectId = mongoose.Schema.Types.ObjectId
Schema = mongoose.Schema

data = new Schema
  links : Array
  
Model = mongoose.model 'Data', data



module.exports = Model
