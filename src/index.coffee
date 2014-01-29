express = require 'express'
loadJsonFiles = require './load_json_files'
lumber = require 'clumber'
{pick} = require 'underscore'
{Responder} = require './responder'
Dsl = require './dsl'

class MockApiServer
  constructor: (@options) ->
    @logger = @_initLogger()

  start: (done) ->
    @logger.info '[STARTING-SERVER]'

    @app = express()
    @app.use @_cannedResponses
    loadJsonFiles 'test/mock-api', (err, hash) =>
      @responder = new Responder hash
      @server = @app.listen @options.port, done
 
  stop: ->
    @logger.info '[STOPPING-SERVER]'
    @server.close()

  respondTo: (args...) ->
    new Dsl @_addResponseSpecification, args

  _addResponseSpecification: (spec) =>
    @responder = @responder.withResponseSpecification spec

  _initLogger: () ->
    transports = []
    transports.push new lumber.transports.Console if @options.logToConsole

    if @options.logToFile?
      transports.push new lumber.transports.File
        filename: @options.logToFile
        level: 'info'

    new lumber.Logger(transports: transports)
 
  _cannedResponses: (req, res, next) =>
    request = pick req, 'method', 'path', 'query'
    @logger.info '[MOCK-REQUEST]', request
    response = @responder.respondTo request
    return next() if response == undefined
    @logger.info '[MOCK-RESPONSE]', response
    res.header 'Content-Type', 'application/json'
    res.send JSON.stringify response
 
module.exports = (options, cb) ->
  server = new MockApiServer options
  server.start (err) ->
    return unless cb?
    cb err, server
