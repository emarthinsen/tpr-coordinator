require 'gmail'

module TaskHelper
	attr_reader :gmail_client

	def calculate_shipping_and_handling(number_of_radios, shipment_priority)
	#        first class   priority  priority express
	# 1-pack    5.95         12.95      38.45
	# 2-pack                 7.95       38.45
	# 3-pack                 8.95       44.05

	  case shipment_priority
	  when 'economy'
	    # Economy packs over 1 have to go priority due to weight
	    case number_of_radios
	    when 1
	      5.95
	    when 2
	      7.95
	    when 3
	      8.95
	    end
	  when 'priority'
	    case number_of_radios
	    when 1
	      12.95
	    when 2
	      7.95
	    when 3
	      8.95
	    end
	  when 'express'
	    case number_of_radios
	    when 1
	      38.45
	    when 2
	      38.45
	    when 3
	      44.05
	    end
	  end
	end

	def shipment_priority_mapping(priority_string)
		priority_string =	priority_string.downcase
    if priority_string.include?('economy') || priority_string.include?('standard')
        'economy'
    elsif priority_string.include?('preferred') || priority_string.include?('priority')
        'priority'
    elsif priority_string.include?('express') || priority_string.include?('expedited')
        'express'
    end
  end

  def gmail_client
  	@gmail_client ||= Gmail.connect!(ENV['GMAIL_USERNAME'], ENV['GMAIL_PASSWORD'])
  end

  def send_email(email_params)
  	compose_email(email_params).deliver
  end

  def send_reply(email, email_params)
  	# build reply Mail object
  	message = email.reply()
  	# add / overwrite with new parameters
	  email_params.each do |k,v|
			message.send(k, v)
		end
		# send reply
  	gmail_client.deliver(message)
  end

  def compose_email(params)
  	gmail_client.compose do |email|
  		params.each do |k,v|
  			email.send(k, v)
  		end
  	end
  end

  def find_unread_emails
  	gmail_client.inbox.find(:unread)
  end

  def create_order(order_params)
    Rails.logger.info("Creating order with params: #{order_params}.")
    # Check if order has already been created
    if order_params[:reference_number].nil?
      unless Order.find_by_name(order_params[:name]).nil?
        Rails.logger.warn("Order already created for #{order_params[:name]}.")
      end
    else
      unless Order.find_by_reference_number(order_params[:reference_number]).nil?
        Rails.logger.warn("Skipping order import. Order already created for #{order_params[:name]}.")
        raise TPROrderAlreadyCreated
      end
    end
    OrdersController.new.make_queue_order_with_radios(order_params)
  end

  def clean_up_order(order_params)
    Rails.logger.info("Cleaning up order: #{order_params}.")

    if order_params[:reference_number].nil?
      order = Order.find_by_reference_number(order_params[:reference_number])
    else
      order = Order.find_by_name(order_params[:name])
    end

    # find shipments
    shipments = order.shipments
    if shipments.count != 0
      shipments.each do |shipment|
        # find radios
        radios = []
        shipment.radio.each{ |r| radios << r }
        if radios.count != 0
          radios.each do |radio|
            Rails.logger.info("Destroying radio #{radio.id}")
            radio.destroy
          end
        else
          Rails.logger.info("Shipment #{shipment.id} has no radios")
        end
        Rails.logger.info("Destroying shipment #{shipment.id}")
        shipment.destroy
      end
    else
      Rails.logger.info("Order #{order.id} has no shipments")
    end

    Rails.logger.info("Destroying order #{order.id}")
    order.destroy
  end

  def notify_of_import(order_source, failed_orders=[])
    # TODO: Add in number of successful vs errors. Or maybe just errors complete success.
    emails = ENV['EMAILS_TO_NOTIFY_OF_IMPORT'].split(',')
    emails.each do |email|
      Rails.logger.info("Notifying #{email} of successful import for #{order_source}")
      email_params = {
        subject: "TPR Coordinator: #{order_source.capitalize} Import Complete #{Date.today}",
        to: email,
        body: "Import complete with #{failed_orders.count} failed order(s)! \n #{failed_orders}"
      }

      send_email(email_params)
    end
  end

  class TPROrderAlreadyCreated < Exception
  end
end


