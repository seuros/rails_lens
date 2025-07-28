# frozen_string_literal: true

class SpaceshipsController < ApplicationController
  before_action :set_spaceship, only: %i[show edit update destroy]
  def index
    @spaceships = Spaceship.all
  end
  def show; end

  def new
    @spaceship = Spaceship.new
  end
  def create
    @spaceship = Spaceship.new(spaceship_params)

    if @spaceship.save
      redirect_to @spaceship, notice: 'Spaceship was successfully created.'
    else
      render :new
    end
  end

  def edit; end
  def update
    if @spaceship.update(spaceship_params)
      redirect_to @spaceship, notice: 'Spaceship was successfully updated.'
    else
      render :edit
    end
  end
  def destroy
    @spaceship.destroy
    redirect_to spaceships_url, notice: 'Spaceship was successfully destroyed.'
  end

  private

  def set_spaceship
    @spaceship = Spaceship.find(params[:id])
  end

  def spaceship_params
    params.require(:spaceship).permit(:name, :type, :status)
  end
end
