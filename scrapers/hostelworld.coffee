Scraper = require('../models/scraper')
moment = require('moment')
cheerio = require('cheerio')
currencies = require('../currencies')

class Hostelworld extends Scraper

  constructor: (search) ->
    super
    @id = "hostelworld"
    @name = "hostelworld"
    @preRequestUrl = "http://www.hostelworld.com/index/keywordsuggestions"
    @requestUrl = "http://www.hostelworld.com/search"

  translateSearch: (callback) ->
    checkInDate = moment(@search.checkInDate, 'YYYY-MM-DD')
    checkOutDate = moment(@search.checkOutDate, 'YYYY-MM-DD')

    query =
      date_from: checkInDate.format('DD+MMM+YYYY')
      NumNights: checkOutDate.diff(checkInDate, 'days')
      search_keywords: @search.location
      home_search_predictive: 1
      number_of_guests: @search.parties
      group_type: ''
      age_ranges: ''

    requestOptions =
      qs: query
      uri: "http://www.hostelworld.com/index/suggestionslist"

    @request requestOptions, (res, body) ->
      try
        if body?.length > 0
          lines = body.split("\n")
          suggestedLocations = lines[1].split('|')
          search_keywords = suggestedLocations[0]
      catch e
        callback?(e)
        return

      translatedSearch =
        action: 'search'
        search_property_id: ''
        search_from_suggestion: 0
        searchkeywords: ''
        reset: 1
        search_type: 'predictive'
        search_keywords: search_keywords
        country: ''
        city: ''
        guests: query.number_of_guests
        group_type: ''
        date_from: query.date_from
        NumNights: query.NumNights
        'prop_type%5B%5D': ['HOSTEL','GUESTHOUSE','HOTEL','APARTMENT','CAMPSITE']

      callback?(null, translatedSearch)

  startFetching: (searchOptions, offset, callback) ->
    requestOptions =
      uri: @preRequestUrl
      qs: searchOptions

    @request requestOptions, (res, body) =>
      try
        $ = cheerio.load(body)
        list = body.match(/\$\.currency\.list.*$/m)
        currencyList = JSON.parse(list[0].match(/\{.*\}\}/))

        ajaxKey = $('#jsnResKey').val()

        requestOptions =
          uri: "http://www.hostelworld.com/static/js/1.22.1.0/properties-ajax-#{ajaxKey}"

        @request requestOptions, (res, body)->
          return if @stopped
          jsonBody = JSON.parse(body)
          price = 0

          accommodations = jsonBody.data.map (element) ->
            try
               currency = element.c
               price = parseFloat(element.dpr)
               if not price
                 price = parseFloat(element.ppr)
               if currency isnt 'USD'
                 originalPrice = price
                 price = currencies.getUSDvalue(price, currency)
                 #unsupported conversion from our service
                 #try converting with own hostelworld provided data
                 if not price?
                   toEUR = currencyList[currency].toEUR
                   toUSD = currencyList.USD.fromEUR
                   price = (originalPrice/toEUR)/toUSD
            catch e
              callback?(e)

            if price is 0
              error = new Error("Couldn't correctly evaluate prices for hostelworld! Sorry...")
              callback?(error)

            rating = JSON.stringify(element.rt)
            if rating?.length
              rating = rating.replace('%','')
            else
              rating = null

            accommodation =
              name: element.nm
              stars: 0
              price: price
              rating: rating
              type: element.tp?.toLowerCase()
              deeplink: element.url
              thumbnail: element.img

            location =
              lng: parseFloat(element.lng)
              lat: parseFloat(element.lat)
            if not isNaN(location.lng) and not isNaN(location.lat)
              accommodation.location = [location.lng, location.lat]

            return accommodation

          callback?(null, accommodations, offset)
      catch e
        callback?(e)

module.exports = Hostelworld