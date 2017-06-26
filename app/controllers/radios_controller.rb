class RadiosController < ApplicationController
  before_action :set_radio, only: [:show, :update, :destroy]

  # GET /radios
  # GET /radios.json
  def index
    @radios = Radio.all
  end

  # GET /radios/1
  # GET /radios/1.json
  def show
  end

  # POST /radios
  # POST /radios.json
  def create
    @radio = Radio.new(radio_params)

    if @radio.save
      render :show, status: :created, location: @radio
    else
      render json: @radio.errors, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /radios/1
  # PATCH/PUT /radios/1.json
  def update
    if @radio.update(radio_params)
      render :show, status: :ok, location: @radio
    else
      render json: @radio.errors, status: :unprocessable_entity
    end
  end

  # DELETE /radios/1
  # DELETE /radios/1.json
  def destroy
    @radio.destroy
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_radio
      @radio = Radio.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def radio_params
      params.require(:radio).permit(:frequency)
    end
end
