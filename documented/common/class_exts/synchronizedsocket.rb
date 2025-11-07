# Carve out from lich.rbw
# extension to SynchronizedSocket class 2024-06-13

module Lich
  module Common
    # Represents a thread-safe wrapper around a socket.
    # This class ensures that socket operations are synchronized using a mutex.
    # @example Creating a synchronized socket
    #   socket = SynchronizedSocket.new(original_socket)
    class SynchronizedSocket
      # Initializes a new SynchronizedSocket instance.
      # @param o [Object] The socket object to be synchronized.
      # @return [SynchronizedSocket] The new instance of SynchronizedSocket.
      def initialize(o)
        @delegate = o
        @mutex = Mutex.new
        # self # removed by robocop, needs broad testing
      end

      # Outputs a string to the socket.
      # @param args [*Object] The arguments to be sent to the socket.
      # @param block [Proc] An optional block to be executed.
      # @return [nil] Returns nil after outputting.
      # @example Sending a message to the socket
      #   socket.puts("Hello, World!")
      def puts(*args, &block)
        @mutex.synchronize {
          @delegate.puts(*args, &block)
        }
      end

      # Conditionally outputs a string to the socket based on a block's return value.
      # @param args [*Object] The arguments to be sent to the socket if the condition is true.
      # @return [Boolean] Returns true if the message was sent, false otherwise.
      # @example Conditionally sending a message
      #   socket.puts_if("Hello, World!") { true }
      def puts_if(*args)
        @mutex.synchronize {
          if yield
            @delegate.puts(*args)
            return true
          else
            return false
          end
        }
      end

      # Writes data to the socket.
      # @param args [*Object] The arguments to be sent to the socket.
      # @param block [Proc] An optional block to be executed.
      # @return [nil] Returns nil after writing.
      # @example Writing data to the socket
      #   socket.write("Data to send")
      def write(*args, &block)
        @mutex.synchronize {
          @delegate.write(*args, &block)
        }
      end

      # Handles calls to methods that are not defined in this class.
      # @param method [Symbol] The name of the method being called.
      # @param args [*Object] The arguments passed to the method.
      # @param block [Proc] An optional block to be executed.
      # @return [Object] Returns the result of the method call on the delegate.
      # @note This method delegates calls to the underlying socket object.
      def method_missing(method, *args, &block)
        @delegate.__send__ method, *args, &block
      end
    end
  end
end
