#Require http module
http = require('http')

#Export module
currencies = module.exports

allCurrencies = [
  {code: "CAD", symbol: "$", usd: null}
  {code: "COP", symbol: "$", usd: null}
  {code: "EUR", symbol: "€", usd: null}
  {code: "GBP", symbol: "£", usd: null}
]

#Retrieves the value for a particular currency if another has been supplied
currencies.getUSDvalue = (value, originCurrency) ->
  for c in allCurrencies
    if c.code == originCurrency
      return value / c.usd

#Updates all currencies. Gets and sets each currency USD value
currencies.updateAll = ->
  requestOptions =
    host: "www.google.com"
    path: null
    headers: [{"accept": "json"}]

  allCurrencies.forEach (currency) ->
    requestOptions.path = "/ig/calculator?hl=en&q=1USD=?#{currency.code}"
    http.get requestOptions, (res) ->
      res.setEncoding('utf8')

      res.on 'data', (data) ->
        data = eval("(#{data})")
        currency.usd = parseFloat(data.rhs.match(/([0-9]|\.)/g).join(""))

setInterval(
  currencies.updateAll
  1000*60*60*6
)

currencies.updateAll()
