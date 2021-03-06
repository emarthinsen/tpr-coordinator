FactoryGirl.define do
  factory :base_radio, class: Radio do
    serial_number random_tpr_serial_number
    operator random_name
    pcb_version 'PR9026'
    firmware_version 'firmware_v1'
    quality_control_status 'passed'

    factory :radio_assembled, class: Radio do
      serial_number random_tpr_serial_number
      assembly_date Time.new
      boxed false

      factory :radio_boxed, class: Radio do
        serial_number random_tpr_serial_number
        frequency random_frequency
        country_code 'US'

        boxed true

        # Associations
        shipment
      end
    end
  end

  factory :radio_inital_order, class: Radio do
    frequency random_frequency
    boxed false
    country_code 'US'

    # Associations
    shipment
  end
end
