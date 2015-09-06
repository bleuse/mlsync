#! /usr/bin/env ruby
# encoding: utf-8

require './connectors/sympa'
require './connectors/extranet'
require './credentials.rb' # configuration & credentials defined there


##################
# Data retrieval #
##################

# FFCAM extranet
extranet_ffcam = Extranet.new(url=$ffcam_url, year=$ffcam_year)
extranet_ffcam.login(login=$ffcam_login, passwd=$ffcam_passwd)

ffcam_members = extranet_ffcam.members()
ffcam_members_by_id = Hash[ffcam_members.map {|h| [h[:id], h]}] if ffcam_members
ffcam_mlo = extranet_ffcam.review('esmug-gucem')
ffcam_mld = extranet_ffcam.review('esmug-gucem-discussion')

# Gresille sympa
sympa_gresille = Sympa.new($gresille_url)
sympa_gresille.login(login=$gresille_login, passwd=$gresille_passwd)

gresille_mlo = sympa_gresille.review(listname='esmug-gucem')
gresille_mld = sympa_gresille.review(listname='esmug-gucem-discussion')

################################
# Mailing list synchronization #
################################

# Offical mailing list
ffcam_mlo = ffcam_mlo.map{|id| ffcam_members_by_id[id][:email]}.compact
new_mlo_users = ffcam_mlo - gresille_mlo

new_mlo_users.each do |user|
	sympa_gresille.add(listname='esmug-gucem', email=user)
end

puts '=' * 80
puts '" MLO new users'
puts '=' * 80
puts new_mlo_users

# Discussion mailing list
ffcam_mld = ffcam_mld.map{|id| ffcam_members_by_id[id][:email]}.compact
new_mld_users = ffcam_mld - gresille_mld

new_mld_users.each do |user|
	sympa_gresille.add(listname='esmug-gucem-discussion', email=user)
end

puts '=' * 80
puts '" MLD new users'
puts '=' * 80
puts new_mld_users
