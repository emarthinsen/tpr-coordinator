FactoryGirl.define do
  factory :shipment do
    tracking_number random_tracking_number
    # Default to economy processng
    shipment_priority "economy"

    # Associations
    order

    factory :created do
      shipment_status "created"

      after :create do |created|
        create(:radio_inital_order, :shipment => created, serial_number: random_tpr_serial_number)
      end

      factory :express do
        shipment_priority "express"
      end

      factory :priority do
        shipment_priority "priority"
      end
    end

    factory :label_created do
        shipment_status "label_created"
        label_url "https://shippo-delivery-east.s3.amazonaws.com/some_label.pdf"

        after :create do |label_created|
          create(:radio_boxed, shipment: label_created, serial_number: random_tpr_serial_number)
          create(:radio_inital_order, shipment: label_created)
          create(:radio_inital_order, shipment: label_created)
        end

      factory :label_printed do
        shipment_status "label_printed"
      end

      factory :priority_processing do
        priority_processing true

        after :create do |label_created|
          create(:radio_boxed, shipment: label_created, serial_number: random_tpr_serial_number)
        end
      end
    end

    factory :boxed do
      shipment_status "boxed"
      ship_date "2017-07-28"

      after :create do |boxed|
        create(:radio_boxed, :shipment => boxed, serial_number: random_tpr_serial_number)
        create(:radio_boxed, :shipment => boxed, serial_number: random_tpr_serial_number)
        create(:radio_boxed, :shipment => boxed, serial_number: random_tpr_serial_number)
      end
    end

    factory :boxed_false do
      shipment_status "label_created"
      ship_date "2017-07-28"
    end

    factory :shipped do
      shipment_status "shipped"
      ship_date "2017-07-28"

      after :create do |shipped|
        create(:radio_boxed, :shipment => shipped, serial_number: random_tpr_serial_number)
        create(:radio_boxed, :shipment => shipped, serial_number: random_tpr_serial_number)
      end
    end
  end
end