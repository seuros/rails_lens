# frozen_string_literal: true
# Base mailer for all crew-related communications
class CrewMailer < ApplicationMailer
  default from: 'crew-services@federation.gov',
          reply_to: 'no-reply@federation.gov'
  def welcome_aboard(crew_member)
    @crew_member = crew_member
    @starfleet_handbook = attach_handbook

    mail(
      to: crew_member.email,
      subject: 'Welcome to Starfleet!'
    )
  end

  def promotion_notification(crew_member, old_rank, new_rank)
    @crew_member = crew_member
    @old_rank = old_rank
    @new_rank = new_rank
    @promotion_date = Date.current

    mail(
      to: crew_member.email,
      cc: crew_member.commanding_officer&.email,
      subject: "Congratulations on your promotion to #{new_rank}!"
    )
  end

  def medical_checkup_reminder(crew_member, appointment_date)
    @crew_member = crew_member
    @appointment_date = appointment_date
    @medical_bay = crew_member.current_assignment.medical_bay

    mail(
      to: crew_member.email,
      subject: 'Medical Checkup Reminder'
    )
  end

  private

  def attach_handbook
    attachments['starfleet_handbook.pdf'] = File.read(Rails.root.join('public', 'starfleet_handbook.pdf'))
  end
end
# Emergency mailer for urgent crew communications
class EmergencyCrewMailer < CrewMailer
  # Swap from and reply-to for emergency communications
  default from: 'no-reply@federation.gov',
          reply_to: 'crew-services@federation.gov'

  def emergency_alert(crew_member, alert_type, message)
    @crew_member = crew_member
    @alert_type = alert_type
    @message = message
    @timestamp = Time.current

    mail(
      to: crew_member.email,
      cc: crew_member.commanding_officer&.email,
      subject: "🚨 EMERGENCY ALERT: #{alert_type.upcase}",
      priority: 'high'
    )
  end

  def evacuation_notice(crew_member, evacuation_zone, assembly_point)
    @crew_member = crew_member
    @evacuation_zone = evacuation_zone
    @assembly_point = assembly_point
    @evacuation_time = Time.current

    mail(
      to: crew_member.email,
      subject: '🚨 EVACUATION NOTICE - IMMEDIATE ACTION REQUIRED',
      priority: 'high'
    )
  end
end
