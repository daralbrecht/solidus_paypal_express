require 'paypal-sdk-rest'
module Spree
  class Gateway::PayPalExpress < Gateway
    preference :use_new_layout, :boolean, default: true
    preference :client_id, :string
    preference :client_secret, :string
    preference :server, :string, default: 'sandbox'
    preference :landing_page, :string, default: 'Billing'
    preference :logourl, :string, default: ''

    def supports?(source)
      true
    end

    def provider_class
      ::PayPal::SDK::REST
    end

    def provider
      provider_class.set_config(
        mode: preferred_server.present? ? preferred_server : 'sandbox',
        client_id: preferred_client_id,
        client_secret: preferred_client_secret)
      provider_class
    end

    def method_type
      'paypal'
    end

    # amount :: float
    # express_checkout :: Spree::PaypalExpressCheckout
    # gateway_options :: hash
    def authorize(amount, express_checkout, gateway_options={})
      execute_payment(express_checkout)
    end

    # https://developer.paypal.com/docs/classic/api/merchant/DoCapture_API_Operation_NVP/
    # for more information
    def capture(amount_cents, authorization, currency:, **_options)
      authorization = provider::Authorization.find(authorization)
      capture = authorization.capture({
        amount: {
          currency: currency,
          total: sprintf("%0.02f", amount_cents / 100.0) },
        is_final_capture: true })

      build_transaction_response(capture)
    end

    def purchase(amount_cents, express_checkout, **_options)
      execute_payment(express_checkout)
    end

    def credit(credit_cents, transaction_id, originator:, **_options)
      payment = originator.payment
      amount = sprintf("%0.02f", credit_cents / 100.0)

      transaction = provider::Capture.find(payment.transaction_id)
      refund = transaction.refund({
        :amount => {
          :currency => payment.currency,
          :total => amount
        }
      })

      if refund.success?
        payment.source.update_attributes({
          refunded_at: Time.now,
          refund_transaction_id: refund.id,
          state: 'refunded'
        })
      end

      build_transaction_response(refund)
    end

    def execute_payment(express_checkout)
      payment = provider::Payment.find(express_checkout.payment_id)
      payment.execute(payer_id: express_checkout.payer_id)
      build_transaction_response(payment)
    end

    def build_transaction_response(transaction)
      ActiveMerchant::Billing::Response.new(
        transaction.success?,
        transaction.success? ? JSON.pretty_generate(transaction.to_hash) : transaction.error[:message],
        transaction.to_hash,
        authorization: authorization_from_response(transaction),
        test: sandbox?)
    end

    def sandbox?
      self.preferred_server == 'sandbox'
    end

    private

    def authorization_from_response(transaction)
      if transaction.is_a?(provider_class::DataTypes::Payment)
        if transaction.intent == 'authorize'
          transaction.transactions[0].related_resources[0].authorization.id
        elsif transaction.intent =='sale'
          transaction.transactions[0].related_resources[0].sale.id
        end
      else
        transaction.id
      end
    end
  end
end
