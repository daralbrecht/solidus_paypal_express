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
        mode: preferred_server.present? ? preferred_server : "sandbox",
        client_id: preferred_client_id,
        client_secret: preferred_client_secret)
      provider_class
    end

    def auto_capture?
      false
    end

    def method_type
      'paypal'
    end

    # amount :: float
    # express_checkout :: Spree::PaypalExpressCheckout
    # gateway_options :: hash
    def authorize(amount, express_checkout, gateway_options={})
      do_authorize(express_checkout)
    end

    # https://developer.paypal.com/docs/classic/api/merchant/DoCapture_API_Operation_NVP/
    # for more information
    def capture(amount_cents, authorization, currency:, **_options)
      do_capture(amount_cents, authorization, currency)
    end

    # TODO: rebuild this to use paypal-sdk-rest
    def credit(credit_cents, transaction_id, originator:, **_options)
      payment = originator.payment
      amount = credit_cents / 100.0

      refund_type = payment.amount == amount.to_f ? "Full" : "Partial"

      refund_transaction = provider.build_refund_transaction(
        { TransactionID: payment.transaction_id,
          RefundType: refund_type,
          Amount: {
            currencyID: payment.currency,
            value: amount },
          RefundSource: "any" })

      refund_transaction_response = provider.refund_transaction(refund_transaction)

      if refund_transaction_response.success?
        payment.source.update_attributes(
          { refunded_at: Time.now,
            refund_transaction_id: refund_transaction_response.RefundTransactionID,
            state: "refunded",
            refund_type: refund_type
        })
      end

      build_response(
        refund_transaction_response,
        refund_transaction_response.refund_transaction_id)
    end

    def do_authorize(express_checkout)
      payment = provider::Payment.find(express_checkout.payment_id)
      status = payment.execute(payer_id: express_checkout.payer_id)
      build_authorization_response(status, payment)
    end

    def do_capture(amount_cents, authorization, currency)
      authorization = provider::Authorization.find(authorization)
      capture = authorization.capture({
        amount: {
          currency: currency,
          total: amount_cents / 100.0 },
        is_final_capture: true })

      build_capture_response(capture)
    end

    def build_authorization_response(status, payment)
      ActiveMerchant::Billing::Response.new(
        status,
        JSON.pretty_generate(payment.to_hash),
        payment.to_hash,
        authorization: payment.transactions[0].related_resources[0].authorization.id,
        test: sandbox?)
     end

    def build_capture_response(capture)
      ActiveMerchant::Billing::Response.new(
        capture.success?,
        JSON.pretty_generate(capture.to_hash),
        capture.to_hash,
        test: sandbox?)
    end

    def sandbox?
      self.preferred_server == 'sandbox'
    end
  end
end
