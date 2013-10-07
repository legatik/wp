Scraper = require('../models/scraper')
querystring = require 'querystring'
cheerio = require 'cheerio'
moment = require 'moment'
request = require 'request'

class Flipkey extends Scraper

  constructor: (search) ->
    super
    @id = "flipkey"
    @name = "flipkey"

  translateSearch: (callback) ->
    checkInDate = moment(@search.checkInDate, 'YYYY-MM-DD')
    checkOutDate = moment(@search.checkOutDate, 'YYYY-MM-DD')
    if checkOutDate < checkInDate
      console.log 'check-out date should be after check-in date!'
      @endFetching()

    else if new moment() > checkInDate
      console.log 'check-in date should be after present moment!'
      @endFetching()

    else
      preRequest =
        qs:
          query: @search.location
        uri: "http://www.flipkey.com/search/autocomplete"
      request preRequest, (err, res, body) ->
          jsonBody = JSON.parse body
          suggestedLocation = jsonBody.suggestions[jsonBody.counts.indexOf Math.max.apply(Math, jsonBody.counts).toString()]
          suggestedData = jsonBody.data[jsonBody.counts.indexOf Math.max.apply(Math, jsonBody.counts).toString()]
          translateSearch =
            "check-in": moment(checkInDate).format('MM/DD/YYYY')
            "check-out": moment(checkOutDate).format('MM/DD/YYYY')

          requestOptions =
              uri: "http://www.flipkey.com/g#{suggestedData}"
              qs: translateSearch

          request requestOptions, (err, res, body) =>
              $ = cheerio.load(body)
              els = $('.popular-child > a')
              if els.length > 0
                el = $('.popular-child > a')[0]
                fullCityPrefix = $(el).attr('href')
                updatedRequestOptions = 
                    uri: "http://www.flipkey.com#{fullCityPrefix}"
                    qs: translateSearch
                callback?(null, updatedRequestOptions) 
              else
                callback?(null, requestOptions) 

  startFetching: (searchOptions, offset, callback) ->
    offset = offset||1
    self = @
    searchOptions.qs.page = offset
    @request searchOptions, (res, body) =>
      try
        $ = cheerio.load(body)
        abc = $('script').filter (index)->
            $(@).text().indexOf('FlipKey.property_information')isnt-1

        text = abc.text()
        dataArray =  JSON.parse(text.substring(text.indexOf('['), text.indexOf(';')))
        page_number = parseFloat text.substring(text.indexOf('total_pages')+13, text.indexOf('total_pages')+16)
        accommodations = dataArray.map (data) ->
          accommodation =
            name:           data.property_name
            neighborhood:   'watch the name'
            price:          parseFloat $(data.display_rate.rate).text().replace(',', '')
            thumbnail:      data.primary_photo
            deeplink:       "http://www.flipkey.com/#{data.url}"
            location:       [data.longitude, data.latitude]
            type:           'apartment rentals'
          return accommodation

        if offset is page_number
          self.endFetching()
        else
          callback?(null, accommodations, offset+1)
          self.startFetching(searchOptions, offset+1, callback)
      catch error
        callback?(error)

module.exports = Flipkey
