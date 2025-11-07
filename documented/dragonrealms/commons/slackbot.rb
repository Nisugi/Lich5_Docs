module Lich
  module DragonRealms
    # A bot for interacting with Slack API
    # This class handles authentication, user management, and sending messages.
    # @example Creating a SlackBot instance
    #   bot = Lich::DragonRealms::SlackBot.new
    class SlackBot
      # Initializes a new SlackBot instance
      # Sets up the API URL and retrieves the user list.
      # @return [SlackBot]
      def initialize
        @api_url = 'https://slack.com/api/'
        @lnet = (Script.running + Script.hidden).find { |val| val.name == 'lnet' }
        find_token unless authed?(UserVars.slack_token)

        params = { 'token' => UserVars.slack_token }
        res = post('users.list', params)
        @users_list = JSON.parse(res.body)
      end

      # Checks if the provided token is authenticated with Slack
      # @param token [String] The Slack token to verify
      # @return [Boolean] Returns true if authenticated, false otherwise
      # @raise [StandardError] Raises an error if the request fails
      # @example
      #   bot.authed?("xoxb-1234567890")
      def authed?(token)
        params = { 'token' => token }
        res = post('auth.test', params)
        body = JSON.parse(res.body)
        body['ok']
      end

      # Requests a Slack token from a specified lichbot
      # @param lichbot [String] The name of the lichbot to request the token from
      # @return [String, false] Returns the token if found, false otherwise
      # @raise [Timeout::Error] Raises an error if the request times out
      # @example
      #   token = bot.request_token("Quilsilgas")
      def request_token(lichbot)
        ttl = 10
        send_time = Time.now
        @lnet.unique_buffer.push("chat to #{lichbot} RequestSlackToken")
        loop do
          line = get
          pause 0.05
          return false if Time.now - send_time > ttl

          case line
          when /\[Private\]-.*:#{lichbot}: "slack_token: (.*)"/
            msg = Regexp.last_match(1)
            return msg != 'Not Found' ? msg : false
          when /\[server\]: "no user .*/
            return false
          end
        end
      end

      # Attempts to find a valid Slack token from known lichbots
      # Searches through predefined lichbots and updates the UserVars with a valid token if found.
      # @return [void]
      # @example
      #   bot.find_token
      def find_token
        lichbots = %w[Quilsilgas]
        echo 'Looking for a token...'
        return if lichbots.any? do |bot|
          token = request_token(bot)
          authed = authed?(token) if token
          UserVars.slack_token = token if authed
          authed
        end

        echo 'Unable to locate a token :['
        exit
      end

      # Sends a POST request to the Slack API
      # @param method [String] The API method to call
      # @param params [Hash] The parameters to send with the request
      # @return [Net::HTTPResponse] The response from the Slack API
      # @raise [StandardError] Raises an error if the request fails
      # @example
      #   response = bot.post("auth.test", {"token" => "xoxb-1234567890"})
      def post(method, params)
        uri = URI.parse("#{@api_url}#{method}")
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = true
        http.verify_mode = OpenSSL::SSL::VERIFY_NONE
        req = Net::HTTP::Post.new(uri.path)
        req.set_form_data(params)
        http.request(req)
      end

      # Sends a direct message to a specified user
      # @param username [String] The username of the recipient
      # @param message [String] The message to send
      # @return [Net::HTTPResponse] The response from the Slack API
      # @raise [StandardError] Raises an error if the request fails
      # @example
      #   bot.direct_message("john_doe", "Hello, John!")
      def direct_message(username, message)
        dm_channel = get_dm_channel(username)

        params = { 'token' => UserVars.slack_token, 'channel' => dm_channel, 'text' => "#{checkname}: #{message}", 'as_user' => true }
        post('chat.postMessage', params)
      end

      # Retrieves the direct message channel ID for a given username
      # @param username [String] The username to find the DM channel for
      # @return [String] The ID of the DM channel
      # @raise [StandardError] Raises an error if the user is not found
      # @example
      #   channel_id = bot.get_dm_channel("john_doe")
      def get_dm_channel(username)
        user = @users_list['members'].find { |u| u['name'] == username }
        user['id']
      end
    end
  end
end
