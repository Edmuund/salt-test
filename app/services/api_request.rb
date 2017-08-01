# handles third-party API integration
module ApiRequest
  module Resource
    require 'single_request'

    class Customer < SingleRequest
      def initialize(email)
        @email = email
      end

      def create
        url        = 'https://www.saltedge.com/api/v3/customers/'
        action     = :post
        headers    = {}
        parameters = { data: { identifier: @email } }
        SingleRequest.new(url, action, headers, parameters).run
        return SingleRequest.error unless SingleRequest.error.nil?
        { customer_id:     SingleRequest.response['id'],
          customer_secret: SingleRequest.response['secret'] }
      end
    end

    class Login < SingleRequest
      class << self
        attr_accessor :stage
      end

      def initialize(current_user, params: { login: {} }, existing_login: false, secret: nil)
        @customer_secret = current_user.customer_secret
        @username        = params[:login][:username]
        @password        = params[:login][:pass]
        @existing_login  = existing_login
        @secret          = secret
      end

      def create
        Login.stage = 'Creating login ...'
        url         = 'https://www.saltedge.com/api/v3/login/'
        action      = :post
        headers     = { 'customer-secret' => @customer_secret }
        parameters  = { data: { country_code:  'XF',
                                provider_code: 'fakebank_simple_xf',
                                fetch_type:    'recent',
                                credentials: { login:    @username,
                                               password: @password } } }
        SingleRequest.new(url, action, headers, parameters).run
        return SingleRequest.error unless SingleRequest.error.nil?
        @secret = SingleRequest.response['secret']
        return SingleRequest.error unless show_login
        return @login_attributes unless login_attributes
        return SingleRequest.error unless fetch_accounts && fetch_transactions
        Login.stage = 'Finishing ...'
        @login_attributes
      end

      def reconnect
        Login.stage = 'Reconnecting ...'
        url         = 'https://www.saltedge.com/api/v3/login/reconnect'
        action      = :put
        headers     = { 'customer-secret' => @customer_secret,
                        'login-secret'    => @secret }
        parameters  = { data: { credentials: { login:    @username,
                                               password: @password } } }
        SingleRequest.new(url, action, headers, parameters).run
        return SingleRequest.error unless SingleRequest.error.nil? && show_login
        return @login_attributes unless login_attributes
        return SingleRequest.error unless fetch_accounts && fetch_transactions
        Login.stage = 'Finishing ...'
        @login_attributes
      end

      def refresh
        url        = 'https://www.saltedge.com/api/v3/login/refresh'
        action     = :put
        headers    = { 'customer-secret' => @customer_secret,
                       'login-secret'    => @secret }
        parameters = { data: { fetch_type: 'recent' } }
        SingleRequest.new(url, action, headers, parameters).run
        return SingleRequest.error unless SingleRequest.error.nil? && show_login
        return @login_attributes unless login_attributes
        return SingleRequest.error unless fetch_accounts && fetch_transactions
        @login_attributes
      end

      def destroy
        url        = 'https://www.saltedge.com/api/v3/login'
        action     = :delete
        headers    = { 'customer-secret' => @customer_secret,
                       'login-secret'    => @existing_login.secret }
        parameters = {}
        SingleRequest.new(url, action, headers, parameters).run
        return SingleRequest.error unless SingleRequest.error.nil?
        SingleRequest.response['id']
      end

      private

      def show_login
        url        = 'https://www.saltedge.com/api/v3/login/'
        action     = :get
        headers    = { 'customer-secret' => @customer_secret,
                       'login-secret'    => @secret }
        parameters = {}
        SingleRequest.new(url, action, headers, parameters).run
        return false unless SingleRequest.error.nil?
        while SingleRequest.response['next_refresh_possible_at'].nil?
          SingleRequest.new(url, action, headers, parameters).run
          break if SingleRequest.response['last_attempt']['last_stage']['name'] == 'finish' &&
                   SingleRequest.response['last_attempt']['fail_message']
        end
        true
      end

      def login_attributes
        @login_attributes = { id:           SingleRequest.response['id'],
                              secret:       SingleRequest.response['secret'],
                              provider:     SingleRequest.response['provider_name'],
                              country:      SingleRequest.response['country_code'],
                              status:       SingleRequest.response['status'],
                              error:        SingleRequest.response['last_attempt']['fail_message'],
                              created_at:   Time.parse(SingleRequest.response['created_at']),
                              updated_at:   Time.parse(SingleRequest.response['updated_at']),
                              accounts_attributes: [] }
        return false unless @login_attributes[:status] == 'active'
        @login_attributes[:next_refresh] = Time.parse(SingleRequest.response['next_refresh_possible_at'])
      end

      def fetch_accounts
        Login.stage = 'Fetching accounts ...'
        url        = 'https://www.saltedge.com/api/v3/accounts'
        action     = :get
        headers    = { 'customer-secret' => @customer_secret,
                       'login-secret'    => @secret }
        parameters = {}
        SingleRequest.new(url, action, headers, parameters).run
        return false unless SingleRequest.error.nil?

        SingleRequest.response.each do |account|
          account = { identifier:       account['id'],
                      currency:         account['currency_code'],
                      name:             account['name'],
                      nature:           account['nature'],
                      balance:          account['balance'],
                      iban:             account['extra']['iban'],
                      cards:            account['extra']['cards'].to_s,
                      swift:            account['extra']['swift'],
                      client_name:      account['extra']['client_name'],
                      account_name:     account['extra']['account_name'],
                      account_number:   account['extra']['account_number'],
                      available_amount: account['extra']['available_amount'],
                      credit_limit:     account['extra']['credit_limit'],
                      posted:           account['extra']['transactions_count']['posted'],
                      pending:          account['extra']['transactions_count']['pending'],
                      created_at:       Time.parse(account['created_at']),
                      updated_at:       Time.parse(account['updated_at']),
                      transactions_attributes: [] }
          existing_account = false
          existing_account = @existing_login.accounts.find_by(identifier: account[:identifier]) if @existing_login
          account[:id] = existing_account.id if existing_account
          @login_attributes[:accounts_attributes] << account
        end
      end

      def fetch_transactions
        Login.stage = 'Fetching transactions ...'
        url        = 'https://www.saltedge.com/api/v3/transactions'
        action     = :get
        headers    = { 'customer-secret' => @customer_secret,
                       'login-secret'    => @secret }
        parameters = {}
        SingleRequest.new(url, action, headers, parameters).run
        return false unless SingleRequest.error.nil?
        transactions = SingleRequest.response
        return false unless fetch_pending
        transactions.concat(SingleRequest.response)

        transactions.each do |transaction|
          account = @login_attributes[:accounts_attributes].find { |acc| acc[:identifier] == transaction['account_id'] }
          transaction = { identifier:                transaction['id'],
                          category:                  transaction['category'],
                          currency:                  transaction['currency_code'],
                          amount:                    transaction['amount'],
                          description:               transaction['description'],
                          account_balance_snapshot:  transaction['extra']['account_balance_snapshot'],
                          categorization_confidence: transaction['extra']['categorization_confidence'],
                          made_on:                   transaction['made_on'],
                          mode:                      transaction['mode'],
                          duplicated:                transaction['duplicated'],
                          status:                    transaction['status'],
                          created_at:                Time.parse(transaction['created_at']),
                          updated_at:                Time.parse(transaction['updated_at']) }
          existing_transaction = false
          existing_transaction = @existing_login.transactions.find_by(identifier: transaction[:identifier]) if @existing_login
          transaction[:id] = existing_transaction.id if existing_transaction
          account[:transactions_attributes] << transaction
        end
      end

      def fetch_pending
        if @existing_login
          pending = @existing_login.transactions.select { |t| t.status == 'pending' }
          pending.each(&:delete)
        end
        url        = 'https://www.saltedge.com/api/v3/transactions/pending'
        action     = :get
        headers    = { 'customer-secret' => @customer_secret,
                       'login-secret'    => @secret }
        parameters = {}
        SingleRequest.new(url, action, headers, parameters).run
        return false unless SingleRequest.error.nil?
        true
      end
    end
  end
end