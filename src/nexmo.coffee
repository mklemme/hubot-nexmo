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
{Robot,Adapter,TextMessage,User} = require 'hubot'

HTTP    = require "http"
QS      = require "querystring"

class Nexmo extends Adapter

  constructor: (robot) ->
    @sid   = process.env.HUBOT_NEXMO_AUTH_SECRET
    @token = process.env.HUBOT_NEXMO_AUTH_KEY
    @from  = process.env.HUBOT_NEXMO_FROM
    @robot = robot
    super robot
    @robot.logger.info "hubot-nexmo: Adapter loaded."

  run: ->

    # unless @verifyToken
    #   @emit "error", new Error "You must configure the MESSENGER_VERIFY_TOKEN environment variable."
    # unless @accessToken
    #   @emit "error", new Error "You must configure the MESSENGER_ACCESS_TOKEN environment variable."

    self = @

    @robot.router.post "/hubot/sms", (request, response) =>

      response.writeHead 200, 'Content-Type': 'text/plain'
      response.end()

      message = request.body.text
      from = request.body.msisdn
      if from? and message?
        user = @robot.brain.userForId from
        @receive_sms(message, from, user)

    @robot.on "emoteWithEmoji", (data) =>
      @send_sms data.message, data.user.id, true, (error, body) ->
        if error or not body?
          console.log "Error sending emoteWithEmoji"
          console.log error



    @emit "connected"

  send: (envelope, strings...) ->
    user = envelope.user
    message = strings.join "\n"

    @send_sms message, user.id, false, (error, body) ->
      if error or not body?
        console.log "Error sending outbound SMS."
        console.log error

  receive_sms: (body, from, user) ->

    return if body.length is 0
    @receive new TextMessage user, body, 'messageId'

  send_sms: (message, to, unicode, callback) ->

    user = @robot.brain.userForId to

    if unicode
      type = "unicode"
    else
      type = "text"


    console.log(type)

    data = JSON.stringify({
     api_key: @token,
     api_secret: @sid,
     to: to,
     from: @from,
     text: message,
     type: type
    })

    console.log(data)

    @robot.http("https://rest.nexmo.com")
      .path("/sms/json")
      .header("Content-Type","application/json")
      .post(data) (err, res, body) ->
        if err
          console.log("err")
          console.log(err)
          callback err
        else if res.statusCode is 202
          console.log("body: 202")
          console.log(body)
          json = JSON.parse(body)
          callback null, json
        else
          console.log("body")
          console.log body
          json = JSON.parse(body)
          callback null, json

  reply: (envelope, strings...) ->
    console.log("sending: ")
    console.log(strings)
    user = envelope.user
    message = strings.join "\n"

    @send_sms message, user.id, (error, body) ->
      if error or not body?
        console.log "Error sending outbound SMS."
        console.log error

exports.Nexmo = Nexmo

exports.use = (robot) ->
  new Nexmo robot
