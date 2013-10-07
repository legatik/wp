Scraper = require('../models/scraper')
moment = require('moment')
cheerio = require('cheerio')

class Hotwire extends Scraper

  constructor: (search) ->
    super
    @id = "hotwire"
    @name = "hotwire"
    @requestUrl = "http://api.hotwire.com/v1/search/hotel"

  translateSearch: (callback) ->

    translatedSearch =
        apikey: 'vtcsjrc7t3c3t5kd2628b5cq'
        format: "JSON"
        dest: @search.location
        startdate: moment(@search.checkInDate, "YYYY-MM-DD").format("MM/DD/YYYY")
        enddate: moment(@search.checkOutDate, "YYYY-MM-DD").format("MM/DD/YYYY")
        rooms: @search.rooms
        adults: @search.parties
        children: 0
#        hwpos: 'USD'
      callback?(null, translatedSearch)

  startFetching: (searchOptions, offset, callback) ->
    console.log 'start fetching', searchOptions
    searchOptions.pn = offset+1

    requestOptions =
      uri: @requestUrl
      qs: searchOptions

    @request requestOptions, (res, body) =>

      try
        jsonBody = JSON.parse body
        if jsonBody.StatusCode is '0'
          neighborhoods = jsonBody?.MetaData?.HotelMetaData?.Neighborhoods
          accommodations = jsonBody.Result.map (element) ->
            neighborhoodid = element.NeighborhoodId
            curNeighborhood = neighborhoods.filter (e) ->
              e.Id == neighborhoodid
            element =
              deeplink: element.DeepLink
              price: element.TotalPrice
              neighborhood: curNeighborhood[0].Name
              locations: curNeighborhood[0].Centroid

          if accommodations.length
            callback?(null, accommodations, offset+1)
            @endFetching()
          else
            console.log 'there are no results on fetching with these parameters'
            @endFetching()
        else
          console.log jsonBody.Errors
          @endFetching()
      catch error
        callback?(error)



module.exports = Hotwire
