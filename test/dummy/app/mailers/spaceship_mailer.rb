# frozen_string_literal: true
class SpaceshipMailer < ApplicationMailer
  default from: 'starfleet@federation.gov'
  def mission_assignment(crew_member, spaceship)
    @crew_member = crew_member
    @spaceship = spaceship
    @mission_details = spaceship.current_mission

    mail(
      to: crew_member.email,
      subject: "Mission Assignment: #{spaceship.name}"
    )
  end

  def maintenance_notification(spaceship, crew_members)
    @spaceship = spaceship
    @crew_members = crew_members
    @maintenance_schedule = spaceship.maintenance_schedule

    mail(
      to: crew_members.map(&:email),
      subject: "Maintenance Schedule for #{spaceship.name}"
    )
  end

  def emergency_alert(message, recipients)
    @message = message
    @timestamp = Time.current
    @alert_level = message.priority

    mail(
      to: recipients,
      subject: "🚨 EMERGENCY ALERT: #{message.title}",
      priority: 'urgent'
    )
  end
end
