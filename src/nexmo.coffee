# Description:
#   An adapter for Plivo (sms service)
#
# Dependencies:
#   "hubot": "2"
#
# Configuration:
#   HUBOT_NEXO_AUTH_KEY    | Your Nexmo auth key.
#   HUBOT_NEXO_AUTH_SECRET | Your Nexmo auth secret.
#   HUBOT_NEXO_FROM        | Your purchased Nexmo phone number
#
# Commands:
#   hubot <trigger> - <what the respond trigger does>
#   <trigger> - <what the hear trigger does>
#
# Notes:
#   <optional notes required for the script>
#
# Author:
#   Myk Klemme (@mklemme)
#
try
  {Robot,Adapter,TextMessage,User} = require 'hubot'
catch
  prequire = require('parent-require')
  {Robot,Adapter,TextMessage,User} = prequire 'hubot'

HTTP    = require "http"
QS      = require "querystring"

class Nexmo extends Adapter

  constructor: (robot) ->
    @sid   = process.env.HUBOT_NEXMO_AUTH_SECRET
    @token = process.env.HUBOT_NEXMO_AUTH_KEY
    @from  = process.env.HUBOT_NEXMO_FROM
    @robot = robot
    super robot
    # @robot.logger.info "Constructor"

  run: ->
    self = @

    @robot.router.post "/hubot/sms", (request, response) =>
      console.log(request.body)

      response.writeHead 200, 'Content-Type': 'text/plain'
      response.end()

      message = request.body.text
      from = request.body.msisdn
      if from? and message?

        user = @robot.brain.userForId from
        @receive_sms(message, from, user)

        @robot.emit "sms:received", {
          from : from,
          message: message,
          user: user
        }

  send: (envelope, strings...) ->
    @robot.logger.info "Send"

  receive_sms: (body, from, user) ->

    return if body.length is 0
    console.log("got it!")
    @receive new TextMessage user, body, 'messageId'

  send_sms: (message, to, callback) ->

    user = @robot.brain.userForId to

    data = JSON.stringify({
     api_key: @token,
     api_secret: @sid,
     to: to,
     from: @from,
     text: message
    })

    @robot.http("https://rest.nexmo.com")
      .path("/sms/json")
      .header("Content-Type","application/json")
      .post(data) (err, res, body) ->
        if err
          console.log(err)
          callback err
        else if res.statusCode is 202
          console.log(body)
          json = JSON.parse(body)
          callback null, json
        else
          console.log body
          json = JSON.parse(body)
          callback json

      @robot.emit "sms:sent", {
        from: @from,
        to: to,
        message: message,
        user: user
      }

  reply: (envelope, strings...) ->
    @robot.logger.info "Reply"

exports.Nexmo = Nexmo

exports.use = (robot) ->
  new Nexmo robot
