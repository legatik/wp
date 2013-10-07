request = require('request')

class Scraper
  constructor: (search) -> #Must be implemented on subclass. Call super at the beginning.
    @search = search #Don't assign on subclass
    @cookieJar = request.jar(arguments.callee) #Don't assign on subclass
    @stopped = false #Don't assign on subclass
    #assign @id and @name on subclass
    #@id must be the filename, and @name a readable name to be printed

  translateSearch: (callback) ->
    #Must be implemented on subclass.
    #Must call callback as follows: callback(error, translatedSearch)
    #translatedSearch is the translated search object. Don't modify the @search property.

  startFetching: (searchOptions, offset, callback) ->
    #Must be implemented on subclass.
    #The first argument is the translated search object.
    #The second argument is the offset which the scraper must start fetching from
    #The third argument is a callback
    #Must call callback as follows: callback(error, accommodations, newOffset)
    #Play with offset and newOffset executing this method recursively to do pagination
    #When pagination finishes, call the @endFetching() method

  request: (requestOptions, callback) -> #Don't implement on subclass. Use this function for http requests on subclass.
    requestOptions.jar?= @cookieJar
    requestOptions.followAllRedirects?= true
    requestOptions.headers?= {}
    requestOptions.encoding?= "utf8"
    requestOptions.headers["User-Agent"]?= "Mozilla/5.0 (X11; Linux i686) AppleWebKit/537.22 (KHTML, like Gecko) Ubuntu Chromium/25.0.1364.160 Chrome/25.0.1364.160 Safari/537.22"

    request requestOptions, (error, res, body) =>
      return console.log(error, error.stack) if error?

      if res.statusCode >= 400 && res.statusCode < 500
        error = new Error(
            """
              http client error from scraper with id: @id
              status code: #{res.statusCode}
              headers: #{JSON.stringify(res.headers, null, '\t')}
              body: #{body}
            """
          )
        return console.error(error)
      else if res.statusCode >= 500 && res.statusCode < 600
        error = new Error(
            """
              http server error from scraper with id: @id
              status code: #{res.statusCode}
              headers: #{JSON.stringify(res.headers, null, '\t')}
              body: #{body}
            """
          )
        return console.error(error)

      callback?(res, body)

  fetch: (offset = 0) -> #Don't implement on subclass
    console.log("#{@id} scraper start fetching from offset #{offset} at #{(new Date()).toString()}\n")

    @translateSearch (error, searchOptions) =>
      return console.error(error) if error?

      @startFetching searchOptions, offset, (error, accommodations, offset) =>
        return console.error(error) if error?
        console.log("#{@id} scraper fetched offset #{offset} at #{(new Date()).toString()}. #{accommodations.length} results:\n")
        console.log(JSON.stringify(accommodations, null, '\t'))

  endFetching: -> #Don't implement on subclass. Call inside the @startFecthing method on the last recursion when finish paginating.
    console.log("#{@id} scraper ended fetching at #{(new Date()).toString()}\n")

module.exports = Scraper

