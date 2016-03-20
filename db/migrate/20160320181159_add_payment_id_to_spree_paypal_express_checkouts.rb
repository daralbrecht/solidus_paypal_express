class AddPaymentIdToSpreePaypalExpressCheckouts < ActiveRecord::Migration
  def change
    add_column :spree_paypal_express_checkouts, :payment_id, :string
  end
end
