#! /usr/bin/env ruby
# encoding: utf-8


require_relative 'connectors/extranet'
require_relative 'connectors/sympa'
require_relative 'credentials.rb' # configuration & credentials defined there

require_relative 'helpers/patches/hash'


$sympa_gresille = Sympa.new($gresille_url)
$sympa_gresille.login(login=$gresille_login, passwd=$gresille_passwd)

$extranet_ffcam = Extranet.new(url=$ffcam_url, year=$ffcam_year)
$extranet_ffcam.login(login=$ffcam_login, passwd=$ffcam_passwd)


def synchronize(listname)
	#---------------------------------
	# PICK NEW EMAIL ADDRESSES TO ADD
	#---------------------------------

	# retrieve subscription request & sign-off event
	ffcam_request = $extranet_ffcam.review(listname)
	gresille_signoff = $sympa_gresille.get_signoff(listname)

	# drop subscription requests older than the log of sign-off span (we do
	# here conservative adds: meaning we do not add unless we are sure the
	# user really wants it)
	ffcam_request.reject! do |row|
		row[:date] < gresille_signoff[:valid_after]
	end

	# merge information on each email address
	considered_emails = {}
	ffcam_request.each do |row|
		next unless row[:email]
		content = {id: row[:id], email: row[:email], on: row[:date]}
		considered_emails[row[:email]] =
			considered_emails.fetch(row[:email], {}).merge(content)
	end
	gresille_signoff[:off].each do |row|
		next unless row[:email]
		content = {email: row[:email], off: row[:date]}
		considered_emails[row[:email]] =
			considered_emails.fetch(row[:email], {}).merge(content)
	end
	considered_emails = considered_emails.values

	# drop email addresses that signed off
	considered_emails.reject! do |row|
		row.key? :off and (!row.key? :on or row[:on] < row[:off])
	end

	# remove already subscribed emails
	gresille_members = $sympa_gresille.review(listname)
	new_emails = considered_emails.map {|row| row[:email]}
	new_emails -= gresille_members

	#-----------------------------------
	# PUSH NEW EMAIL ADDRESSES TO SYMPA
	#-----------------------------------

	# summarize actions header
	puts '=' * 80
	puts "\" #{listname}"
	puts '=' * 80

	# add new emails to sympa
	if not new_emails.empty?
		puts '" new users:'
		new_emails.each do |email|
#			$sympa_gresille.add(listname=listname, email=email)
			puts email
		end
	else
		puts '" no new users'
	end
end


mailing_lists = ['esmug-gucem', 'esmug-gucem-discussion']
mailing_lists.each do |listname|
	synchronize(listname)
	puts
end
