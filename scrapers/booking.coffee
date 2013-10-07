Scraper = require('../models/scraper')
querystring = require('querystring')
cheerio = require('cheerio')

class Booking extends Scraper

  constructor: (search) ->
    super
    @id = "booking"
    @name = "Booking"
    @requestUrl = "http://www.booking.com/searchresults.html"

  affiliateTrack: (link) ->
    return "#{link}&aid=363764"
  
  translateSearch: (callback) ->
    translatedSearch = {}

    #Request form
    requestOptions =
      uri: "http://www.booking.com/index.html"

    console.log(requestOptions) if process.env.debug is 'TRUE'
    @request requestOptions, (response, body) =>
      try
        $ = cheerio.load(body)
        form = $('#frm')
        translatedSearch.src =        form.find("input[name=src]").attr("value")
        translatedSearch.nflt =       form.find("input[name=nflt]").attr("value")
        translatedSearch.error_url =  form.find("input[name=error_url]").attr("value")
        translatedSearch.dcid =       form.find("input[name=dcid]").attr("value")
        translatedSearch.sid =        form.find("input[name=sid]").attr("value")
        translatedSearch.si =         form.find("input[name=si]").attr("value")
        translatedSearch.aid =        $("input[name=aid]").attr("value")
        translatedSearch.dest_type =  "city"

        [checkInYear, checkInMonth, checkInDay] = @search.checkInDate.split("-")
        [checkOutYear, checkOutMonth, checkOutDay] = @search.checkOutDate.split("-")

        translatedSearch.checkin_monthday = checkInDay
        translatedSearch.checkin_year_month = checkInYear+"-"+checkInMonth
        translatedSearch.checkout_monthday = checkOutDay
        translatedSearch.checkout_year_month = checkOutYear+"-"+checkOutMonth
      catch e
        callback?(e)
        return

      #Request city
      cityQuery =
        lang: "en"
        sid: translatedSearch.sid
        aid: translatedSearch.aid
        term: @search.location.split(",")[0].trim()

      cityQueryOptions=
        qs: cityQuery
        uri: "http://www.booking.com/autocomplete"

      console.log(cityQueryOptions) if process.env.debug is 'TRUE'
      @request cityQueryOptions, (response, body) =>
        try
          jsonBody = JSON.parse(body)

          if not jsonBody.city?.length
            error = new Error(
              """
                No city found in booking
                statusCode: #{response.statusCode}
                headers: #{JSON.stringify(response.headers, null, '\t')}
                body: #{response.body}
              """
            )
            callback?(error)
            return

          translatedSearch.dest_id = jsonBody.city[0].dest_id
        catch e
          callback?(e)
          return

        translatedSearch.selected_currency = 'USD'
        translatedSearch.rows = 50
        translatedSearch.in_a_group = 'on'
        translatedSearch.org_nr_rooms =  @search.rooms
        translatedSearch.org_nr_adults =  @search.parties
        translatedSearch.org_nr_children = 0

        remain = @search.parties % @search.rooms
        eachRoom = (@search.parties - remain) / @search.rooms

        for i in [0...@search.rooms]
          add = 0
          if remain isnt 0
            add++
            remain--

        translatedSearch.group =
          group_adults: eachRoom + add
          group_children: 0

        callback?(null, translatedSearch)

  startFetching: (searchOptions, offset, callback) ->
    searchOptions.offset = offset

    requestOptions =
      uri: "#{@requestUrl}?#{querystring.stringify(searchOptions)}"

    console.log(requestOptions) if process.env.debug is 'TRUE'
    @request requestOptions, (response, body) =>
      try
        $ = cheerio.load(body)
        accommodations = $('div.flash_deal_soldout').map (index, element) =>
          element = $(element)
          accommodation = {}
          rating = element.find("span.average").text()
          if rating?.length
            accommodation.rating = parseFloat(rating.trim())*10 #format: 8.2, 5.7...
          else
            accommodation.rating = null
          accommodation.type = 'hotel'
            
          accommodation.stars = parseFloat(element.attr("data-stars"))
          accommodation.name = element.find("a.hotel_name_link").text().trim()
          accommodation.deeplink = @affiliateTrack( 'http://www.booking.com' + element.find("a.hotel_name_link").attr("href") )
          accommodation.thumbnail = element.find('.sr_item_photo img.hotel').attr('src')

          location = element.find('.address a.show_map').attr('data-coords')?.split(',')
          if location?.length is 2
            location[0] = parseFloat(location[0])
            location[1] = parseFloat(location[1])
            accommodation.location = location

          neighborhood = element.find("div.address").find("a[rel=200]").text()
          if neighborhood!=""
            accommodation.neighborhood = neighborhood.replace(new RegExp(" map$"),'')
              .replace(new RegExp("^[0-9]+\. "),'').trim()
          accommodation.price = element.find("div.total").find("strong").find("span").text().replace("US$",'').replace("$",'').replace(",",'.')
            .trim()

          if accommodation.price is ''
            accommodation.price = element.find("strong.price").text().replace("US$",'').replace("$",'').replace(",",'.')
              .trim()

          accommodation.price = parseFloat(accommodation.price)
          return accommodation

        if accommodations.length
          callback?(null, accommodations, offset+accommodations.length)
          @startFetching(searchOptions, offset+accommodations.length, callback)
        else
          @endFetching()
      catch e
        callback?(e)
        return

module.exports = Booking
