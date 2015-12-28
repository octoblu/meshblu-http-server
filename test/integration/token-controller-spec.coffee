_ = require 'lodash'
request = require 'request'
Server = require '../../src/server'
async      = require 'async'
redis      = require 'redis'
RedisNS    = require '@octoblu/redis-ns'
JobManager = require 'meshblu-core-job-manager'

describe 'DELETE /devices/:uuid/tokens/query', ->
  beforeEach (done) ->
    @port = 0xd00d
    @sut = new Server
      port: @port
      disableLogging: true
      jobTimeoutSeconds: 1
      namespace: 'meshblu:server:http:test'

    @sut.run done

  afterEach (done) ->
    @sut.stop => done()

  beforeEach ->
    @redis = _.bindAll new RedisNS 'meshblu:server:http:test', redis.createClient()
    @jobManager = new JobManager client: @redis, timeoutSeconds: 1

  context 'when the request is successful', ->
    beforeEach ->
      async.forever (next) =>
        @jobManager.getRequest ['request'], (error, @request) =>
          next @request
          return unless @request?

          response =
            metadata:
              code: 204
              responseId: @request.metadata.responseId
              name: 'dinosaur-getter'

          @jobManager.createResponse 'response', response

    beforeEach (done) ->
      options =
        auth:
          username: 'irritable-captian'
          password: 'poop-deck'
        json: true
        qs:
          type: 'dinosaur'

      request.del "http://localhost:#{@port}/devices/:uuid/tokens", options, (error, @response, @body) =>
        done error

    it 'should return a 204', ->
      expect(@response.statusCode).to.equal 204

    it 'should dispatch the correct metadata', ->
      expect(@request).to.containSubset
        metadata:
          fromUuid: 'irritable-captian'
          auth:
            uuid: 'irritable-captian'
            token: 'poop-deck'

    it 'should send the search body as the data of the job', ->
      data = JSON.parse @request.rawData
      expect(data).to.containSubset type: 'dinosaur'
