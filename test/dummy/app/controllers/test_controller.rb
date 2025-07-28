# frozen_string_literal: true

class TestController < ApplicationController
  def index
    render json: {
      status: 'ok',
      models: ActiveRecord::Base.descendants.map(&:name).sort,
      rails_lens_version: RailsLens::VERSION
    }
  end
end
