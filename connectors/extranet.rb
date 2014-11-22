#! /usr/bin/env ruby
# encoding: utf-8

require 'httpi'
require 'nokogiri'
require 'smarter_csv'
require 'tempfile'


class Extranet


	class ExtranetError < StandardError; end


	def initialize(base_url, year)
		@base_url = base_url
		@year = year
		@session = nil
		HTTPI.log = false
	end

	def login(login, passwd)
		session_req = HTTPI::Request.new
		session_req.url = "#{@base_url}/#{@year}/Effectifs/accueil.php"
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

	def members()
		# retrieve extranet export
		members_req = HTTPI::Request.new
		members_req.url = "#{@base_url}/#{@year}/Effectifs/report_manager.php"
		members_req.body = {
			sid: @session,
			report_name: 'specExp01',
		}
		members_response = HTTPI::post(members_req)

		members_csv = nil

		# store export in temp file & extract csv data from temp file
		Tempfile.create(['members', '.csv'], :encoding => 'ascii-8bit') do |f|
			f.write(members_response.body)
			f.rewind

			# create and return ruby view of needed export data
			members_csv = SmarterCSV.process(
				f,
				:file_encoding => 'iso-8859-1',
				:col_sep => "\t",
				:key_mapping => {:id => :id, :mel => :email},
				:remove_unmapped_keys => true,
				:convert_values_to_numeric => {:only => :id}
			)
		end

		# extra data normalization
		if members_csv
			members_csv.map {|row| row[:email].downcase! if row[:email]}
		end

		return members_csv
	end

	def review(listname)
		# retrieve corresponding extranet export
		review_req = HTTPI::Request.new
		review_req.url = "#{@base_url}/#{@year}/Effectifs/report_manager.php"
		review_req.body = {
			sid: @session,
			report_name: 'LstActivClub',
			bool_i_have_criteria: true,
			'criteria[]' => ['', self.class.listid(listname), 'O'],
		}
		review_response = HTTPI::post(review_req)

		review_csv = nil

		# store export in temp file & extract csv data from temp file
		Tempfile.create(['review', '.csv'], :encoding => 'ascii-8bit') do |f|
			f.write(review_response.body)
			f.rewind

			# create and return array of ids belonging to list
			review_csv = SmarterCSV.process(
				f,
				:file_encoding => 'iso-8859-1',
				:col_sep => "\t",
				:key_mapping => {:id => :id},
				:remove_unmapped_keys => true,
				:convert_value_to_numeric => {:only => :id}
			)
		end

		return review_csv.map {|row| row[:id]} if review_csv

	end


	def self.listid(listname)
		case listname
		when 'esmug-gucem'
			return 'MLO'
		when 'esmug-gucem-discussion'
			return 'MLD'
		else
			raise ExtranetError, 'Unknown list'
		end
	end
end

