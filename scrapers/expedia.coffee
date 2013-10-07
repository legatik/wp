#Expedia Docs: http://developer.ean.com/docs/hotel-list/
#Expedia Application Name: AllTherooms 
#Expedia API Key: s3megh56v2w6ujm6vfvxvs2e 
#Expedia API Shared Secret: FkKX4hTP 
#
# Will link to EAN affiliate site rather than to actual Expedia site

Scraper = require('../models/scraper')
util =    require('util')
moment =  require('moment')
request = require 'request'

class Expedia extends Scraper

  constructor: (search) ->
    super
    @id = "expedia"
    @name = "expedia"
    @requestUrl =     "http://api.ean.com/ean-services/rs/hotel/v3/list"
    @geoRequestUrl =  "http://api.ean.com/ean-services/rs/hotel/v3/geoSearch" # http://developer.ean.com/docs/geo-functions/
    @requiredSearchParameters = 
       minorRev: 26
       cid: 55505
       apiKey: 's3megh56v2w6ujm6vfvxvs2e'

  stop: () ->
    return
       
  translateLocationString: (location) ->
    return location?.replace(/\s-.*/,'')
  
  getDestinationID: (locationString, callback) ->
    requestOptions =
      uri: @geoRequestUrl
      qs:
        destinationString: locationString      

    @addRequiredParametersToQuery(requestOptions.qs)      
    @request requestOptions, (response, body) =>
      try
        jsonBody = JSON.parse body
        
        if(process.env.debug is "TRUE")
          fs = require("fs")
          fs.writeFileSync("expedialocationjson.txt",JSON.stringify(jsonBody, null, '\t') )

        destinationId = jsonBody.LocationInfoResponse.LocationInfos.LocationInfo.destinationId
        callback?(null, destinationId)
        
      catch error
        callback?(error)

  addRequiredParametersToQuery: (query) ->
    return util._extend(query,@requiredSearchParameters)
  
  
  translateSearch: (callback) -> 
    @getDestinationID @search.location, (error, destinationID) =>
      return callback?(error) if error?
      
      translatedSearch =
        locale:                 'en_US'
        currencyCode:           'USD'
        destinationId:          destinationID
        supplierCacheTolerance: 'MED'
        arrivalDate:            moment(@search.checkInDate, "YYYY-MM-DD").format("MM/DD/YY")
        departureDate:          moment(@search.checkOutDate, "YYYY-MM-DD").format("MM/DD/YY")
        room1:                  @search.parties
        numberOfResults:        200
        supplierCacheTolerance: 'MED_ENHANCED'

      @addRequiredParametersToQuery(translatedSearch)
      callback?(null, translatedSearch)

  startFetching: (searchOptions, offset, callback) ->
    requestOptions =
      uri: @requestUrl
      qs: searchOptions

    @request requestOptions, (response, body) =>
      try
        jsonBody = JSON.parse body

        if(process.env.debug is "TRUE")
          fs = require("fs")
          fs.writeFileSync("expediajson.txt",JSON.stringify(jsonBody, null, '\t') )

        accommodations = jsonBody?.HotelListResponse?.HotelList?.HotelSummary.map (hotel)->
          accommodation =
            name:           hotel.name
            neighborhood:   hotel.locationDescription
            price:          hotel.lowRate 
            thumbnail:      "http://media.expedia.com#{hotel.thumbNailUrl}".replace(/_t\.jpg/,'_n.jpg') # t and n stand for "tiny and "normal"
            deeplink:       hotel.deepLink.replace(/&amp;/g, '&') #expedia is html encoding the text
            location:       [hotel.longitude, hotel.latitude]
            type:           'hotel'
            stars:          hotel.hotelRating
            rating:         if hotel.tripAdvisorRating then hotel.tripAdvisorRating * 20 else undefined
          return accommodation
                    
        if jsonBody?.HotelListResponse?.moreResultsAvailable
          callback?(null, accommodations, null)
          nextPageOptions =  
            cacheKey:       jsonBody?.HotelListResponse?.cacheKey
            cacheLocation:  jsonBody?.HotelListResponse?.cacheLocation
          @addRequiredParametersToQuery(nextPageOptions)
          @startFetching(nextPageOptions, null, callback) 
        else
          callback?(null, accommodations, null)
          @endFetching()
      catch error
        callback?(error)

module.exports = Expedia
