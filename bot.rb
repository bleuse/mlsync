#! /usr/bin/env ruby
# encoding: utf-8


require_relative 'connectors/sympa'
require_relative 'connectors/extranet'
require_relative 'credentials.rb' # configuration & credentials defined there


# Authentication #
##################

# FFCAM extranet
$extranet_ffcam = Extranet.new(url=$ffcam_url, year=$ffcam_year)
$extranet_ffcam.login(login=$ffcam_login, passwd=$ffcam_passwd)

# Gresille sympa
$sympa_gresille = Sympa.new($gresille_url)
$sympa_gresille.login(login=$gresille_login, passwd=$gresille_passwd)


# Mailing list synchronization #
################################

def synchronize(listname)
	# get list's subscribers from extranet
	ffcam_emails = $extranet_ffcam.review(listname)

	# get list's known emails
	gresille_emails = $sympa_gresille.review(listname)

	# get list's known removed emails (by admin or by user itself)
	gresille_signoff = $sympa_gresille.get_signoff(listname)

	# add missing emails to sympa
	new_emails = ffcam_emails - gresille_emails - gresille_signoff
	new_emails.each do |email|
		$sympa_gresille.add(listname=listname, email=email)
	end

	# summarize actions header
	puts '=' * 80
	puts "\" #{listname}"
	puts '=' * 80

	# summarize adds
	if not new_emails.empty?
		puts '" new users:'
		puts '-' * 40
		puts new_emails
	else
		puts '" no new users'
		puts '-' * 40
	end

	# warn signed-off ffcam users incoherences (database sync issue)
	warn_emails = ffcam_emails & gresille_signoff
	if not warn_emails.empty?
		puts
		puts '!!!!!    SIGNED-OFF FFCAM USERS    !!!!!'
		puts '-' * 40
		puts warn_emails
	end

end


mailing_lists = ['esmug-gucem', 'esmug-gucem-discussion']
mailing_lists.each do |listname|
	synchronize(listname)
	puts
end
