require 'rails_helper'

RSpec.describe Shipment, type: :model do
  let(:model) { build(:shipped) }

  it 'valid with valid attributes' do
    expect(model).to be_valid
  end

  it 'is valid without a tracking_number' do
    model.tracking_number = nil
    expect(model).to be_valid
  end

  it 'is not valid with an not valid tracking number' do
    model.tracking_number = 'asdf3t45TRACKINGFAKE'
    expect(model).to_not be_valid
  end

  it 'is valid when date is nil' do
    model.ship_date = nil
    expect(model).to be_valid
  end

  it 'is valid when return_label_url is nil' do
    model.return_label_url = nil
    expect(model).to be_valid
  end

  context 'a shipment has a status that' do
    it 'has a valid shipment_status' do
      model.shipment_status = 'created'
      expect(model).to be_valid

      model.shipment_status = 'label_created'
      expect(model).to be_valid

      model.shipment_status = 'label_printed'
      expect(model).to be_valid

      model.shipment_status = 'shipped'
      expect(model).to be_valid

      model.shipment_status = 'boxed'
      expect(model).to be_valid

      model.shipment_status = 'transit'
      expect(model).to be_valid

      model.shipment_status = 'delivered'
      expect(model).to be_valid

      model.shipment_status = 'returned'
      expect(model).to be_valid

      model.shipment_status = 'failure'
      expect(model).to be_valid

      model.shipment_status = 'done'
      expect(model).to_not be_valid
    end
  end
end
