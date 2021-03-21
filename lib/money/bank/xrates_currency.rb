require 'money'
require 'money/rates_store/rate_removal_support'
require 'open-uri'

class Money
  module Bank
    # Raised when there is an unexpected error in extracting exchange rates
    # from XRates Finance Calculator
    class XratesCurrencyFetchError < Error
    end

    class XratesCurrency < Money::Bank::VariableExchange
      SERVICE_HOST = 'x-rates.com'.freeze
      SERVICE_PATH = '/calculator'.freeze

      # @return [Hash] Stores the currently known rates.
      attr_reader :rates

      class << self
        # @return [Integer] Returns the Time To Live (TTL) in seconds.
        attr_reader :ttl_in_seconds

        # @return [Time] Returns the time when the rates expire.
        attr_reader :rates_expiration

        ##
        # Set the Time To Live (TTL) in seconds.
        #
        # @param [Integer] the seconds between an expiration and another.
        def ttl_in_seconds=(value)
          @ttl_in_seconds = value
          refresh_rates_expiration! if ttl_in_seconds
        end

        ##
        # Set the rates expiration TTL seconds from the current time.
        #
        # @return [Time] The next expiration.
        def refresh_rates_expiration!
          @rates_expiration = Time.now + ttl_in_seconds
        end
      end

      def initialize(*)
        super
        @store.extend Money::RatesStore::RateRemovalSupport
      end

      ##
      # Clears all rates stored in @rates
      #
      # @return [Hash] The empty @rates Hash.
      #
      # @example
      #   @bank = XratesCurrency.new  #=> <Money::Bank::XratesCurrency...>
      #   @bank.get_rate(:USD, :EUR)  #=> 0.776337241
      #   @bank.flush_rates           #=> {}
      def flush_rates
        store.clear_rates
      end

      ##
      # Clears the specified rate stored in @rates.
      #
      # @param [String, Symbol, Currency] from Currency to convert from (used
      #   for key into @rates).
      # @param [String, Symbol, Currency] to Currency to convert to (used for
      #   key into @rates).
      #
      # @return [Float] The flushed rate.
      #
      # @example
      #   @bank = XratesCurrency.new    #=> <Money::Bank::XratesCurrency...>
      #   @bank.get_rate(:USD, :EUR)    #=> 0.776337241
      #   @bank.flush_rate(:USD, :EUR)  #=> 0.776337241
      def flush_rate(from, to)
        store.remove_rate(from, to)
      end

      ##
      # Returns the requested rate.
      #
      # It also flushes all the rates when and if they are expired.
      #
      # @param [String, Symbol, Currency] from Currency to convert from
      # @param [String, Symbol, Currency] to Currency to convert to
      #
      # @return [Float] The requested rate.
      #
      # @example
      #   @bank = XratesCurrency.new  #=> <Money::Bank::XratesCurrency...>
      #   @bank.get_rate(:USD, :EUR)  #=> 0.776337241
      def get_rate(from, to)
        expire_rates
        store.get_rate(from, to) || store.add_rate(from, to, fetch_rate(from, to))
      end

      ##
      # Flushes all the rates if they are expired.
      #
      # @return [Boolean]
      def expire_rates
        if self.class.ttl_in_seconds && self.class.rates_expiration <= Time.now
          flush_rates
          self.class.refresh_rates_expiration!
          true
        else
          false
        end
      end

      private

      ##
      # Queries for the requested rate and returns it.
      #
      # @param [String, Symbol, Currency] from Currency to convert from
      # @param [String, Symbol, Currency] to Currency to convert to
      #
      # @return [BigDecimal] The requested rate.
      def fetch_rate(from, to)
        from = Currency.wrap(from)
        to = Currency.wrap(to)

        data = build_uri(from, to).read
        rate = extract_rate(data)

        rate = 1 / extract_rate(build_uri(to, from).read) if rate < 0.1

        rate
      end

      ##
      # Build a URI for the given arguments.
      #
      # @param [Currency] from The currency to convert from.
      # @param [Currency] to The currency to convert to.
      #
      # @return [URI::HTTP]
      def build_uri(from, to)
        uri = URI::HTTPS.build(
          host: SERVICE_HOST,
          path: SERVICE_PATH,
          query: "from=#{from.iso_code}&to=#{to.iso_code}&amount=1"
        )
      end

      ##
      # Takes the response from XRates and extract the rate.
      #
      # @param [String] data The x-rate string to decode.
      #
      # @return [BigDecimal]
      def extract_rate(data)
        case data
        when %r{<span class=bld>(\d+\.?\d*) [A-Z]{3}</span>}
          BigDecimal(Regexp.last_match(1))
        when /Could not convert\./
          raise UnknownRate
        when /<span class="ccOutputRslt">(\d+\.?\d*)</
          BigDecimal(Regexp.last_match(1))
        else
          raise XrateCurrencyFetchError
        end
      end
    end
  end
end
