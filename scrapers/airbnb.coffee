Scraper = require('../models/scraper')
moment = require('moment')
XMLHttpRequest = require("xmlhttprequest").XMLHttpRequest
querystring = require('querystring')

class Airbnb extends Scraper

  constructor: (search) ->
    super
    @id = "airbnb"
    @name = "airbnb"
    @requestUrl = "https://www.airbnb.com/search/ajax_get_results"

  translateSearch: (callback) ->
    translatedSearch =
      location: @search.location
      checkin: moment(@search.checkInDate, "YYYY-MM-DD").format("MM/DD/YYYY")
      checkout: moment(@search.checkOutDate, "YYYY-MM-DD").format("MM/DD/YYYY")
      gests: @search.parties

    callback?(null, translatedSearch)

  startFetching: (searchOptions, offset, callback) ->
    searchOptions.page = offset+1

    queryString = "#{@requestUrl}?#{querystring.stringify(searchOptions)}"

    self = @
    xhr = new XMLHttpRequest()
    xhr.onreadystatechange = ->
      if @readyState is 4
        try
          jsonBody = JSON.parse(@responseText)

          accommodations = jsonBody.properties.map (property) ->
            accommodation =
              name: property.name
              neighborhood: property.neighborhood?.name
              type: property.room_type?.toLowerCase()
              price: property.price
              thumbnail: property.thumbnail_url
              deeplink: "https://www.airbnb.com/rooms/#{property.id}"
              location: [property.lng, property.lat]

            return accommodation

          if accommodations.length
            callback?(null, accommodations, offset+1)
            self.startFetching(searchOptions, offset+1, callback)
          else
            self.endFetching()
        catch e
          callback?(e)

    xhr.open("GET", queryString)
    xhr.send()

module.exports = Airbnb