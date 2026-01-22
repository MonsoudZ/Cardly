class ApplicationMailer < ActionMailer::Base
  default from: "notifications@cardly.com"
  layout "mailer"
end
