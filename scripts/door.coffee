# Description:
#   Hubot interface to unlock the front door
#
# Commands:
#   hubot unlock - unlocks the front door.
#   hubot door unlock - unlocks the front door.
#   hubot door register <person's name> - register the most recently tapped card
#
# Configuration:
#   HUBOT_UNLOCK_URL
#   HUBOT_UNLOCK_KEY
#   HUBOT_UNLOCK_ACTION
#   HUBOT_UNLOCK_ANNOUNCE
#   HUBOT_UNLOCK_REGISTERKEY
#
# Author:
#   Detry322

moment = require('moment')

module.exports = (robot) ->

  config = require('hubot-conf')('unlock', robot)

  makeURL = (user) ->
    "#{config('url')}/index.php?key=#{config('key')}&action=#{config('action')}&username=#{user}"

  unlock = (user, res) ->
    robot.http(makeURL(user)).get() (err, response, body) ->
      if err or response.statusCode isnt 200
        res.send "Something went wrong trying to unlock the door"
        return

  register = (name, res) ->
    exp_date = moment().add(2, 'years').format('YYYY-MM-DD')
    data = "first_name=#{name}&last_name=&affiliation=peckbot&exp_date=#{exp_date}&auth_key=#{config('registerkey')}"
    robot.http("#{config('url')}/add_handler.php").post(data) (err, response, body) ->
      if err or response.statusCode isnt 200
        res.send response.statusCode
        res.send "Something went wrong trying to register that user"
        return
      res.send "Added #{name}"
      robot.messageRoom config('announce'), "#{res.message.user.name} added *#{user}*'s card to the door unlock system."

  robot.respond /(door )?unlock/i, (res) ->
    user = res.message.user.name.toLowerCase()
    res.send "Unlocking door..."
    unlock(user, res)

  robot.respond /door register(.*)$/i, (res) ->
    res.send "You are registering the most recently tapped card. Make sure that the most recently tapped card is the person you want to register.\n\nIf you are sure, use `peckbot door actuallyregister <person's name>`"

  robot.respond /door actuallyregister (.+)$/i, (res) ->
    user = res.match[1]
    register(user, res)

  robot.router.post '/unlock/:secret', (req, res) ->
    if req.params.secret == process.env.HUBOT_SCRIPTS_SECRET
      unlock('web', res)
    else
      res.send "That isn't the correct secret"

