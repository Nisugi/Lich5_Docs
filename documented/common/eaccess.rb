require "openssl"
require "socket"
require_relative 'account'

module Lich
  # Provides common functionality for the Lich project
  #
  # This module contains methods for handling SSL connections and authentication.
  # @example Using the EAccess module
  #   Lich::Common::EAccess.auth(password: "my_password", account: "my_account")
  module Common
    # Handles EAccess related operations
    #
    # This module provides methods for downloading and verifying PEM files, as well as authenticating users.
    # @example Authenticating a user
    #   Lich::Common::EAccess.auth(password: "password", account: "account_name")
    module EAccess
      # The path to the PEM file used for SSL connections.
      PEM = File.join(DATA_DIR, "simu.pem")
      # pp PEM
      # The size of packets to read from the connection.
      PACKET_SIZE = 8192

      # Checks if the PEM file exists
      # @return [Boolean] true if the PEM file exists, false otherwise
      # @example Checking for PEM existence
      #   exists = Lich::Common::EAccess.pem_exist?
      def self.pem_exist?
        File.exist? PEM
      end

      # Downloads the PEM file from the specified hostname and port
      # @param hostname [String] The hostname to connect to (default: "eaccess.play.net")
      # @param port [Integer] The port to connect to (default: 7910)
      # @return [void]
      # @raise [StandardError] if the connection fails
      # @example Downloading the PEM file
      #   Lich::Common::EAccess.download_pem
      def self.download_pem(hostname = "eaccess.play.net", port = 7910)
        # Create an OpenSSL context
        ctx = OpenSSL::SSL::SSLContext.new
        # Get remote TCP socket
        sock = TCPSocket.new(hostname, port)
        # pass that socket to OpenSSL
        ssl = OpenSSL::SSL::SSLSocket.new(sock, ctx)
        # establish connection, if possible
        ssl.connect
        # write the .pem to disk
        File.write(EAccess::PEM, ssl.peer_cert)
      end

      # Verifies the PEM certificate against the stored PEM file
      # @param conn [OpenSSL::SSL::SSLSocket] The SSL connection to verify
      # @return [Boolean] true if the certificate matches, false otherwise
      # @raise [StandardError] if the certificate does not match and download fails
      # @example Verifying a PEM certificate
      #   Lich::Common::EAccess.verify_pem(conn)
      def self.verify_pem(conn)
        # return if conn.peer_cert.to_s = File.read(EAccess::PEM)
        if !(conn.peer_cert.to_s == File.read(EAccess::PEM))
          Lich.log "Exception, \nssl peer certificate did not match #{EAccess::PEM}\nwas:\n#{conn.peer_cert}"
          download_pem
        else
          return true
        end
        #     fail Exception, "\nssl peer certificate did not match #{EAccess::PEM}\nwas:\n#{conn.peer_cert}"
      end

      # Establishes a secure socket connection to the specified hostname and port
      # @param hostname [String] The hostname to connect to (default: "eaccess.play.net")
      # @param port [Integer] The port to connect to (default: 7910)
      # @return [OpenSSL::SSL::SSLSocket] The established SSL socket
      # @raise [StandardError] if the PEM verification fails
      # @example Creating a secure socket
      #   ssl_socket = Lich::Common::EAccess.socket
      def self.socket(hostname = "eaccess.play.net", port = 7910)
        download_pem unless pem_exist?
        socket = TCPSocket.open(hostname, port)
        cert_store              = OpenSSL::X509::Store.new
        ssl_context             = OpenSSL::SSL::SSLContext.new
        ssl_context.cert_store  = cert_store
        ssl_context.verify_mode = OpenSSL::SSL::VERIFY_PEER
        cert_store.add_file(EAccess::PEM) if pem_exist?
        ssl_socket = OpenSSL::SSL::SSLSocket.new(socket, ssl_context)
        ssl_socket.sync_close = true
        EAccess.verify_pem(ssl_socket.connect)
        return ssl_socket
      end

      # Authenticates a user with the given credentials
      # @param password [String] The user's password
      # @param account [String] The user's account name
      # @param character [String, nil] The character name (optional)
      # @param game_code [String, nil] The game code (optional)
      # @param legacy [Boolean] Whether to use legacy authentication (default: false)
      # @return [String, Array<Hash>] An error message or an array of login information
      # @raise [StandardError] if authentication fails
      # @example Authenticating a user
      #   login_info = Lich::Common::EAccess.auth(password: "password", account: "account_name")
      def self.auth(password:, account:, character: nil, game_code: nil, legacy: false)
        Account.name = account
        Account.game_code = game_code
        Account.character = character
        conn = EAccess.socket()
        # it is vitally important to verify self-signed certs
        # because there is no chain-of-trust for them
        EAccess.verify_pem(conn)
        conn.puts "K\n"
        hashkey = EAccess.read(conn)
        # pp "hash=%s" % hashkey
        password = password.split('').map { |c| c.getbyte(0) }
        hashkey = hashkey.split('').map { |c| c.getbyte(0) }
        password.each_index { |i| password[i] = ((password[i] - 32) ^ hashkey[i]) + 32 }
        password = password.map { |c| c.chr }.join
        conn.puts "A\t#{account}\t#{password}\n"
        response = EAccess.read(conn)
        unless /KEY\t(?<key>.*)\t/.match(response)
          eaccess_error = "Error(%s)" % response.split(/\s+/).last
          return eaccess_error
        end
        # pp "A:response=%s" % response
        conn.puts "M\n"
        response = EAccess.read(conn)
        fail StandardError, response unless response =~ /^M\t/
        # pp "M:response=%s" % response

        unless legacy
          conn.puts "F\t#{game_code}\n"
          response = EAccess.read(conn)
          fail StandardError, response unless response =~ /NORMAL|PREMIUM|TRIAL|INTERNAL|FREE/
          Account.subscription = response
          # pp "F:response=%s" % response
          conn.puts "G\t#{game_code}\n"
          EAccess.read(conn)
          # pp "G:response=%s" % response
          conn.puts "P\t#{game_code}\n"
          EAccess.read(conn)
          # pp "P:response=%s" % response
          conn.puts "C\n"
          response = EAccess.read(conn)
          # pp "C:response=%s" % response
          Account.members = response
          char_code = response.sub(/^C\t[0-9]+\t[0-9]+\t[0-9]+\t[0-9]+[\t\n]/, '')
                              .scan(/[^\t]+\t[^\t^\n]+/)
                              .find { |c| c.split("\t")[1] == character }
                              .split("\t")[0]
          conn.puts "L\t#{char_code}\tSTORM\n"
          response = EAccess.read(conn)
          fail StandardError, response unless response =~ /^L\t/
          # pp "L:response=%s" % response
          conn.close unless conn.closed?
          login_info = Hash[response.sub(/^L\tOK\t/, '')
                                    .split("\t")
                                    .map { |kv|
                              k, v = kv.split("=")
                              [k.downcase, v]
                            }]
        else
          login_info = Array.new
          for game in response.sub(/^M\t/, '').scan(/[^\t]+\t[^\t^\n]+/)
            game_code, game_name = game.split("\t")
            # pp "M:response = %s" % response
            conn.puts "N\t#{game_code}\n"
            response = EAccess.read(conn)
            if response =~ /STORM/
              conn.puts "F\t#{game_code}\n"
              response = EAccess.read(conn)
              if response =~ /NORMAL|PREMIUM|TRIAL|INTERNAL|FREE/
                Account.subscription = response
                conn.puts "G\t#{game_code}\n"
                EAccess.read(conn)
                conn.puts "P\t#{game_code}\n"
                EAccess.read(conn)
                conn.puts "C\n"
                response = EAccess.read(conn)
                Account.members = response
                for code_name in response.sub(/^C\t[0-9]+\t[0-9]+\t[0-9]+\t[0-9]+[\t\n]/, '').scan(/[^\t]+\t[^\t^\n]+/)
                  char_code, char_name = code_name.split("\t")
                  hash = { :game_code => "#{game_code}", :game_name => "#{game_name}",
                          :char_code => "#{char_code}", :char_name => "#{char_name}" }
                  login_info.push(hash)
                end
              end
            end
          end
        end
        conn.close unless conn.closed?
        return login_info
      end

      # Reads data from the connection
      # @param conn [TCPSocket] The connection to read from
      # @return [String] The data read from the connection
      # @example Reading data from a connection
      #   data = Lich::Common::EAccess.read(conn)
      def self.read(conn)
        conn.sysread(PACKET_SIZE)
      end
    end
  end
end
