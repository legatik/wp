Scraper = require('../models/scraper')
querystring = require 'querystring'
cheerio = require 'cheerio'
moment = require 'moment'
request = require 'request'


class Jetsetter extends Scraper


  constructor: (search) ->
    super
    @id = "jetsetter"
    @name = "jetsetter"

  translateSearch: (callback) ->
    checkOutDate = moment(@search.checkOutDate, 'YYYY-MM-DD')
    checkInDate = moment(@search.checkInDate, 'YYYY-MM-DD')
    location = @search.location.replace(" ","%20")
    guests = @search.parties
    @timeStay = (checkOutDate - checkInDate)/3600000
    if checkOutDate < checkInDate
      console.log 'check-out date should be after check-in date!'
      @endFetching()
    else
      checkInDate = moment(@search.checkInDate).format("YYYYMMDD")
      checkOutDate = moment(@search.checkOutDate).format("YYYYMMDD")
      data =
        term: @search.location
        selector:
          paginator:
            limit:5
            offset:0
          ordering:
            field: "relevance"
        includeSuggestedTerms:true
        numOccupants: guests
        propertyTypeFilter: "All"
        tokenType: "autocomplete"
        resultTypes: ["property", "tag"]
        priceRangeFilter:
          min: 0
          max: null
        numRooms: @search.rooms
        dateCriterion: [
          checkin: checkInDate
          checkout: checkOutDate
        ]
        facets: []
      callback?(null,data)
  startFetching: (searchOptions, offset, callback) ->
    self = @
    offset = offset||1
    self.offset = offset*5 -5
    self.accommodationArr=[]
    self.checkArr=[]
    searchOptions.selector.paginator.offset = self.offset
    requestUrl = "http://www.jetsetter.com/api-proxy/v3/SearchService/searchProperties/PropertySearchCriteria/"
    eSearchOptions =escape(JSON.stringify(searchOptions))
    preRequest =
      uri: "http://agency.pegast.ru/samo5/export/default.php?samo_action=reference&oauth_token=fb021bef5a6b206c9969316693bcde3d&laststamp=0x0000000000000000&delstamp=0x00000000020b2874&type=hotel"
    request.get preRequest, (err, res, body) ->
       console.log "asd",body
#      body = JSON.parse(body)
#      infoArr = body.data.specArray
#      lengInfoArr = infoArr.length
#      if lengInfoArr > 0
#        accommodations = infoArr.map (data, i) ->
#          locationArr = [data.latitude,data.longitude]
#          accommodation = {
#                name:data.title,
#                neighborhood:data.shortLocation
#                thumbnail:"img",
#                deeplink:"http://www.jetsetter.com/"+data.jsUrl,
#                type:data.type,
#                location:locationArr
#           }
##           preRequest =
##             uri: accommodation.deeplink
##           request preRequest, (err, res, body) ->
##             $ = cheerio.load(body)
##             screenGallery = $('#screen-gallery')
##             imgUrl = $(screenGallery).find(".selected > img").attr("src")
##             imgUrl = imgUrl.replace("//","")
##             accommodation.thumbnail = imgUrl
#           if(!data.eventSpec)then data.eventSpec = {id : 0}
#           preRequest =
#             headers:
#               apikey:"1a9d6ce2d9ed102f9ff495096f141429"
#             uri: "http://www.jetsetter.com/api-proxy/v3/ProductService/getPricingByTrip/checkin/"+searchOptions.dateCriterion[0].checkin+"/checkout/"+searchOptions.dateCriterion[0].checkout+"/propertyId/"+data.id+"/eventId/"+data.eventSpec.id+"/numRooms/"+searchOptions.numRooms+""
#           request preRequest, (err, res, body) ->
#             body = JSON.parse(body)
#             if body.data[0]
#               accommodation.price = body.data[0].discountedSubtotal
#             else
#               accommodation.price = ""
#             collectItems(accommodation,i,lengInfoArr,offset)
#           return accommodation
#      else
#        self.endFetching()
#    collectItems = (data,i,length,offset) =>
#      self.checkArr.push(i)
#      if(data)
#        self.accommodationArr.push(data)
#      if self.checkArr.length is length
#        callback?(null, self.accommodationArr, offset+1)
#        self.startFetching(searchOptions, offset+1, callback)
module.exports = Jetsetter

