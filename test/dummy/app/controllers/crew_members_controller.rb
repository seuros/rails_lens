# frozen_string_literal: true

class CrewMembersController < ApplicationController
  before_action :authenticate_user!
  before_action :set_crew_member, only: %i[show edit update destroy]
  def index
    @crew_members = CrewMember.active.includes(:spaceships)
  end
  def show; end

  def new
    @crew_member = CrewMember.new
  end
  def create
    @crew_member = CrewMember.new(crew_member_params)

    if @crew_member.save
      redirect_to @crew_member, notice: 'Crew member was successfully created.'
    else
      render :new
    end
  end

  def edit; end
  def update
    if @crew_member.update(crew_member_params)
      redirect_to @crew_member, notice: 'Crew member was successfully updated.'
    else
      render :edit
    end
  end
  def destroy
    @crew_member.destroy
    redirect_to crew_members_url, notice: 'Crew member was successfully removed.'
  end
  def assign_to_ship
    @crew_member = CrewMember.find(params[:id])
    @spaceship = Spaceship.find(params[:spaceship_id])

    # Logic to assign crew member to spaceship
    redirect_to @crew_member, notice: 'Crew member assigned to spaceship.'
  end

  private

  def set_crew_member
    @crew_member = CrewMember.find(params[:id])
  end

  def crew_member_params
    params.require(:crew_member).permit(:name, :rank, :species, :birth_planet, :service_record, :active,
                                        :joined_starfleet_at, :status, :specialization)
  end
end
