module Spree
  class PaypalController < StoreController

    # This is the entry point for after being redirected from the cart
    # payment page.
    def express
      order = current_order || raise(ActiveRecord::RecordNotFound)
      items = order.line_items.map(&method(:line_item)).compact

      additional_adjustments = order.all_adjustments.additional
      tax_adjustments = additional_adjustments.tax
      shipping_adjustments = additional_adjustments.shipping

      # TODO: change code below when you figure out how adjustments works
      additional_adjustments.eligible.each do |adjustment|
        next if (tax_adjustments + shipping_adjustments).include?(adjustment)
        items << { name: adjustment.label,
                   price: sprintf( "%0.02f", adjustment.amount),
                   currency: order.currency,
                   quantity: 1 }
      end
      unless order.shipment_total.zero?
        items << { name: 'Shipment',
                   price: sprintf( "%0.02f", order.shipment_total),
                   currency: order.currency,
                   quantity: 1 }
      end

      payment = build_paypal_payment(order, items)

      begin
        if payment.create
          redirect_to  payment.links.find{|v| v.method == "REDIRECT" }.href
        else
          flash[:error] = Spree.t('flash.generic_error', scope: 'paypal', reasons: payment.error[:details].map(&:issue).join(' '))
          redirect_to checkout_state_path(:payment)
        end
      rescue SocketError
        flash[:error] = Spree.t('flash.connection_failed', scope: 'paypal')
        redirect_to checkout_state_path(:payment)
      end
    end

    # This is the entry point for PayPal after the user has completed payment
    # on the hosted payment page within PayPal's domain.
    def confirm
      order = current_order || raise(ActiveRecord::RecordNotFound)
      order.payments.create!(
        {
          source: Spree::PaypalExpressCheckout.create(
            {
              token: params[:token],
              payer_id: params[:PayerID],
              payment_id: params[:paymentId]
            }
          ),
          amount: sprintf( "%0.02f", order.total),
          payment_method: payment_method
        }
      )
      order.next
      if order.complete?
        flash.notice = Spree.t(:order_processed_successfully)
        flash[:order_completed] = true
        session[:order_id] = nil
        redirect_to completion_route(order)
      else
        redirect_to checkout_state_path(order.state)
      end
    end

    def cancel
      flash[:notice] = Spree.t('flash.cancel', scope: 'paypal')
      order = current_order || raise(ActiveRecord::RecordNotFound)
      redirect_to checkout_state_path(order.state, paypal_cancel_token: params[:token])
    end

    private

    def line_item(item)
      # Because PayPal doesn't accept $0 items at all.
      # See #10
      # https://cms.paypal.com/uk/cgi-bin/?cmd=_render-content&content_ID=developer/e_howto_api_ECCustomizing
      # "It can be a positive or negative value but not zero."
      unless item.price.zero?
        {
          name: item.product.name,
          sku: item.variant.sku,
          price: sprintf( "%0.02f", item.price),
          currency: item.order.currency,
          quantity: item.quantity
        }
      end
    end

    def build_paypal_payment(order, items)
      provider::Payment.new({
        intent: payment_method.auto_capture? ? 'sale' : 'authorize',
        payer: {
          payment_method: "paypal" },
        redirect_urls: {
          return_url: confirm_paypal_url(payment_method_id: params[:payment_method_id], utm_nooverride: 1),
          cancel_url: cancel_paypal_url},
        transactions: payment_details(items)
      })
    end

    def payment_method
      Spree::PaymentMethod.find(params[:payment_method_id])
    end

    def provider
      payment_method.provider
    end

    def payment_details(items)
      [{
        item_list: {
          items: items },
        amount: {
          total: current_order.total,
          currency: current_order.currency },
        description: 'Does this description is showed to client?'
      }]
    end

    def completion_route(order)
      order_path(order)
    end
  end
end
