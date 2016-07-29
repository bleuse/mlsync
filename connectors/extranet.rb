# encoding: utf-8

# Copyright © 2016
# Contributed by Raphaël Bleuse <raphael@bleuse.net>
#
#   This program is free software: you can redistribute it and/or modify
#   it under the terms of the GNU General Public License as published by
#   the Free Software Foundation, either version 3 of the License, or
#   (at your option) any later version.
#
#   This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License
#   along with this program.  If not, see <http://www.gnu.org/licenses/>.

require 'httpi'
require 'nokogiri'
require 'smarter_csv'
require 'tempfile'

require_relative 'helper'
require_relative '../helpers/patches/hash'


class Extranet


	class ExtranetError < StandardError; end


	def initialize(base_url)
		@base_url = base_url
		@session = nil
		HTTPI.log = false
	end


	def login(login, passwd)
		session_req = HTTPI::Request.new
		session_req.url = "#{@base_url}/app/Effectifs/accueil.php"
		session_req.body = {
			str_action: 'login',
			str_login: login,
			str_password: passwd,
			bool_force_session: true,
		}
		session_response = HTTPI::post(session_req)
		session_html_doc = Nokogiri::HTML(session_response.body)
		@session = session_html_doc.at('#sid')[:value]
	end


	def dump_members()
		# retrieve extranet export
		members_req = HTTPI::Request.new
		members_req.url = "#{@base_url}/app/Effectifs/report_manager.php"
		members_req.body = {
			sid: @session,
			report_name: 'specExp01',
		}
		members_response = HTTPI::post(members_req)

		members_csv = nil

		# store export in temp file & extract csv data from temp file
		Tempfile.create(['members_', '.csv'], :encoding => 'ascii-8bit') do |f|
			f.write(members_response.body)
			f.rewind

			# create and return ruby view of needed export data
			members_csv = SmarterCSV.process(
				f,
				:file_encoding => 'iso-8859-1',
				:col_sep => "\t",
				:key_mapping => {
					:id => :id,
					:mel => :email,
					:mlo => :signon_mlo,
					:mld => :signon_mld
				},
				:remove_unmapped_keys => true,
				:convert_values_to_numeric => {:only => :id},
				:value_converters => {
					:signon_mlo => ExtranetDateParser,
					:signon_mld => ExtranetDateParser
				}

			)
		end

		# extra data normalization
		if members_csv
			members_csv.map do |row|
				row[:email].downcase! if row[:email]
			end
		end

		return members_csv
	end


	def review(listname)
		# map listname to key symbol in hash returned by dump_members
		_list_symbs = {
			'esmug-gucem' => :signon_mlo,
			'esmug-gucem-discussion' => :signon_mld
		}
		if not _list_symbs.key?(listname)
			raise ExtranetError, 'Unknown list: ' + listname
		end
		_list_key = _list_symbs[listname]

		# format response
		list_emails = dump_members()
		list_emails.map! do |row|
			row[:date] = row.delete(_list_key)
			row.slice(:id, :email, :date) if row[:date]
		end
		list_emails.compact!

		return list_emails
	end
end

