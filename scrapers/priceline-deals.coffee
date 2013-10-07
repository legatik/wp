Scraper = require('../models/scraper')
moment = require('moment')
querystring = require('querystring')

class PricelineDeals extends Scraper

  constructor: (search) ->
    super
    @id = "priceline-deals"
    @name = "Priceline"
    @requestUrl = "http://www.priceline.com/hotelxd/searchDeals.do"

  translateSearch: (callback) ->
    translatedSearch =
      plf: 'PCLN'
      src: 'RTL_LST_TAB'
      noWait: 'Y'
      cityName: @search.location
      checkInDate: moment(@search.checkInDate, "YYYY-MM-DD").format("MM/DD/YYYY")
      checkOutDate: moment(@search.checkOutDate, "YYYY-MM-DD").format("MM/DD/YYYY")
      numberOfRooms: @search.rooms

    requestOptions =
      uri: "http://www.priceline.com/hotels/"

    @request requestOptions, (res, body) =>
      try
        #get jsk param
        found = body.match /jsk: "([0-9a-z]+)",/

        if not found?
          found =  body.match /jsk=(.+)&/

        [strmatch, jsk] = found

        if not jsk?
          error = new Error("RegExp error triying to obatain the parameter jsk")
          return callback?(error)

        translatedSearch.jsk = jsk
        callback?(null, translatedSearch)
      catch error
        return callback?(error)

  startFetching: (searchOptions, offset, callback) ->
    requestOptions =
      uri: @requestUrl
      qs: searchOptions

    @request requestOptions, (res, body) =>
      try
        [definition, jsonDealData] = body.match(/var dealData = (.+);/)

        if not jsonDealData?
          error = new Error("RegExp error triying to obatain deal data")
          callback?(error)
          return

        dealData = JSON.parse(jsonDealData)
        accommodations = dealData.deals.map (element) ->
          deeplinkQuery =
            hdsk: dealData.hdsk
            dealID: element.id
            dealKey: element.dealKey
            itinKey: dealData.itinKey
            qdp: element.price

          accommodation =
            stars: parseFloat(element.star)
            price: parseFloat(element.price)
            type: 'opaque'
            deeplink: "#{dealData.detailURLBase}&#{querystring.stringify(deeplinkQuery)}"

          if element.score
            rating = parseFloat(element.score)*10
            accommodation.rating = if isNaN(rating) then null else rating
          else
            accommodation.rating = null

          if element.name.indexOf("-") > 0
            [accommodation.name, accommodation.neighborhood] = element.name.split('-').map (element) -> return element.trim()
          else
            accommodation.neighborhood = element.name.trim()
          return accommodation

        callback?(null, accommodations, offset)
        @endFetching()
      catch e
        callback?(e)

module.exports = PricelineDeals