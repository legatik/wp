Scraper = require('../models/scraper')
moment = require('moment')
querystring = require('querystring')

class Priceline extends Scraper

  constructor: (search) ->
    super
    @id = "priceline"
    @name = "Priceline"
    @requestUrl = "https://www.priceline.com/smartphone/hotel/hotelsearch.do"

  translateSearch: (callback) ->
    translatedSearch = {}

    translatedSearch.checkindate = moment(@search.checkInDate, "YYYY-MM-DD").format("MM/DD/YYYY")
    translatedSearch.checkoutdate = moment(@search.checkOutDate, "YYYY-MM-DD").format("MM/DD/YYYY")

    requestOptions =
      uri: "http://www.priceline.com/hotels/"

    @request requestOptions, (res, body) =>
      try
        #get jsk and plf params
        found = body.match /jsk: "([0-9a-z]+)",/

        if not found?
          found =  body.match /jsk=(.+)&/

        [strmatch, jsk] = found

        if not jsk?
          error = new Error("RegExp error triying to obatain the parameter jsk")
          return callback?(error)

        translatedSearch.jsk = jsk

        cityQuery =
          jsk: jsk
          'function': 'type_ahead'
          ss: @search.location

        cityQueryOptions =
          qs: cityQuery
          uri: "https://www.priceline.com/smartphone/hotel/citysearch.do"

        #Request city
        @request cityQueryOptions, (res, body) ->
          try
            jsonBody = JSON.parse(body)
            if not jsonBody.tips?.length
              error = new Error(
                  """
                    No city found in priceline
                    statusCode: #{res.statusCode}
                    headers: #{JSON.stringify(res.headers, null, '\t')}
                    body: #{res.body}
                  """
                )
              return callback?(error)
            translatedSearch.cityid = jsonBody.tips[0].pid
          catch error
            return callback?(error)

          #Set harcoded attrs
          translatedSearch.sort = 'popularity'
          translatedSearch.lat = 0
          translatedSearch.lon = 0
          translatedSearch.minStar = 1

          callback?(null, translatedSearch)
      catch error
        return callback?(error)

  startFetching: (searchOptions, offset, callback) ->
    searchOptions.offset = offset

    requestOptions =
      uri: @requestUrl
      qs: searchOptions
      encoding: 'binary'

    @request requestOptions, (res, body) =>
      try
        jsonBody = JSON.parse(body)

        accommodations = jsonBody.hotels.map (element) =>
          if not element.remainingRooms?
            return null
          if element.remainingRooms < @search.rooms
            return null

          deepLinkOptions =
            jsk: searchOptions.jsk
            plf: "PCLH"
            propID: element.pclnHotelID

          accommodation =
            name: element.hotelName
            price: parseFloat(element.merchPrice)
            neighborhood: element.neighborhood
            stars: parseFloat(element.starRating)
            deeplink: "http://www.priceline.com/hotel/hotelOverviewGuide.do?#{querystring.stringify(deepLinkOptions)}"
            thumbnail: element.thumbnailURL
            type: 'hotel'
            location: [element.lon, element.lat]

          if element.overallRatingScore isnt 0
            accommodation.rating = Math.round(parseFloat(element.overallRatingScore)*10)
          else
            accommodation.rating = null
          return accommodation

        accommodations = accommodations.filter (accommodation) ->
          return accommodation?

        if accommodations.length
          callback?(null, accommodations, offset+accommodations.length)
          @startFetching(searchOptions, offset+accommodations.length, callback)
        else
          @endFetching()

      catch error
        callback?(error)

module.exports = Priceline