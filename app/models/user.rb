require 'digest/md5'

class User < ActiveRecord::Base
  devise :database_authenticatable, :recoverable, :trackable,
         :validatable, :timeoutable, :lockable,                # devise core model extensions
         :suspendable,  # in signonotron2/lib/devise/models/suspendable.rb
         :strengthened  # in signonotron2/lib/devise/models/strengthened.rb

  attr_accessible :uid, :name, :email, :password, :password_confirmation, :twitter, :github, :beard
  attr_readonly :uid

  def to_sensible_json
    to_json(:only => [:uid, :version, :name, :email, :github, :twitter])
  end

  def gravatar_url(opts = {})
    opts.symbolize_keys!
    qs = opts.select { |k, v| k == :s }.collect { |k, v| "#{k}=#{Rack::Utils.escape(v)}" }.join('&')
    qs = "?" + qs unless qs == ""

    "#{opts[:ssl] ? 'https://secure' : 'http://www'}.gravatar.com/avatar/" +
      Digest::MD5.hexdigest(email.downcase) + qs
  end
end
